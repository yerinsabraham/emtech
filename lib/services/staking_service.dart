import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/staking_model.dart';
import 'notification_service.dart';
import 'achievement_service.dart';

class StakingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  /// Stake EMC tokens
  Future<String> stakeEMC({
    required String userId,
    required String userName,
    required double amount,
  }) async {
    try {
      // Validate user has enough EMC
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      final availableEMC = (userData?['availableEMC'] ?? userData?['emcBalance'] ?? 0).toDouble();

      if (availableEMC < amount) {
        throw Exception('Insufficient EMC balance. Available: $availableEMC EMC');
      }

      if (amount < 1000) {
        throw Exception('Minimum staking amount is 1,000 EMC');
      }

      // Calculate tier
      final tier = StakingModel.calculateTier(amount);

      // Create staking record
      final staking = StakingModel(
        id: '',
        userId: userId,
        userName: userName,
        stakedAmount: amount,
        stakedAt: DateTime.now(),
        tier: tier,
        isActive: true,
        votingPower: StakingModel.calculateVotingPower(amount, 0),
      );

      final docRef = await _firestore.collection('stakes').add(staking.toFirestore());

      // Update user's staked & available EMC
      await _firestore.collection('users').doc(userId).update({
        'stakedEMC': FieldValue.increment(amount),
        'availableEMC': FieldValue.increment(-amount),
        'emcBalance': FieldValue.increment(-amount),
      });

      // Notify user
      await _notificationService.createNotification(
        userId: userId,
        title: 'EMC Staked Successfully',
        message: 'You staked ${amount.toStringAsFixed(0)} EMC and earned ${staking.tierBadge} status!',
        type: 'staking',
        actionUrl: '/wallet/staking/${docRef.id}',
      );

      // Trigger achievement check for first stake
      unawaited(AchievementService().onStake(userId));

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to stake EMC: $e');
    }
  }
  Future<void> unstakeEMC({
    required String stakingId,
    required String userId,
  }) async {
    try {
      final stakingDoc = await _firestore.collection('stakes').doc(stakingId).get();
      if (!stakingDoc.exists) {
        throw Exception('Staking record not found');
      }

      final staking = StakingModel.fromFirestore(stakingDoc);
      
      if (staking.userId != userId) {
        throw Exception('Unauthorized');
      }

      if (!staking.isActive) {
        throw Exception('Staking already unstaked');
      }

      // Calculate current rewards
      final durationDays = DateTime.now().difference(staking.stakedAt).inDays;
      final rewards = StakingModel.calculateRewards(
        staking.stakedAmount,
        staking.tier,
        durationDays,
      );

      // Update staking record
      await _firestore.collection('stakes').doc(stakingId).update({
        'isActive': false,
        'unstakedAt': Timestamp.fromDate(DateTime.now()),
        'stakingDurationDays': durationDays,
        'rewardsEarned': rewards,
      });

      // Return staked amount + rewards to user
      final totalReturn = staking.stakedAmount + rewards;
      
      await _firestore.collection('users').doc(userId).update({
        'stakedEMC': FieldValue.increment(-staking.stakedAmount),
        'availableEMC': FieldValue.increment(totalReturn),
        'emcBalance': FieldValue.increment(totalReturn),
        'totalEMCEarned': FieldValue.increment(rewards),
      });

      // Notify user
      await _notificationService.createNotification(
        userId: userId,
        title: 'EMC Unstaked',
        message: 'Unstaked ${staking.stakedAmount.toStringAsFixed(0)} EMC + ${rewards.toStringAsFixed(0)} EMC rewards!',
        type: 'staking',
        actionUrl: '/wallet',
      );
    } catch (e) {
      throw Exception('Failed to unstake EMC: $e');
    }
  }

  /// Get user's active stakes
  Stream<List<StakingModel>> getUserStakes(String userId, {bool activeOnly = false}) {
    var query = _firestore
        .collection('stakes')
        .where('userId', isEqualTo: userId);

    if (activeOnly) {
      query = query.where('isActive', isEqualTo: true);
    }

    return query
        .orderBy('stakedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StakingModel.fromFirestore(doc))
            .toList());
  }

  /// Get total staked EMC for user
  Future<double> getTotalStaked(String userId) async {
    final snapshot = await _firestore
        .collection('stakes')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .get();

    return snapshot.docs
        .map((doc) => (doc.data()['stakedAmount'] ?? 0).toDouble())
        .fold<double>(0.0, (sum, amount) => sum + amount);
  }

  /// Get user's highest staking tier
  Future<StakingTier> getUserStakingTier(String userId) async {
    final totalStaked = await getTotalStaked(userId);
    return StakingModel.calculateTier(totalStaked);
  }

  /// Get staking duration for loan qualification
  Future<int> getLongestStakingDuration(String userId) async {
    final snapshot = await _firestore
        .collection('stakes')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('stakedAt', descending: false)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return 0;

    final oldestStake = StakingModel.fromFirestore(snapshot.docs.first);
    return DateTime.now().difference(oldestStake.stakedAt).inDays;
  }

  /// Calculate current rewards for active stakes
  Future<double> calculateCurrentRewards(String userId) async {
    final snapshot = await _firestore
        .collection('stakes')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .get();

    double totalRewards = 0;

    for (var doc in snapshot.docs) {
      final stake = StakingModel.fromFirestore(doc);
      final durationDays = DateTime.now().difference(stake.stakedAt).inDays;
      final rewards = StakingModel.calculateRewards(
        stake.stakedAmount,
        stake.tier,
        durationDays,
      );
      totalRewards += rewards;
    }

    return totalRewards;
  }

  /// Calculate total voting power
  Future<double> calculateVotingPower(String userId) async {
    final snapshot = await _firestore
        .collection('stakes')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .get();

    double totalPower = 0;

    for (var doc in snapshot.docs) {
      final stake = StakingModel.fromFirestore(doc);
      final durationDays = DateTime.now().difference(stake.stakedAt).inDays;
      final power = StakingModel.calculateVotingPower(
        stake.stakedAmount,
        durationDays,
      );
      totalPower += power;
    }

    return totalPower;
  }

  /// Get all stakes (admin view)
  Stream<List<StakingModel>> getAllStakes({bool activeOnly = false}) {
    Query<Map<String, dynamic>> query = _firestore.collection('stakes');

    if (activeOnly) {
      query = query.where('isActive', isEqualTo: true);
    }

    return query
        .orderBy('stakedAmount', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StakingModel.fromFirestore(doc))
            .toList());
  }

  /// Get staking statistics
  Future<Map<String, dynamic>> getStakingStats() async {
    final allStakesSnapshot = await _firestore
        .collection('stakes')
        .where('isActive', isEqualTo: true)
        .get();

    double totalStaked = 0;
    int totalStakers = 0;
    Map<String, int> tierDistribution = {
      'platinum': 0,
      'gold': 0,
      'silver': 0,
      'bronze': 0,
    };

    final uniqueStakers = <String>{};

    for (var doc in allStakesSnapshot.docs) {
      final stake = StakingModel.fromFirestore(doc);
      totalStaked += stake.stakedAmount;
      uniqueStakers.add(stake.userId);

      switch (stake.tier) {
        case StakingTier.platinum:
          tierDistribution['platinum'] = (tierDistribution['platinum'] ?? 0) + 1;
          break;
        case StakingTier.gold:
          tierDistribution['gold'] = (tierDistribution['gold'] ?? 0) + 1;
          break;
        case StakingTier.silver:
          tierDistribution['silver'] = (tierDistribution['silver'] ?? 0) + 1;
          break;
        case StakingTier.bronze:
          tierDistribution['bronze'] = (tierDistribution['bronze'] ?? 0) + 1;
          break;
        default:
          break;
      }
    }

    totalStakers = uniqueStakers.length;

    return {
      'totalStaked': totalStaked,
      'totalStakers': totalStakers,
      'tierDistribution': tierDistribution,
      'averageStake': totalStakers > 0 ? totalStaked / totalStakers : 0,
    };
  }
}
