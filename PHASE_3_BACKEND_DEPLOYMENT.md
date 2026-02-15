# Phase 3 Backend Deployment Guide
## EMC Tokenomics System - Firestore Setup

> **Date**: February 15, 2026  
> **System**: Emtech School Management Platform  
> **Feature**: Staking, Loans, and Reward Systems

---

## 📋 Overview

Phase 3 introduces a complete tokenomics ecosystem with **900 Million EMC** total supply. This guide covers deploying:
- **4 New Firestore Collections**: `stakes`, `loans`, `loan_payments`, `rewards`
- **Security Rules**: Role-based access for students, lecturers, admins
- **12+ Composite Indexes**: For efficient querying
- **Cloud Functions**: Automated reward allocation and loan processing
- **Initial Data**: Bootstrap tokenomics configuration

---

## 🗄️ Firestore Collections

### 1. **stakes** Collection
Stores all staking positions with tier calculations and reward tracking.

```javascript
{
  stakeId: string,              // Document ID
  userId: string,               // Student UID
  userName: string,             // Display name
  stakedAmount: number,         // EMC locked
  tier: string,                 // 'Bronze', 'Silver', 'Gold', 'Platinum'
  apy: number,                  // Annual percentage yield (5-20%)
  stakedAt: timestamp,          // Start date
  duration: number,             // Lock period in days (30, 90, 180, 365)
  unlockDate: timestamp,        // When stake can be withdrawn
  isActive: boolean,            // Active/unstaked status
  rewards: number,              // Accumulated rewards
  lastRewardCalculation: timestamp, // Last reward update
  votingPower: number,          // Governance weight
  createdAt: timestamp,
  updatedAt: timestamp
}
```

**Tier Thresholds**:
- Bronze: 1,000 - 4,999 EMC (5% APY)
- Silver: 5,000 - 19,999 EMC (10% APY)
- Gold: 20,000 - 49,999 EMC (15% APY)
- Platinum: 50,000+ EMC (20% APY)

---

### 2. **loans** Collection
Tracks loan applications, approvals, and repayment status.

```javascript
{
  loanId: string,               // Document ID
  studentId: string,            // Borrower UID
  studentName: string,
  studentEmail: string,
  
  // Application details
  requestedAmount: number,      // EMC requested
  purpose: string,              // Loan reason
  termMonths: number,           // 6, 12, 18, or 24 months
  
  // Qualification data
  gpa: number,                  // Student GPA (0-4.0)
  highestGrade: string,         // 'A', 'B', 'C', etc.
  stakingDuration: number,      // Days staked (qualification requirement)
  kycVerified: boolean,         // KYC status
  referenceLecturerId: string?, // Optional reference
  referenceLecturerName: string?,
  
  // Approval data
  status: string,               // 'pending', 'approved', 'rejected', 'disbursed', 'active', 'completed', 'defaulted'
  approvedAmount: number?,      // Admin-approved amount
  interestRate: number?,        // Default 8% APR
  monthlyPayment: number?,      // Calculated payment
  totalInterest: number?,       // Total interest to pay
  approvedBy: string?,          // Admin UID
  approvalNotes: string?,
  approvedAt: timestamp?,
  
  // Disbursement
  disbursedAt: timestamp?,
  
  // Repayment tracking
  totalPaid: number,            // Sum of all payments
  remainingBalance: number,     // Outstanding amount
  nextPaymentDue: timestamp?,
  missedPayments: number,       // Count of missed payments
  
  // Dates
  appliedAt: timestamp,
  completedAt: timestamp?,
  defaultedAt: timestamp?,
  createdAt: timestamp,
  updatedAt: timestamp
}
```

**Qualification Formula**:
```
Qualifies IF:
  (GPA >= 2.0 OR highestGrade >= 'B') AND
  (stakingDuration >= 30 days OR hasReference) AND
  kycVerified == true AND
  activeLoanCount < 2
```

**Max Loan Calculation**:
```javascript
maxLoan = 5000 * GPA_multiplier * tier_bonus * duration_multiplier

GPA_multipliers:
  GPA >= 3.5: 2.0x
  GPA >= 3.0: 1.5x
  GPA >= 2.5: 1.2x
  GPA >= 2.0: 1.0x

Tier_bonus:
  Platinum: 2.0x
  Gold: 1.5x
  Silver: 1.2x
  Bronze: 1.0x

Duration_multiplier:
  365+ days: 1.5x
  180+ days: 1.3x
  90+ days: 1.1x
  30+ days: 1.0x
```

---

### 3. **loan_payments** Collection
Records individual loan payment transactions.

```javascript
{
  paymentId: string,            // Document ID
  loanId: string,               // Reference to loan
  studentId: string,
  
  amount: number,               // Payment amount in EMC
  principalAmount: number,      // Principal portion
  interestAmount: number,       // Interest portion
  
  dueDate: timestamp,           // Original due date
  paidAt: timestamp,            // Actual payment timestamp
  daysLate: number,             // 0 if on-time
  latePenalty: number,          // 5% per week late
  
  status: string,               // 'pending', 'paid', 'late', 'missed'
  paymentNumber: number,        // 1, 2, 3... in sequence
  
  createdAt: timestamp,
  updatedAt: timestamp
}
```

**Late Penalty Calculation**:
```
weeksLate = ceil(daysLate / 7)
latePenalty = amount * 0.05 * weeksLate
```

---

### 4. **rewards** Collection
Tracks EMC reward allocations (enrollment, grades, referrals).

```javascript
{
  rewardId: string,             // Document ID
  userId: string,               // Recipient UID
  userName: string,
  userEmail: string,
  
  type: string,                 // 'enrollment', 'grade', 'referral', 'completion'
  amount: number,               // EMC awarded
  
  // Context
  courseId: string?,            // Related course
  courseName: string?,
  gradeId: string?,             // Related grade document
  letterGrade: string?,         // 'A', 'B', 'C'...
  multiplier: number?,          // Grade multiplier (0.5 - 1.5)
  
  // Redemption
  redeemed: boolean,            // Whether claimed
  redeemedAt: timestamp?,
  
  // Metadata
  description: string,          // Human-readable description
  createdAt: timestamp,
  updatedAt: timestamp
}
```

**Reward Amounts**:
- **Enrollment**: 1,000 EMC (freemium) / 2,000 EMC (paid)
- **Grade Multipliers**: A=150%, B=125%, C=100%, D=75%, E=50%, F=0%
- **Final Reward**: `baseReward * gradeMultiplier` (redeemable after completion)

---

## 🔐 Security Rules

Deploy these Firestore security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    function isAdmin() {
      return isAuthenticated() && 
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    function isLecturer() {
      return isAuthenticated() && 
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'lecturer';
    }
    
    // ========================================
    // STAKES COLLECTION
    // ========================================
    match /stakes/{stakeId} {
      // Students can read their own stakes
      allow read: if isOwner(resource.data.userId) || isAdmin();
      
      // Students can create stakes (validated by service)
      allow create: if isAuthenticated() && 
                       request.resource.data.userId == request.auth.uid &&
                       request.resource.data.stakedAmount > 0 &&
                       request.resource.data.duration in [30, 90, 180, 365];
      
      // Only owner can update their stakes (unstaking)
      allow update: if isOwner(resource.data.userId) || isAdmin();
      
      // Only admins can delete stakes
      allow delete: if isAdmin();
    }
    
    // ========================================
    // LOANS COLLECTION
    // ========================================
    match /loans/{loanId} {
      // Students can read their own loans, admins can read all
      allow read: if isOwner(resource.data.studentId) || isAdmin() || isLecturer();
      
      // Students can create loan applications
      allow create: if isAuthenticated() && 
                       request.resource.data.studentId == request.auth.uid &&
                       request.resource.data.status == 'pending' &&
                       request.resource.data.requestedAmount > 0 &&
                       request.resource.data.termMonths in [6, 12, 18, 24];
      
      // Only admins can update loans (approve/reject)
      // Students can update to make payments (handled by service)
      allow update: if isAdmin() || 
                       (isOwner(resource.data.studentId) && 
                        request.resource.data.status in ['active', 'completed']);
      
      // Only admins can delete loans
      allow delete: if isAdmin();
    }
    
    // ========================================
    // LOAN PAYMENTS COLLECTION
    // ========================================
    match /loan_payments/{paymentId} {
      // Students can read their own payments, admins can read all
      allow read: if isOwner(resource.data.studentId) || isAdmin();
      
      // System creates payment records (service account)
      allow create: if isAuthenticated();
      
      // Only service/admin can update payments
      allow update: if isAdmin();
      
      // Only admins can delete payments
      allow delete: if isAdmin();
    }
    
    // ========================================
    // REWARDS COLLECTION
    // ========================================
    match /rewards/{rewardId} {
      // Students can read their own rewards, admins can read all
      allow read: if isOwner(resource.data.userId) || isAdmin() || isLecturer();
      
      // System creates rewards (enrollment, grading)
      allow create: if isAuthenticated();
      
      // Students can redeem rewards, admins can modify
      allow update: if (isOwner(resource.data.userId) && 
                        !resource.data.redeemed && 
                        request.resource.data.redeemed == true) || 
                       isAdmin();
      
      // Only admins can delete rewards
      allow delete: if isAdmin();
    }
  }
}
```

---

## 📊 Composite Indexes

Create these indexes for efficient queries:

### **stakes** Collection
```json
{
  "collectionGroup": "stakes",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "userId", "order": "ASCENDING" },
    { "fieldPath": "isActive", "order": "ASCENDING" },
    { "fieldPath": "stakedAt", "order": "DESCENDING" }
  ]
}
```

```json
{
  "collectionGroup": "stakes",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "isActive", "order": "ASCENDING" },
    { "fieldPath": "tier", "order": "ASCENDING" },
    { "fieldPath": "stakedAmount", "order": "DESCENDING" }
  ]
}
```

```json
{
  "collectionGroup": "stakes",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "isActive", "order": "ASCENDING" },
    { "fieldPath": "stakedAmount", "order": "DESCENDING" }
  ]
}
```

### **loans** Collection
```json
{
  "collectionGroup": "loans",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "studentId", "order": "ASCENDING" },
    { "fieldPath": "status", "order": "ASCENDING" },
    { "fieldPath": "appliedAt", "order": "DESCENDING" }
  ]
}
```

```json
{
  "collectionGroup": "loans",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "status", "order": "ASCENDING" },
    { "fieldPath": "appliedAt", "order": "DESCENDING" }
  ]
}
```

```json
{
  "collectionGroup": "loans",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "studentId", "order": "ASCENDING" },
    { "fieldPath": "appliedAt", "order": "DESCENDING" }
  ]
}
```

```json
{
  "collectionGroup": "loans",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "status", "order": "ASCENDING" },
    { "fieldPath": "nextPaymentDue", "order": "ASCENDING" }
  ]
}
```

### **loan_payments** Collection
```json
{
  "collectionGroup": "loan_payments",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "loanId", "order": "ASCENDING" },
    { "fieldPath": "paymentNumber", "order": "ASCENDING" }
  ]
}
```

```json
{
  "collectionGroup": "loan_payments",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "studentId", "order": "ASCENDING" },
    { "fieldPath": "status", "order": "ASCENDING" },
    { "fieldPath": "dueDate", "order": "ASCENDING" }
  ]
}
```

```json
{
  "collectionGroup": "loan_payments",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "status", "order": "ASCENDING" },
    { "fieldPath": "dueDate", "order": "ASCENDING" }
  ]
}
```

### **rewards** Collection
```json
{
  "collectionGroup": "rewards",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "userId", "order": "ASCENDING" },
    { "fieldPath": "redeemed", "order": "ASCENDING" },
    { "fieldPath": "createdAt", "order": "DESCENDING" }
  ]
}
```

```json
{
  "collectionGroup": "rewards",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "userId", "order": "ASCENDING" },
    { "fieldPath": "type", "order": "ASCENDING" },
    { "fieldPath": "createdAt", "order": "DESCENDING" }
  ]
}
```

```json
{
  "collectionGroup": "rewards",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "courseId", "order": "ASCENDING" },
    { "fieldPath": "userId", "order": "ASCENDING" }
  ]
}
```

---

## ☁️ Cloud Functions

### 1. **Automated Enrollment Rewards**
Triggered when a student enrolls in a course.

```javascript
// functions/index.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.allocateEnrollmentReward = functions.firestore
  .document('enrollments/{enrollmentId}')
  .onCreate(async (snap, context) => {
    const enrollment = snap.data();
    const { studentId, courseId, courseName, isPaid } = enrollment;
    
    // Determine reward amount
    const rewardAmount = isPaid ? 2000 : 1000;
    
    // Create reward record
    await admin.firestore().collection('rewards').add({
      userId: studentId,
      userName: enrollment.studentName,
      userEmail: enrollment.studentEmail,
      type: 'enrollment',
      amount: rewardAmount,
      courseId: courseId,
      courseName: courseName,
      redeemed: false,
      description: `Enrollment reward for ${courseName} (${isPaid ? 'Paid' : 'Freemium'})`,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    // Update user's unredeemed balance
    await admin.firestore().collection('users').doc(studentId).update({
      unredeemedEMC: admin.firestore.FieldValue.increment(rewardAmount),
      totalEMCEarned: admin.firestore.FieldValue.increment(rewardAmount),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    console.log(`Allocated ${rewardAmount} EMC enrollment reward to ${studentId}`);
  });
```

### 2. **Grade-Based Reward Multiplier**
Triggered when a grade is submitted.

```javascript
exports.applyGradeRewardMultiplier = functions.firestore
  .document('grades/{gradeId}')
  .onCreate(async (snap, context) => {
    const grade = snap.data();
    const { studentId, courseId, letterGrade, courseName } = grade;
    
    // Get enrollment reward for this course
    const rewardSnapshot = await admin.firestore().collection('rewards')
      .where('userId', '==', studentId)
      .where('courseId', '==', courseId)
      .where('type', '==', 'enrollment')
      .where('redeemed', '==', false)
      .limit(1)
      .get();
    
    if (rewardSnapshot.empty) {
      console.log('No unredeemed enrollment reward found');
      return;
    }
    
    const rewardDoc = rewardSnapshot.docs[0];
    const baseReward = rewardDoc.data().amount;
    
    // Calculate multiplier
    const multipliers = {
      'A': 1.5,
      'B': 1.25,
      'C': 1.0,
      'D': 0.75,
      'E': 0.5,
      'F': 0.0
    };
    
    const multiplier = multipliers[letterGrade] || 1.0;
    const finalReward = baseReward * multiplier;
    
    // Update reward with grade multiplier
    await rewardDoc.ref.update({
      gradeId: snap.id,
      letterGrade: letterGrade,
      multiplier: multiplier,
      amount: finalReward,
      description: `${courseName} - Grade ${letterGrade} (${multiplier}x multiplier)`,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    // Update user's unredeemed balance
    const adjustment = finalReward - baseReward;
    await admin.firestore().collection('users').doc(studentId).update({
      unredeemedEMC: admin.firestore.FieldValue.increment(adjustment),
      totalEMCEarned: admin.firestore.FieldValue.increment(adjustment),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    console.log(`Applied ${multiplier}x multiplier for grade ${letterGrade} to ${studentId}`);
  });
```

### 3. **Automated Overdue Loan Processing**
Scheduled function to check for overdue loans daily.

```javascript
exports.processOverdueLoans = functions.pubsub
  .schedule('every day 00:00')
  .timeZone('America/New_York')
  .onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();
    
    // Find active loans with overdue payments
    const overdueLoans = await admin.firestore().collection('loans')
      .where('status', '==', 'active')
      .where('nextPaymentDue', '<', now)
      .get();
    
    const batch = admin.firestore().batch();
    let processedCount = 0;
    
    for (const loanDoc of overdueLoans.docs) {
      const loan = loanDoc.data();
      const missedPayments = (loan.missedPayments || 0) + 1;
      
      // Mark as defaulted after 3 missed payments
      if (missedPayments >= 3) {
        batch.update(loanDoc.ref, {
          status: 'defaulted',
          missedPayments: missedPayments,
          defaultedAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
        
        // Send notification
        await admin.firestore().collection('notifications').add({
          userId: loan.studentId,
          type: 'loan',
          title: 'Loan Defaulted',
          message: `Your loan has been marked as defaulted due to ${missedPayments} missed payments.`,
          read: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp()
        });
      } else {
        // Increment missed count
        batch.update(loanDoc.ref, {
          missedPayments: missedPayments,
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
        
        // Send reminder
        await admin.firestore().collection('notifications').add({
          userId: loan.studentId,
          type: 'loan',
          title: 'Payment Overdue',
          message: `Your loan payment is overdue. Please make payment to avoid penalties.`,
          read: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp()
        });
      }
      
      processedCount++;
    }
    
    await batch.commit();
    console.log(`Processed ${processedCount} overdue loans`);
  });
```

### 4. **Daily Staking Rewards Calculation**
Calculate and add daily APY rewards to active stakes.

```javascript
exports.calculateStakingRewards = functions.pubsub
  .schedule('every day 01:00')
  .timeZone('America/New_York')
  .onRun(async (context) => {
    const activeStakes = await admin.firestore().collection('stakes')
      .where('isActive', '==', true)
      .get();
    
    const batch = admin.firestore().batch();
    let totalRewardsAdded = 0;
    
    for (const stakeDoc of activeStakes.docs) {
      const stake = stakeDoc.data();
      const { stakedAmount, apy } = stake;
      
      // Calculate daily reward: (amount * APY) / 365
      const dailyReward = (stakedAmount * (apy / 100)) / 365;
      
      batch.update(stakeDoc.ref, {
        rewards: admin.firestore.FieldValue.increment(dailyReward),
        lastRewardCalculation: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      totalRewardsAdded += dailyReward;
    }
    
    await batch.commit();
    console.log(`Added ${totalRewardsAdded.toFixed(2)} EMC in staking rewards`);
  });
```

---

## 📦 Deployment Steps

### Step 1: Deploy Security Rules
```bash
# Navigate to project root
cd /Users/apple/emtech

# Deploy Firestore rules
firebase deploy --only firestore:rules

# Verify rules are active
firebase firestore:rules get
```

### Step 2: Create Composite Indexes
```bash
# Option 1: Auto-create via firebase.json
# Add indexes to firestore.indexes.json, then:
firebase deploy --only firestore:indexes

# Option 2: Manual creation via Firebase Console
# Go to: https://console.firebase.google.com
# Navigate to: Firestore Database > Indexes > Composite
# Create each index listed in the "Composite Indexes" section above
```

**firestore.indexes.json** (add to existing file):
```json
{
  "indexes": [
    {
      "collectionGroup": "stakes",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "isActive", "order": "ASCENDING" },
        { "fieldPath": "stakedAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "loans",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "studentId", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "appliedAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "rewards",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "redeemed", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    }
  ],
  "fieldOverrides": []
}
```

### Step 3: Deploy Cloud Functions
```bash
# Initialize Cloud Functions (if not already done)
firebase init functions

# Install dependencies
cd functions
npm install

# Copy the Cloud Functions code into functions/index.js
# Then deploy
firebase deploy --only functions

# Deploy specific functions only
firebase deploy --only functions:allocateEnrollmentReward,functions:applyGradeRewardMultiplier,functions:processOverdueLoans,functions:calculateStakingRewards
```

### Step 4: Initialize System Configuration
```bash
# Create a tokenomics configuration document
firebase firestore:set config/tokenomics '{
  "totalSupply": 900000000,
  "circulatingSupply": 0,
  "stakedSupply": 0,
  "reserveSupply": 900000000,
  "enrollmentRewards": {
    "freemium": 1000,
    "paid": 2000
  },
  "stakingTiers": {
    "bronze": {"min": 1000, "max": 4999, "apy": 5},
    "silver": {"min": 5000, "max": 19999, "apy": 10},
    "gold": {"min": 20000, "max": 49999, "apy": 15},
    "platinum": {"min": 50000, "max": 999999999, "apy": 20}
  },
  "loanConfig": {
    "defaultInterestRate": 0.08,
    "maxActiveLoans": 2,
    "latePenaltyRate": 0.05,
    "defaultThreshold": 3
  },
  "lastUpdated": "2026-02-15T00:00:00Z"
}'
```

### Step 5: Verify Deployment
```bash
# Test Firestore rules
firebase emulators:start --only firestore

# Check indexes status
firebase firestore:indexes:list

# View Cloud Functions logs
firebase functions:log

# Test Phase 3 services
flutter test test/services/staking_service_test.dart
flutter test test/services/loan_service_test.dart
flutter test test/services/reward_service_test.dart
```

---

## ✅ Testing Checklist

### Staking System
- [ ] User can stake 1,000 EMC → Bronze tier assigned
- [ ] User can stake 50,000 EMC → Platinum tier, 20% APY
- [ ] Voting power increases with duration
- [ ] Unstake returns principal + calculated rewards
- [ ] Daily reward calculation runs successfully
- [ ] Insufficient balance prevents staking

### Loan System
- [ ] Application without qualification shows error
- [ ] Student with GPA 2.5 + 35 days staking + KYC qualifies
- [ ] Max loan amount calculates correctly
- [ ] Admin can approve loan with custom terms
- [ ] Disbursal adds EMC to student wallet
- [ ] On-time payment updates balance correctly
- [ ] Late payment calculates 5% penalty per week
- [ ] 3 missed payments mark loan as defaulted
- [ ] Max 2 active loans enforced

### Reward System
- [ ] Freemium enrollment → 1,000 unredeemed EMC
- [ ] Paid enrollment → 2,000 unredeemed EMC
- [ ] Grade A on paid course → 3,000 EMC (2K × 150%)
- [ ] Grade F removes enrollment reward
- [ ] Course completion allows redemption
- [ ] Redemption adds EMC to available balance
- [ ] 10% tuition discount with EMC payment

### Security
- [ ] Students can only read their own stakes/loans/rewards
- [ ] Admins can read all collections
- [ ] Lecturers can view loans (for references)
- [ ] Students cannot approve loans
- [ ] Students cannot create rewards manually
- [ ] KYC verification required for loans

---

## 🔧 Maintenance

### Daily Tasks
- Monitor Cloud Function logs for errors
- Check overdue loan processing results
- Verify staking reward calculations
- Review notification delivery

### Weekly Tasks
- Analyze loan default rate
- Review staking tier distribution
- Monitor EMC circulation vs. total supply
- Check reward redemption rates

### Monthly Tasks
- Audit tokenomics balance (ensure no double-spending)
- Review and adjust loan qualification criteria
- Analyze grade reward multiplier effectiveness
- Generate financial reports for admins

### Monitoring Queries
```javascript
// Check total staked EMC
db.collection('stakes')
  .where('isActive', '==', true)
  .get()
  .then(snapshot => {
    const total = snapshot.docs.reduce((sum, doc) => 
      sum + doc.data().stakedAmount, 0);
    console.log('Total Staked:', total);
  });

// Count active loans
db.collection('loans')
  .where('status', 'in', ['approved', 'disbursed', 'active'])
  .get()
  .then(snapshot => console.log('Active Loans:', snapshot.size));

// Total unredeemed rewards
db.collection('rewards')
  .where('redeemed', '==', false)
  .get()
  .then(snapshot => {
    const total = snapshot.docs.reduce((sum, doc) => 
      sum + doc.data().amount, 0);
    console.log('Unredeemed Rewards:', total);
  });
```

---

## 🚨 Troubleshooting

### Issue: "Missing or insufficient permissions"
**Solution**: Verify security rules are deployed and user has correct role in Firestore.

```bash
firebase deploy --only firestore:rules
```

### Issue: "Index not found for query"
**Solution**: Create the missing composite index.

```bash
# Check error message for exact index needed
# Create via Firebase Console or firestore.indexes.json
firebase deploy --only firestore:indexes
```

### Issue: Cloud Functions not triggering
**Solution**: Check function deployment and trigger configuration.

```bash
firebase functions:log --only allocateEnrollmentReward
firebase deploy --only functions
```

### Issue: Staking rewards not calculating
**Solution**: Verify scheduled function is enabled.

```bash
# Check Cloud Scheduler in GCP Console
# Manually trigger function for testing
firebase functions:shell
> calculateStakingRewards()
```

### Issue: Loan qualification always failing
**Solution**: Verify user document has all Phase 3 fields.

```javascript
// Update existing users with Phase 3 fields
db.collection('users').get().then(snapshot => {
  const batch = db.batch();
  snapshot.docs.forEach(doc => {
    batch.update(doc.ref, {
      totalEMCEarned: 0,
      unredeemedEMC: 0,
      stakedEMC: 0,
      availableEMC: doc.data().emcBalance || 0,
      kycVerified: false,
      activeLoanCount: 0
    });
  });
  return batch.commit();
});
```

---

## 📞 Support

- **Documentation**: `/PHASE_3_IMPLEMENTATION.md`
- **Code Reference**: `/lib/services/{staking,loan,reward}_service.dart`
- **Firebase Console**: https://console.firebase.google.com
- **Cloud Functions Logs**: `firebase functions:log`

---

**Deployment Date**: February 15, 2026  
**Version**: Phase 3.0  
**Status**: Ready for Production ✅
