
import { neon } from '@neondatabase/serverless';
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

// Load .env from project root
const __dirname = path.dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: path.join(__dirname, '../.env') });

const databaseUrl = process.env.VITE_DATABASE_URL;

if (!databaseUrl) {
    console.error('❌ VITE_DATABASE_URL is not set in .env file!');
}

const sql = neon(databaseUrl);

export { sql };
