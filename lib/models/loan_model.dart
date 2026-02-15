import 'package:cloud_firestore/cloud_firestore.dart';
import 'staking_model.dart';
import 'grade_model.dart';

/// Loan status
enum LoanStatus {
  pending,      // Application submitted
  underReview,  // Being reviewed by admin
  approved,     // Approved by admin
  rejected,     // Rejected
  disbursed,    // Funds disbursed to student
  active,       // Loan is active (being repaid)
  completed,    // Fully repaid
  defaulted,    // Missed too many payments
}

/// Loan application & tracking model
class LoanModel {
  final String id;
  final String studentId;
  final String studentName;
  final double requestedAmount; // EMC requested
  final double approvedAmount; // Actual amount approved (may be less)
  final double interestRate; // Annual interest rate (e.g., 0.05 = 5%)
  final int termMonths; // Loan term in months
  final String purpose; // Purpose of loan
  final DateTime appliedAt;
  final DateTime? approvedAt;
  final DateTime? disbursedAt;
  final LoanStatus status;
  
  // Qualification criteria
  final double currentGPA; // Student's GPA
  final LetterGrade? highestGrade; // Best grade achieved
  final int stakingDurationDays; // Days staked
  final double stakedAmount; // EMC currently staked
  final StakingTier stakingTier;
  final bool kycVerified; // KYC verification status
  final String? referenceLecturerId; // Lecturer reference
  final String? referenceLecturerName;
  
  // Repayment tracking
  final double totalAmountDue; // Principal + interest
  final double amountPaid;
  final double outstandingBalance;
  final int totalPayments; // Number of payments
  final int completedPayments;
  final DateTime? nextPaymentDue;
  final double monthlyPayment;
  final int missedPayments;
  final double penaltyAmount; // Late penalties
  
  // Admin notes
  final String? adminNotes;
  final String? rejectionReason;
  final String? approvedBy;

  LoanModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.requestedAmount,
    this.approvedAmount = 0,
    this.interestRate = 0.08, // Default 8% APR
    required this.termMonths,
    required this.purpose,
    required this.appliedAt,
    this.approvedAt,
    this.disbursedAt,
    this.status = LoanStatus.pending,
    this.currentGPA = 0.0,
    this.highestGrade,
    this.stakingDurationDays = 0,
    this.stakedAmount = 0,
    this.stakingTier = StakingTier.none,
    this.kycVerified = false,
    this.referenceLecturerId,
    this.referenceLecturerName,
    this.totalAmountDue = 0,
    this.amountPaid = 0,
    this.outstandingBalance = 0,
    this.totalPayments = 0,
    this.completedPayments = 0,
    this.nextPaymentDue,
    this.monthlyPayment = 0,
    this.missedPayments = 0,
    this.penaltyAmount = 0,
    this.adminNotes,
    this.rejectionReason,
    this.approvedBy,
  });

  /// Check if student qualifies for loan
  static bool checkQualification({
    required double gpa,
    required LetterGrade? highestGrade,
    required int stakingDays,
    required bool kycVerified,
    required bool hasReference,
  }) {
    // Minimum requirements:
    // 1. GPA >= 2.0 (C average) OR highest grade >= B
    // 2. Staked for at least 30 days OR has lecturer reference
    // 3. KYC verified
    
    final hasGoodGrades = gpa >= 2.0 || 
        (highestGrade != null && 
         (highestGrade == LetterGrade.A || highestGrade == LetterGrade.B));
    
    final hasStakingOrReference = stakingDays >= 30 || hasReference;
    
    return hasGoodGrades && hasStakingOrReference && kycVerified;
  }

  /// Calculate max loan amount based on qualification
  static double calculateMaxLoanAmount({
    required double gpa,
    required StakingTier tier,
    required int stakingDays,
  }) {
    double baseAmount = 5000.0; // Base EMC loan amount

    // GPA multipliers
    if (gpa >= 3.5) {
      baseAmount *= 2.0; // 10,000 EMC
    } else if (gpa >= 3.0) {
      baseAmount *= 1.5; // 7,500 EMC
    } else if (gpa >= 2.5) {
      baseAmount *= 1.2; // 6,000 EMC
    }

    // Staking tier bonuses
    switch (tier) {
      case StakingTier.platinum:
        baseAmount *= 1.5;
        break;
      case StakingTier.gold:
        baseAmount *= 1.3;
        break;
      case StakingTier.silver:
        baseAmount *= 1.2;
        break;
      case StakingTier.bronze:
        baseAmount *= 1.1;
        break;
      default:
        break;
    }

    // Long-term staking bonus (>180 days: +20%)
    if (stakingDays >= 180) {
      baseAmount *= 1.2;
    }

    return baseAmount;
  }

  /// Calculate monthly payment
  static double calculateMonthlyPayment(
    double principal,
    double annualRate,
    int termMonths,
  ) {
    if (termMonths == 0) return 0;
    
    final monthlyRate = annualRate / 12;
    if (monthlyRate == 0) return principal / termMonths;

    // Standard loan payment formula
    final numerator = principal * monthlyRate * Math.pow(1 + monthlyRate, termMonths);
    final denominator = Math.pow(1 + monthlyRate, termMonths) - 1;
    return numerator / denominator;
  }

  /// Get progress percentage
  double get progressPercentage {
    if (totalAmountDue == 0) return 0;
    return (amountPaid / totalAmountDue) * 100;
  }

  /// Check if loan is in good standing
  bool get isInGoodStanding {
    return status == LoanStatus.active && missedPayments < 2;
  }

  /// Get status color
  String get statusColor {
    switch (status) {
      case LoanStatus.approved:
      case LoanStatus.disbursed:
      case LoanStatus.completed:
        return 'green';
      case LoanStatus.active:
        return missedPayments > 0 ? 'orange' : 'blue';
      case LoanStatus.rejected:
      case LoanStatus.defaulted:
        return 'red';
      default:
        return 'grey';
    }
  }

  /// Get status display text
  String get statusDisplay {
    switch (status) {
      case LoanStatus.pending:
        return 'Pending Review';
      case LoanStatus.underReview:
        return 'Under Review';
      case LoanStatus.approved:
        return 'Approved - Awaiting Disbursement';
      case LoanStatus.rejected:
        return 'Rejected';
      case LoanStatus.disbursed:
        return 'Funds Disbursed';
      case LoanStatus.active:
        return isInGoodStanding ? 'Active - Good Standing' : 'Active - Late Payment';
      case LoanStatus.completed:
        return 'Completed';
      case LoanStatus.defaulted:
        return 'Defaulted';
    }
  }

  factory LoanModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LoanModel(
      id: doc.id,
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      requestedAmount: (data['requestedAmount'] ?? 0).toDouble(),
      approvedAmount: (data['approvedAmount'] ?? 0).toDouble(),
      interestRate: (data['interestRate'] ?? 0.08).toDouble(),
      termMonths: data['termMonths'] ?? 12,
      purpose: data['purpose'] ?? '',
      appliedAt: (data['appliedAt'] as Timestamp).toDate(),
      approvedAt: data['approvedAt'] != null
          ? (data['approvedAt'] as Timestamp).toDate()
          : null,
      disbursedAt: data['disbursedAt'] != null
          ? (data['disbursedAt'] as Timestamp).toDate()
          : null,
      status: LoanStatus.values.firstWhere(
        (s) => s.toString() == data['status'],
        orElse: () => LoanStatus.pending,
      ),
      currentGPA: (data['currentGPA'] ?? 0).toDouble(),
      highestGrade: data['highestGrade'] != null
          ? LetterGrade.values.firstWhere(
              (g) => g.toString() == data['highestGrade'],
              orElse: () => LetterGrade.F,
            )
          : null,
      stakingDurationDays: data['stakingDurationDays'] ?? 0,
      stakedAmount: (data['stakedAmount'] ?? 0).toDouble(),
      stakingTier: StakingTier.values.firstWhere(
        (t) => t.toString() == data['stakingTier'],
        orElse: () => StakingTier.none,
      ),
      kycVerified: data['kycVerified'] ?? false,
      referenceLecturerId: data['referenceLecturerId'],
      referenceLecturerName: data['referenceLecturerName'],
      totalAmountDue: (data['totalAmountDue'] ?? 0).toDouble(),
      amountPaid: (data['amountPaid'] ?? 0).toDouble(),
      outstandingBalance: (data['outstandingBalance'] ?? 0).toDouble(),
      totalPayments: data['totalPayments'] ?? 0,
      completedPayments: data['completedPayments'] ?? 0,
      nextPaymentDue: data['nextPaymentDue'] != null
          ? (data['nextPaymentDue'] as Timestamp).toDate()
          : null,
      monthlyPayment: (data['monthlyPayment'] ?? 0).toDouble(),
      missedPayments: data['missedPayments'] ?? 0,
      penaltyAmount: (data['penaltyAmount'] ?? 0).toDouble(),
      adminNotes: data['adminNotes'],
      rejectionReason: data['rejectionReason'],
      approvedBy: data['approvedBy'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'requestedAmount': requestedAmount,
      'approvedAmount': approvedAmount,
      'interestRate': interestRate,
      'termMonths': termMonths,
      'purpose': purpose,
      'appliedAt': Timestamp.fromDate(appliedAt),
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'disbursedAt': disbursedAt != null ? Timestamp.fromDate(disbursedAt!) : null,
      'status': status.toString(),
      'currentGPA': currentGPA,
      'highestGrade': highestGrade?.toString(),
      'stakingDurationDays': stakingDurationDays,
      'stakedAmount': stakedAmount,
      'stakingTier': stakingTier.toString(),
      'kycVerified': kycVerified,
      'referenceLecturerId': referenceLecturerId,
      'referenceLecturerName': referenceLecturerName,
      'totalAmountDue': totalAmountDue,
      'amountPaid': amountPaid,
      'outstandingBalance': outstandingBalance,
      'totalPayments': totalPayments,
      'completedPayments': completedPayments,
      'nextPaymentDue': nextPaymentDue != null ? Timestamp.fromDate(nextPaymentDue!) : null,
      'monthlyPayment': monthlyPayment,
      'missedPayments': missedPayments,
      'penaltyAmount': penaltyAmount,
      'adminNotes': adminNotes,
      'rejectionReason': rejectionReason,
      'approvedBy': approvedBy,
    };
  }
}

// Helper for Math.pow
class Math {
  static double pow(double base, int exp) {
    double result = 1.0;
    for (int i = 0; i < exp; i++) {
      result *= base;
    }
    return result;
  }
}
