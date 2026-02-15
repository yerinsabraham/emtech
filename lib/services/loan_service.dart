import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/loan_model.dart';
import '../models/loan_payment_model.dart';
import '../models/grade_model.dart';
import 'staking_service.dart';
import 'grading_service.dart';
import 'notification_service.dart';

class LoanService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StakingService _stakingService = StakingService();
  final GradingService _gradingService = GradingService();
  final NotificationService _notificationService = NotificationService();

  /// Apply for a loan
  Future<String> applyForLoan({
    required String studentId,
    required String studentName,
    required double requestedAmount,
    required int termMonths,
    required String purpose,
    String? referenceLecturerId,
    String? referenceLecturerName,
  }) async {
    try {
      // Get student data
      final userDoc = await _firestore.collection('users').doc(studentId).get();
      final userData = userDoc.data();

      if (userData == null) {
        throw Exception('User not found');
      }

      // Check KYC verification
      final kycVerified = userData['kycVerified'] ?? false;

      // Get GPA
      final gpa = await _gradingService.calculateGPA(studentId);

      // Get highest grade
      final grades = await _gradingService.getStudentGrades(studentId).first;
      LetterGrade? highestGrade;
      if (grades.isNotEmpty) {
        highestGrade = grades
            .map((g) => g.grade)
            .reduce((a, b) => (a.index < b.index) ? a : b);
      }

      // Get staking info
      final stakingDays = await _stakingService.getLongestStakingDuration(studentId);
      final stakedAmount = await _stakingService.getTotalStaked(studentId);
      final stakingTier = await _stakingService.getUserStakingTier(studentId);

      // Check qualification
      final qualifies = LoanModel.checkQualification(
        gpa: gpa,
        highestGrade: highestGrade,
        stakingDays: stakingDays,
        kycVerified: kycVerified,
        hasReference: referenceLecturerId != null,
      );

      if (!qualifies) {
        throw Exception(
          'Loan qualification not met. Requirements:\n'
          '• GPA >= 2.0 OR Grade B+ or better\n'
          '• 30+ days staked OR lecturer reference\n'
          '• KYC verification completed',
        );
      }

      // Calculate max loan amount
      final maxAmount = LoanModel.calculateMaxLoanAmount(
        gpa: gpa,
        tier: stakingTier,
        stakingDays: stakingDays,
      );

      if (requestedAmount > maxAmount) {
        throw Exception(
          'Requested amount exceeds maximum eligible amount: ${maxAmount.toStringAsFixed(0)} EMC',
        );
      }

      // Check active loan limit (max 2 active loans)
      final activeLoanCount = userData['activeLoanCount'] ?? 0;
      if (activeLoanCount >= 2) {
        throw Exception('Maximum active loan limit reached (2 loans)');
      }

      // Create loan application
      final loan = LoanModel(
        id: '',
        studentId: studentId,
        studentName: studentName,
        requestedAmount: requestedAmount,
        termMonths: termMonths,
        purpose: purpose,
        appliedAt: DateTime.now(),
        status: LoanStatus.pending,
        currentGPA: gpa,
        highestGrade: highestGrade,
        stakingDurationDays: stakingDays,
        stakedAmount: stakedAmount,
        stakingTier: stakingTier,
        kycVerified: kycVerified,
        referenceLecturerId: referenceLecturerId,
        referenceLecturerName: referenceLecturerName,
      );

      final docRef = await _firestore.collection('loans').add(loan.toFirestore());

      // Notify admins
      await _notificationService.notifyByRole(
        role: 'admin',
        title: 'New Loan Application',
        message: '$studentName applied for ${requestedAmount.toStringAsFixed(0)} EMC loan',
        type: 'loan',
        actionUrl: '/admin/loans/$docRef',
      );

      // Notify student
      await _notificationService.createNotification(
        userId: studentId,
        title: 'Loan Application Submitted',
        message: 'Your loan application for ${requestedAmount.toStringAsFixed(0)} EMC is under review',
        type: 'loan',
        actionUrl: '/loans/${docRef.id}',
      );

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to apply for loan: $e');
    }
  }

  /// Approve loan (Admin only)
  Future<void> approveLoan({
    required String loanId,
    required String adminId,
    required String adminName,
    required double approvedAmount,
    double? customInterestRate,
    String? adminNotes,
  }) async {
    try {
      final loanDoc = await _firestore.collection('loans').doc(loanId).get();
      if (!loanDoc.exists) {
        throw Exception('Loan not found');
      }

      final loan = LoanModel.fromFirestore(loanDoc);

      if (loan.status != LoanStatus.pending && loan.status != LoanStatus.underReview) {
        throw Exception('Loan is not in pending status');
      }

      // Calculate loan terms
      final interestRate = customInterestRate ?? 0.08; // Default 8% APR
      final monthlyPayment = LoanModel.calculateMonthlyPayment(
        approvedAmount,
        interestRate,
        loan.termMonths,
      );
      final totalAmountDue = monthlyPayment * loan.termMonths;

      // Update loan
      await _firestore.collection('loans').doc(loanId).update({
        'status': LoanStatus.approved.toString(),
        'approvedAmount': approvedAmount,
        'interestRate': interestRate,
        'approvedAt': Timestamp.fromDate(DateTime.now()),
        'approvedBy': adminName,
        'adminNotes': adminNotes,
        'totalAmountDue': totalAmountDue,
        'monthlyPayment': monthlyPayment,
        'outstandingBalance': totalAmountDue,
        'totalPayments': loan.termMonths,
        'completedPayments': 0,
        'nextPaymentDue': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 30)),
        ),
      });

      // Notify student
      await _notificationService.createNotification(
        userId: loan.studentId,
        title: 'Loan Approved! 🎉',
        message: 'Your loan for ${approvedAmount.toStringAsFixed(0)} EMC has been approved. Ready to disburse!',
        type: 'loan',
        actionUrl: '/loans/$loanId',
      );

      // Notify reference lecturer if any
      if (loan.referenceLecturerId != null) {
        await _notificationService.createNotification(
          userId: loan.referenceLecturerId!,
          title: 'Student Loan Approved',
          message: '${loan.studentName}\'s loan application you referenced was approved',
          type: 'loan',
        );
      }
    } catch (e) {
      throw Exception('Failed to approve loan: $e');
    }
  }

  /// Reject loan (Admin only)
  Future<void> rejectLoan({
    required String loanId,
    required String reason,
    String? adminNotes,
  }) async {
    try {
      final loanDoc = await _firestore.collection('loans').doc(loanId).get();
      if (!loanDoc.exists) {
        throw Exception('Loan not found');
      }

      final loan = LoanModel.fromFirestore(loanDoc);

      await _firestore.collection('loans').doc(loanId).update({
        'status': LoanStatus.rejected.toString(),
        'rejectionReason': reason,
        'adminNotes': adminNotes,
      });

      // Notify student
      await _notificationService.createNotification(
        userId: loan.studentId,
        title: 'Loan Application Update',
        message: 'Your loan application was not approved. Reason: $reason',
        type: 'loan',
        actionUrl: '/loans/$loanId',
      );
    } catch (e) {
      throw Exception('Failed to reject loan: $e');
    }
  }

  /// Disburse loan funds to student
  Future<void> disburseLoan({
    required String loanId,
    required String adminId,
  }) async {
    try {
      final loanDoc = await _firestore.collection('loans').doc(loanId).get();
      if (!loanDoc.exists) {
        throw Exception('Loan not found');
      }

      final loan = LoanModel.fromFirestore(loanDoc);

      if (loan.status != LoanStatus.approved) {
        throw Exception('Loan must be approved before disbursement');
      }

      // Disburse EMC to student wallet
      await _firestore.collection('users').doc(loan.studentId).update({
        'availableEMC': FieldValue.increment(loan.approvedAmount),
        'emcBalance': FieldValue.increment(loan.approvedAmount),
        'activeLoanCount': FieldValue.increment(1),
      });

      // Update loan status
      await _firestore.collection('loans').doc(loanId).update({
        'status': LoanStatus.active.toString(),
        'disbursedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Notify student
      await _notificationService.createNotification(
        userId: loan.studentId,
        title: 'Loan Funds Disbursed',
        message: '${loan.approvedAmount.toStringAsFixed(0)} EMC has been added to your wallet!',
        type: 'payment',
        actionUrl: '/wallet',
      );
    } catch (e) {
      throw Exception('Failed to disburse loan: $e');
    }
  }

  /// Make loan payment
  Future<String> makeLoanPayment({
    required String loanId,
    required String studentId,
    required double amount,
  }) async {
    try {
      final loanDoc = await _firestore.collection('loans').doc(loanId).get();
      if (!loanDoc.exists) {
        throw Exception('Loan not found');
      }

      final loan = LoanModel.fromFirestore(loanDoc);

      if (loan.status != LoanStatus.active) {
        throw Exception('Loan is not active');
      }

      // Check user has enough EMC
      final userDoc = await _firestore.collection('users').doc(studentId).get();
      final availableEMC = (userDoc.data()?['availableEMC'] ?? 0).toDouble();

      if (availableEMC < amount) {
        throw Exception('Insufficient EMC balance');
      }

      // Calculate late penalty if applicable
      final now = DateTime.now();
      final dueDate = loan.nextPaymentDue ?? now;
      final isLate = now.isAfter(dueDate);
      final daysLate = isLate ? now.difference(dueDate).inDays : 0;
      final penalty = LoanPaymentModel.calculateLatePenalty(amount, daysLate);

      final totalPayment = amount + penalty;

      if (availableEMC < totalPayment) {
        throw Exception(
          'Insufficient EMC for payment + penalty. Need: ${totalPayment.toStringAsFixed(0)} EMC',
        );
      }

      // Calculate interest and principal portions
      final monthlyInterest = (loan.outstandingBalance * loan.interestRate) / 12;
      final interestPortion = monthlyInterest > amount ? amount : monthlyInterest;
      final principalPortion = amount - interestPortion;

      // Create payment record
      final payment = LoanPaymentModel(
        id: '',
        loanId: loanId,
        studentId: studentId,
        amount: amount,
        paidAt: now,
        dueDate: dueDate,
        isLate: isLate,
        dayslate: daysLate,
        penaltyAmount: penalty,
        interestPortion: interestPortion,
        principalPortion: principalPortion,
        balanceAfterPayment: loan.outstandingBalance - principalPortion,
      );

      final paymentDocRef = await _firestore.collection('loan_payments').add(payment.toFirestore());

      // Update loan
      final newBalance = loan.outstandingBalance - principalPortion;
      final newCompletedPayments = loan.completedPayments + 1;
      final isFullyPaid = newBalance <= 0.01; // Account for floating point

      final loanUpdate = <String, dynamic>{
        'outstandingBalance': newBalance,
        'amountPaid': FieldValue.increment(amount),
        'completedPayments': newCompletedPayments,
        'penaltyAmount': FieldValue.increment(penalty),
      };

      if (isFullyPaid) {
        loanUpdate['status'] = LoanStatus.completed.toString();
      } else {
        // Set next payment due date
        loanUpdate['nextPaymentDue'] = Timestamp.fromDate(
          dueDate.add(const Duration(days: 30)),
        );
        if (isLate) {
          loanUpdate['missedPayments'] = FieldValue.increment(1);
        }
      }

      await _firestore.collection('loans').doc(loanId).update(loanUpdate);

      // Deduct EMC from user
      await _firestore.collection('users').doc(studentId).update({
        'availableEMC': FieldValue.increment(-totalPayment),
        'emcBalance': FieldValue.increment(-totalPayment),
      });

      // If loan completed, decrement active loan count
      if (isFullyPaid) {
        await _firestore.collection('users').doc(studentId).update({
          'activeLoanCount': FieldValue.increment(-1),
        });

        await _notificationService.createNotification(
          userId: studentId,
          title: 'Loan Completed! 🎉',
          message: 'Congratulations! You\'ve fully repaid your loan.',
          type: 'loan',
          actionUrl: '/loans/$loanId',
        );
      } else {
        await _notificationService.createNotification(
          userId: studentId,
          title: 'Payment Received',
          message: 'Payment of ${amount.toStringAsFixed(0)} EMC received. Balance: ${newBalance.toStringAsFixed(0)} EMC',
          type: 'payment',
          actionUrl: '/loans/$loanId',
        );
      }

      return paymentDocRef.id;
    } catch (e) {
      throw Exception('Failed to make loan payment: $e');
    }
  }

  /// Get student's loans
  Stream<List<LoanModel>> getStudentLoans(String studentId, {LoanStatus? status}) {
    var query = _firestore
        .collection('loans')
        .where('studentId', isEqualTo: studentId);

    if (status != null) {
      query = query.where('status', isEqualTo: status.toString());
    }

    return query
        .orderBy('appliedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LoanModel.fromFirestore(doc))
            .toList());
  }

  /// Get loan payments
  Stream<List<LoanPaymentModel>> getLoanPayments(String loanId) {
    return _firestore
        .collection('loan_payments')
        .where('loanId', isEqualTo: loanId)
        .orderBy('paidAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LoanPaymentModel.fromFirestore(doc))
            .toList());
  }

  /// Get all loans (Admin view)
  Stream<List<LoanModel>> getAllLoans({LoanStatus? status}) {
    Query<Map<String, dynamic>> query = _firestore.collection('loans');

    if (status != null) {
      query = query.where('status', isEqualTo: status.toString());
    }

    return query
        .orderBy('appliedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LoanModel.fromFirestore(doc))
            .toList());
  }

  /// Get loan statistics (Admin)
  Future<Map<String, dynamic>> getLoanStats() async {
    final allLoansSnapshot = await _firestore.collection('loans').get();

    double totalDisbursed = 0;
    double totalOutstanding = 0;
    double totalRepaid = 0;
    int activeLoans = 0;
    int completedLoans = 0;
    int defaultedLoans = 0;

    for (var doc in allLoansSnapshot.docs) {
      final loan = LoanModel.fromFirestore(doc);

      if (loan.status == LoanStatus.active || loan.status == LoanStatus.completed) {
        totalDisbursed += loan.approvedAmount;
      }

      if (loan.status == LoanStatus.active) {
        activeLoans++;
        totalOutstanding += loan.outstandingBalance;
        totalRepaid += loan.amountPaid;
      } else if (loan.status == LoanStatus.completed) {
        completedLoans++;
        totalRepaid += loan.amountPaid;
      } else if (loan.status == LoanStatus.defaulted) {
        defaultedLoans++;
        totalOutstanding += loan.outstandingBalance;
      }
    }

    return {
      'totalDisbursed': totalDisbursed,
      'totalOutstanding': totalOutstanding,
      'totalRepaid': totalRepaid,
      'activeLoans': activeLoans,
      'completedLoans': completedLoans,
      'defaultedLoans': defaultedLoans,
      'totalLoans': allLoansSnapshot.docs.length,
    };
  }

  /// Check for overdue loans and mark as defaulted (run periodically)
  Future<void> processOverdueLoans() async {
    final overdueSnapshot = await _firestore
        .collection('loans')
        .where('status', isEqualTo: LoanStatus.active.toString())
        .get();

    final now = DateTime.now();

    for (var doc in overdueSnapshot.docs) {
      final loan = LoanModel.fromFirestore(doc);

      // If missed 3+ payments, mark as defaulted
      if (loan.missedPayments >= 3) {
        await _firestore.collection('loans').doc(doc.id).update({
          'status': LoanStatus.defaulted.toString(),
        });

        await _notificationService.createNotification(
          userId: loan.studentId,
          title: 'Loan Defaulted',
          message: 'Your loan has been marked as defaulted due to missed payments',
          type: 'loan',
          actionUrl: '/loans/${doc.id}',
        );
      }
      // If payment overdue, send reminder
      else if (loan.nextPaymentDue != null && now.isAfter(loan.nextPaymentDue!)) {
        await _notificationService.createNotification(
          userId: loan.studentId,
          title: 'Payment Overdue',
          message: 'Your loan payment of ${loan.monthlyPayment.toStringAsFixed(0)} EMC is overdue',
          type: 'loan',
          actionUrl: '/loans/${doc.id}',
        );
      }
    }
  }
}
