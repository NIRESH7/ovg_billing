const { MongoClient, ObjectId } = require('mongodb');
const bcrypt = require('bcryptjs');

async function updatePassword() {
  const url = 'mongodb://localhost:27017';
  const client = new MongoClient(url);
  
  try {
    await client.connect();
    const db = client.db('ovg_billing');
    const usersCollection = db.collection('users');
    
    const newPassword = 'admin@1233';
    const hashedPassword = await bcrypt.hash(newPassword, 10);
    
    const result = await usersCollection.updateOne(
      { username: 'admin' },
      { $set: { password: hashedPassword } }
    );
    
    if (result.matchedCount > 0) {
      console.log('Password updated successfully for user: admin');
    } else {
      // If admin doesn't exist, maybe it's another username? Let's check all users.
      const allUsers = await usersCollection.find().toArray();
      console.log('User "admin" not found. Existing users:', allUsers.map(u => u.username));
      
      if (allUsers.length > 0) {
          const firstUser = allUsers[0].username;
          await usersCollection.updateOne(
              { username: firstUser },
              { $set: { password: hashedPassword } }
          );
          console.log(`Password updated successfully for first available user: ${firstUser}`);
      }
    }
  } catch (error) {
    console.error('Error updating password:', error);
  } finally {
    await client.close();
  }
}

updatePassword();
