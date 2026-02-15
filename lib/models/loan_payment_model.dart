import 'package:cloud_firestore/cloud_firestore.dart';

/// Loan payment record
class LoanPaymentModel {
  final String id;
  final String loanId;
  final String studentId;
  final double amount; // EMC paid
  final DateTime paidAt;
  final DateTime dueDate; // When payment was due
  final bool isLate; // Paid after due date
  final int dayslate;
  final double penaltyAmount; // Late fee
  final double interestPortion; // Portion that paid interest
  final double principalPortion; // Portion that paid principal
  final double balanceAfterPayment; // Remaining loan balance
  final String? transactionId; // Reference to wallet transaction
  final String paymentMethod; // 'emc_wallet', 'card', etc.
  final Map<String, dynamic> metadata;

  LoanPaymentModel({
    required this.id,
    required this.loanId,
    required this.studentId,
    required this.amount,
    required this.paidAt,
    required this.dueDate,
    this.isLate = false,
    this.dayslate = 0,
    this.penaltyAmount = 0,
    this.interestPortion = 0,
    this.principalPortion = 0,
    required this.balanceAfterPayment,
    this.transactionId,
    this.paymentMethod = 'emc_wallet',
    this.metadata = const {},
  });

  /// Calculate late penalty (5% of payment amount per week late)
  static double calculateLatePenalty(double paymentAmount, int daysLate) {
    if (daysLate <= 0) return 0;
    
    final weeksLate = (daysLate / 7).ceil();
    return paymentAmount * 0.05 * weeksLate;
  }

  /// Get payment status badge
  String get statusBadge {
    if (isLate) {
      return '⚠️ Late Payment';
    }
    return '✓ On Time';
  }

  factory LoanPaymentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LoanPaymentModel(
      id: doc.id,
      loanId: data['loanId'] ?? '',
      studentId: data['studentId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      paidAt: (data['paidAt'] as Timestamp).toDate(),
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      isLate: data['isLate'] ?? false,
      dayslate: data['daysLate'] ?? 0,
      penaltyAmount: (data['penaltyAmount'] ?? 0).toDouble(),
      interestPortion: (data['interestPortion'] ?? 0).toDouble(),
      principalPortion: (data['principalPortion'] ?? 0).toDouble(),
      balanceAfterPayment: (data['balanceAfterPayment'] ?? 0).toDouble(),
      transactionId: data['transactionId'],
      paymentMethod: data['paymentMethod'] ?? 'emc_wallet',
      metadata: data['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'loanId': loanId,
      'studentId': studentId,
      'amount': amount,
      'paidAt': Timestamp.fromDate(paidAt),
      'dueDate': Timestamp.fromDate(dueDate),
      'isLate': isLate,
      'daysLate': dayslate,
      'penaltyAmount': penaltyAmount,
      'interestPortion': interestPortion,
      'principalPortion': principalPortion,
      'balanceAfterPayment': balanceAfterPayment,
      'transactionId': transactionId,
      'paymentMethod': paymentMethod,
      'metadata': metadata,
    };
  }
}
