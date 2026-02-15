# Backend Migration Guide

## Current Architecture (Firebase)

The Emtech School app is built with a **service-oriented architecture** that abstracts Firebase-specific implementations, making migration to AWS or other backends straightforward.

## Service Layer Abstraction

### 1. **AuthService** (`lib/services/auth_service.dart`)
**Current:** Firebase Authentication + Firestore
**Migration Path:** Replace with AWS Cognito + DynamoDB

```dart
// Current Firebase implementation
class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // All methods return standard Dart types (UserModel, String?, etc.)
  // No Firebase-specific types exposed to UI
}
```

**For AWS Migration:**
- Replace `FirebaseAuth` with AWS Amplify Auth
- Replace `FirebaseFirestore` with DynamoDB client
- Keep method signatures identical
- UI code requires ZERO changes

### 2. **FirestoreService** (`lib/services/firestore_service.dart`)
**Current:** Cloud Firestore
**Migration Path:** AWS DynamoDB + AppSync

```dart
// Current implementation returns generic Streams and Futures
Stream<List<BookModel>> getBooks({String? category})
Future<void> addBook(BookModel book)
```

**For AWS Migration:**
- Create `DynamoDBService` with identical method signatures
- Replace `_firestore` with DynamoDB DocumentClient
- Convert Firestore snapshots to DynamoDB query results
- UI code requires ZERO changes

### 3. **Data Models** (Independent of Firebase)
All models are pure Dart classes with `toMap()` and `fromMap()` methods:
- `UserModel`
- `BookModel`
- `CourseModel`
- `TransactionModel`

**No changes needed** - work with any database.

## Migration Checklist

### Phase 1: AWS Setup
- [ ] Create AWS account and configure Amplify
- [ ] Set up Cognito user pools
- [ ] Create DynamoDB tables matching Firestore collections
- [ ] Configure S3 buckets for storage
- [ ] Set up AppSync for real-time data (if needed)

### Phase 2: Service Replacement
- [ ] Create `lib/services/aws/`
- [ ] Implement `AWSAuthService` matching `AuthService` interface
- [ ] Implement `DynamoDBService` matching `FirestoreService` interface
- [ ] Implement `S3StorageService` for file uploads

### Phase 3: Gradual Migration
- [ ] Use feature flags to switch between Firebase and AWS
- [ ] Migrate non-critical features first (books, courses)
- [ ] Migrate user data last
- [ ] Run both systems in parallel during transition

### Phase 4: Complete Switch
- [ ] Update `main.dart` provider initialization
- [ ] Archive Firebase project
- [ ] Update documentation

## Database Schema Mapping

### Firestore → DynamoDB

| Firestore Collection | DynamoDB Table | Partition Key | Sort Key |
|---------------------|----------------|---------------|----------|
| users | Users | userId | - |
| books | Books | bookId | - |
| courses | Courses | courseId | - |
| transactions | Transactions | userId | createdAt |
| assignments | Assignments | courseId | assignmentId |
| submissions | Submissions | userId | submissionId |
| grades | Grades | userId | courseId |
| certificates | Certificates | certificateId | - |

### Firestore Storage → S3 Buckets

| Storage Path | S3 Bucket Structure |
|-------------|---------------------|
| `/users/{userId}/profile/` | `emtech-profile/{userId}/` |
| `/courses/{courseId}/materials/` | `emtech-courses/{courseId}/materials/` |
| `/submissions/{userId}/{assignmentId}/` | `emtech-submissions/{userId}/{assignmentId}/` |
| `/certificates/{userId}/` | `emtech-certificates/{userId}/` |

## Code Changes Required (Minimal)

### main.dart
```dart
// Current
providers: [
  ChangeNotifierProvider(create: (_) => AuthService()),
  ChangeNotifierProvider(create: (_) => FirestoreService()),
]

// After migration
providers: [
  ChangeNotifierProvider(create: (_) => AWSAuthService()),
  ChangeNotifierProvider(create: (_) => DynamoDBService()),
]
```

### Dependencies (pubspec.yaml)
```yaml
# Current
firebase_core: ^3.12.0
firebase_auth: ^5.4.0
cloud_firestore: ^5.6.0
firebase_storage: ^12.4.0

# After migration
amplify_flutter: ^2.0.0
amplify_auth_cognito: ^2.0.0
amplify_storage_s3: ^2.0.0
amplify_api: ^2.0.0
```

## Real-time Data Considerations

### Current: Firestore Streams
```dart
Stream<List<TransactionModel>> getTransactions(String userId) {
  return _firestore
    .collection('transactions')
    .snapshots()
    .map((snapshot) => ...);
}
```

### AWS Option 1: DynamoDB Streams + AppSync
```dart
Stream<List<TransactionModel>> getTransactions(String userId) {
  return _appsync
    .subscribe(TransactionsSubscription(userId: userId))
    .map((data) => ...);
}
```

### AWS Option 2: Polling (simpler)
```dart
Stream<List<TransactionModel>> getTransactions(String userId) {
  return Stream.periodic(Duration(seconds: 5), (_) async {
    return await _dynamodb.query(userId);
  });
}
```

## Cost Comparison

### Firebase (Current Costs)
- Authentication: Free for standard features
- Firestore: $0.18/GB stored, $0.06 per 100k reads
- Storage: $0.026/GB
- **Estimated monthly:** $10-50 for early stage

### AWS (Projected Costs)
- Cognito: Free for <50k users
- DynamoDB: $0.25/GB stored, $0.50 per million reads
- S3: $0.023/GB
- **Estimated monthly:** $5-30 for early stage

## Security Rules Migration

### Firestore Rules → IAM Policies
Current Firestore rules in `firestore.rules` map to:
- AWS IAM roles for API Gateway
- DynamoDB table policies
- S3 bucket policies

See `AWS_SECURITY.md` for detailed mapping.

## Rollback Plan

Keep Firebase active for 3 months after migration:
1. Data syncing tool to keep both in sync
2. Feature flag to instantly switch back
3. Automated backup from AWS to Firebase daily

## Why This Architecture Works

✅ **No vendor lock-in** - Services implement interfaces  
✅ **UI unchanged** - Provider pattern abstracts backend  
✅ **Parallel running** - Can run Firebase + AWS simultaneously  
✅ **Incremental migration** - Move features one at a time  
✅ **Easy rollback** - Switch providers in one line

## Next Steps

1. Read AWS Amplify documentation
2. Set up AWS account and create test environment
3. Implement one service (e.g., `AWSAuthService`) as proof of concept
4. Test with feature flag before full migration

---

**Last Updated:** February 15, 2026  
**Contact:** Development Team
