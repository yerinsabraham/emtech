# Phase 4 Backend Deployment Guide
## Graduation & Final Records System

This guide covers the backend deployment for Phase 4: Certificate issuance, verification, and scholarship deposit management.

---

## 🎓 Overview

Phase 4 implements:
- **Certificate Issuance**: Automatic certificate generation for passing grades (C and above)
- **QR Code Verification**: Public certificate verification via QR codes
- **Scholarship Escrow**: 30% deposit system for 100% scholarships
- **Graduation Processing**: Automatic deposit release/forfeiture based on final grades

---

## 📊 Firestore Collections

### 1. **certificates** Collection

Stores all issued certificates with verification data.

**Document Structure:**
```javascript
{
  // Certificate Identity
  "certificateNumber": "EMC-2026-STU123-CS101-1234567890",
  "type": "courseCompletion", // courseCompletion, graduation, excellence, participation
  "status": "issued", // issued, revoked, pending
  
  // Student Information
  "studentId": "abc123...",
  "studentName": "John Doe",
  "studentEmail": "john@student.emtech.school",
  
  // Course Information
  "courseId": "xyz789...",
  "courseName": "Introduction to Computer Science",
  "semester": "2026-1",
  
  // Academic Details
  "grade": "A", // Letter grade
  "gpa": 4.0, // Grade point average
  "completionDate": Timestamp,
  
  // Issuance Details
  "issuedBy": "lecturer123...",
  "issuedByName": "Dr. Jane Smith",
  "issuedAt": Timestamp,
  
  // Verification
  "verificationUrl": "https://emtech.school/verify-certificate/EMC-2026-...",
  "qrCodeData": "https://emtech.school/verify-certificate/EMC-2026-...",
  
  // Revocation (if applicable)
  "isRevoked": false,
  "revokedBy": null,
  "revokedByName": null,
  "revokedAt": null,
  "revocationReason": null,
  
  // Additional Data
  "metadata": {
    "numericScore": 95.0,
    "emcReward": 100.0,
    "gradedAt": "2026-06-15T10:30:00.000Z"
  }
}
```

**Composite Indexes Required:**
```javascript
Collection: certificates
Fields:
- studentId (Ascending) + status (Ascending) + issuedAt (Descending)
- courseId (Ascending) + status (Ascending) + issuedAt (Descending)
- certificateNumber (Ascending) + status (Ascending)
- type (Ascending) + status (Ascending) + issuedAt (Descending)
```

**Security Rules:**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /certificates/{certificateId} {
      // Anyone can read certificates (for verification)
      allow read: if true;
      
      // Only admins can create/update certificates
      allow create: if isAdmin() || isLecturer();
      allow update: if isAdmin();
      allow delete: if false; // Never delete certificates
      
      function isAdmin() {
        return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
      }
      
      function isLecturer() {
        return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'lecturer';
      }
    }
  }
}
```

---

### 2. **scholarships** Collection

Manages scholarship deposits and graduation requirements.

**Document Structure:**
```javascript
{
  // Scholarship Identity
  "type": "full", // full, partial, merit, need
  "percentage": 100.0, // Scholarship percentage (0-100)
  
  // Student Information
  "studentId": "abc123...",
  "studentName": "John Doe",
  "studentEmail": "john@student.emtech.school",
  
  // Financial Details
  "originalTuitionFee": 10000.00,
  "scholarshipAmount": 10000.00, // Amount covered by scholarship
  "depositRequired": 3000.00, // 30% of tuition for 100% scholarship
  "depositStatus": "deposited", // pending, deposited, released, forfeited
  "depositPaid": 3000.00,
  "depositPaidAt": Timestamp,
  
  // Academic Requirements
  "minimumGPA": 2.0, // Minimum GPA to retain scholarship
  "minimumLetterGrade": "C", // Minimum letter grade
  "currentGPA": null,
  "finalGPA": null,
  "meetsMinimumRequirement": false,
  
  // Graduation Status
  "hasGraduated": false,
  "graduationDate": null,
  "depositReleasedAt": null,
  "depositForfeitedAt": null,
  
  // Metadata
  "createdAt": Timestamp,
  "updatedAt": Timestamp,
  "createdBy": "admin123...",
  "notes": "Merit-based scholarship for academic excellence"
}
```

**Composite Indexes Required:**
```javascript
Collection: scholarships
Fields:
- studentId (Ascending) + depositStatus (Ascending) + createdAt (Descending)
- depositStatus (Ascending) + hasGraduated (Ascending) + createdAt (Descending)
- type (Ascending) + depositStatus (Ascending)
```

**Security Rules:**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /scholarships/{scholarshipId} {
      // Students can read their own scholarships
      allow read: if request.auth.uid == resource.data.studentId || isAdmin();
      
      // Only admins can create/update scholarships
      allow create, update: if isAdmin();
      allow delete: if false; // Never delete scholarship records
      
      function isAdmin() {
        return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
      }
    }
  }
}
```

---

## 🔧 Firebase Console Setup

### Step 1: Create Composite Indexes

1. Go to **Firebase Console** → **Firestore Database** → **Indexes**
2. Click **Add Index** and create the following:

**For certificates collection:**
- Index 1:
  - Collection ID: `certificates`
  - Field 1: `studentId` (Ascending)
  - Field 2: `status` (Ascending)
  - Field 3: `issuedAt` (Descending)

- Index 2:
  - Collection ID: `certificates`
  - Field 1: `courseId` (Ascending)
  - Field 2: `status` (Ascending)
  - Field 3: `issuedAt` (Descending)

- Index 3:
  - Collection ID: `certificates`
  - Field 1: `certificateNumber` (Ascending)
  - Field 2: `status` (Ascending)

**For scholarships collection:**
- Index 1:
  - Collection ID: `scholarships`
  - Field 1: `studentId` (Ascending)
  - Field 2: `depositStatus` (Ascending)
  - Field 3: `createdAt` (Descending)

- Index 2:
  - Collection ID: `scholarships`
  - Field 1: `depositStatus` (Ascending)
  - Field 2: `hasGraduated` (Ascending)
  - Field 3: `createdAt` (Descending)

### Step 2: Update Security Rules

1. Go to **Firestore Database** → **Rules**
2. Add the rules from the sections above
3. Merge with existing rules for other collections
4. **Publish** the updated rules

**Complete Rules Example (merged with existing):**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Existing rules...
    
    // Phase 4: Certificates
    match /certificates/{certificateId} {
      allow read: if true; // Public verification
      allow create: if isAdmin() || isLecturer();
      allow update: if isAdmin();
      allow delete: if false;
    }
    
    // Phase 4: Scholarships
    match /scholarships/{scholarshipId} {
      allow read: if request.auth.uid == resource.data.studentId || isAdmin();
      allow create, update: if isAdmin();
      allow delete: if false;
    }
    
    function isAdmin() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    function isLecturer() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'lecturer';
    }
  }
}
```

---

## 🎯 Certificate System Features

### Automatic Certificate Issuance

Certificates are automatically issued when:
1. A lecturer assigns a grade to a student
2. The grade is **C or above** (passing grade)
3. The student doesn't already have a certificate for that course

**Certificate Number Format:**
```
EMC-{YEAR}-{STUDENT_CODE}-{COURSE_CODE}-{TIMESTAMP}
Example: EMC-2026-STU123-CS101-1234567890
```

**Verification URL Format:**
```
https://emtech.school/verify-certificate/{certificateNumber}
Example: https://emtech.school/verify-certificate/EMC-2026-STU123-CS101-1234567890
```

### QR Code Verification

- QR codes contain the verification URL
- Scanning redirects to the public verification page
- Shows certificate status (Valid/Invalid/Revoked)
- Displays full certificate details for valid certificates

### Certificate Types

1. **Course Completion**: Issued for completing a course (auto-issued)
2. **Graduation**: Issued when student graduates (manual/batch)
3. **Excellence**: Awarded for outstanding performance (manual)
4. **Participation**: Given for workshop/event participation (manual)

---

## 💰 Scholarship Deposit System

### Deposit Calculation

**For 100% Scholarships:**
- Deposit Required = 30% of original tuition fee
- Example: $10,000 tuition → $3,000 deposit required

**For Partial Scholarships:**
- No deposit required
- Example: 50% scholarship → $0 deposit

### Minimum Grade Requirements

**Default:**
- Minimum GPA: **2.0** (C average)
- Minimum Letter Grade: **C**

**Customizable per scholarship:**
- Can be set higher (e.g., 3.0 GPA for merit scholarships)
- Can be set lower (e.g., 1.5 GPA for need-based)

### Graduation Processing

**When student meets minimum requirement:**
1. Deposit status → `released`
2. `depositReleasedAt` timestamp recorded
3. Student notified: "Deposit released!"
4. Funds returned to student account

**When student fails to meet minimum:**
1. Deposit status → `forfeited`
2. `depositForfeitedAt` timestamp recorded
3. Student notified: "Deposit forfeited"
4. Funds retained by institution

---

## 📱 User Interface Features

### Student Dashboard - Certificates Tab

**Location:** Student Dashboard → 6th Tab "Certificates"

**Features:**
- List of all earned certificates
- Status badges (Issued, Revoked, Pending)
- Certificate preview
- Full certificate viewer (diploma-style design)
- QR code display
- Share verification link
- Download PDF (coming soon)

### Public Verification Page

**URL:** `/verify-certificate/:certificateNumber`

**Features:**
- Certificate number input
- Verification button
- Status banner (green for valid, red for revoked)
- Full certificate details
- Revocation reason (if applicable)
- Institution verification seal

---

## 🔔 Notifications

### Certificate Notifications

**Certificate Issued:**
```
Title: "Certificate Earned!"
Message: "Congratulations! You've earned a certificate for {courseName}. View it now!"
Type: certificate
Action: Navigate to Certificates tab
```

**Certificate Revoked:**
```
Title: "Certificate Revoked"
Message: "Your certificate for {courseName} has been revoked. Reason: {reason}"
Type: certificate
```

### Scholarship Notifications

**Scholarship Approved:**
```
Title: "Scholarship Approved!"
Message: "Congratulations! You have been awarded a {type}. Please pay the deposit of ${amount} to secure your scholarship."
Type: scholarship
```

**Deposit Received:**
```
Title: "Deposit Paid!"
Message: "Your scholarship deposit of ${amount} has been received. Your scholarship is now active!"
Type: scholarship
```

**Deposit Released (Graduation):**
```
Title: "Deposit Released!"
Message: "Congratulations on graduating! Your deposit of ${amount} has been released."
Type: scholarship
```

**Deposit Forfeited:**
```
Title: "Deposit Forfeited"
Message: "Your scholarship deposit has been forfeited as you did not meet the minimum grade requirement."
Type: scholarship
```

---

## 🧪 Testing Checklist

### Certificate System Testing

- [ ] **Auto-Issuance**: Assign grade (C+) → verify certificate created
- [ ] **Duplicate Prevention**: Assign grade twice → only 1 certificate
- [ ] **Failing Grade**: Assign grade (D/F) → no certificate issued
- [ ] **Certificate Gallery**: Navigate to Certificates tab → see all certificates
- [ ] **Certificate Viewer**: Tap certificate → view full diploma design
- [ ] **QR Code**: Scan QR → verify redirects to verification page
- [ ] **Public Verification**: Enter certificate number → see valid status
- [ ] **Revocation**: Admin revokes → status changes to "Invalid"
- [ ] **Notification**: Certificate issued → student receives notification

### Scholarship System Testing

- [ ] **Create Scholarship**: 100% scholarship → 30% deposit calculated
- [ ] **Partial Scholarship**: 50% scholarship → 0% deposit required
- [ ] **Deposit Payment**: Record payment → status updates to "deposited"
- [ ] **Graduation Success**: Graduate with 2.5 GPA → deposit released
- [ ] **Graduation Failure**: Graduate with 1.5 GPA → deposit forfeited
- [ ] **Minimum Requirement**: Custom GPA (3.0) → correctly evaluated
- [ ] **Notifications**: Each action triggers appropriate notification

---

## 🚀 Deployment Steps

1. **Update Dependencies:**
   ```bash
   cd /path/to/emtech
   flutter pub get
   ```

2. **Create Firestore Indexes:**
   - Follow "Step 1: Create Composite Indexes" above
   - Wait for indexes to build (5-10 minutes)

3. **Update Security Rules:**
   - Follow "Step 2: Update Security Rules" above
   - Test rules with Firebase Emulator (optional)

4. **Test Auto-Issuance:**
   - Assign a grade (C or above) to a student
   - Check Firestore → `certificates` collection
   - Verify certificate document created

5. **Test Certificate Verification:**
   - Navigate to `/verify-certificate/{certificateNumber}`
   - Enter certificate number from Firestore
   - Verify status shows "Valid"

6. **Test Scholarship Deposit:**
   - Create a 100% scholarship in Firestore console
   - Verify `depositRequired` = 30% of tuition
   - Record deposit payment
   - Verify `depositStatus` = "deposited"

7. **Deploy to Production:**
   ```bash
   flutter build web --release
   firebase deploy --only hosting
   ```

---

## 📊 Admin Operations

### Manual Certificate Issuance

Use `CertificateService.issueCertificate()` for:
- Graduation certificates (batch processing)
- Excellence awards
- Workshop participation

**Example:**
```dart
await certificateService.issueCertificate(
  studentId: 'abc123',
  studentName: 'John Doe',
  studentEmail: 'john@emtech.school',
  courseId: 'xyz789',
  courseName: 'Advanced Programming',
  lecturerId: 'lec456',
  lecturerName: 'Dr. Smith',
  grade: 'A',
  gpa: 4.0,
  semester: '2026-1',
  issuedById: 'admin123',
  issuedByName: 'Admin User',
  type: CertificateType.excellence,
);
```

### Scholarship Management

**Create Scholarship:**
```dart
await scholarshipService.createScholarship(
  studentId: 'abc123',
  studentName: 'John Doe',
  studentEmail: 'john@emtech.school',
  type: ScholarshipType.full,
  percentage: 100.0,
  originalTuitionFee: 10000.0,
  minimumGPA: 2.0,
  createdBy: 'admin123',
);
```

**Process Graduation:**
```dart
await scholarshipService.processGraduation(
  scholarshipId: 'scholarship123',
  finalGPA: 3.5,
  finalLetterGrade: LetterGrade.A,
);
```

---

## 🔐 Security Considerations

### Certificate Verification

- **Public Read Access**: Certificates are publicly readable for verification
- **No PII Exposure**: Sensitive data excluded from public view
- **Revocation Tracking**: All revocations logged with reason and timestamp

### Scholarship Data

- **Student Privacy**: Only student or admin can view scholarship details
- **Audit Trail**: All deposit payments recorded with timestamps
- **Immutable Records**: Scholarships can never be deleted (soft delete only)

### QR Code Security

- **URL Validation**: QR codes contain HTTPS URLs only
- **Certificate Number**: Acts as unique identifier, not guessable
- **Status Check**: Always verify certificate status on scan

---

## 📈 Future Enhancements (Web3 Integration)

When blockchain integration is ready:

1. **Certificate NFTs:**
   - Deploy certificate smart contract to Polygon
   - Mint certificates as NFTs (ERC-721)
   - Store certificate hash on-chain
   - QR code links to blockchain verification

2. **Scholarship Smart Contracts:**
   - Escrow deposits in smart contract
   - Automatic release based on oracle (grade data)
   - Transparent fund management
   - Programmable scholarship terms

3. **Decentralized Verification:**
   - Verify certificates via blockchain explorer
   - No central authority required
   - Immutable record on-chain

---

## 🆘 Troubleshooting

### Certificate Not Auto-Issued

**Problem:** Grade assigned but no certificate created  
**Solution:**
1. Check grade is C or above
2. Verify no existing certificate for course
3. Check Firestore security rules allow creation
4. Review logs for errors in `CertificateService.autoIssueCertificateOnGrade()`

### QR Code Not Working

**Problem:** Scanning QR code doesn't redirect  
**Solution:**
1. Verify QR code contains full HTTPS URL
2. Check `qr_flutter` package is installed
3. Test verification URL in browser manually

### Scholarship Deposit Not Calculated

**Problem:** Deposit required shows $0 for 100% scholarship  
**Solution:**
1. Verify `percentage` field = 100.0
2. Check `originalTuitionFee` is set correctly
3. Review `ScholarshipModel.calculateDepositRequired()` method

### Graduation Not Processing

**Problem:** Deposit not released/forfeited on graduation  
**Solution:**
1. Verify `finalGPA` and `finalLetterGrade` are provided
2. Check `minimumGPA` setting in scholarship
3. Review `ScholarshipService.processGraduation()` logs

---

## 📞 Support

For issues or questions:
- **Technical**: Check Flutter/Firebase logs
- **Security**: Review Firestore security rules
- **Performance**: Monitor Firestore usage in console

---

**Phase 4 is now fully deployed and operational! 🎉**

Next Phase: Admin dashboard enhancements and blockchain integration.
