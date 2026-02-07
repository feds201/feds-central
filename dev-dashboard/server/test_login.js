
import fetch from 'node-fetch'; // Might not be available? Node 18+ has global fetch.
// Node 25 is used (from error.txt). So global fetch is available.

async function testLogin() {
    console.log('Attempting login on port 3001...');
    try {
        const response = await fetch('http://localhost:3001/api/auth/login', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                email: 'feds.programming@gmail.com',
                password: 'password123' // Dummy password, expect 401 or 500
            })
        });

        console.log('Status:', response.status);
        const text = await response.text();
        console.log('Body:', text);
    } catch (e) {
        console.error('Fetch error:', e);
    }
}

testLogin();
