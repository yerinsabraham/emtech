import 'package:cloud_firestore/cloud_firestore.dart';

/// Staking levels based on locked EMC amount
enum StakingTier {
  none,      // 0 EMC
  bronze,    // 1,000 - 4,999 EMC
  silver,    // 5,000 - 19,999 EMC
  gold,      // 20,000 - 49,999 EMC
  platinum,  // 50,000+ EMC
}

/// Represents a staking position (EMC locked for rewards & voting power)
class StakingModel {
  final String id;
  final String userId;
  final String userName;
  final double stakedAmount; // EMC staked
  final DateTime stakedAt;
  final DateTime? unstakedAt; // null if still active
  final bool isActive;
  final StakingTier tier;
  final int stakingDurationDays; // Auto-calculated
  final double votingPower; // Based on amount & duration
  final double rewardsEarned; // APY rewards earned
  final Map<String, dynamic> metadata;

  StakingModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.stakedAmount,
    required this.stakedAt,
    this.unstakedAt,
    this.isActive = true,
    required this.tier,
    this.stakingDurationDays = 0,
    this.votingPower = 0.0,
    this.rewardsEarned = 0.0,
    this.metadata = const {},
  });

  /// Calculate staking tier based on amount
  static StakingTier calculateTier(double amount) {
    if (amount >= 50000) return StakingTier.platinum;
    if (amount >= 20000) return StakingTier.gold;
    if (amount >= 5000) return StakingTier.silver;
    if (amount >= 1000) return StakingTier.bronze;
    return StakingTier.none;
  }

  /// Get staking duration in days
  int get durationDays {
    final endDate = unstakedAt ?? DateTime.now();
    return endDate.difference(stakedAt).inDays;
  }

  /// Calculate voting power (amount * duration multiplier)
  static double calculateVotingPower(double amount, int durationDays) {
    // Base voting power = staked amount
    double power = amount;

    // Duration bonuses:
    // 30+ days: 1.2x
    // 90+ days: 1.5x
    // 180+ days: 2.0x
    // 365+ days: 3.0x
    if (durationDays >= 365) {
      power *= 3.0;
    } else if (durationDays >= 180) {
      power *= 2.0;
    } else if (durationDays >= 90) {
      power *= 1.5;
    } else if (durationDays >= 30) {
      power *= 1.2;
    }

    return power;
  }

  /// Calculate APY rewards (simple interest)
  /// APY rates: Bronze 5%, Silver 10%, Gold 15%, Platinum 20%
  static double calculateRewards(double amount, StakingTier tier, int durationDays) {
    double apyRate = 0.0;
    switch (tier) {
      case StakingTier.bronze:
        apyRate = 0.05; // 5%
        break;
      case StakingTier.silver:
        apyRate = 0.10; // 10%
        break;
      case StakingTier.gold:
        apyRate = 0.15; // 15%
        break;
      case StakingTier.platinum:
        apyRate = 0.20; // 20%
        break;
      default:
        apyRate = 0.0;
    }

    // Calculate rewards: (amount * apyRate * days) / 365
    return (amount * apyRate * durationDays) / 365;
  }

  /// Get tier badge name
  String get tierBadge {
    switch (tier) {
      case StakingTier.platinum:
        return '💎 Platinum Staker';
      case StakingTier.gold:
        return '🥇 Gold Staker';
      case StakingTier.silver:
        return '🥈 Silver Staker';
      case StakingTier.bronze:
        return '🥉 Bronze Staker';
      default:
        return '';
    }
  }

  /// Get APY percentage for tier
  String get apyPercentage {
    switch (tier) {
      case StakingTier.platinum:
        return '20%';
      case StakingTier.gold:
        return '15%';
      case StakingTier.silver:
        return '10%';
      case StakingTier.bronze:
        return '5%';
      default:
        return '0%';
    }
  }

  factory StakingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StakingModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      stakedAmount: (data['stakedAmount'] ?? 0).toDouble(),
      stakedAt: (data['stakedAt'] as Timestamp).toDate(),
      unstakedAt: data['unstakedAt'] != null
          ? (data['unstakedAt'] as Timestamp).toDate()
          : null,
      isActive: data['isActive'] ?? true,
      tier: StakingTier.values.firstWhere(
        (t) => t.toString() == data['tier'],
        orElse: () => StakingTier.none,
      ),
      stakingDurationDays: data['stakingDurationDays'] ?? 0,
      votingPower: (data['votingPower'] ?? 0).toDouble(),
      rewardsEarned: (data['rewardsEarned'] ?? 0).toDouble(),
      metadata: data['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'stakedAmount': stakedAmount,
      'stakedAt': Timestamp.fromDate(stakedAt),
      'unstakedAt': unstakedAt != null ? Timestamp.fromDate(unstakedAt!) : null,
      'isActive': isActive,
      'tier': tier.toString(),
      'stakingDurationDays': stakingDurationDays,
      'votingPower': votingPower,
      'rewardsEarned': rewardsEarned,
      'metadata': metadata,
    };
  }

  StakingModel copyWith({
    String? id,
    String? userId,
    String? userName,
    double? stakedAmount,
    DateTime? stakedAt,
    DateTime? unstakedAt,
    bool? isActive,
    StakingTier? tier,
    int? stakingDurationDays,
    double? votingPower,
    double? rewardsEarned,
    Map<String, dynamic>? metadata,
  }) {
    return StakingModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      stakedAmount: stakedAmount ?? this.stakedAmount,
      stakedAt: stakedAt ?? this.stakedAt,
      unstakedAt: unstakedAt ?? this.unstakedAt,
      isActive: isActive ?? this.isActive,
      tier: tier ?? this.tier,
      stakingDurationDays: stakingDurationDays ?? this.stakingDurationDays,
      votingPower: votingPower ?? this.votingPower,
      rewardsEarned: rewardsEarned ?? this.rewardsEarned,
      metadata: metadata ?? this.metadata,
    );
  }
}
