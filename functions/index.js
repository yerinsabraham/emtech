const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { RtcTokenBuilder, RtcRole } = require('agora-access-token');

admin.initializeApp();

// Agora Configuration — uses .env file (process.env)
const AGORA_APP_ID = process.env.AGORA_APP_ID || '';
const AGORA_APP_CERTIFICATE = process.env.AGORA_APP_CERTIFICATE || '';

/**
 * Generate Agora RTC Token
 * 
 * This function generates a token for a user to join an Agora voice/video channel.
 * The token is valid for 24 hours by default.
 * 
 * Request body:
 * - channelName: string (required) - The name of the channel
 * - uid: number (optional) - User ID, defaults to 0
 * - role: string (optional) - 'publisher' or 'audience', defaults to 'publisher'
 * - expirationTimeInSeconds: number (optional) - Token validity in seconds, defaults to 86400 (24 hours)
 * 
 * Response:
 * - token: string - The generated Agora token
 * - channelName: string - The channel name
 * - uid: number - The user ID
 * - expireTime: number - Unix timestamp when token expires
 */
exports.generateAgoraToken = functions.https.onCall(async (data, context) => {
  // Verify user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated to generate token'
    );
  }

  // Validate Agora configuration
  if (!AGORA_APP_ID || !AGORA_APP_CERTIFICATE) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'Agora credentials not configured. Run: firebase functions:config:set agora.app_id="YOUR_ID" agora.app_certificate="YOUR_CERT"'
    );
  }

  try {
    // Extract parameters
    const channelName = data.channelName;
    const uid = data.uid || 0;
    const role = data.role === 'audience' ? RtcRole.AUDIENCE : RtcRole.PUBLISHER;
    const expirationTimeInSeconds = data.expirationTimeInSeconds || 86400; // 24 hours

    // Validate channel name
    if (!channelName || typeof channelName !== 'string') {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Channel name is required and must be a string'
      );
    }

    // Calculate privilege expire time (current time + expiration)
    const currentTimestamp = Math.floor(Date.now() / 1000);
    const privilegeExpireTime = currentTimestamp + expirationTimeInSeconds;

    // Build the token
    const token = RtcTokenBuilder.buildTokenWithUid(
      AGORA_APP_ID,
      AGORA_APP_CERTIFICATE,
      channelName,
      uid,
      role,
      privilegeExpireTime
    );

    // Log token generation (for monitoring)
    console.log(`Token generated for user ${context.auth.uid}, channel: ${channelName}`);

    // Return token and metadata
    return {
      token: token,
      channelName: channelName,
      uid: uid,
      expireTime: privilegeExpireTime,
      appId: AGORA_APP_ID
    };
  } catch (error) {
    console.error('Error generating Agora token:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to generate token: ' + error.message
    );
  }
});

/**
 * Verify if Agora is properly configured
 * (Useful for debugging)
 */
exports.checkAgoraConfig = functions.https.onCall(async (data, context) => {
  // Only allow admins to check config
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  // Get user role from Firestore
  const userDoc = await admin.firestore().collection('users').doc(context.auth.uid).get();
  const userRole = userDoc.data()?.role;

  if (userRole !== 'admin') {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Only admins can check configuration'
    );
  }

  return {
    configured: !!(AGORA_APP_ID && AGORA_APP_CERTIFICATE),
    hasAppId: !!AGORA_APP_ID,
    hasAppCertificate: !!AGORA_APP_CERTIFICATE,
    message: (AGORA_APP_ID && AGORA_APP_CERTIFICATE) 
      ? 'Agora is properly configured' 
      : 'Agora credentials missing. Run: firebase functions:config:set agora.app_id="YOUR_ID" agora.app_certificate="YOUR_CERT"'
  };
});

/**
 * Clean up old call records (optional)
 * Runs daily to delete call records older than 30 days
 */
exports.cleanupOldCalls = functions.pubsub.schedule('every 24 hours').onRun(async (context) => {
  const thirtyDaysAgo = admin.firestore.Timestamp.fromDate(
    new Date(Date.now() - 30 * 24 * 60 * 60 * 1000)
  );

  const oldCalls = await admin.firestore()
    .collection('calls')
    .where('createdAt', '<', thirtyDaysAgo)
    .get();

  const batch = admin.firestore().batch();
  oldCalls.docs.forEach((doc) => {
    batch.delete(doc.ref);
  });

  await batch.commit();
  console.log(`Cleaned up ${oldCalls.size} old call records`);
  return null;
});

/**
 * Create Lecturer Account
 *
 * Called by admins to create a lecturer account without signing out the admin.
 * Uses the Admin SDK so the client session is unaffected.
 *
 * Request data:
 * - email: string (required)
 * - password: string (required)
 * - name: string (required)
 */
exports.createLecturerAccount = functions.https.onCall(async (data, context) => {
  // Verify caller is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'You must be logged in to create lecturer accounts.'
    );
  }

  // Verify caller is an admin by checking their Firestore role
  const callerDoc = await admin.firestore()
    .collection('users')
    .doc(context.auth.uid)
    .get();

  if (!callerDoc.exists || callerDoc.data().role !== 'admin') {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Only admins can create lecturer accounts.'
    );
  }

  const { email, password, name } = data;

  if (!email || !password || !name) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'email, password, and name are required.'
    );
  }

  try {
    // Create Firebase Auth user using Admin SDK (does NOT affect client session)
    const userRecord = await admin.auth().createUser({
      email: email.trim(),
      password: password,
      displayName: name.trim(),
    });

    // Write user document to Firestore
    await admin.firestore().collection('users').doc(userRecord.uid).set({
      uid: userRecord.uid,
      email: email.trim(),
      name: name.trim(),
      role: 'lecturer',
      emcBalance: 0,
      availableEMC: 0,
      stakedEMC: 0,
      unredeemedEMC: 0,
      totalEMCEarned: 0,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      isActive: true,
    });

    console.log(`Lecturer account created: ${userRecord.uid} (${email})`);
    return { uid: userRecord.uid, message: 'Lecturer account created successfully.' };

  } catch (error) {
    console.error('Error creating lecturer account:', error);
    if (error.code === 'auth/email-already-exists') {
      throw new functions.https.HttpsError(
        'already-exists',
        'An account with this email already exists.'
      );
    }
    throw new functions.https.HttpsError(
      'internal',
      error.message || 'Failed to create lecturer account.'
    );
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// PAYSTACK PAYMENT VERIFICATION
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Verify a Paystack transaction server-side.
 *
 * Request data:
 * - reference: string (required) — Paystack transaction reference
 *
 * Response:
 * - verified: boolean
 * - amount: number (in NGN, converted from kobo)
 * - reference: string
 * - channel: string
 *
 * Setup:
 *   firebase functions:config:set paystack.secret_key="sk_test_xxx"
 */
exports.verifyPaystackTransaction = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be logged in.');
  }

  const { reference } = data;
  if (!reference || typeof reference !== 'string') {
    throw new functions.https.HttpsError('invalid-argument', 'Transaction reference is required.');
  }

  const secretKey = process.env.PAYSTACK_SECRET_KEY;
  if (!secretKey) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'Paystack secret key not configured. Run: firebase functions:config:set paystack.secret_key="sk_test_xxx"'
    );
  }

  // Call Paystack verify endpoint using Node built-in https
  const https = require('https');
  const paystackResult = await new Promise((resolve, reject) => {
    const options = {
      hostname: 'api.paystack.co',
      path: `/transaction/verify/${encodeURIComponent(reference)}`,
      method: 'GET',
      headers: {
        Authorization: `Bearer ${secretKey}`,
        'Content-Type': 'application/json',
      },
    };
    const req = https.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => { body += chunk; });
      res.on('end', () => {
        try { resolve(JSON.parse(body)); }
        catch (e) { reject(new Error('Invalid JSON from Paystack: ' + body)); }
      });
    });
    req.on('error', reject);
    req.end();
  });

  if (!paystackResult.status || paystackResult.data?.status !== 'success') {
    console.warn(`Paystack verification failed for ${reference}:`, paystackResult.message);
    throw new functions.https.HttpsError(
      'failed-precondition',
      paystackResult.message || 'Payment verification failed.'
    );
  }

  const txData = paystackResult.data;
  const amountNGN = txData.amount / 100; // Paystack stores in kobo

  // Record verified transaction in Firestore
  await admin.firestore().collection('transactions').add({
    userId: context.auth.uid,
    type: 'paystack_payment',
    reference: txData.reference,
    amount: amountNGN,
    currency: txData.currency,
    status: txData.status,
    channel: txData.channel,
    customerEmail: txData.customer?.email || '',
    paidAt: txData.paid_at || null,
    metadata: txData.metadata || {},
    verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log(`Paystack verified: ${reference} — ₦${amountNGN} by ${context.auth.uid}`);
  return {
    verified: true,
    amount: amountNGN,
    reference: txData.reference,
    channel: txData.channel,
    currency: txData.currency,
  };
});

// ─────────────────────────────────────────────────────────────────────────────
// SCHEDULED: PROCESS OVERDUE LOANS
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Runs daily. Scans active loans where nextPaymentDue < now,
 * marks them overdue, and creates an in-app notification for the student.
 */
exports.processOverdueLoans = functions.pubsub.schedule('every 24 hours').onRun(async (context) => {
  const now = admin.firestore.Timestamp.now();

  const activeLoansSnap = await admin.firestore()
    .collection('loans')
    .where('status', '==', 'active')
    .get();

  if (activeLoansSnap.empty) {
    console.log('No active loans to process.');
    return null;
  }

  const batch = admin.firestore().batch();
  let overdueCount = 0;

  for (const loanDoc of activeLoansSnap.docs) {
    const loan = loanDoc.data();
    const nextDue = loan.nextPaymentDue;

    if (nextDue && nextDue.toDate() < now.toDate() && !loan.isOverdue) {
      // Mark loan overdue
      batch.update(loanDoc.ref, {
        isOverdue: true,
        overdueAt: now,
        updatedAt: now,
      });

      // Create in-app notification
      const notifRef = admin.firestore().collection('notifications').doc();
      batch.set(notifRef, {
        userId: loan.studentId,
        title: '⚠️ Loan Payment Overdue',
        message: `Your loan payment of ${loan.monthlyPayment} EMC was due and has not been received. Please make a payment to avoid penalties.`,
        type: 'loan_overdue',
        isRead: false,
        relatedId: loanDoc.id,
        createdAt: now,
      });

      overdueCount++;
    }
  }

  await batch.commit();
  console.log(`processOverdueLoans: marked ${overdueCount} loans overdue.`);
  return null;
});

// ─────────────────────────────────────────────────────────────────────────────
// SCHEDULED: RESET DAILY TASKS
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Runs every day at midnight WAT (UTC+1).
 * Deletes all userDailyTask completion records from previous days so
 * the daily task UI resets fresh for each user each morning.
 */
exports.resetDailyTasks = functions.pubsub
  .schedule('0 23 * * *') // 23:00 UTC = 00:00 WAT (Africa/Lagos, UTC+1)
  .timeZone('UTC')
  .onRun(async (context) => {
    const today = new Date();
    today.setUTCHours(0, 0, 0, 0);
    const todayTimestamp = admin.firestore.Timestamp.fromDate(today);

    const usersSnap = await admin.firestore().collection('users').select('uid').get();
    let totalDeleted = 0;

    for (const userDoc of usersSnap.docs) {
      const completionsSnap = await admin.firestore()
        .collection('userDailyTasks')
        .doc(userDoc.id)
        .collection('completions')
        .where('completedAt', '<', todayTimestamp)
        .get();

      if (completionsSnap.empty) continue;

      const batch = admin.firestore().batch();
      completionsSnap.docs.forEach((doc) => batch.delete(doc.ref));
      await batch.commit();
      totalDeleted += completionsSnap.size;
    }

    console.log(`resetDailyTasks: deleted ${totalDeleted} completion records.`);
    return null;
  });

// ─────────────────────────────────────────────────────────────────────────────
// FIRESTORE TRIGGER: SEND PUSH NOTIFICATION
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Fires whenever a new document is created in the `notifications` collection.
 * Looks up the target user's FCM tokens and sends a multicast push.
 * Auto-removes stale/invalid tokens from the user document.
 */
exports.sendPushNotification = functions.firestore
  .document('notifications/{notificationId}')
  .onCreate(async (snap, context) => {
    const notification = snap.data();
    if (!notification || !notification.userId) return null;

    const userId = notification.userId;

    const userDoc = await admin.firestore().collection('users').doc(userId).get();
    if (!userDoc.exists) return null;

    const fcmTokens = userDoc.data()?.fcmTokens;
    if (!fcmTokens || fcmTokens.length === 0) return null;

    const payload = {
      notification: {
        title: notification.title || 'EMTech School',
        body: notification.message || '',
      },
      data: {
        type: notification.type || 'general',
        notificationId: context.params.notificationId,
        relatedId: notification.relatedId || '',
      },
      tokens: fcmTokens,
    };

    try {
      const response = await admin.messaging().sendEachForMulticast(payload);
      console.log(`Push sent: ${response.successCount}/${fcmTokens.length} devices for user ${userId}`);

      // Prune invalid / unregistered tokens
      const staleTokens = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          const code = resp.error?.code || '';
          if (
            code === 'messaging/invalid-registration-token' ||
            code === 'messaging/registration-token-not-registered'
          ) {
            staleTokens.push(fcmTokens[idx]);
          }
        }
      });

      if (staleTokens.length > 0) {
        await admin.firestore().collection('users').doc(userId).update({
          fcmTokens: admin.firestore.FieldValue.arrayRemove(...staleTokens),
        });
        console.log(`Pruned ${staleTokens.length} stale FCM tokens for user ${userId}`);
      }
    } catch (error) {
      console.error('sendPushNotification error:', error);
    }

    return null;
  });

// ─────────────────────────────────────────────────────────────────────────────
// DELETE USER ACCOUNT
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Callable by the authenticated user to permanently delete their account.
 * Deletes: Firestore user doc, their transactions, notifications, then Auth account.
 */
exports.deleteUserAccount = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be logged in.');
  }

  const uid = context.auth.uid;

  try {
    const db = admin.firestore();

    // Delete sub-collections linked to this user
    const userDataCollections = [
      db.collection('transactions').where('userId', '==', uid),
      db.collection('notifications').where('userId', '==', uid),
      db.collection('rewards').where('userId', '==', uid),
      db.collection('stakes').where('userId', '==', uid),
    ];

    for (const query of userDataCollections) {
      const snap = await query.get();
      if (!snap.empty) {
        const batch = db.batch();
        snap.docs.forEach((doc) => batch.delete(doc.ref));
        await batch.commit();
      }
    }

    // Delete userDailyTasks subcollection
    const completionsSnap = await db
      .collection('userDailyTasks')
      .doc(uid)
      .collection('completions')
      .get();
    if (!completionsSnap.empty) {
      const batch = db.batch();
      completionsSnap.docs.forEach((doc) => batch.delete(doc.ref));
      await batch.commit();
    }
    await db.collection('userDailyTasks').doc(uid).delete();

    // Delete userAchievements
    const achievementsSnap = await db
      .collection('userAchievements')
      .doc(uid)
      .collection('achievements')
      .get();
    if (!achievementsSnap.empty) {
      const batch = db.batch();
      achievementsSnap.docs.forEach((doc) => batch.delete(doc.ref));
      await batch.commit();
    }
    await db.collection('userAchievements').doc(uid).delete();

    // Delete the main user document
    await db.collection('users').doc(uid).delete();

    // Delete Firebase Auth account last
    await admin.auth().deleteUser(uid);

    console.log(`User account deleted: ${uid}`);
    return { success: true, message: 'Account deleted successfully.' };

  } catch (error) {
    console.error(`Error deleting account for ${uid}:`, error);
    throw new functions.https.HttpsError('internal', error.message || 'Failed to delete account.');
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// SEED MOCK DATA
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Admin-only callable. Seeds mock data to Firestore for all categories.
 * All seeded documents are tagged with isMockData: true.
 *
 * Request data:
 * - category: string (optional) — 'books' | 'dailyTasks' | 'forumPosts' | 'blogPosts' | 'scholarships' | 'all'
 *   Defaults to 'all'.
 */
exports.seedMockData = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be logged in.');
  }
  const callerDoc = await admin.firestore().collection('users').doc(context.auth.uid).get();
  if (!callerDoc.exists || callerDoc.data().role !== 'admin') {
    throw new functions.https.HttpsError('permission-denied', 'Only admins can seed mock data.');
  }

  const category = data?.category || 'all';
  const db = admin.firestore();
  const now = admin.firestore.FieldValue.serverTimestamp();
  const seeded = {};

  // ── BOOKS ──────────────────────────────────────────────────────────────────
  if (category === 'all' || category === 'books') {
    const mockBooks = [
      { title: 'Introduction to Blockchain', author: 'Dr. Adamu Musa', description: 'Comprehensive guide to blockchain technology and its applications.', priceEmc: 500, category: 'Technology', coverImageUrl: 'https://picsum.photos/seed/book1/300/400', isMockData: true, createdAt: now },
      { title: 'Web3 Development Guide', author: 'Prof. Chioma Osei', description: 'Step-by-step guide to building decentralized applications.', priceEmc: 750, category: 'Technology', coverImageUrl: 'https://picsum.photos/seed/book2/300/400', isMockData: true, createdAt: now },
      { title: 'Financial Technology Fundamentals', author: 'Dr. Kwame Asante', description: 'Understanding fintech landscape in Africa and beyond.', priceEmc: 600, category: 'Finance', coverImageUrl: 'https://picsum.photos/seed/book3/300/400', isMockData: true, createdAt: now },
      { title: 'Smart Contract Programming', author: 'Eng. Fatima Al-Hassan', description: 'Write secure and efficient smart contracts on Ethereum.', priceEmc: 850, category: 'Technology', coverImageUrl: 'https://picsum.photos/seed/book4/300/400', isMockData: true, createdAt: now },
      { title: 'Digital Marketing Mastery', author: 'Ms. Amara Diallo', description: 'Modern digital marketing strategies for African businesses.', priceEmc: 400, category: 'Business', coverImageUrl: 'https://picsum.photos/seed/book5/300/400', isMockData: true, createdAt: now },
      { title: 'Cryptocurrency Investment Guide', author: 'Mr. Emeka Nwosu', description: 'Risk management and investment strategies in crypto markets.', priceEmc: 700, category: 'Finance', coverImageUrl: 'https://picsum.photos/seed/book6/300/400', isMockData: true, createdAt: now },
      { title: 'Data Science with Python', author: 'Dr. Yara Mensah', description: 'Machine learning and data analysis using Python.', priceEmc: 650, category: 'Technology', coverImageUrl: 'https://picsum.photos/seed/book7/300/400', isMockData: true, createdAt: now },
      { title: 'Entrepreneurship in Africa', author: 'Dr. Bola Adekunle', description: 'Building successful startups in the African ecosystem.', priceEmc: 450, category: 'Business', coverImageUrl: 'https://picsum.photos/seed/book8/300/400', isMockData: true, createdAt: now },
      { title: 'Mobile App Development', author: 'Eng. Seun Oladipo', description: 'Build cross-platform mobile apps with Flutter.', priceEmc: 800, category: 'Technology', coverImageUrl: 'https://picsum.photos/seed/book9/300/400', isMockData: true, createdAt: now },
      { title: 'African Tech Ecosystem', author: 'Prof. Nana Adjei', description: 'Overview of technology startups and innovation across Africa.', priceEmc: 350, category: 'Business', coverImageUrl: 'https://picsum.photos/seed/book10/300/400', isMockData: true, createdAt: now },
    ];
    const batch = db.batch();
    for (const book of mockBooks) {
      batch.set(db.collection('books').doc(), book);
    }
    await batch.commit();
    seeded.books = mockBooks.length;
  }

  // ── DAILY TASKS ────────────────────────────────────────────────────────────
  if (category === 'all' || category === 'dailyTasks') {
    const mockTasks = [
      { title: 'Watch a Course Lesson', description: 'Complete at least one lesson from any enrolled course.', rewardEmc: 50, category: 'learning', iconName: 'play_circle', isActive: true, isMockData: true, createdAt: now },
      { title: 'Post in the Forum', description: 'Share a thought, question, or resource in the student forum.', rewardEmc: 30, category: 'social', iconName: 'forum', isActive: true, isMockData: true, createdAt: now },
      { title: 'Review Your Notes', description: 'Spend 10 minutes reviewing your course notes or materials.', rewardEmc: 20, category: 'learning', iconName: 'notes', isActive: true, isMockData: true, createdAt: now },
      { title: 'Complete an Assignment', description: 'Submit a pending assignment before its due date.', rewardEmc: 100, category: 'achievement', iconName: 'assignment_turned_in', isActive: true, isMockData: true, createdAt: now },
      { title: 'Read a Blog Article', description: 'Read at least one article from the EMTech Blog.', rewardEmc: 25, category: 'learning', iconName: 'article', isActive: true, isMockData: true, createdAt: now },
      { title: 'Refer a Friend', description: 'Share your referral link with a friend.', rewardEmc: 150, category: 'social', iconName: 'group_add', isActive: true, isMockData: true, createdAt: now },
      { title: 'Daily Login Streak', description: 'Log in to EMTech School today to maintain your streak.', rewardEmc: 10, category: 'achievement', iconName: 'local_fire_department', isActive: true, isMockData: true, createdAt: now },
    ];
    const batch = db.batch();
    for (const task of mockTasks) {
      batch.set(db.collection('dailyTasks').doc(), task);
    }
    await batch.commit();
    seeded.dailyTasks = mockTasks.length;
  }

  // ── FORUM POSTS ────────────────────────────────────────────────────────────
  if (category === 'all' || category === 'forumPosts') {
    const mockPosts = [
      { authorId: 'mock_user_1', authorName: 'Amara Johnson', title: 'Best resources for learning Blockchain?', content: 'Hey everyone! I\'m new to blockchain development and looking for the best learning resources. Any recommendations from those who have been through the EMTech courses?', category: 'General Discussion', tags: ['blockchain', 'learning', 'resources'], likes: 24, replyCount: 8, isPinned: false, isMockData: true, createdAt: now },
      { authorId: 'mock_user_2', authorName: 'Kwame Osei', title: 'Tips for the EMC Staking System', content: 'I\'ve been staking my EMC tokens for the past month and the rewards are great! Here are some tips: Start early to build your tier, compound your rewards, and don\'t unstake unless necessary.', category: 'Tips & Tricks', tags: ['emc', 'staking', 'tips'], likes: 47, replyCount: 15, isPinned: true, isMockData: true, createdAt: now },
      { authorId: 'mock_user_3', authorName: 'Fatima Bello', title: 'Study Group for Web3 Development Course', content: 'Looking for fellow students taking the Web3 Development course to form a study group. We can meet virtually every weekend to discuss concepts and help each other with assignments.', category: 'Study Groups', tags: ['web3', 'study-group', 'collaboration'], likes: 31, replyCount: 22, isPinned: false, isMockData: true, createdAt: now },
      { authorId: 'mock_user_4', authorName: 'Emeka Nwosu', title: 'How I earned 5000 EMC in my first month', content: 'When I first joined EMTech School, I wasn\'t sure how the EMC system worked. After one month of completing daily tasks, submitting assignments on time, and participating in the forum, I\'ve earned over 5000 EMC!', category: 'Success Stories', tags: ['emc', 'success', 'motivation'], likes: 89, replyCount: 34, isPinned: false, isMockData: true, createdAt: now },
      { authorId: 'mock_user_5', authorName: 'Chidinma Eze', title: 'Question about the Loan System', content: 'Hi all, I\'m considering taking out an EMC loan to pay for the advanced blockchain course. Has anyone done this before? What\'s the repayment experience like?', category: 'General Discussion', tags: ['loan', 'courses', 'finance'], likes: 18, replyCount: 12, isPinned: false, isMockData: true, createdAt: now },
      { authorId: 'mock_user_6', authorName: 'Musa Ibrahim', title: 'Scholarship Application Tips', content: 'I recently got approved for the Merit Scholarship! Here are my tips: maintain a high GPA, participate actively in forums, and apply early. The scholarship covered 50% of my course fees!', category: 'Scholarships', tags: ['scholarship', 'tips', 'gpa'], likes: 62, replyCount: 28, isPinned: false, isMockData: true, createdAt: now },
    ];
    const batch = db.batch();
    for (const post of mockPosts) {
      batch.set(db.collection('forumPosts').doc(), post);
    }
    await batch.commit();
    seeded.forumPosts = mockPosts.length;
  }

  // ── BLOG POSTS ─────────────────────────────────────────────────────────────
  if (category === 'all' || category === 'blogPosts') {
    const mockBlogs = [
      { title: 'The Future of Blockchain Education in Africa', excerpt: 'How blockchain technology is revolutionizing educational credentials and opportunities across the African continent.', content: 'Africa is at the forefront of blockchain adoption, with Nigeria, Kenya, and South Africa leading the charge. EMTech School is proud to be part of this movement by providing world-class blockchain education that is accessible and affordable.\n\nBlockchain technology offers unprecedented opportunities for credential verification, reducing fraud and enabling seamless cross-border recognition of qualifications. Our graduates are already making waves in the global tech ecosystem.\n\nThe future is bright, and with the right education, African tech professionals are poised to lead the next wave of blockchain innovation.', author: 'EMTech Editorial Team', category: 'Technology', imageUrl: 'https://picsum.photos/seed/blog1/800/400', publishedAt: now, tags: ['blockchain', 'africa', 'education'], isMockData: true },
      { title: '5 Ways to Maximize Your EMC Token Earnings', excerpt: 'Smart strategies for earning and growing your EMC token balance while advancing your education at EMTech School.', content: 'EMC tokens are the lifeblood of the EMTech ecosystem. Here are 5 proven strategies to maximize your earnings:\n\n1. **Complete Daily Tasks**: Each task rewards you with EMC. Consistency compounds over time.\n2. **Submit Assignments Early**: Early submissions earn bonus EMC.\n3. **Achieve High Grades**: A+ grades reward up to 500 EMC per course.\n4. **Stake Your Tokens**: Staking generates passive EMC income.\n5. **Participate in Forums**: Active contributors earn community rewards.\n\nBy combining these strategies, top students earn over 10,000 EMC monthly.', author: 'Prof. Adaeze Williams', category: 'Finance', imageUrl: 'https://picsum.photos/seed/blog2/800/400', publishedAt: now, tags: ['emc', 'tokens', 'earnings'], isMockData: true },
      { title: 'EMTech Student Spotlight: From Zero to Blockchain Developer', excerpt: 'Meet Chidi Okonkwo, who went from a complete beginner to landing a job at a top blockchain firm in just 8 months.', content: 'Chidi Okonkwo never imagined he would be writing smart contracts for a living. Just 8 months ago, he was working as a shop attendant in Lagos with a burning desire to learn tech.\n\n"EMTech School changed my life," says Chidi. "The courses were practical, the lecturers were always available, and the EMC system motivated me to keep pushing."\n\nAfter completing the full blockchain development curriculum and maintaining a 4.2 GPA, Chidi was recruited by a leading DeFi startup. His starting salary was 5x his previous income.', author: 'EMTech Editorial Team', category: 'Success Stories', imageUrl: 'https://picsum.photos/seed/blog3/800/400', publishedAt: now, tags: ['success', 'student', 'career'], isMockData: true },
      { title: 'Understanding Web3 and Its Impact on Financial Inclusion', excerpt: 'How Web3 technologies are breaking down financial barriers and creating new opportunities for the unbanked population.', content: 'Over 1.4 billion adults worldwide remain unbanked, with a disproportionate concentration in sub-Saharan Africa. Web3 technologies — including DeFi protocols, stablecoins, and blockchain-based identity systems — offer a path to financial inclusion that traditional banking cannot.\n\nEMTech School\'s curriculum specifically addresses this opportunity, training students to build solutions that serve the underserved. Our graduates are already deploying DeFi applications that provide savings, lending, and insurance products to communities with no formal banking access.', author: 'Dr. Ngozi Adeyemi', category: 'Finance', imageUrl: 'https://picsum.photos/seed/blog4/800/400', publishedAt: now, tags: ['web3', 'defi', 'inclusion'], isMockData: true },
      { title: 'Announcing the EMTech Merit Scholarship 2026', excerpt: 'Applications are now open for our largest scholarship program yet, with over ₦5 million in awards available.', content: 'EMTech School is thrilled to announce the 2026 Merit Scholarship Program, our most ambitious initiative yet. We are committed to removing financial barriers from quality technology education.\n\n**Scholarship Tiers:**\n- Gold Scholarship: 100% tuition coverage (10 recipients)\n- Silver Scholarship: 75% tuition coverage (25 recipients)\n- Bronze Scholarship: 50% tuition coverage (50 recipients)\n\n**Eligibility:** Open to all enrolled students with a minimum GPA of 3.5.\n\n**Application Deadline:** March 31, 2026\n\nApply now through the Scholarship Board in the app!', author: 'EMTech Scholarship Committee', category: 'Announcements', imageUrl: 'https://picsum.photos/seed/blog5/800/400', publishedAt: now, tags: ['scholarship', 'announcement', 'funding'], isMockData: true },
      { title: 'The EMTech Staking System Explained', excerpt: 'A deep dive into how the EMC staking mechanism works, tier benefits, and strategies for maximizing your staking rewards.', content: 'The EMTech staking system is one of our most innovative features. By locking your EMC tokens, you earn passive rewards while contributing to the stability of the ecosystem.\n\n**Staking Tiers:**\n- Bronze (500+ EMC): 5% APY, basic voting rights\n- Silver (2,000+ EMC): 10% APY, priority course access\n- Gold (5,000+ EMC): 15% APY, + scholarship eligibility\n- Platinum (10,000+ EMC): 20% APY, governance voting\n\n**Compound Effect:** Reinvesting your staking rewards every month can grow a 1,000 EMC stake to over 2,000 EMC within 18 months at the Silver tier.\n\nThe staking system is open to all authenticated users. Start small and grow your position over time.', author: 'EMTech Finance Team', category: 'Technology', imageUrl: 'https://picsum.photos/seed/blog6/800/400', publishedAt: now, tags: ['staking', 'emc', 'defi'], isMockData: true },
    ];
    const batch = db.batch();
    for (const post of mockBlogs) {
      batch.set(db.collection('blogPosts').doc(), post);
    }
    await batch.commit();
    seeded.blogPosts = mockBlogs.length;
  }

  // ── SCHOLARSHIPS ───────────────────────────────────────────────────────────
  if (category === 'all' || category === 'scholarships') {
    const mockScholarships = [
      { title: 'EMTech Merit Scholarship', description: 'Awarded to high-achieving students with outstanding academic performance. Covers up to 100% of course fees.', type: 'merit', percentage: 100, depositRequired: 0, depositStatus: 'not_required', minimumGradeRequired: 'A', requirements: ['Minimum GPA 3.8', 'At least 2 completed courses', 'Active forum participant'], deadline: '2026-03-31', availableSlots: 10, isMockData: true, isActive: true, createdAt: now },
      { title: 'Need-Based Financial Aid', description: 'Financial assistance for students facing economic hardship. Covers up to 75% of course fees based on demonstrated need.', type: 'need_based', percentage: 75, depositRequired: 5000, depositStatus: 'pending', minimumGradeRequired: 'C', requirements: ['Proof of financial need', 'Minimum GPA 2.5', 'Interview required'], deadline: '2026-04-15', availableSlots: 25, isMockData: true, isActive: true, createdAt: now },
      { title: 'Women in Tech Scholarship', description: 'Empowering women to pursue careers in technology. Covers 50% of course fees for female students enrolled in tech courses.', type: 'diversity', percentage: 50, depositRequired: 0, depositStatus: 'not_required', minimumGradeRequired: 'B', requirements: ['Identify as female', 'Enrolled in a tech course', 'Personal statement required'], deadline: '2026-05-01', availableSlots: 30, isMockData: true, isActive: true, createdAt: now },
      { title: 'Innovation Challenge Scholarship', description: 'Awarded to students who submit the most innovative blockchain project proposal. Full scholarship + mentorship.', type: 'competition', percentage: 100, depositRequired: 0, depositStatus: 'not_required', minimumGradeRequired: 'B+', requirements: ['Submit original project proposal', 'Pass technical review', 'Presentation to panel'], deadline: '2026-06-30', availableSlots: 5, isMockData: true, isActive: true, createdAt: now },
    ];
    const batch = db.batch();
    for (const scholarship of mockScholarships) {
      batch.set(db.collection('scholarships').doc(), scholarship);
    }
    await batch.commit();
    seeded.scholarships = mockScholarships.length;
  }

  console.log(`seedMockData complete:`, seeded);
  return { success: true, seeded };
});

// ─────────────────────────────────────────────────────────────────────────────
// CLEANUP MOCK DATA
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Admin-only callable. Deletes all documents tagged with isMockData: true
 * from the specified category collection (or all categories).
 *
 * Request data:
 * - category: string — 'books' | 'dailyTasks' | 'forumPosts' | 'blogPosts' | 'scholarships' | 'all'
 */
exports.cleanupMockData = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be logged in.');
  }
  const callerDoc = await admin.firestore().collection('users').doc(context.auth.uid).get();
  if (!callerDoc.exists || callerDoc.data().role !== 'admin') {
    throw new functions.https.HttpsError('permission-denied', 'Only admins can clean up mock data.');
  }

  const category = data?.category || 'all';
  const db = admin.firestore();

  const collectionsToClean = {
    books: 'books',
    dailyTasks: 'dailyTasks',
    forumPosts: 'forumPosts',
    blogPosts: 'blogPosts',
    scholarships: 'scholarships',
  };

  const targets = category === 'all'
    ? Object.values(collectionsToClean)
    : [collectionsToClean[category]];

  if (!targets || targets.some((t) => !t)) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      `Invalid category "${category}". Must be one of: ${Object.keys(collectionsToClean).join(', ')}, or "all".`
    );
  }

  const deleted = {};

  for (const collectionName of targets) {
    const snap = await db.collection(collectionName)
      .where('isMockData', '==', true)
      .get();

    if (snap.empty) {
      deleted[collectionName] = 0;
      continue;
    }

    // Firestore batch supports max 500 ops; chunk if needed
    const chunkSize = 499;
    for (let i = 0; i < snap.docs.length; i += chunkSize) {
      const chunk = snap.docs.slice(i, i + chunkSize);
      const batch = db.batch();
      chunk.forEach((doc) => batch.delete(doc.ref));
      await batch.commit();
    }

    deleted[collectionName] = snap.size;
    console.log(`cleanupMockData: deleted ${snap.size} mock docs from ${collectionName}`);
  }

  return { success: true, deleted };
});
