import { startRegistration, startAuthentication } from '@simplewebauthn/browser';

const API_Base = '/api/auth';

// Try to refresh the access token using the httpOnly refresh cookie
const refreshAccessToken = async () => {
    const res = await fetch('/api/auth/refresh', {
        method: 'POST',
        credentials: 'include',
    });
    if (!res.ok) return null;
    const data = await res.json();
    if (data.token) {
        localStorage.setItem('token', data.token);
    }
    return data.token;
};

// Helper for authorized requests (auto-refreshes on 401/403)
const authFetch = async (url, options = {}) => {
    const makeRequest = (token) => {
        const headers = {
            'Content-Type': 'application/json',
            ...options.headers,
            ...(token ? { 'Authorization': `Bearer ${token}` } : {}),
        };
        return fetch(url, { ...options, headers, credentials: 'include' });
    };

    let token = localStorage.getItem('token');
    let res = await makeRequest(token);

    if (res.status === 401 || res.status === 403) {
        const newToken = await refreshAccessToken();
        if (newToken) {
            res = await makeRequest(newToken);
        } else {
            // Refresh failed — force logout
            api.signOut();
            throw new Error('Session expired');
        }
    }

    if (!res.ok) {
        const error = await res.json().catch(() => ({ error: 'Request failed' }));
        throw new Error(error.error || `Error ${res.status}`);
    }
    return res.json();
};

export const api = {
    // Sign Up
    signUp: async (email, password, fullName) => {
        const res = await fetch(`${API_Base}/signup`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            credentials: 'include',
            body: JSON.stringify({ email, password, full_name: fullName }),
        });

        if (!res.ok) {
            const err = await res.json();
            throw new Error(err.error || 'Signup failed');
        }

        const data = await res.json();
        if (data.token) {
            localStorage.setItem('token', data.token);
            localStorage.setItem('user', JSON.stringify(data.user));
        }
        return data;
    },

    // Login (Password)
    signIn: async (email, password) => {
        const res = await fetch(`${API_Base}/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            credentials: 'include',
            body: JSON.stringify({ email, password }),
        });

        if (!res.ok) {
            const err = await res.json();
            throw new Error(err.error || 'Login failed');
        }

        const data = await res.json();
        if (data.token) {
            localStorage.setItem('token', data.token);
            localStorage.setItem('user', JSON.stringify(data.user));
        }
        return data;
    },

    // Logout
    signOut: () => {
        localStorage.removeItem('token');
        localStorage.removeItem('user');
        window.location.href = '/sign-in';
    },

    // Get Session
    getSession: () => {
        const token = localStorage.getItem('token');
        const userStr = localStorage.getItem('user');
        if (!token || !userStr) return null;
        return { token, user: JSON.parse(userStr) };
    },

    // --- Passkeys ---

    // List Passkeys
    listPasskeys: async () => {
        return authFetch(`${API_Base}/passkey/list`);
    },

    // Register Passkey
    registerPasskey: async () => {
        try {
            // 1. Get options
            const options = await authFetch(`${API_Base}/passkey/register-options`, { method: 'POST' });

            // 2. Start ceremony
            const attResp = await startRegistration(options);

            // 3. Verify
            const verification = await authFetch(`${API_Base}/passkey/register-verify`, {
                method: 'POST',
                body: JSON.stringify(attResp),
            });

            return verification;
        } catch (err) {
            console.error(err);
            throw err;
        }
    },

    // Login with Passkey
    signInPasskey: async (email = null) => {
        try {
            // 1. Get options
            const res = await fetch(`${API_Base}/passkey/auth-options`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                credentials: 'include',
                body: JSON.stringify({ email }),
            });

            if (!res.ok) throw new Error('Failed to get auth options');
            const options = await res.json();

            // Extract challengeToken for resident key flow
            const { challengeToken, ...authOptions } = options;

            // 2. Start ceremony
            const asseResp = await startAuthentication(authOptions);

            // 3. Verify
            const verifyPayload = {
                body: asseResp,
                challengeToken // Will be undefined if not provided, which is fine
            };
            if (email) verifyPayload.email = email;

            const verifyRes = await fetch(`${API_Base}/passkey/auth-verify`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                credentials: 'include',
                body: JSON.stringify(verifyPayload),
            });

            if (!verifyRes.ok) {
                const err = await verifyRes.json();
                throw new Error(err.error || 'Verification failed');
            }

            const data = await verifyRes.json();
            if (data.token) {
                localStorage.setItem('token', data.token);
                localStorage.setItem('user', JSON.stringify(data.user));
            }
            return data;
        } catch (err) {
            console.error(err);
            throw err;
        }
    },

    // Delete Passkey
    deletePasskey: async (id) => {
        return authFetch(`${API_Base}/passkey/${id}`, { method: 'DELETE' });
    }
};
