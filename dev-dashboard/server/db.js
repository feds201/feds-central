
import { neon } from '@neondatabase/serverless';
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

// Load .env from project root
const __dirname = path.dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: path.join(__dirname, '../.env') });

const databaseUrl = process.env.VITE_DATABASE_URL;

let sql;

if (!databaseUrl) {
    console.warn('⚠️  VITE_DATABASE_URL is not set — running with mock database (dev mode)');
    // Mock sql tagged template that returns empty arrays
    sql = () => Promise.resolve([]);
} else {
    sql = neon(databaseUrl);
}

export { sql };
