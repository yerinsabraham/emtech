# Phase 2 Backend Deployment Guide

## Firestore Security Rules

Add these rules to your `firestore.rules` file:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isAdmin() {
      return isAuthenticated() && 
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    function isLecturer() {
      return isAuthenticated() && 
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'lecturer';
    }
    
    function isStudent() {
      return isAuthenticated() && 
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'student';
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    function isEnrolled(courseId) {
      return exists(/databases/$(database)/documents/enrollments/$(request.auth.uid + '_' + courseId));
    }

    // Assignments Collection
    match /assignments/{assignmentId} {
      allow read: if isAuthenticated() && (
        isAdmin() || 
        isLecturer() || 
        (isStudent() && resource.data.isPublished == true && isEnrolled(resource.data.courseId))
      );
      allow create: if isLecturer() || isAdmin();
      allow update, delete: if isAdmin() || 
        (isLecturer() && resource.data.lecturerId == request.auth.uid);
    }

    // Exams Collection
    match /exams/{examId} {
      allow read: if isAuthenticated() && (
        isAdmin() || 
        isLecturer() || 
        (isStudent() && 
         resource.data.status == 'published' && 
         isEnrolled(resource.data.courseId))
      );
      allow create: if isLecturer() || isAdmin();
      allow update: if isAdmin() || 
        (isLecturer() && resource.data.lecturerId == request.auth.uid);
      allow delete: if isAdmin();
    }

    // Submissions Collection
    match /submissions/{submissionId} {
      allow read: if isAuthenticated() && (
        isAdmin() || 
        isOwner(resource.data.studentId) || 
        (isLecturer() && resource.data.courseId != null)
      );
      allow create: if isStudent() && isOwner(request.resource.data.studentId);
      allow update: if isAdmin() || 
        isLecturer() || 
        (isStudent() && isOwner(resource.data.studentId) && resource.data.status == 'pending');
      allow delete: if isAdmin();
    }

    // Content Collection
    match /content/{contentId} {
      allow read: if isAuthenticated() && (
        isAdmin() || 
        isLecturer() || 
        (isStudent() && isEnrolled(resource.data.courseId))
      );
      allow create: if isLecturer() || isAdmin();
      allow update, delete: if isAdmin() || 
        (isLecturer() && resource.data.uploadedBy == request.auth.uid) ||
        resource.data.uploadedBy == request.auth.uid;
    }

    // Grades Collection
    match /grades/{gradeId} {
      allow read: if isAuthenticated() && (
        isAdmin() || 
        isOwner(resource.data.studentId) || 
        isLecturer()
      );
      allow create, update: if isLecturer() || isAdmin();
      allow delete: if isAdmin();
    }

    // Enrollments Collection
    match /enrollments/{enrollmentId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update, delete: if isAdmin();
    }

    // Existing rules for other collections...
    // (users, courses, notifications, payments, wallets, etc.)
  }
}
```

## Firestore Indexes

Add these composite indexes in Firebase Console:

### 1. Assignments Index
- **Collection**: `assignments`
- **Fields**:
  - `courseId` (Ascending)
  - `isPublished` (Ascending)
  - `dueDate` (Ascending)

### 2. Assignments by Lecturer Index
- **Collection**: `assignments`
- **Fields**:
  - `lecturerId` (Ascending)
  - `createdAt` (Descending)

### 3. Exams Index
- **Collection**: `exams`
- **Fields**:
  - `courseId` (Ascending)
  - `status` (Ascending)
  - `startTime` (Ascending)

### 4. Exams by Lecturer Index
- **Collection**: `exams`
- **Fields**:
  - `lecturerId` (Ascending)
  - `createdAt` (Descending)

### 5. Exams Pending Approval
- **Collection**: `exams`
- **Fields**:
  - `status` (Ascending)
  - `createdAt` (Descending)

### 6. Submissions by Student Index
- **Collection**: `submissions`
- **Fields**:
  - `studentId` (Ascending)
  - `submittedAt` (Descending)

### 7. Submissions by Assignment
- **Collection**: `submissions`
- **Fields**:
  - `assignmentId` (Ascending)
  - `submittedAt` (Descending)

### 8. Submissions by Exam
- **Collection**: `submissions`
- **Fields**:
  - `examId` (Ascending)
  - `submittedAt` (Descending)

### 9. Content by Course Index
- **Collection**: `content`
- **Fields**:
  - `courseId` (Ascending)
  - `uploadedAt` (Descending)

### 10. Content by Uploader
- **Collection**: `content`
- **Fields**:
  - `uploadedBy` (Ascending)
  - `uploadedAt` (Descending)

### 11. Grades by Student Index
- **Collection**: `grades`
- **Fields**:
  - `studentId` (Ascending)
  - `gradedAt` (Descending)

### 12. Grades by Course
- **Collection**: `grades`
- **Fields**:
  - `courseId` (Ascending)
  - `gradedAt` (Descending)

## Firebase Storage Rules

Add these rules to your `storage.rules` file:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isAdmin() {
      return request.auth.token.role == 'admin';
    }
    
    function isLecturer() {
      return request.auth.token.role == 'lecturer';
    }
    
    // Assignment files
    match /assignments/{courseId}/{filename} {
      allow read: if isAuthenticated();
      allow write: if isLecturer() || isAdmin();
    }
    
    // Submission files
    match /submissions/{userId}/{filename} {
      allow read: if isAuthenticated() && (
        request.auth.uid == userId || 
        isLecturer() || 
        isAdmin()
      );
      allow write: if isAuthenticated() && request.auth.uid == userId;
    }
    
    // Content/Course Materials
    match /content/{courseId}/{filename} {
      allow read: if isAuthenticated();
      allow write: if isLecturer() || isAdmin();
    }
    
    // Exam files (if needed)
    match /exams/{courseId}/{filename} {
      allow read: if isAuthenticated();
      allow write: if isLecturer() || isAdmin();
    }
  }
}
```

## Deployment Steps

### 1. Deploy Firestore Rules
```bash
firebase deploy --only firestore:rules
```

### 2. Create Firestore Indexes

**Option A: Using Firebase Console**
1. Go to Firebase Console → Firestore Database → Indexes
2. Click "Create Index" for each index listed above
3. Set Collection ID and Fields as specified
4. Wait for index creation (can take 5-10 minutes)

**Option B: Using Firebase CLI** (Recommended)
Create `firestore.indexes.json`:

```json
{
  "indexes": [
    {
      "collectionGroup": "assignments",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "courseId", "order": "ASCENDING"},
        {"fieldPath": "isPublished", "order": "ASCENDING"},
        {"fieldPath": "dueDate", "order": "ASCENDING"}
      ]
    },
    {
      "collectionGroup": "assignments",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "lecturerId", "order": "ASCENDING"},
        {"fieldPath": "createdAt", "order": "DESCENDING"}
      ]
    },
    {
      "collectionGroup": "exams",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "courseId", "order": "ASCENDING"},
        {"fieldPath": "status", "order": "ASCENDING"},
        {"fieldPath": "startTime", "order": "ASCENDING"}
      ]
    },
    {
      "collectionGroup": "exams",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "lecturerId", "order": "ASCENDING"},
        {"fieldPath": "createdAt", "order": "DESCENDING"}
      ]
    },
    {
      "collectionGroup": "exams",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "status", "order": "ASCENDING"},
        {"fieldPath": "createdAt", "order": "DESCENDING"}
      ]
    },
    {
      "collectionGroup": "submissions",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "studentId", "order": "ASCENDING"},
        {"fieldPath": "submittedAt", "order": "DESCENDING"}
      ]
    },
    {
      "collectionGroup": "submissions",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "assignmentId", "order": "ASCENDING"},
        {"fieldPath": "submittedAt", "order": "DESCENDING"}
      ]
    },
    {
      "collectionGroup": "submissions",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "examId", "order": "ASCENDING"},
        {"fieldPath": "submittedAt", "order": "DESCENDING"}
      ]
    },
    {
      "collectionGroup": "content",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "courseId", "order": "ASCENDING"},
        {"fieldPath": "uploadedAt", "order": "DESCENDING"}
      ]
    },
    {
      "collectionGroup": "content",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "uploadedBy", "order": "ASCENDING"},
        {"fieldPath": "uploadedAt", "order": "DESCENDING"}
      ]
    },
    {
      "collectionGroup": "grades",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "studentId", "order": "ASCENDING"},
        {"fieldPath": "gradedAt", "order": "DESCENDING"}
      ]
    },
    {
      "collectionGroup": "grades",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "courseId", "order": "ASCENDING"},
        {"fieldPath": "gradedAt", "order": "DESCENDING"}
      ]
    }
  ],
  "fieldOverrides": []
}
```

Deploy indexes:
```bash
firebase deploy --only firestore:indexes
```

### 3. Deploy Storage Rules
```bash
firebase deploy --only storage
```

### 4. Initialize Collections (Optional)
Create initial documents to initialize collections:

```javascript
// Run in Firebase Console or Cloud Functions
const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();

// Initialize collections with placeholder docs (will be deleted)
async function initializeCollections() {
  const collections = ['assignments', 'exams', 'submissions', 'content', 'grades', 'enrollments'];
  
  for (const collection of collections) {
    await db.collection(collection).doc('_init').set({
      initialized: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    // Delete placeholder
    await db.collection(collection).doc('_init').delete();
  }
  
  console.log('Collections initialized');
}
```

## Update User Collection for EMC Tracking

Ensure all user documents have these fields:

```javascript
{
  uid: string,
  email: string,
  role: 'admin' | 'lecturer' | 'student',
  
  // Phase 2 Fields
  unredeemedEMC: number (default: 0),
  
  // Will be added in Phase 3
  totalEMCEarned: number (default: 0),
  stakedEMC: number (default: 0),
  availableEMC: number (default: 0),
}
```

## Monitoring & Testing

### Test Phase 2 Features:
1. **Lecturer Creates Assignment** → Check Firestore, Storage, Notifications
2. **Student Submits Assignment** → Verify file upload, submission doc created
3. **Lecturer Grades Submission** → Check grade recorded, EMC unredeemed updated
4. **Lecturer Creates Exam** → Submit for approval
5. **Admin Approves Exam** → Verify status change, notifications sent
6. **Student Takes Exam** → Auto-grading works
7. **Content Upload** → Files stored, permissions correct
8. **Grade Assignment** → EMC rewards calculated correctly
9. **Redeem EMC** → Wallet balance updated

### Monitoring Queries:
```javascript
// Monitor pending exams
db.collection('exams')
  .where('status', '==', 'pendingApproval')
  .onSnapshot(snapshot => {
    console.log('Pending exams:', snapshot.size);
  });

// Monitor submissions
db.collection('submissions')
  .where('status', '==', 'pending')
  .onSnapshot(snapshot => {
    console.log('Pending submissions:', snapshot.size);
  });
```

## Common Issues

### Issue: "Missing Index" Error
**Solution**: Check the error message for the index URL, click it to auto-create the index

### Issue: Permission Denied on Read/Write
**Solution**: Verify:
1. User is authenticated
2. User role is set correctly in Firestore
3. Security rules are deployed
4. Enrollment exists for course content

### Issue: File Upload Fails
**Solution**: Check:
1. Storage rules are deployed
2. File size limits (default 10MB for Firebase)
3. User has correct role
4. Filename/path is valid

## Phase 2 Backend Checklist

- [ ] Firestore security rules deployed
- [ ] All 12 Firestore indexes created
- [ ] Storage rules deployed
- [ ] User collection updated with EMC fields
- [ ] Test assignment creation
- [ ] Test submission flow
- [ ] Test exam approval workflow
- [ ] Test content upload
- [ ] Test grading & EMC rewards
- [ ] Monitor Firestore usage
- [ ] Set up billing alerts
- [ ] Configure backups

## Next: Phase 3 Backend Requirements

Phase 3 will require additional collections:
- `stakes` - EMC staking records
- `loans` - Student loan applications
- `loan_payments` - Loan repayment tracking
- `voting_power` - Stake-based voting records

These will be documented in Phase 3 deployment guide.

---

**Last Updated**: Phase 2 Complete
**Status**: ✅ Ready for Production Deployment
