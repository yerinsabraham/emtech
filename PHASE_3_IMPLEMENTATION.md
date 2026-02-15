# 🪙 MTech School - Phase 3: Tokenomics & Financial Systems

## 📋 Overview

Phase 3 implements a comprehensive **point-based tokenomics system** that mimics blockchain behavior without actual blockchain integration. The system includes EMC token management, staking rewards, loan qualification and disbursement, and automated reward allocation.

---

## ✅ Implementation Complete

### 🗂️ Data Models (3 Models + User Updates)

1. **StakingModel** - EMC staking with tiered rewards
   - 4 tiers: Bronze (1K-5K), Silver (5K-20K), Gold (20K-50K), Platinum (50K+)
   - APY rewards: 5%, 10%, 15%, 20% respectively
   - Voting power calculation based on amount × duration multiplier
   - Duration bonuses: 30d (1.2x), 90d (1.5x), 180d (2.0x), 365d (3.0x)

2. **LoanModel** - Student loan application & tracking
   - Qualification checks: GPA, staking duration, KYC, lecturer reference
   - Max loan calculation based on GPA + staking tier
   - Interest rate: 8% APR (default, admin customizable)
   - Repayment tracking with late penalties
   - Loan statuses: pending, underReview, approved, rejected, disbursed, active, completed, defaulted

3. **LoanPaymentModel** - Loan repayment records
   - Payment tracking with interest/principal breakdown
   - Late penalty calculation: 5% per week late
   - Payment history and balance tracking

4. **UserModel Updates** - Added Phase 3 fields
   - `totalEMCEarned` - Lifetime EMC earned
   - `unredeemedEMC` - EMC from grades/courses not yet redeemed  
   - `stakedEMC` - Currently staked EMC
   - `availableEMC` - Available for spending (balance - staked)
   - `kycVerified` - KYC verification status
   - `activeLoanCount` - Number of active loans (max 2)

### ⚙️ Services (3 New Services)

1. **StakingService** - Complete staking management
   - `stakeEMC()` - Lock EMC for rewards
   - `unstakeEMC()` - Unlock staked EMC + rewards
   - `getUserStakes()` - Get user's staking positions
   - `getTotalStaked()` - Calculate total staked amount
   - `getUserStakingTier()` - Get highest tier
   - `getLongestStakingDuration()` - For loan qualification
   - `calculateCurrentRewards()` - Real-time reward calculation
   - `calculateVotingPower()` - Governance power calculation
   - `getStakingStats()` - Admin statistics

2. **LoanService** - Loan lifecycle management
   - `applyForLoan()` - Student loan application with qualification checks
   - `approveLoan()` - Admin approval with custom terms
   - `rejectLoan()` - Admin rejection with reason
   - `disburseLoan()` - Transfer EMC to student wallet
   - `makeLoanPayment()` - Process loan repayments
   - `getStudentLoans()` - Get loans by student
   - `getLoanPayments()` - Get payment history
   - `getAllLoans()` - Admin view all loans
   - `getLoanStats()` - Loan statistics
   - `processOverdueLoans()` - Automated default checking

3. **RewardService** - EMC reward allocation
   - `allocateEnrollmentReward()` - Sign-up & enrollment rewards (1000/2000 EMC)
   - `redeemCourseCompletionRewards()` - Unlock rewards after completion
   - `getTotalUnredeemedRewards()` - Check pending rewards
   - `getRewardHistory()` - Reward transaction history
   - `calculateEMCPaymentDiscount()` - 10% discount when paying with EMC
   - `payTuitionWithEMC()` - Process EMC course payments
   - `getRewardStats()` - Admin reward statistics

### 🎨 UI Components (2 Major Pages)

1. **EnhancedWalletPage** - Complete wallet with 4 tabs
   - **Overview Tab**: Balance breakdown (Available, Staked, Unredeemed, Rewards)
   - **Staking Tab**: Active stakes with tier badges, APY, rewards, unstake button
   - **Rewards Tab**: Reward history (enrollment, grading, staking)
   - **History Tab**: Transaction history (placeholder)
   - Quick actions: Stake EMC, Redeem rewards

2. **LoanApplicationPage** - Loan application & management
   - Qualification checker (real-time)
   - Loan amount calculator (max loan based on GPA + staking)
   - Term selection: 6, 12, 18, 24 months
   - Loan summary (monthly payment, total interest, total repayment)
   - My Loans section with payment buttons
   - Requirements guide for non-qualified users

---

## 💰 Tokenomics System Details

### Total EMC Supply
- **900,000,000 EMC** (900 Million)
- Point-based system (no blockchain currently)
- Tracked in Firestore with user balances

### EMC Allocation Rules

#### 1. Sign-Up & Enrollment Rewards
```
Freemium Course Enrollment: 1,000 EMC (unredeemed)
Paid Course Enrollment:     2,000 EMC (unredeemed)
Redeemable: After course completion only
```

#### 2. Grade-Based Rewards (Existing from Phase 2)
```
Base Reward: 1,000 EMC (Freemium) / 2,000 EMC (Paid)

Grade Multipliers:
- Grade A: 150% (1,500 / 3,000 EMC)
- Grade B: 125% (1,250 / 2,500 EMC)
- Grade C: 100% (1,000 / 2,000 EMC)
- Grade D:  75% (750  / 1,500 EMC)
- Grade E:  50% (500  / 1,000 EMC)
- Grade F:   0% (0    / 0 EMC)
```

#### 3. Staking Rewards (APY)
```
Bronze Tier   (1K-5K EMC):    5% APY
Silver Tier   (5K-20K EMC):  10% APY
Gold Tier     (20K-50K EMC): 15% APY
Platinum Tier (50K+ EMC):    20% APY

Daily reward calculation: (stakedAmount × APY × days) / 365
```

####  4. Tuition Payment Discount
```
Pay with EMC: 10% discount on course price
Example: 10,000 EMC course → Pay 9,000 EMC with wallet
```

---

## 🔒 Staking System

### Staking Tiers & Benefits

| Tier | Amount | APY | Voting Power Multiplier | Badge |
|------|--------|-----|-------------------------|-------|
| Bronze | 1,000 - 4,999 EMC | 5% | 1.2x (30d), 1.5x (90d), 2.0x (180d), 3.0x (365d) | 🥉 Bronze Staker |
| Silver | 5,000 - 19,999 EMC | 10% | Same as above | 🥈 Silver Staker |
| Gold | 20,000 - 49,999 EMC | 15% | Same as above | 🥇 Gold Staker |
| Platinum | 50,000+ EMC | 20% | Same as above | 💎 Platinum Staker |

### Staking Features
- **Minimum Stake**: 1,000 EMC
- **Lock Duration**: User choice (longer = higher voting power)
- **Rewards**: Auto-calculated, claimed on unstake
- **Voting Power**: Used for governance (future Phase 4 feature)
- **Unstaking**: Instant, returns principal + rewards

### Staking Flow
1. User clicks "Stake EMC" in wallet
2. Enters amount (min 1,000 EMC)
3. System locks EMC, creates stake record
4. Rewards accrue daily based on APY
5. User unstakes anytime → receives principal + rewards
6. Voting power increases with duration

---

## 💳 Loan System

### Loan Qualification Criteria

**Minimum Requirements:**
1. **Academic Performance** (one of):
   - GPA ≥ 2.0 (C average)
   - Highest grade achieved: B or better

2. **Trust Factor** (one of):
   - Staked EMC for ≥ 30 days
   - Lecturer reference letter

3. **KYC Verification**: Required for all loans

### Max Loan Amount Calculation

```dart
Base Amount: 5,000 EMC

GPA Multipliers:
- GPA ≥ 3.5: 2.0× → 10,000 EMC
- GPA ≥ 3.0: 1.5× → 7,500 EMC
- GPA ≥ 2.5: 1.2× → 6,000 EMC
- GPA ≥ 2.0: 1.0× → 5,000 EMC

Staking Tier Bonuses:
- Platinum: +50%
- Gold:     +30%
- Silver:   +20%
- Bronze:   +10%

Long-Term Staking Bonus:
- 180+ days staked: +20%

Example: Student with GPA 3.6, Gold tier, 200 days staked:
5,000 × 2.0 (GPA) × 1.3 (Gold) × 1.2 (Long-term) = 15,600 EMC max loan
```

### Loan Terms
- **Interest Rate**: 8% APR (admin customizable)
- **Term Options**: 6, 12, 18, 24 months
- **Late Penalty**: 5% of payment amount per week late
- **Max Active Loans**: 2 per student
- **Default Trigger**: 3+ missed payments

### Loan Lifecycle
1. **Application**: Student applies with amount, term, purpose
2. **Qualification Check**: System validates criteria automatically
3. **Admin Review**: Admin approves/rejects with notes
4. **Approval**: Loan approved, terms calculated
5. **Disbursement**: EMC transferred to student wallet
6. **Active**: Monthly payments required
7. **Completion**: Fully repaid OR Defaulted (3+ missed payments)

### Payment Breakdown
Each payment is split into:
- **Interest Portion**: (Outstanding Balance × Interest Rate) / 12
- **Principal Portion**: Payment Amount - Interest Portion
- **Late Penalty**: 5% per week if overdue

---

## 🔥 Firestore Collections

### New Collections for Phase 3

#### 1. `stakes` Collection
```javascript
{
  userId: string,
  userName: string,
  stakedAmount: number (EMC),
  stakedAt: timestamp,
  unstakedAt: timestamp | null,
  isActive: boolean,
  tier: string (enum),
  stakingDurationDays: number,
  votingPower: number,
  rewardsEarned: number,
  metadata: map
}
```

**Indexes Required:**
- `userId` (ASC) + `isActive` (ASC) + `stakedAt` (DESC)
- `isActive` (ASC) + `stakedAmount` (DESC)

#### 2. `loans` Collection
```javascript
{
  studentId: string,
  studentName: string,
  requestedAmount: number,
  approvedAmount: number,
  interestRate: number (0.08 = 8%),
  termMonths: number,
  purpose: string,
  appliedAt: timestamp,
  approvedAt: timestamp | null,
  disbursedAt: timestamp | null,
  status: string (enum),
  
  // Qualification data
  currentGPA: number,
  highestGrade: string | null,
  stakingDurationDays: number,
  stakedAmount: number,
  stakingTier: string,
  kycVerified: boolean,
  referenceLecturerId: string | null,
  referenceLecturerName: string | null,
  
  // Repayment tracking
  totalAmountDue: number,
  amountPaid: number,
  outstandingBalance: number,
  totalPayments: number,
  completedPayments: number,
  nextPaymentDue: timestamp | null,
  monthlyPayment: number,
  missedPayments: number,
  penaltyAmount: number,
  
  // Admin
  adminNotes: string | null,
  rejectionReason: string | null,
  approvedBy: string | null
}
```

**Indexes Required:**
- `studentId` (ASC) + `appliedAt` (DESC)
- `status` (ASC) + `appliedAt` (DESC)
- `status` (ASC) + `nextPaymentDue` (ASC) [for overdue checking]

#### 3. `loan_payments` Collection
```javascript
{
  loanId: string,
  studentId: string,
  amount: number,
  paidAt: timestamp,
  dueDate: timestamp,
  isLate: boolean,
  daysLate: number,
  penaltyAmount: number,
  interestPortion: number,
  principalPortion: number,
  balanceAfterPayment: number,
  transactionId: string | null,
  paymentMethod: string,
  metadata: map
}
```

**Indexes Required:**
- `loanId` (ASC) + `paidAt` (DESC)
- `studentId` (ASC) + `paidAt` (DESC)

#### 4. `rewards` Collection
```javascript
{
  userId: string,
  courseId: string | null,
  type: string ('enrollment', 'grading', 'staking'),
  amount: number,
  redeemed: boolean,
  createdAt: timestamp,
  redeemedAt: timestamp | null,
  courseType: string ('freemium' | 'paid'),
  metadata: map
}
```

**Indexes Required:**
- `userId` (ASC) + `redeemed` (ASC) + `createdAt` (DESC)
- `userId` (ASC) + `courseId` (ASC) + `type` (ASC)

---

## 📊 Updated User Fields

Add to existing `users` collection:

```javascript
{
  // Existing fields...
  
  // Phase 3 additions:
  totalEMCEarned: number (default: 0),
  unredeemedEMC: number (default: 0),
  stakedEMC: number (default: 0),
  availableEMC: number (default: emcBalance),
  kycVerified: boolean (default: false),
  activeLoanCount: number (default: 0)
}
```

---

## 🔔 Notification Integration

### New Notification Types

| Action | Notification To | Type | Message |
|--------|----------------|------|---------|
| EMC Staked | User | `staking` | "You staked X EMC and earned [Tier] status!" |
| EMC Unstaked | User | `staking` | "Unstaked X EMC + Y EMC rewards!" |
| Enrollment Reward | User | `reward` | "You'll receive X EMC upon course completion!" |
| Rewards Redeemed | User | `reward` | "You earned X EMC for completing the course!" |
| Loan Applied | Admin | `loan` | "Student applied for X EMC loan" |
| Loan Applied | Student | `loan` | "Your loan application is under review" |
| Loan Approved | Student | `loan` | "Your loan for X EMC has been approved!" |
| Loan Approved | Lecturer (if reference) | `loan` | "Student's loan you referenced was approved" |
| Loan Rejected | Student | `loan` | "Loan not approved. Reason: X" |
| Loan Disbursed | Student | `payment` | "X EMC added to your wallet!" |
| Payment Made | Student | `payment` | "Payment received. Balance: X EMC" |
| Loan Completed | Student | `loan` | "Congratulations! Loan fully repaid!" |
| Payment Overdue | Student | `loan` | "Your loan payment is overdue" |
| Loan Defaulted | Student | `loan` | "Loan marked as defaulted" |
| EMC Payment | User | `payment` | "Course purchased with EMC. You saved X EMC!" |

---

## 🚀 Key Features

### For Students
✅ **EMC Wallet** with real-time balance tracking  
✅ **Staking System** with tiered rewards (5%-20% APY)  
✅ **Enrollment Rewards** (1000/2000 EMC pending completion)  
✅ **Grade Rewards** (50%-150% multipliers)  
✅ **Loan Application** with automated qualification checking  
✅ **Loan Repayment** with payment history  
✅ **EMC Tuition Payment** with 10% discount  
✅ **Reward History** tracking all EMC earnings  
✅ **Voting Power** based on staking (future governance)

### For Admins
✅ **Loan Approval Workflow** with custom terms  
✅ **Staking Statistics** (total staked, tier distribution)  
✅ **Loan Statistics** (disbursed, outstanding, completed, defaulted)  
✅ **Reward Statistics** (allocated, redeemed, % of supply)  
✅ **Overdue Loan Processing** (automated default marking)  
✅ **Custom Interest Rates** per loan  
✅ **Student Qualification View** (GPA, staking, KYC status)

### For Lecturers
✅ **Loan References** (can vouch for students)  
✅ **Notifications** when referenced students get loans  

---

## 📝 Integration Points

### Course Enrollment Flow
```dart
1. Student purchases course
2. RewardService.allocateEnrollmentReward() called
3. Unredeemed EMC added (1000 or 2000)
4. Reward record created in Firestore
5. Notification sent to student
```

### Course Completion Flow
```dart
1. Student completes course (graded/passed)
2. RewardService.redeemCourseCompletionRewards() called
3. Unredeemed EMC → Available EMC
4. Balance updated
5. Notification: "You earned X EMC!"
```

### Staking Flow
```dart
1. User enters stake amount
2. System validates: min 1000 EMC, sufficient balance
3. StakingService.stakeEMC() called
4. EMC locked: availableEMC -= amount, stakedEMC += amount
5. Stake record created with tier, APY
6. Notification + badge awarded
```

### Loan Application Flow
```dart
1. Student fills loan form
2. System checks:
   - GPA ≥ 2.0 OR Grade ≥ B
   - Staking ≥ 30 days OR has reference
   - KYC verified
   - Active loans < 2
3. If qualified: LoanService.applyForLoan()
4. Admin receives notification
5. Student receives confirmation
```

### Loan Disbursement Flow
```dart
1. Admin approves loan (sets terms)
2. LoanService.disburseLoan() called
3. EMC transferred: availableEMC += approvedAmount
4. Loan status: approved → active
5. Next payment due set (30 days)
6. Student notified
```

---

## 🧪 Testing Checklist

### Staking Tests
- [ ] Stake EMC (min 1000)
- [ ] Check tier badge assigned correctly
- [ ] Verify APY calculation
- [ ] Test duration-based voting power multiplier
- [ ] Unstake and receive rewards
- [ ] Verify balance updates (staked → available)
- [ ] Test insufficient balance error
- [ ] Test below minimum error

### Loan Tests
- [ ] Apply for loan when not qualified → rejection
- [ ] Achieve qualification (GPA + staking)
- [ ] Apply for loan within max amount
- [ ] Apply for loan exceeding max → error
- [ ] Admin approve loan
- [ ] Disburse loan to wallet
- [ ] Make on-time payment
- [ ] Make late payment → penalty calculated
- [ ] Complete loan fully → status updated
- [ ] Miss 3 payments → defaulted
- [ ] Test max 2 active loans limit

### Reward Tests
- [ ] Enroll in freemium course → 1000 unredeemed EMC
- [ ] Enroll in paid course → 2000 unredeemed EMC
- [ ] Complete course → redeem rewards
- [ ] Verify balance transfer (unredeemed → available)
- [ ] Get grade → EMC reward with multiplier
- [ ] View reward history

### EMC Payment Tests
- [ ] Pay tuition with EMC
- [ ] Verify 10% discount applied
- [ ] Check insufficient balance error
- [ ] Verify enrollment after payment

---

## ⚠️ Known Limitations

1. **No Actual Blockchain**: Currently point-based system in Firestore
2. **Admin Loan Dashboard**: Basic UI needed (approve/reject interface)
3. **Automated Overdue Processing**: Requires scheduled Cloud Function
4. **KYC Verification Flow**: Manual admin process (no automated KYC yet)
5. **Voting/Governance**: Voting power calculated but governance UI not implemented
6. **Loan Default Recovery**: No automated collection system
7. **EMC Token Listing**: "Post-listing" features (discounts) ready but no exchange integration

---

## 🔐 Security Considerations

### Firestore Rules Needed

```javascript
// Stakes collection
match /stakes/{stakeId} {
  allow read: if request.auth != null && (
    request.auth.uid == resource.data.userId || 
    userRole() == 'admin'
  );
  allow create: if request.auth != null && 
    request.auth.uid == request.resource.data.userId;
  allow update: if userRole() == 'admin' || 
    request.auth.uid == resource.data.userId;
}

// Loans collection
match /loans/{loanId} {
  allow read: if request.auth != null && (
    request.auth.uid == resource.data.studentId || 
    userRole() == 'admin' ||
    (userRole() == 'lecturer' && request.auth.uid == resource.data.referenceLecturerId)
  );
  allow create: if request.auth != null && 
    request.auth.uid == request.resource.data.studentId &&
    userRole() == 'student';
  allow update: if userRole() == 'admin';
}

// Loan Payments collection
match /loan_payments/{paymentId} {
  allow read: if request.auth != null && (
    request.auth.uid == resource.data.studentId || 
    userRole() == 'admin'
  );
  allow create: if request.auth != null && 
    request.auth.uid == request.resource.data.studentId;
}

// Rewards collection
match /rewards/{rewardId} {
  allow read: if request.auth != null && (
    request.auth.uid == resource.data.userId || 
    userRole() == 'admin'
  );
  allow create, update: if userRole() == 'admin' || 
    serverInitiated();
}
```

---

## 📈 Admin Dashboard Requirements

### Loan Management (To Be Built)
- **Pending Loans Tab**: List all pending loan applications
- **Loan Details View**: Student info, qualification data, requested amount
- **Approval Form**: Set approved amount, interest rate, add notes
- **Rejection Form**: Enter rejection reason
- **Active Loans Monitor**: Track payments, send reminders
- **Defaulted Loans**: View defaulted loans, contact students

### Staking Overview
- Total EMC staked across all users
- Tier distribution chart
- Top stakers leaderboard
- Staking trends (daily/weekly/monthly)

### Reward Statistics
- Total EMC allocated
- Total EMC redeemed
- Unredeemed EMC pool
- Percentage of total supply circulating

---

## 🎯 Next Steps (Post Phase 3)

### Phase 4 Features (Governance & Certificates)
1. **Voting System**: Use voting power for proposals
2. **DAO Governance**: Student council voting
3. **Blockchain Certificate Minting**: On-chain graduation records
4. **Scholarship Deposit System**: 30% escrow for 100% scholarship students
5. **EMC Token Listing**: Actual token deployment (Polygon network)
6. **Exchange Integration**: Trade EMC on DEX
7. **Loan Marketplace**: P2P lending between students

### Immediate Enhancements
- [ ] Build admin loan approval dashboard
- [ ] Implement KYC verification flow
- [ ] Add automated overdue loan checking (Cloud Function)
- [ ] Create EMC transaction history
- [ ] Build loan payment scheduler
- [ ] Add loan early repayment option
- [ ] Create staking analytics dashboard
- [ ] Implement EMC transfer between users

---

## 📞 Support & Documentation

### Files Created
- `lib/models/staking_model.dart` - Staking data model
- `lib/models/loan_model.dart` - Loan data model
- `lib/models/loan_payment_model.dart` - Payment tracking
- `lib/models/user_model.dart` - Updated with Phase 3 fields
- `lib/services/staking_service.dart` - Staking logic
- `lib/services/loan_service.dart` - Loan lifecycle management
- `lib/services/reward_service.dart` - EMC reward allocation
- `lib/screens/wallet/enhanced_wallet_page.dart` - Wallet UI
- `lib/screens/student/loan_application_page.dart` - Loan UI
- `PHASE_3_IMPLEMENTATION.md` - This documentation

### Related Documentation
- `PHASE_2_IMPLEMENTATION.md` - Academic & Content Management
- `PHASE_2_BACKEND_DEPLOYMENT.md` - Firestore setup guide
- `PHASE_1_COMPLETION.md` - Core MVP documentation

---

**Phase 3 Status**: ✅ **Core Implementation Complete**  
**Ready for**: Testing, Admin UI completion, Cloud Function deployment  
**Next Phase**: Phase 4 - Governance & Blockchain Certificates

---

*Generated: Phase 3 Tokenomics Implementation*  
*Last Updated: February 15, 2026*
