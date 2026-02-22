# EMTech School — Full Functionality Roadmap

> **Generated:** February 22, 2026  
> **Purpose:** Complete audit of every feature in the app, what works, what's mock, and what needs to be built for full functionality.  
> **Core Principle:** Mock data is RETAINED (visible to all users) but admin can delete it. All features get real implementations layered alongside mock data.

---

## Table of Contents

1. [App Overview & Architecture](#1-app-overview--architecture)
2. [Current State Summary](#2-current-state-summary)
3. [Mock Data Strategy](#3-mock-data-strategy)
4. [Feature-by-Feature Implementation Plan](#4-feature-by-feature-implementation-plan)
   - [4.1 Authentication & User Management](#41-authentication--user-management)
   - [4.2 Course System](#42-course-system)
   - [4.3 Bookshop](#43-bookshop)
   - [4.4 Payment System (Paystack)](#44-payment-system-paystack)
   - [4.5 EMC Wallet & Token Economy](#45-emc-wallet--token-economy)
   - [4.6 Daily Tasks](#46-daily-tasks)
   - [4.7 Student Forum](#47-student-forum)
   - [4.8 Blog / News](#48-blog--news)
   - [4.9 Scholarship Board](#49-scholarship-board)
   - [4.10 Student Dashboard](#410-student-dashboard)
   - [4.11 Lecturer Dashboard](#411-lecturer-dashboard)
   - [4.12 Admin Panel](#412-admin-panel)
   - [4.13 Staking System](#413-staking-system)
   - [4.14 Loan System](#414-loan-system)
   - [4.15 Certificates](#415-certificates)
   - [4.16 Notifications (Push)](#416-notifications-push)
   - [4.17 Voice/Video Calls (Agora)](#417-voicevideo-calls-agora)
   - [4.18 Live Classes (YouTube)](#418-live-classes-youtube)
   - [4.19 Support System](#419-support-system)
   - [4.20 Profile & Settings](#420-profile--settings)
   - [4.21 Achievements & Gamification](#421-achievements--gamification)
   - [4.22 Learning History](#422-learning-history)
   - [4.23 Saved Courses](#423-saved-courses)
   - [4.24 About / Info Desk](#424-about--info-desk)
5. [Firestore Rules Update](#5-firestore-rules-update)
6. [Firebase Cloud Functions to Build](#6-firebase-cloud-functions-to-build)
7. [Third-Party APIs & Services Setup Guide](#7-third-party-apis--services-setup-guide)
   - [7.1 Paystack (Payments)](#71-paystack-payments)
   - [7.2 Agora (Voice/Video Calls)](#72-agora-voicevideo-calls)
   - [7.3 Firebase Cloud Messaging (Push Notifications)](#73-firebase-cloud-messaging-push-notifications)
   - [7.4 Firebase Cloud Functions Deployment](#74-firebase-cloud-functions-deployment)
   - [7.5 Google Sign-In Configuration](#75-google-sign-in-configuration)
8. [Database Schema (Firestore Collections)](#8-database-schema-firestore-collections)
9. [Implementation Priority & Phases](#9-implementation-priority--phases)
10. [Estimated Work Breakdown](#10-estimated-work-breakdown)

---

## 1. App Overview & Architecture

| Aspect | Details |
|--------|---------|
| **Framework** | Flutter 3.10+ / Dart |
| **Backend** | Firebase (Auth, Firestore, Storage, Cloud Functions, Remote Config) |
| **State Management** | Provider (ChangeNotifier) |
| **Token Economy** | EMC token — internal currency for courses, rewards, staking, loans |
| **User Roles** | `student`, `lecturer`, `admin` |
| **Platforms** | Android, iOS, macOS, Web, Windows |
| **Key Packages** | `agora_rtc_engine`, `youtube_player_flutter`, `google_sign_in`, `qr_flutter`, `firebase_*` |

### Navigation Structure
- **Bottom Nav** (role-based):
  - **Student/Admin:** Home → Bookshop → Wallet → Profile
  - **Lecturer:** Home → My Courses → Wallet → Profile  
  - **Guest:** Home → Bookshop → Guest Wallet → Profile

---

## 2. Current State Summary

### What's WORKING (Real Firebase)
| Feature | Status |
|---------|--------|
| Email/Password Auth | ✅ Fully working |
| Google Sign-In | ✅ Fully working |
| Course browsing (Firestore) | ✅ Working |
| Diploma course seeding | ✅ Working |
| Course enrollment (Firestore) | ✅ Working |
| Bookshop (Firestore stream) | ✅ Working |
| EMC token balance tracking | ✅ Working |
| Transaction recording | ✅ Working |
| Notification system (in-app + push FCM) | ✅ Working |
| Assignment service (CRUD) | ✅ Working |
| Exam service (with approval workflow) | ✅ Working |
| Content upload service | ✅ Working |
| Grading service | ✅ Working |
| Certificate issuance, verification & PDF | ✅ Working |
| Staking service (EMC) | ✅ Working |
| Loan service (full lifecycle) | ✅ Working |
| Scholarship service | ✅ Working |
| Reward service | ✅ Working |
| Voice calls (Agora) | ✅ Working (needs token server deployed) |
| Live class viewer (YouTube) | ✅ Working |
| Role-based access control | ✅ Working |
| **Payment system (Paystack)** | ✅ `flutter_paystack_plus` integrated |
| **Assignment submission UI** | ✅ Full form with file upload |
| **Exam taking UI** | ✅ MCQ page with timer |
| **Content viewer** | ✅ Video, PDF, link handling |
| **Lecturer creation dialogs** | ✅ Assignment, Exam, Content fully built |
| **Lecturer grading & students tab** | ✅ Real submission grading |
| **Forum** | ✅ Real Firestore CRUD, create/reply/like |
| **Blog/News** | ✅ Real Firestore, admin CRUD |
| **Daily tasks** | ✅ Firestore-backed, persistence, EMC rewards |
| **Support ticket system** | ✅ Form submits to Firestore |
| **Achievement system** | ✅ 13 achievements, Firestore tracking, EMC rewards |
| **Settings persistence** | ✅ SharedPreferences, password change, account deletion |
| **Admin analytics dashboard** | ✅ Live stats + bar charts |
| **Admin loan management** | ✅ Approve/reject/disburse |
| **Mock data management** | ✅ Admin can seed/delete by category |
| **About page dynamic stats** | ✅ Real Firestore counts |
| **Wallet reward redemption** | ✅ Wired to RewardService |
| **Create lecturer (Cloud Function)** | ✅ Admin SDK, no sign-out |

### What's MOCK / Placeholder
| Feature | Issue |
|---------|-------|
| Staking display (wallet) | May still have mock fallback for edge cases |

### What's BROKEN / Incomplete
| Feature | Issue |
|---------|-------|
| **Course detail page** | Still a bottom sheet — no full dedicated page |
| **Loan repayment UI** | No student repayment screen (service exists) |
| **Learning history** | Real enrollment data not confirmed wired |
| **Video calls** | Voice only — video toggle **intentionally deferred** (voice-only is correct for support) |
| **Earn EMC page** | `// TODO` replaced — `EarnEmcPage` built with daily tasks, forum, course enrolment/completion, achievements, staking & referral (soon) |
| **Cloud Functions** | ✅ All 11 deployed — migrated to `process.env` (.env file) |
| **Agora token server** | App ID ✅ set — `app_certificate` still needed (get from console.agora.io) |

---

## 3. Mock Data Strategy

### Principle
> **Keep all mock data. Make it deletable by admins only. Layer real implementations on top.**

### Implementation Plan

1. **Add `isMockData` field** to Firestore documents — when mock data is seeded to Firebase, tag each document with `isMockData: true`
2. **Seed mock data to Firestore** — instead of returning hardcoded lists, push mock data into actual Firestore collections on first run
3. **Admin delete controls** — admin panel gets a "Mock Data Management" section where admins can:
   - View all mock data (filtered by `isMockData == true`)
   - Delete individual mock items
   - Bulk delete all mock data per category
4. **Regular users** see mock data alongside real data (indistinguishable)
5. **`MockDataConfig` toggles** remain but default to `false` — all data flows through Firestore

### Categories to Seed
| Category | Mock Items | Firestore Collection |
|----------|-----------|---------------------|
| Books | 13 books | `books` |
| Daily Tasks | 7 tasks | `dailyTasks` |
| Forum Posts | 6 posts | `forumPosts` |
| Blog Posts | 6 posts | `blogPosts` |
| Scholarships | 4 scholarships | `scholarships` |
| Courses | 10 courses | `courses` (plus 20 diploma) |

---

## 4. Feature-by-Feature Implementation Plan

### 4.1 Authentication & User Management

**Currently working:** Email/password signup & login, Google Sign-In, role-based access, EMC signup bonus (1000 EMC).

**Needs fixing:**
| Task | Details | Priority |
|------|---------|----------|
| Fix `createLecturerAccount()` | Use a Firebase Admin SDK Cloud Function instead of client-side `createUserWithEmailAndPassword` (which signs out the current admin) | 🔴 High |
| Add phone/bio to `updateUserProfile()` | `edit_profile_page.dart` has fields but doesn't pass them to the service | 🟡 Medium |
| Implement profile photo upload | Use Firebase Storage `users/{uid}/profile/avatar.jpg`, update `photoUrl` field | 🟡 Medium |
| Password change | Implement `updatePassword()` via Firebase Auth in settings page | 🟡 Medium |
| Account deletion | Implement `deleteUser()` — delete Firestore doc + Auth account | 🟡 Medium |
| KYC verification flow | `kycVerified` field exists on `UserModel` but no UI to verify KYC | 🟢 Low |

### 4.2 Course System

**Currently working:** Course browsing from Firestore, category filtering, enrollment (saves to user's `enrolledCourses`), lecturer course creation dialog.

**Needs building:**
| Task | Details | Priority |
|------|---------|----------|
| Course search | Implement search in `courses_list_page.dart` (`// TODO: Implement search`) | 🔴 High |
| Course detail page | Replace bottom sheet with a full course detail page (modules, instructor, reviews, content list) | 🔴 High |
| Course progress tracking | Track module completion per student (`enrollments` subcollection with progress) | 🔴 High |
| Course content viewer | When student taps course content, open appropriate viewer (video, PDF, link) | 🔴 High |
| Enrollment with real payment | Link enrollment to Paystack or EMC payment (currently faked) | 🔴 High |
| Course ratings/reviews | Allow students to rate/review after enrollment | 🟢 Low |
| Course bookmarking (save) | Save/unsave courses with proper Firestore persistence (currently SharedPreferences with IDs only) | 🟡 Medium |

### 4.3 Bookshop

**Currently working:** Book grid with category filters, streaming from Firestore (with mock fallback), purchase deducts EMC.

**Needs building:**
| Task | Details | Priority |
|------|---------|----------|
| Seed mock books to Firestore | Move 13 mock books to actual Firestore `books` collection tagged with `isMockData: true` | 🔴 High |
| Book detail page | Full book detail view instead of just grid cards | 🟡 Medium |
| Book reader/download | After purchase, allow reading or downloading the book | 🟡 Medium |
| Admin book management | CRUD for books in admin panel (add, edit, delete) | 🟡 Medium |
| Purchase history | Track purchased books per user | 🟡 Medium |
| Paystack payment option | Allow book purchase with real money via Paystack alongside EMC | 🟢 Low |

### 4.4 Payment System (Paystack)

**Currently:** Entirely simulated. `paystack_checkout_page.dart` is a placeholder with "Simulate Success/Failure" buttons. No SDK integrated.

**Needs building:**
| Task | Details | Priority |
|------|---------|----------|
| Integrate Paystack Flutter SDK | Add `flutter_paystack_plus` or `paystack_flutter_inline` package | 🔴 Critical |
| Create Paystack payment service | New `payment_service.dart` handling initialization, checkout, verification | 🔴 Critical |
| Payment verification Cloud Function | Server-side verification of Paystack transactions via their API | 🔴 Critical |
| Replace simulated checkout | Replace `paystack_checkout_page.dart` with real Paystack inline checkout | 🔴 Critical |
| EMC balance payment | Actually deduct EMC balance on payment (currently shows success without deducting) | 🔴 High |
| Payment for courses | Wire real payment into `course_enrollment_page.dart` | 🔴 High |
| Payment for books | Wire real payment into Bookshop purchase flow | 🟡 Medium |
| Transaction recording | Record all Paystack transactions in Firestore with verification references | 🔴 High |
| EMC ↔ NGN conversion | Define and enforce EMC to Naira rate (currently 1 EMC = 1000 NGN) | 🟡 Medium |

### 4.5 EMC Wallet & Token Economy

**Currently working:** Balance display, EMC earn/spend tracking, `GuestWalletPage` with transaction history.

**Needs building:**
| Task | Details | Priority |
|------|---------|----------|
| Transaction history (Firebase) | `enhanced_wallet_page.dart` History tab says "coming soon" when mock is off — implement real Firestore stream | 🔴 High |
| Wallet overview (Firebase) | Wire Overview tab to real balance breakdown from `UserModel` fields (`availableEMC`, `stakedEMC`, `unredeemedEMC`, `totalEMCEarned`) | 🔴 High |
| Reward redemption | `_redeemUnredeemedRewards()` is a snackbar-only — wire to `RewardService.redeemCourseCompletionRewards()` | 🔴 High |
| Earn EMC opportunities | The "Earn" button in `GuestWalletPage` shows a snackbar (`// TODO: Navigate to earning opportunities`) — build earning opportunities page | 🟡 Medium |
| EMC top-up via Paystack | Allow users to buy EMC with real money | 🟡 Medium |
| EMC withdrawal | Allow users to cash out EMC to bank (via Paystack payout API or manual) | 🟢 Low |

### 4.6 Daily Tasks

**Currently:** Mock data from `MockDataService.getMockDailyTasks()`, completion state is ephemeral (resets on rebuild).

**Needs building:**
| Task | Details | Priority |
|------|---------|----------|
| Seed mock tasks to Firestore | Move 7 mock tasks to `dailyTasks` collection with `isMockData: true` | 🔴 High |
| Daily task service | New service to manage tasks — CRUD, track completions per user per day | 🔴 High |
| Task completion persistence | Save completed task state in Firestore (`userDailyTasks` subcollection) | 🔴 High |
| EMC reward on completion | Actually award EMC tokens when task is completed | 🔴 High |
| Daily reset mechanism | Cloud Function or client-side logic to reset/generate new daily tasks | 🟡 Medium |
| Admin task management | Admin can create/edit/delete daily tasks | 🟡 Medium |
| Task categories & filters | Filter by category (learning, social, achievement) | 🟢 Low |

### 4.7 Student Forum

**Currently:** Mock data, no create/reply/search functionality. "Coming soon" snackbars.

**Needs building:**
| Task | Details | Priority |
|------|---------|----------|
| Seed mock posts to Firestore | Move 6 mock posts to `forumPosts` collection with `isMockData: true` | 🔴 High |
| Forum service | New `forum_service.dart` — CRUD posts, replies, likes, search | 🔴 High |
| Create post UI | Build create post dialog/page (title, content, category, tags) | 🔴 High |
| Reply system | Subcollection `forumPosts/{id}/replies` with threaded replies | 🔴 High |
| Like/upvote system | Atomic like count increment with user tracking (prevent double-like) | 🟡 Medium |
| Search functionality | Full-text search on forum posts (title + content) | 🟡 Medium |
| Pin/unpin posts | Admin/lecturer can pin important posts | 🟡 Medium |
| Report posts | Users can report inappropriate content | 🟢 Low |

### 4.8 Blog / News

**Currently:** Mock data from `MockDataService.getMockBlogPosts()`. Category filtering works on mock data.

**Needs building:**
| Task | Details | Priority |
|------|---------|----------|
| Seed mock posts to Firestore | Move 6 mock blog posts to `blogPosts` collection with `isMockData: true` | 🔴 High |
| Blog service | New `blog_service.dart` — CRUD, stream by category | 🔴 High |
| Real blog content | Replace placeholder `'Full article content here...'` with actual content | 🔴 High |
| Admin blog management | Admin can create/edit/delete/publish blog posts | 🔴 High |
| Rich text editor | Use a markdown or rich text editor for blog content creation | 🟡 Medium |
| Blog images | Support image uploads for blog post covers | 🟡 Medium |
| Bookmark/save articles | Users can save favorite articles | 🟢 Low |

### 4.9 Scholarship Board

**Currently:** Mock data from `MockDataService.getMockScholarshipOpportunities()`. Apply button shows "Coming soon".

**Needs building:**
| Task | Details | Priority |
|------|---------|----------|
| Seed mock scholarships to Firestore | Move 4 mock scholarships to `scholarships` collection with `isMockData: true` | 🔴 High |
| Browse available scholarships | Stream real scholarships from Firestore (service already exists) | 🔴 High |
| Apply for scholarship | Build application form — student applies, admin reviews | 🔴 High |
| Application status tracking | Student can see pending/approved/rejected applications | 🟡 Medium |
| Admin scholarship creation | Admin can create new scholarship opportunities in admin panel | 🟡 Medium |
| Deposit payment flow | Wire deposit payment to Paystack or EMC wallet | 🟡 Medium |

### 4.10 Student Dashboard

**Currently:** 6 tabs (My Courses, Assignments, Exams, Materials, Grades, Certificates). Lists data from Firebase but **action buttons are snackbar stubs**.

**Needs building:**
| Task | Details | Priority |
|------|---------|----------|
| Assignment submission UI | Real form: text input, file upload, submit to `AssignmentService.submitAssignment()` | 🔴 Critical |
| Exam taking UI | Full exam page: show questions, MCQ selection, timer, submit to `ExamService.submitExamAttempt()` | 🔴 Critical |
| Content viewer | Open content by type: video player, PDF viewer, external link launcher | 🔴 Critical |
| Course progress page | Per-course progress: completed modules, assignments status, grade | 🔴 High |
| Grade detail with EMC rewards | Show EMC earned per grade, total unredeemed, redeem button | 🟡 Medium |
| Certificate view from grades | Link from grade to certificate (if issued) | 🟡 Medium |

### 4.11 Lecturer Dashboard

**Currently:** 7 tabs with mostly working lists. Creation dialogs are **stubs** ("Full implementation available" text).

**Needs building:**
| Task | Details | Priority |
|------|---------|----------|
| Create Assignment dialog | Full form: title, description, course, due date, points, attachment upload. Wire to `AssignmentService.createAssignment()` | 🔴 Critical |
| Create Exam dialog | Full form: title, questions builder (MCQ), schedule, pass mark. Wire to `ExamService.createExam()` | 🔴 Critical |
| Upload Content dialog | Full form: title, type selector, file picker/URL input, access level. Wire to `ContentService.uploadContent()` | 🔴 Critical |
| Grade submission | Lecturer can grade student submissions from the Assignments tab | 🔴 High |
| Students tab | Implement student management — view enrolled students per course, their progress, grades | 🔴 High |
| Edit/Delete course | Full course editing and deletion | 🟡 Medium |
| Exam approval tracking | Show approval status, allow re-submit if rejected | 🟡 Medium |
| Live class CRUD | Edit/cancel/reschedule live classes | 🟡 Medium |

### 4.12 Admin Panel

**Currently:** 5 tabs (Users, Create Lecturer, Courses, Certificates, Scholarships). Users tab and certificates tab work. Courses tab only has seed button.

**Needs building:**
| Task | Details | Priority |
|------|---------|----------|
| Mock data management tab | View and bulk-delete mock data by category | 🔴 High |
| Course management | Full CRUD: create, edit, delete, approve courses | 🔴 High |
| Fix create lecturer (Cloud Function) | Move account creation to a Cloud Function so admin doesn't get signed out | 🔴 High |
| Exam approval queue | View pending exams, approve/reject with feedback | 🔴 High |
| Loan management | Admin views for loan approvals, disbursements, overdue tracking | 🔴 High |
| Blog management | Create/edit/publish blog posts | 🟡 Medium |
| Daily task management | Create/edit/delete daily tasks | 🟡 Medium |
| Forum moderation | Pin/delete/moderate forum posts | 🟡 Medium |
| Analytics dashboard | Total users, revenue, active courses, enrollment stats | 🟡 Medium |
| Fix hardcoded admin IDs | Replace `'admin'` strings with actual `auth.currentUser.uid` | 🟡 Medium |
| System settings | App-wide configuration (EMC rates, staking tiers, etc.) | 🟢 Low |

### 4.13 Staking System

**Currently working:** Full staking service (stake, unstake, tiers, rewards calculation). Wallet tab displays staking with mock data fallback.

**Needs building:**
| Task | Details | Priority |
|------|---------|----------|
| Wire wallet staking tab to Firebase | Remove mock fallback, stream real staking data always | 🔴 High |
| Staking dashboard UI polish | Show tier progress bar, next tier info, APY display | 🟡 Medium |
| Auto-compound rewards | Option to auto-restake earned rewards | 🟢 Low |

### 4.14 Loan System

**Currently working:** Full loan lifecycle service (apply, approve, disburse, repay, default tracking). Loan application page works.

**Needs building:**
| Task | Details | Priority |
|------|---------|----------|
| Admin loan dashboard | View all loans, approve/reject, disburse, monitor repayments | 🔴 High |
| Loan repayment UI | Student UI to make loan payments from EMC wallet | 🔴 High |
| Loan repayment schedule | Show payment schedule, upcoming/overdue payments | 🟡 Medium |
| Overdue processing | Wire `processOverdueLoans()` to a scheduled Cloud Function | 🟡 Medium |

### 4.15 Certificates

**Currently working:** Issue, verify, revoke, QR codes. Student and admin views work.

**Needs building:**
| Task | Details | Priority |
|------|---------|----------|
| PDF download | Generate certificate as PDF (use `pdf` package) | 🟡 Medium |
| Share certificate | Share via system share sheet | 🟡 Medium |
| Fix hardcoded verification URL | Replace `https://emtech.school` with actual domain or dynamic deep link | 🟡 Medium |
| Fix admin IDs | Use actual admin UID instead of hardcoded `'admin'` | 🟡 Medium |

### 4.16 Notifications (Push)

**Currently:** In-app Firestore-based notifications only. No push notifications.

**Needs building:**
| Task | Details | Priority |
|------|---------|----------|
| Integrate Firebase Cloud Messaging (FCM) | Add `firebase_messaging` package | 🔴 High |
| Store FCM tokens | Save device tokens in user document | 🔴 High |
| Send push notifications | Cloud Function triggers push on notification creation | 🔴 High |
| Notification settings | Allow users to toggle push notification categories | 🟡 Medium |

### 4.17 Voice/Video Calls (Agora)

**Currently working:** Agora RTC initialized, call screen works, incoming call overlay works (admin only).

**Needs building:**
| Task | Details | Priority |
|------|---------|----------|
| Deploy Agora token Cloud Function | Deploy `generateAgoraToken` function and set config | 🔴 High |
| Set Agora app certificate | Run `firebase functions:config:set agora.app_certificate="..."` | 🔴 High |
| ~~Video call support~~ | Intentionally deferred — voice-only is appropriate for support calls | ~~🟡 Medium~~ ✅ Won't-do |
| Call history page | Viewable call log for users | 🟢 Low |

### 4.18 Live Classes (YouTube)

**Currently working:** YouTube player, live class viewer with Firestore stream, viewer count.

**Needs building:**
| Task | Details | Priority |
|------|---------|----------|
| Student live class discovery | Show upcoming/live classes on student dashboard or home page | 🟡 Medium |
| Live class chat | Real-time chat alongside video (Firestore subcollection) | ✅ Done |
| Class recording access | Allow viewing past class recordings | 🟢 Low |

### 4.19 Support System

**Currently:** FAQ section works. Voice call to support works (Agora). Contact form **doesn't submit**.

**Needs building:**
| Task | Details | Priority |
|------|---------|----------|
| Support ticket service | New `support_service.dart` — create tickets in Firestore `supportTickets` collection | 🔴 High |
| Support form submission | Wire form to actually save to Firestore, notify admin | 🔴 High |
| Admin support ticket view | Admin sees and responds to support tickets | 🟡 Medium |
| Ticket status tracking | Student can see open/resolved tickets | 🟡 Medium |
| Email notifications | Send email on ticket creation (via Cloud Function + email service) | 🟢 Low |

### 4.20 Profile & Settings

**Currently:** Profile displays correctly. Settings page has non-functional toggles.

**Needs building:**
| Task | Details | Priority |
|------|---------|----------|
| Save phone & bio | Pass phone/bio fields to `updateUserProfile()` | 🔴 High |
| Photo upload | Implement Firebase Storage upload + update `photoUrl` | 🔴 High |
| Persist settings | Save toggles to SharedPreferences or Firestore | 🟡 Medium |
| Password change | Implement `reauthenticateWithCredential()` + `updatePassword()` | 🟡 Medium |
| Privacy settings | Define what privacy settings mean and implement them | 🟢 Low |
| Account deletion | Delete user data from Firestore + delete Firebase Auth account | 🟡 Medium |
| Dark/Light mode toggle | Actually switch theme (currently toggle does nothing) | 🟢 Low |
| Language selection | Implement localization (if needed) | 🟢 Low |

### 4.21 Achievements & Gamification

**Currently:** 8 hardcoded achievements with static progress. No real tracking.

**Needs building:**
| Task | Details | Priority |
|------|---------|----------|
| Achievement service | Track achievement progress in Firestore (`userAchievements` subcollection) | 🟡 Medium |
| Define achievement triggers | Map achievements to real events (first course, first exam, 10 forum posts, etc.) | 🟡 Medium |
| Achievement unlock notifications | Notify user when achievement is unlocked | 🟡 Medium |
| Achievement EMC rewards | Award EMC on achievement unlock | 🟢 Low |

### 4.22 Learning History

**Currently:** 5 hardcoded courses with static progress percentages.

**Needs building:**
| Task | Details | Priority |
|------|---------|----------|
| Track real course progress | Query enrollment data + completion status per module | 🔴 High |
| Show actual enrolled courses | Use `enrolledCourses` from `UserModel` + Firestore course data | 🔴 High |
| Content completion tracking | Mark individual content/modules as completed | 🟡 Medium |
| Time spent tracking | Track time spent on content/courses | 🟢 Low |

### 4.23 Saved Courses

**Currently:** Stores course IDs in SharedPreferences. Displays "Saved Course" placeholder text, not actual course data.

**Needs building:**
| Task | Details | Priority |
|------|---------|----------|
| Fetch saved course details | Load actual course data from Firestore using saved IDs | 🔴 High |
| Move to Firestore | Store saved courses in user's Firestore subcollection (syncs across devices) | 🟡 Medium |
| Save/unsave from course list | Add bookmark button on course cards in `courses_list_page.dart` | 🟡 Medium |

### 4.24 About / Info Desk

**Currently:** All stats hardcoded ("5000+ Students", "150+ Courses", etc.).

**Needs building:**
| Task | Details | Priority |
|------|---------|----------|
| Dynamic stats | Pull real counts from Firestore (user count, course count, etc.) | 🟡 Medium |
| Contact info | Add real contact details (email, phone, social links) | 🟢 Low |

---

## 5. Firestore Rules Update

The current rules have several `allow write: if false` that block real functionality. These need updating:

```
// NEEDS UPDATING:
assignments     → allow write: if false    → CHANGE TO: if isLecturerOrAdmin()
submissions     → allow update: if false   → CHANGE TO: if isLecturerOrAdmin() (for grading)
grades          → allow write: if false    → CHANGE TO: if isLecturerOrAdmin()
certificates    → allow write: if false    → CHANGE TO: if isLecturerOrAdmin()
content         → Storage rules: if false  → CHANGE TO: if isLecturerOrAdmin()

// NEW COLLECTIONS NEEDED:
forumPosts      → read: if isAuthenticated(); write: if isAuthenticated()
forumReplies    → read: if isAuthenticated(); write: if isAuthenticated()
blogPosts       → read: if true; write: if isAdmin()
dailyTasks      → read: if isAuthenticated(); write: if isAdmin()
userDailyTasks  → read/write: if isOwner(userId)
supportTickets  → read: if isOwner() || isAdmin(); write: if isAuthenticated()
notifications   → read: if isOwner(userId); create: if isAuthenticated(); delete: if isOwner(userId)
liveClasses     → read: if isAuthenticated(); write: if isLecturerOrAdmin()
enrollments     → read: if isOwner() || isLecturerOrAdmin(); write: if isAuthenticated()
calls           → read/write: if isAuthenticated()
loans           → read: if isOwner() || isAdmin(); write: if isAuthenticated() || isAdmin()
loanPayments    → read: if isAuthenticated(); write: if isAuthenticated()
```

---

## 6. Firebase Cloud Functions to Build

### Written in `functions/index.js` (need `firebase deploy --only functions`)
| Function | Status |
|----------|---------| 
| `generateAgoraToken` | ✅ Written — needs `agora.app_certificate` config set |
| `checkAgoraConfig` | ✅ Written — admin-only diagnostic |
| `cleanupOldCalls` | ✅ Written — scheduled daily cleanup |
| `createLecturerAccount` | ✅ Written — Admin SDK, does not sign out admin |
| `verifyPaystackTransaction` | ✅ Written — server-side Paystack HTTPS verify |
| `processOverdueLoans` | ✅ Written — scheduled daily, flags overdue + notifies |
| `resetDailyTasks` | ✅ Written — scheduled midnight WAT, clears completions |
| `sendPushNotification` | ✅ Written — Firestore trigger, FCM multicast, auto-prunes bad tokens |
| `deleteUserAccount` | ✅ Written — deletes Firestore doc + Auth user |
| `seedMockData` | ✅ Written — callable, admin-only, seeds all categories |
| `cleanupMockData` | ✅ Written — callable, admin-only, bulk deletes by category |

### Still Needed
| Function | Purpose | Priority |
|----------|---------|----------|
| `getAppStats` | Callable: aggregated stats for About page | 🟢 Low |
| `sendEmailNotification` | Triggered: email on support ticket creation | 🟢 Low |

> ⚠️ **All 11 functions are now deployed** (migrated from deprecated `functions.config()` to `.env` / `process.env`).
> Agora `app_certificate` is still blank — voice calls will work in test mode but tokens will be unsigned until you set it:
> ```bash
> # Edit functions/.env and set:
> AGORA_APP_CERTIFICATE=your_certificate_here
> firebase deploy --only functions
> ```

---

## 7. Third-Party APIs & Services Setup Guide

### 7.1 Paystack (Payments)

**What it is:** Nigerian payment gateway supporting cards, bank transfers, USSD, and mobile money.

**Setup steps:**
1. **Create Paystack account** at [https://dashboard.paystack.com/signup](https://dashboard.paystack.com/signup)
2. **Get API keys** from Dashboard → Settings → API Keys & Webhooks:
   - **Test Public Key:** `pk_test_xxxxxxxxxxxxxxxx`
   - **Test Secret Key:** `sk_test_xxxxxxxxxxxxxxxx`
   - **Live Public Key:** `pk_live_xxxxxxxxxxxxxxxx` (after going live)
   - **Live Secret Key:** `sk_live_xxxxxxxxxxxxxxxx` (after going live)
3. **Add Flutter package** to `pubspec.yaml`:
   ```yaml
   dependencies:
     flutter_paystack_plus: ^2.0.0  # or paystack_flutter_inline
   ```
4. **Configure webhook URL** (for server-side verification):
   - Set webhook to your Cloud Function URL: `https://us-central1-emtech-be4d4.cloudfunctions.net/paystackWebhook`
5. **Set secret key in Cloud Functions config:**
   ```bash
   firebase functions:config:set paystack.secret_key="sk_test_xxxxxxxx"
   firebase functions:config:set paystack.public_key="pk_test_xxxxxxxx"
   ```
6. **Go live checklist** (when ready for production):
   - Submit business documentation on Paystack Dashboard
   - Switch from test keys to live keys
   - Update webhook URLs

**Cost:** Free to create account. Transaction fees: 1.5% + ₦100 (capped at ₦2,000) for local transactions.

**EMC ↔ NGN Rate:** Currently hardcoded as 1 EMC = ₦1,000. Define this as a configurable value in Firebase Remote Config.

---

### 7.2 Agora (Voice/Video Calls)

**What it is:** Real-time communication SDK for voice and video calls.

**Current state:** App ID is configured (`6994ddd5b9674386b5602fb67fbb2c9e`). App certificate is NOT configured. Cloud Function exists but may not be deployed.

**Setup steps:**
1. **Agora Console** — [https://console.agora.io](https://console.agora.io)
2. **Get App Certificate** from Project → Edit → Primary Certificate
3. **Set Cloud Functions config:**
   ```bash
   firebase functions:config:set agora.app_id="6994ddd5b9674386b5602fb67fbb2c9e"
   firebase functions:config:set agora.app_certificate="YOUR_APP_CERTIFICATE_HERE"
   ```
4. **Deploy Cloud Functions:**
   ```bash
   cd functions && npm install
   firebase deploy --only functions
   ```
5. **Test token generation** — the function generates 24-hour tokens per channel

**Cost:** First 10,000 minutes/month free. Then $0.99–$3.99 per 1,000 minutes depending on quality.

---

### 7.3 Firebase Cloud Messaging (Push Notifications)

**What it is:** Push notification service for mobile and web.

**Setup steps:**
1. **Add package:**
   ```yaml
   dependencies:
     firebase_messaging: ^15.0.0
   ```
2. **iOS Setup:**
   - Enable Push Notifications capability in Xcode
   - Upload APNs authentication key to Firebase Console → Project Settings → Cloud Messaging
   - Key is generated in Apple Developer Console → Certificates, Identifiers & Profiles → Keys
3. **Android:** Works automatically with `google-services.json` already in place
4. **Web:** Already has Firebase configured; add `firebase-messaging-sw.js` service worker
5. **Request permissions** in app on first launch
6. **Store FCM token** in user's Firestore document

**Cost:** Free (unlimited notifications).

---

### 7.4 Firebase Cloud Functions Deployment

**Current:** Functions are written in `functions/index.js` but may not be deployed.

**Setup steps:**
1. **Install dependencies:**
   ```bash
   cd functions
   npm install
   ```
2. **Set all required configs:**
   ```bash
   # Agora
   firebase functions:config:set agora.app_id="6994ddd5b9674386b5602fb67fbb2c9e"
   firebase functions:config:set agora.app_certificate="YOUR_CERT"
   
   # Paystack (after account creation)
   firebase functions:config:set paystack.secret_key="sk_test_xxx"
   firebase functions:config:set paystack.public_key="pk_test_xxx"
   ```
3. **Deploy:**
   ```bash
   firebase deploy --only functions
   ```
4. **Verify:** Check Firebase Console → Functions for deployed functions

**Cost:** Firebase Blaze plan required for Cloud Functions. First 2M invocations/month free, then $0.40 per million.

**Current Firebase plan check:**
```bash
firebase projects:list
```
If on Spark (free) plan, upgrade to Blaze at [Firebase Console](https://console.firebase.google.com) → Project → Upgrade.

---

### 7.5 Google Sign-In Configuration

**Current state:** Working. Already configured.

**Verify/maintain:**
- Android: SHA-1 fingerprint in Firebase Console (required for each new machine)
  ```bash
  cd android && ./gradlew signingReport
  ```
- iOS: `GoogleService-Info.plist` must have correct `REVERSED_CLIENT_ID` in URL schemes
- Web: OAuth consent screen configured in Google Cloud Console

---

## 8. Database Schema (Firestore Collections)

### Existing Collections
| Collection | Document Fields | Used By |
|-----------|----------------|---------|
| `users` | uid, email, name, role, emcBalance, enrolledCourses, photoUrl, session, createdAt, updatedAt, totalEMCEarned, unredeemedEMC, stakedEMC, availableEMC, kycVerified, activeLoanCount | AuthService |
| `courses` | title, description, instructor, priceEmc, category, thumbnailUrl, modules, duration, studentsEnrolled, createdAt | FirestoreService |
| `books` | title, author, description, priceEmc, category, coverImageUrl, createdAt | FirestoreService |
| `transactions` | userId, type (earn/spend), amount, description, relatedId, createdAt | AuthService, FirestoreService |
| `assignments` | courseId, courseName, lecturerId, lecturerName, title, description, attachmentUrl, dueDate, totalPoints, isPublished, submissionCount, createdAt | AssignmentService |
| `submissions` | assignmentId, examId, type, courseId, studentId, studentName, textSubmission, fileUrl, examAnswers, submittedAt, status, score, grade, feedback, gradedAt | AssignmentService, ExamService |
| `exams` | courseId, lecturerId, title, questions[], totalPoints, durationMinutes, scheduledDate, status, approvedAt, rejectionReason, attemptCount | ExamService |
| `content` | courseId, title, type, fileUrl, accessLevel, uploadedById, viewCount, downloadCount, fileSizeBytes | ContentService |
| `grades` | studentId, courseId, grade(enum), numericScore, emcReward, lecturerId, semester, isRedeemed | GradingService |
| `certificates` | studentId, courseId, grade, certificateNumber, verificationUrl, qrCodeData, status, type, issuedBy | CertificateService |
| `stakes` | userId, stakedAmount, tier, isActive, votingPower, rewardsEarned, stakedAt, unstakedAt | StakingService |
| `rewards` | userId, type, amount, isRedeemed, description, createdAt | RewardService |
| `loans` | studentId, requestedAmount, approvedAmount, interestRate, termMonths, status, monthlyPayment, outstandingBalance | LoanService |
| `loanPayments` | loanId, studentId, amount, dueDate, isLate, penaltyAmount | LoanService |
| `scholarships` | studentId, type, percentage, depositRequired, depositStatus, minimumGradeRequired, courseId | ScholarshipService |
| `calls` | callerId, callerName, receiverId, channelName, status, duration, createdAt | CallService |
| `liveClasses` | title, instructorId, courseId, youtubeUrl, status, viewerCount, scheduledAt | LecturerDashboard |
| `notifications` | userId, title, message, type, isRead, createdAt | NotificationService |

### New Collections Needed
| Collection | Purpose | Fields |
|-----------|---------|--------|
| `forumPosts` | Student forum posts | authorId, title, content, category, likes, replies, tags, isPinned, isMockData, createdAt |
| `forumPosts/{id}/replies` | Forum replies | authorId, authorName, content, createdAt |
| `blogPosts` | Blog/news articles | title, excerpt, content, author, category, imageUrl, publishedAt, tags, isMockData |
| `dailyTasks` | Daily tasks definitions | title, description, rewardEmc, category, iconName, isActive, isMockData |
| `userDailyTasks/{userId}/completions` | Track daily task completions | taskId, completedAt, emcRewarded |
| `supportTickets` | Support requests | userId, userName, email, subject, message, status, createdAt, resolvedAt |
| `enrollments` | Course enrollments (richer than array) | userId, courseId, enrolledAt, progress, completedModules, status |
| `userAchievements/{userId}/achievements` | Achievement tracking | achievementId, progress, isUnlocked, unlockedAt |
| `savedCourses/{userId}/courses` | Saved/bookmarked courses | courseId, savedAt |

---

## 9. Implementation Priority & Phases

### ✅ Phase 1: Foundation & Critical Fixes — COMPLETE
1. ✅ Fix Firestore rules
2. ✅ Seed mock data to Firestore with `isMockData: true`
3. ✅ Admin mock data management tab
4. ✅ `createLecturerAccount` Cloud Function (Admin SDK)
5. ✅ Fix hardcoded admin IDs
6. ✅ Save phone/bio fields on profile edit
7. ✅ Course search implementation
8. ✅ Saved courses — Firestore backend

### ✅ Phase 2: Student Experience — COMPLETE
1. ✅ Assignment submission UI (text + file upload)
2. ✅ Exam taking UI (MCQ, timer)
3. ✅ Content viewer (video, PDF, link)
4. ✅ Course progress tracking
5. ✅ Learning history (enrollment data)
6. ✅ Daily tasks (Firestore, persistence, EMC rewards)

### ✅ Phase 3: Payment Integration — COMPLETE
1. ✅ Paystack SDK (`flutter_paystack_plus: ^2.4.0`)
2. ✅ Payment service (checkout, result handling)
3. ✅ `verifyPaystackTransaction` Cloud Function
4. ✅ Course enrollment with real payment
5. ✅ Wallet transaction history (Firestore)

### ✅ Phase 4: Lecturer Tools — COMPLETE
1. ✅ Create Assignment dialog (full form)
2. ✅ Create Exam dialog (MCQ question builder)
3. ✅ Upload Content dialog (file picker + URL)
4. ✅ Grade submissions (lecturer grading UI)
5. ✅ Students management tab
6. ✅ Edit/delete courses

### ✅ Phase 5: Communication & Community — COMPLETE
1. ✅ Push notifications (FCM + `firebase_messaging: ^15.0.0`)
2. ✅ Forum service + UI (create/reply/like/search)
3. ✅ Blog service + admin UI (CRUD)
4. ✅ Support ticket system (Firestore + admin view)
5. ✅ Scholarship application flow

### ✅ Phase 6: Polish & Advanced Features — COMPLETE
1. ✅ Certificate PDF generation & sharing (`pdf: ^3.10.8`, `printing: ^5.13.1`)
2. ✅ Achievement system (13 achievements, real Firestore tracking)
3. ✅ Settings persistence (SharedPreferences)
4. ✅ Password change & account deletion
5. ✅ Admin analytics dashboard (live stats + charts)
6. ✅ Admin loan management (approve/reject/disburse)
7. ✅ About page dynamic stats
8. ✅ Wallet reward redemption (wired to RewardService)
9. ✅ All Cloud Functions written (deployment still needed)

### 🔜 Phase 7: Production Readiness (Remaining)
1. **Deploy Cloud Functions** — ✅ All 11 deployed (`generateAgoraToken`, `verifyPaystackTransaction`, `createLecturerAccount`, etc.)
2. **Course detail page** — full page replacing bottom sheet
3. **Loan repayment UI** — student screen to make payments
4. **Wire achievement triggers** — ✅ Wired in PaymentService, AssignmentService, ExamService, GradingService, CertificateService, ForumService, DailyTaskService, StakingService
5. **Video call upgrade** — intentionally deferred (voice-only is correct for support)
6. **Earn EMC page** — ✅ `EarnEmcPage` built and wired in wallet
7. **Production Firestore rules audit** — verify all collections secured
8. **Live class chat** — real-time Firestore subcollection chat

---

## 10. Estimated Work Breakdown

| Phase | Effort | Key Deliverables |
|-------|--------|------------------|
| **Phase 1:** Foundation | ✅ Complete | Firestore rules, mock data migration, admin controls, profile fixes |
| **Phase 2:** Student Experience | ✅ Complete | Submission UIs, exam taking, content viewer, progress tracking |
| **Phase 3:** Payment | ✅ Complete | Paystack integration, payment flows, Cloud Function verification |
| **Phase 4:** Lecturer Tools | ✅ Complete | Creation dialogs, grading UI, student management |
| **Phase 5:** Communication | ✅ Complete | Push notifications, forum, blog, support tickets |
| **Phase 6:** Polish | ✅ Complete | PDF, achievements, settings, admin dashboard, loan management |
| **Phase 7:** Production | 🔜 In Progress | Functions deploy, course detail, loan repayment, video calls |
| **Total** | **~250 hrs done** | All core features implemented — production deploy remaining |

---

## Quick Reference: What YOU Need to Set Up (External Actions)

Before development can proceed on certain features, you need to take these manual actions:

| Action | Needed For | Link / Command |
|--------|-----------|----------------|
| **Create Paystack account** | Payments | [dashboard.paystack.com/signup](https://dashboard.paystack.com/signup) |
| **Get Paystack API keys** | Payments | Paystack Dashboard → Settings → API Keys |
| **Get Agora App Certificate** | Secure calls | [console.agora.io](https://console.agora.io) → Project → Edit |
| **Upgrade Firebase to Blaze plan** | Cloud Functions | Firebase Console → Project → Upgrade |
| **Deploy Cloud Functions** | Token gen, payments | `firebase deploy --only functions` |
| **Set Firebase Functions config** | Agora + Paystack | See Section 7.4 |
| **iOS Push Notification setup** | Push notifications | Apple Developer → Keys → APNs Auth Key → Upload to Firebase |
| **Add APNs key to Firebase** | iOS push | Firebase Console → Project Settings → Cloud Messaging |
| **Verify SHA-1 fingerprints** | Android Google Sign-In | `cd android && ./gradlew signingReport` |

---

## File Changes Summary

When implementation begins, these are the primary files that will be created or modified:

### New Files to Create
- `lib/services/payment_service.dart` — Paystack integration
- `lib/services/forum_service.dart` — Forum CRUD
- `lib/services/blog_service.dart` — Blog CRUD
- `lib/services/daily_task_service.dart` — Daily tasks
- `lib/services/support_service.dart` — Support tickets
- `lib/services/achievement_service.dart` — Achievement tracking
- `lib/services/push_notification_service.dart` — FCM integration
- `lib/services/mock_data_seeder.dart` — Seed mock data to Firestore
- `lib/screens/student/exam_taking_page.dart` — Exam taking UI
- `lib/screens/student/assignment_submission_page.dart` — Assignment submission
- `lib/screens/student/content_viewer_page.dart` — Content viewing
- `lib/screens/student/course_detail_page.dart` — Course details
- `lib/screens/admin/mock_data_management_tab.dart` — Mock data admin
- `lib/screens/admin/loan_management_tab.dart` — Loan admin
- `lib/screens/admin/exam_approval_tab.dart` — Exam approvals
- `lib/screens/admin/blog_management_tab.dart` — Blog admin
- `functions/paystack.js` — Paystack verification function
- `functions/notifications.js` — Push notification function
- `functions/admin.js` — Admin operations (create lecturer, etc.)

### Key Files to Modify
- `lib/main.dart` — Add new routes, fix navigation
- `lib/config/mock_data_config.dart` — Default mock flags to `false`
- `lib/services/firestore_service.dart` — Remove mock fallbacks
- `lib/services/auth_service.dart` — Fix `createLecturerAccount`, add phone/bio
- `lib/screens/student/student_dashboard_page.dart` — Wire real action UIs
- `lib/screens/lecturer/phase2_widgets.dart` — Build real creation dialogs
- `lib/screens/lecturer/lecturer_dashboard_page.dart` — Students tab, edit/delete
- `lib/screens/admin/admin_panel_page.dart` — Add new tabs
- `lib/screens/wallet/enhanced_wallet_page.dart` — Wire real data
- `lib/screens/payment/paystack_checkout_page.dart` — Real Paystack
- `lib/screens/payment/payment_selection_page.dart` — Real EMC payment
- `lib/screens/course_enrollment_page.dart` — Real payment
- `lib/screens/settings_page.dart` — Persist settings, implement features
- `lib/screens/edit_profile_page.dart` — Photo + phone/bio
- `lib/screens/student_forum_page.dart` — Real CRUD
- `lib/screens/blog_news_page.dart` — Real data
- `lib/screens/daily_tasks_page.dart` — Real data + persistence
- `lib/screens/scholarship_board_page.dart` — Real data + apply
- `lib/screens/saved_courses_page.dart` — Fetch real course data
- `lib/screens/learning_history_page.dart` — Real progress data
- `lib/screens/achievements_page.dart` — Real tracking
- `lib/screens/about_info_desk_page.dart` — Dynamic stats
- `lib/screens/support_page.dart` — Real form submission
- `firestore.rules` — Unblock writes, add new collections
- `storage.rules` — Unblock uploads
- `functions/index.js` — Add new functions
- `pubspec.yaml` — New packages

---

*This document serves as the complete roadmap. Each section can be tackled independently. Start with Phase 1 to establish the foundation, then proceed through phases sequentially.*
