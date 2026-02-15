class TransactionModel {
  final String id;
  final String userId;
  final String type; // 'earn' or 'spend'
  final int amount;
  final String description;
  final String? relatedId; // book ID, course ID, etc.
  final DateTime createdAt;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.description,
    this.relatedId,
    required this.createdAt,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map, String id) {
    return TransactionModel(
      id: id,
      userId: map['userId'] ?? '',
      type: map['type'] ?? 'earn',
      amount: map['amount'] ?? 0,
      description: map['description'] ?? '',
      relatedId: map['relatedId'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type,
      'amount': amount,
      'description': description,
      'relatedId': relatedId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  bool get isEarned => type == 'earn';
}
