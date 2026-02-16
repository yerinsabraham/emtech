class DailyTaskModel {
  final String id;
  final String title;
  final String description;
  final int rewardEmc;
  final String category; // 'learning', 'social', 'achievement'
  final bool isCompleted;
  final DateTime expiresAt;
  final String iconName; // Icon representation

  DailyTaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.rewardEmc,
    required this.category,
    this.isCompleted = false,
    required this.expiresAt,
    this.iconName = 'task_alt',
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'rewardEmc': rewardEmc,
      'category': category,
      'isCompleted': isCompleted,
      'expiresAt': expiresAt.toIso8601String(),
      'iconName': iconName,
    };
  }

  factory DailyTaskModel.fromMap(Map<String, dynamic> map, String id) {
    return DailyTaskModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      rewardEmc: map['rewardEmc'] ?? 0,
      category: map['category'] ?? 'learning',
      isCompleted: map['isCompleted'] ?? false,
      expiresAt: DateTime.parse(map['expiresAt']),
      iconName: map['iconName'] ?? 'task_alt',
    );
  }

  DailyTaskModel copyWith({
    String? id,
    String? title,
    String? description,
    int? rewardEmc,
    String? category,
    bool? isCompleted,
    DateTime? expiresAt,
    String? iconName,
  }) {
    return DailyTaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      rewardEmc: rewardEmc ?? this.rewardEmc,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      expiresAt: expiresAt ?? this.expiresAt,
      iconName: iconName ?? this.iconName,
    );
  }
}
