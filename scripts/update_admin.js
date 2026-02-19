const admin = require('firebase-admin');

// Initialize Firebase Admin with project
admin.initializeApp({
  projectId: 'emtech-be4d4'
});

const db = admin.firestore();
const userId = 'uHC8qESLbtPpH61pUihkDS6B96n2'; // Your UID

async function updateRoleToAdmin() {
  try {
    console.log('🔍 Checking Firestore document...');
    
    const userRef = db.collection('users').doc(userId);
    const doc = await userRef.get();
    
    if (!doc.exists) {
      console.log('❌ Document does not exist! Creating it...');
      await userRef.set({
        uid: userId,
        email: 'yerinssaibs@gmail.com',
        name: 'Yerins Abraham',
        role: 'admin',
        emcBalance: 1000,
        availableEMC: 1000,
        totalEMCEarned: 1000,
        enrolledCourses: [],
        completedCourses: [],
        photoUrl: 'https://lh3.googleusercontent.com/a/ACg8ocIaMufpHqmNqIg5qwsW7OiQEwnY_1YEaRnKENF6uTWD0QTvre47=s96-c',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      });
      console.log('✅ Document created with admin role!');
    } else {
      console.log('📋 Document exists. Current role:', doc.data().role);
      await userRef.update({
        role: 'admin',
        updatedAt: new Date().toISOString()
      });
      console.log('✅ Role updated to admin!');
    }
    
    // Verify
    const verifyDoc = await userRef.get();
    console.log('🎉 VERIFIED - Role is now:', verifyDoc.data().role);
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
  
  process.exit(0);
}

updateRoleToAdmin();
