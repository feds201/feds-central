
import { neon } from '@neondatabase/serverless';
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: path.join(__dirname, '../.env') });

const sql = neon(process.env.VITE_DATABASE_URL);

async function testDb() {
    try {
        console.log('Testing DB connection...');
        const result = await sql`SELECT now()`;
        console.log('✅ DB Connected. Server time:', result[0].now);

        console.log('Checking app_users table...');
        const users = await sql`SELECT count(*) FROM app_users`;
        console.log('User count:', users[0].count);
    } catch (err) {
        console.error('❌ DB Error:', err);
    }
}

testDb();
