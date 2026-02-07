
import bcrypt from 'bcrypt';

async function testBcrypt() {
    console.log('Testing bcrypt...');
    try {
        const salt = await bcrypt.genSalt(10);
        const hash = await bcrypt.hash('test', salt);
        console.log('Hash generated:', hash);
        const match = await bcrypt.compare('test', hash);
        console.log('Compare result:', match);
    } catch (e) {
        console.error('❌ bcrypt error:', e);
    }
}

testBcrypt();
