const { MongoClient } = require('mongodb');
const bcrypt = require('bcryptjs');
const dotenv = require('dotenv');
const path = require('path');

dotenv.config({ path: path.join(__dirname, '.env') });

async function seedUser() {
    const client = new MongoClient(process.env.MONGODB_URL || 'mongodb://localhost:27017');
    try {
        await client.connect();
        const db = client.db(process.env.DB_NAME || 'ovg_billing');
        const users = db.collection('users');

        const username = 'ideal@gmail.com';
        const plainPassword = 'vathadmin@123';

        // Remove existing user if any
        await users.deleteMany({ username });

        const hashed = await bcrypt.hash(plainPassword, 10);
        await users.insertOne({
            username,
            password: hashed,
            role: 'admin',
            createdAt: new Date(),
        });

        console.log('✅ User inserted successfully!');
        console.log(`   Username : ${username}`);
        console.log(`   Password : ${plainPassword}`);
    } catch (err) {
        console.error('❌ Error:', err.message);
    } finally {
        await client.close();
    }
}

seedUser();
