import { Pool } from 'pg';
import fs from 'fs';
import path from 'path';

export async function getConfig() {
  const configPath = path.join(process.cwd(), 'lookup-config.json');
  if (!fs.existsSync(configPath)) {
    throw new Error('Config not found. Please set up settings.');
  }
  return JSON.parse(fs.readFileSync(configPath, 'utf8'));
}

let pool: Pool | null = null;
let currentUrl: string | null = null;

export async function getPool() {
  const config = await getConfig();
  if (!config.neonUrl) {
    throw new Error('Database URL not configured.');
  }
  
  if (!pool || currentUrl !== config.neonUrl) {
    pool = new Pool({
      connectionString: config.neonUrl,
      ssl: { rejectUnauthorized: false }
    });
    currentUrl = config.neonUrl;
  }
  return pool;
}

export async function query(text: string, params?: any[]) {
  const pool = await getPool();
  return pool.query(text, params);
}