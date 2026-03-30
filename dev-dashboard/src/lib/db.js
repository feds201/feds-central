
import { neon } from '@neondatabase/serverless';

// Get database URL from environment
const databaseUrl = import.meta.env.VITE_DATABASE_URL;

if (!databaseUrl) {
  console.error('❌ VITE_DATABASE_URL is not set! Check your .env file.');
}

// Create a SQL query helper using Neon's serverless driver
const sql = databaseUrl ? neon(databaseUrl) : null;

/**
 * Execute a SQL query using Neon Serverless Driver.
 * 
 * @param {string} query - SQL query with $1, $2, etc. placeholders
 * @param {Array} params - Array of parameter values
 * @returns {Promise<Array>} Query results
 * 
 * @example
 * const users = await db('SELECT * FROM services WHERE owner_id = $1', [userId]);
 */
export const db = async (query, params = []) => {
  if (!sql) {
    throw new Error('Database not configured. Set VITE_DATABASE_URL in your .env file.');
  }
  
  try {
    // Use sql.query() for parameterized queries (new Neon API)
    const result = await sql.query(query, params);
    return result;
  } catch (error) {
    console.error('Database Error:', error.message);
    throw error;
  }
};

export { sql };
