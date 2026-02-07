
import express from 'express';
import cors from 'cors';
import jwt from 'jsonwebtoken';
import bcrypt from 'bcrypt';
import { sql } from './db.js';
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';
import { initDiscordBot, shutdownDiscordBot } from './discord-bot.js';

// Load env
const __dirname = path.dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: path.join(__dirname, '../.env') });

const app = express();
const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret-do-not-use-in-prod';

app.use(cors());
app.use(express.json());

// --- Database Init (Auto-run migration for dev convenience) ---
const initDb = async () => {
    try {
        console.log('Checking database tables...');
        // Create app_users
        await sql`
      CREATE TABLE IF NOT EXISTS public.app_users (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        full_name TEXT,
        created_at TIMESTAMPTZ DEFAULT now(),
        updated_at TIMESTAMPTZ DEFAULT now()
      )
    `;

        // Ensure current_challenge column exists
        try {
            await sql`ALTER TABLE public.app_users ADD COLUMN IF NOT EXISTS current_challenge TEXT`;
        } catch (e) {
            console.log('Column checks completed');
        }

        // Create passkey table if not exists
        await sql`
      CREATE TABLE IF NOT EXISTS public.passkey (
        id TEXT PRIMARY KEY,
        name TEXT,
        public_key TEXT NOT NULL,
        user_id TEXT NOT NULL,
        credential_id TEXT NOT NULL,
        counter INTEGER NOT NULL DEFAULT 0,
        device_type TEXT NOT NULL,
        backed_up BOOLEAN NOT NULL DEFAULT false,
        transports TEXT,
        created_at TIMESTAMPTZ DEFAULT now()
      )
    `;
        console.log('Database tables verified.');
    } catch (err) {
        console.error('Database init error:', err);
    }
};
initDb();

// --- Auth Routes ---

// Sign Up
app.post('/api/auth/signup', async (req, res) => {
    try {
        const { email, password, full_name } = req.body;

        if (!email || !password) {
            return res.status(400).json({ error: 'Email and password are required' });
        }

        // Check if user exists
        const existing = await sql`SELECT id FROM app_users WHERE email = ${email}`;
        if (existing.length > 0) {
            return res.status(400).json({ error: 'User already exists' });
        }

        const salt = await bcrypt.genSalt(10);
        const hash = await bcrypt.hash(password, salt);

        const result = await sql`
      INSERT INTO app_users (email, password_hash, full_name)
      VALUES (${email}, ${hash}, ${full_name || null})
      RETURNING id, email, full_name
    `;

        const user = result[0];
        const token = jwt.sign({ userId: user.id, email: user.email }, JWT_SECRET, { expiresIn: '7d' });

        res.json({ token, user });
    } catch (err) {
        console.error('Signup error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Login
app.post('/api/auth/login', async (req, res) => {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({ error: 'Email and password are required' });
        }

        const users = await sql`SELECT * FROM app_users WHERE email = ${email}`;
        if (users.length === 0) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }

        const user = users[0];
        const match = await bcrypt.compare(password, user.password_hash);

        if (!match) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }

        const token = jwt.sign({ userId: user.id, email: user.email }, JWT_SECRET, { expiresIn: '7d' });

        // Return user info (excluding hash)
        const { password_hash, ...userInfo } = user;
        res.json({ token, user: userInfo });
    } catch (err) {
        console.error('Login error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// --- Middleware ---

const authenticateToken = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) return res.sendStatus(401);

    jwt.verify(token, JWT_SECRET, (err, user) => {
        if (err) return res.sendStatus(403);
        req.user = user;
        next();
    });
};

// --- WebAuthn Config ---
import {
    generateRegistrationOptions,
    verifyRegistrationResponse,
    generateAuthenticationOptions,
    verifyAuthenticationResponse,
} from '@simplewebauthn/server';

const rpName = 'FEDS Dev Console';
const rpID = process.env.NODE_ENV === 'production' ? 'developer.feds201.com' : 'localhost';
const origin = process.env.NODE_ENV === 'production' ? 'https://developer.feds201.com' : `http://${rpID}:5173`;

// --- WebAuthn Routes ---

// 1. Register Passkey: Generate Options
app.post('/api/auth/passkey/register-options', authenticateToken, async (req, res) => {
    try {
        const user = req.user;

        // Get user's existing passkeys to exclude them
        const userPasskeys = await sql`SELECT credential_id FROM passkey WHERE user_id = ${user.userId}`;

        // Retrieve complete user object for challenge storage
        const users = await sql`SELECT * FROM app_users WHERE id = ${user.userId}`;
        const dbUser = users[0];

        if (!dbUser) {
            return res.status(404).json({ error: 'User not found' });
        }

        const options = await generateRegistrationOptions({
            rpName,
            rpID,
            userID: new Uint8Array(Buffer.from(dbUser.id)),
            userName: dbUser.email,
            attestationType: 'none',
            excludeCredentials: userPasskeys.map(pk => ({
                id: pk.credential_id,
                transports: pk.transports ? pk.transports.split(',') : [],
            })),
            authenticatorSelection: {
                residentKey: 'preferred',
                userVerification: 'preferred',
                authenticatorAttachment: 'platform',
            },
        });

        // Save challenge to DB
        await sql`UPDATE app_users SET current_challenge = ${options.challenge} WHERE id = ${user.userId}`;

        res.json(options);
    } catch (err) {
        console.error('Passkey register-options error:', err);
        res.status(500).json({ error: 'Failed to generate registration options', details: err.message });
    }
});

// 2. Register Passkey: Verify Response
app.post('/api/auth/passkey/register-verify', authenticateToken, async (req, res) => {
    try {
        const { body } = req; // The credential response
        const user = req.user;

        // Retrieve challenge
        const users = await sql`SELECT current_challenge FROM app_users WHERE id = ${user.userId}`;
        const currentChallenge = users[0]?.current_challenge;

        if (!currentChallenge) {
            return res.status(400).json({ error: 'No challenge found' });
        }

        let verification;
        try {
            verification = await verifyRegistrationResponse({
                response: body,
                expectedChallenge: currentChallenge,
                expectedOrigin: origin,
                expectedRPID: rpID,
            });
        } catch (error) {
            console.error(error);
            return res.status(400).json({ error: error.message });
        }

        const { verified, registrationInfo } = verification;

        // Debug logging
        console.log('Registration Info:', registrationInfo);

        if (verified && registrationInfo) {
            const { credentialDeviceType, credentialBackedUp } = registrationInfo;

            // Robustly extract ID - prefer base64url string from body, fallback to buffer from info
            const credentialID = body.id;

            if (!credentialID) {
                throw new Error('Missing credential ID');
            }

            // Extract Public Key
            let pubKeyBase64 = '';

            // Check top-level or nested credential object
            const pubKeyInfo = registrationInfo.credentialPublicKey || (registrationInfo.credential && registrationInfo.credential.publicKey);

            if (pubKeyInfo) {
                pubKeyBase64 = Buffer.from(pubKeyInfo).toString('base64');
            }

            if (!pubKeyBase64) {
                console.error('Missing public key. RegistrationInfo keys:', Object.keys(registrationInfo));
                if (registrationInfo.credential) {
                    console.error('Credential keys:', Object.keys(registrationInfo.credential));
                }
                return res.status(500).json({ error: 'Failed to extract public key' });
            }

            const newCounter = registrationInfo.counter || (registrationInfo.credential && registrationInfo.credential.counter) || 0;

            // Save new passkey
            await sql`
        INSERT INTO passkey (
          id, 
          name, 
          public_key, 
          user_id, 
          credential_id, 
          counter, 
          device_type, 
          backed_up, 
          transports
        ) VALUES (
          ${credentialID},
          ${'My Passkey'},
          ${pubKeyBase64},
          ${user.userId},
          ${credentialID},
          ${newCounter},
          ${credentialDeviceType || 'unknown'},
          ${credentialBackedUp || false},
          ${''} -- Transports not always returned
        )
      `;

            // Clear challenge
            await sql`UPDATE app_users SET current_challenge = NULL WHERE id = ${user.userId}`;

            res.json({ verified: true });
        } else {
            res.status(400).json({ verified: false, error: 'Verification failed' });
        }
    } catch (err) {
        console.error('Passkey register-verify error:', err);
        res.status(500).json({ error: 'Internal server error', details: err.message });
    }
});

// 3. Login: Generate Options (Public, step 1 of login)
app.post('/api/auth/passkey/auth-options', async (req, res) => {
    try {
        const { email } = req.body;

        // Scenario 1: User identifier provided (Non-discoverable / Discoverable)
        if (email) {
            const users = await sql`SELECT * FROM app_users WHERE email = ${email}`;
            const user = users[0];

            if (!user) {
                return res.status(400).json({ error: 'User not found' });
            }

            const userPasskeys = await sql`SELECT credential_id, transports FROM passkey WHERE user_id = ${user.id}`;

            const options = await generateAuthenticationOptions({
                rpID,
                allowCredentials: userPasskeys.map(pk => ({
                    id: pk.credential_id,
                    transports: pk.transports ? pk.transports.split(',') : [],
                })),
                userVerification: 'preferred',
            });

            // Save challenge to user
            await sql`UPDATE app_users SET current_challenge = ${options.challenge} WHERE id = ${user.id}`;

            return res.json(options);
        }

        // Scenario 2: No user identifier (Resident Key / Discoverable Credential)
        // We don't know who the user is yet, so we can't save the challenge to the DB user record.
        // We'll sign the challenge in a JWT and send it to the client.
        const options = await generateAuthenticationOptions({
            rpID,
            // keys: [], // No allowCredentials for resident keys
            userVerification: 'preferred',
        });

        // Create a stateless challenge token
        const challengeToken = jwt.sign(
            { challenge: options.challenge },
            JWT_SECRET,
            { expiresIn: '5m' }
        );

        // Return options + challengeToken
        // Note: The client lib will ignore extra props, but we need to pass it back in verify
        res.json({ ...options, challengeToken });

    } catch (err) {
        console.error('Passkey auth-options error:', err);
        res.status(500).json({ error: 'Failed to generate auth options' });
    }
});

// 4. Login: Verify Response (Public, step 2 of login)
// 4. Login: Verify Response (Public, step 2 of login)
app.post('/api/auth/passkey/auth-verify', async (req, res) => {
    try {
        const { email, body, challengeToken } = req.body; // body is the credential response

        let user;
        let expectedChallenge;

        if (email) {
            const users = await sql`SELECT * FROM app_users WHERE email = ${email}`;
            user = users[0];
            if (!user) return res.status(400).json({ error: 'User not found' });
            expectedChallenge = user.current_challenge;
        } else if (challengeToken) {
            // Verify token to get challenge
            try {
                const decoded = jwt.verify(challengeToken, JWT_SECRET);
                expectedChallenge = decoded.challenge;
            } catch (e) {
                return res.status(400).json({ error: 'Invalid or expired challenge token' });
            }
        } else {
            return res.status(400).json({ error: 'Missing email or challenge token' });
        }

        // Find which passkey was used
        const credentialID = body.id;
        const passkeys = await sql`SELECT * FROM passkey WHERE credential_id = ${credentialID}`;
        const passkey = passkeys[0];

        if (!passkey) {
            return res.status(400).json({ error: 'Passkey not found' });
        }

        // If we didn't have the user via email, we have them now via passkey
        if (!user) {
            const users = await sql`SELECT * FROM app_users WHERE id = ${passkey.user_id}`;
            user = users[0];
            if (!user) return res.status(400).json({ error: 'User not found for this passkey' });
        }

        // Check passkey object structure
        console.log('Found passkey:', {
            id: passkey.id,
            counter: passkey.counter,
            type: typeof passkey.counter,
            credId: passkey.credential_id
        });

        if (passkey.counter === undefined || passkey.counter === null) {
            console.error('Passkey counter is missing!');
            return res.status(500).json({ error: 'Stored passkey corrupted: missing counter' });
        }

        let verification;
        try {
            const verificationOpts = {
                response: body,
                expectedChallenge,
                expectedOrigin: origin,
                expectedRPID: rpID,
                credential: {
                    publicKey: Buffer.from(passkey.public_key, 'base64'),
                    id: passkey.credential_id, // v13+ might expect string or buffer, passkey.credential_id is base64url string usually
                    counter: Number(passkey.counter),
                    transports: passkey.transports ? passkey.transports.split(',') : [],
                },
            };

            // console.log('Verification Opts prepared');

            verification = await verifyAuthenticationResponse(verificationOpts);
        } catch (error) {
            console.error('verifyAuthenticationResponse threw:', error);
            // Print stack trace
            console.error(error.stack);
            return res.status(400).json({ error: error.message, stack: error.stack });
        }

        const { verified, authenticationInfo } = verification;

        if (verified) {
            // Update counter
            await sql`UPDATE passkey SET counter = ${authenticationInfo.newCounter} WHERE id = ${passkey.id}`;

            // Clear challenge if it was on user
            if (email) {
                await sql`UPDATE app_users SET current_challenge = NULL WHERE id = ${user.id}`;
            }

            // Issue JWT
            const token = jwt.sign({ userId: user.id, email: user.email }, JWT_SECRET, { expiresIn: '7d' });
            const { password_hash, ...userInfo } = user;

            res.json({ verified: true, token, user: userInfo });
        } else {
            res.status(400).json({ verified: false });
        }
    } catch (err) {
        console.error('Passkey auth-verify error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// List Passkeys (Protected)
app.get('/api/auth/passkey/list', authenticateToken, async (req, res) => {
    try {
        const user = req.user;
        const passkeys = await sql`SELECT id, name, created_at FROM passkey WHERE user_id = ${user.userId} ORDER BY created_at DESC`;
        res.json(passkeys);
    } catch (err) {
        console.error('List passkeys error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Delete Passkey (Protected)
app.delete('/api/auth/passkey/:id', authenticateToken, async (req, res) => {
    try {
        const user = req.user;
        const passkeyId = req.params.id;

        // Verify ownership
        const passkeys = await sql`SELECT user_id FROM passkey WHERE id = ${passkeyId}`;
        const passkey = passkeys[0];

        if (!passkey) {
            return res.status(404).json({ error: 'Passkey not found' });
        }

        if (passkey.user_id !== user.userId) {
            return res.status(403).json({ error: 'Unauthorized' });
        }

        await sql`DELETE FROM passkey WHERE id = ${passkeyId}`;
        res.json({ success: true });
    } catch (err) {
        console.error('Delete passkey error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Only start server if run directly (local dev)
if (process.env.NODE_ENV !== 'production' && process.argv[1] === fileURLToPath(import.meta.url)) {
    app.listen(PORT, () => {
        console.log(`Server running on http://localhost:${PORT}`);

        // Start Discord bot
        initDiscordBot();
    });

    // Graceful shutdown
    process.on('SIGINT', async () => {
        console.log('\nShutting down gracefully...');
        await shutdownDiscordBot();
        process.exit(0);
    });
}

export default app;
