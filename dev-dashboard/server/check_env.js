
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: path.join(__dirname, '../.env') });

console.log('VITE_DATABASE_URL present:', !!process.env.VITE_DATABASE_URL);
if (process.env.VITE_DATABASE_URL) {
    console.log('Value starts with:', process.env.VITE_DATABASE_URL.substring(0, 15) + '...');
}
