
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

async function check() {
    console.log('Checking dependencies...');
    try {
        await import('express');
        console.log('✅ express found');
    } catch (e) { console.error('❌ express missing'); }

    try {
        await import('@neondatabase/serverless');
        console.log('✅ @neondatabase/serverless found');
    } catch (e) { console.error('❌ @neondatabase/serverless missing'); }

    try {
        await import('dotenv');
        console.log('✅ dotenv found');
    } catch (e) { console.error('❌ dotenv missing'); }

    // Check .env
    const envPath = path.join(__dirname, '../.env');
    if (fs.existsSync(envPath)) {
        console.log('✅ .env file exists');
        // We can't read it easily due to ignore, but we know it's there.
    } else {
        console.log('❌ .env file missing at ' + envPath);
    }
}

check();
