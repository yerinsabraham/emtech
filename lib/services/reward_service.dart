import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';

/// Handles EMC reward allocation for various actions
class RewardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // EMC Total Supply: 900,000,000 EMC
  static const double totalSupply = 900000000.0;

  /// Allocate sign-up reward (upon course enrollment)
  Future<void> allocateEnrollmentReward({
    required String userId,
    required String courseId,
    required bool isPaidCourse,
  }) async {
    try {
      // Freemium: 1000 EMC, Paid: 2000 EMC
      final rewardAmount = isPaidCourse ? 2000.0 : 1000.0;

      // Add to unredeemed EMC (redeemable after course completion)
      await _firestore.collection('users').doc(userId).update({
        'unredeemedEMC': FieldValue.increment(rewardAmount),
      });

      // Create reward record
      await _firestore.collection('rewards').add({
        'userId': userId,
        'courseId': courseId,
        'type': 'enrollment',
        'amount': rewardAmount,
        'redeemed': false,
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'courseType': isPaidCourse ? 'paid' : 'freemium',
      });

      // Notify user
      await _notificationService.createNotification(
        userId: userId,
        title: 'EMC Reward Pending',
        message: 'You\'ll receive ${rewardAmount.toStringAsFixed(0)} EMC upon course completion!',
        type: 'reward',
        actionUrl: '/wallet',
      );
    } catch (e) {
      throw Exception('Failed to allocate enrollment reward: $e');
    }
  }

  /// Redeem enrollment rewards upon course completion
  Future<void> redeemCourseCompletionRewards({
    required String userId,
    required String courseId,
  }) async {
    try {
      // Get unredeemed rewards for this course
      final rewardsSnapshot = await _firestore
          .collection('rewards')
          .where('userId', isEqualTo: userId)
          .where('courseId', isEqualTo: courseId)
          .where('type', isEqualTo: 'enrollment')
          .where('redeemed', isEqualTo: false)
          .get();

      if (rewardsSnapshot.docs.isEmpty) {
        return; // No rewards to redeem
      }

      double totalReward = 0;

      // Mark all rewards as redeemed and calculate total
      final batch = _firestore.batch();
      for (var doc in rewardsSnapshot.docs) {
        final reward = doc.data();
        totalReward += (reward['amount'] ?? 0).toDouble();
        
        batch.update(doc.reference, {
          'redeemed': true,
          'redeemedAt': Timestamp.fromDate(DateTime.now()),
        });
      }

      await batch.commit();

      // Transfer from unredeemed to available EMC
      await _firestore.collection('users').doc(userId).update({
        'unredeemedEMC': FieldValue.increment(-totalReward),
        'availableEMC': FieldValue.increment(totalReward),
        'emcBalance': FieldValue.increment(totalReward),
        'totalEMCEarned': FieldValue.increment(totalReward),
      });

      // Notify user
      await _notificationService.createNotification(
        userId: userId,
        title: 'EMC Rewards Unlocked! 🎉',
        message: 'You earned ${totalReward.toStringAsFixed(0)} EMC for completing the course!',
        type: 'reward',
        actionUrl: '/wallet',
      );
    } catch (e) {
      throw Exception('Failed to redeem course completion rewards: $e');
    }
  }

  /// Get total unredeemed rewards for user
  Future<double> getTotalUnredeemedRewards(String userId) async {
    final snapshot = await _firestore
        .collection('rewards')
        .where('userId', isEqualTo: userId)
        .where('redeemed', isEqualTo: false)
        .get();

    return snapshot.docs
        .map((doc) => (doc.data()['amount'] ?? 0).toDouble())
        .fold<double>(0.0, (sum, amount) => sum + amount);
  }

  /// Get reward history
  Stream<List<Map<String, dynamic>>> getRewardHistory(String userId) {
    return _firestore
        .collection('rewards')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {...doc.data(), 'id': doc.id})
            .toList());
  }

  /// Calculate tuition discount when paying with EMC
  /// (Post-listing: 10% discount when using EMC)
  double calculateEMCPaymentDiscount(double tuitionPrice) {
    return tuitionPrice * 0.10; // 10% discount
  }

  /// Process EMC payment for course tuition
  Future<void> payTuitionWithEMC({
    required String userId,
    required String courseId,
    required double tuitionPrice,
    required double emcPaymentAmount,
  }) async {
    try {
      // Check user has enough EMC
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final availableEMC = (userDoc.data()?['availableEMC'] ?? 0).toDouble();

      if (availableEMC < emcPaymentAmount) {
        throw Exception('Insufficient EMC balance');
      }

      // Calculate discount
      final discount = calculateEMCPaymentDiscount(tuitionPrice);
      final finalPrice = tuitionPrice - discount;

      // Deduct EMC
      await _firestore.collection('users').doc(userId).update({
        'availableEMC': FieldValue.increment(-emcPaymentAmount),
        'emcBalance': FieldValue.increment(-emcPaymentAmount),
      });

      // Create payment record
      await _firestore.collection('payments').add({
        'userId': userId,
        'courseId': courseId,
        'amount': finalPrice,
        'emcUsed': emcPaymentAmount,
        'discount': discount,
        'paymentMethod': 'emc',
        'status': 'completed',
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });

      // Notify user
      await _notificationService.createNotification(
        userId: userId,
        title: 'Payment Successful',
        message: 'Course purchased with EMC. You saved ${discount.toStringAsFixed(0)} EMC!',
        type: 'payment',
        actionUrl: '/courses/$courseId',
      );
    } catch (e) {
      throw Exception('Failed to process EMC payment: $e');
    }
  }

  /// Get reward statistics (Admin)
  Future<Map<String, dynamic>> getRewardStats() async {
    final rewardsSnapshot = await _firestore.collection('rewards').get();

    double totalAllocated = 0;
    double totalRedeemed = 0;
    int enrollmentRewards = 0;
    int gradingRewards = 0;

    for (var doc in rewardsSnapshot.docs) {
      final reward = doc.data();
      final amount = (reward['amount'] ?? 0).toDouble();
      final redeemed = reward['redeemed'] ?? false;
      final type = reward['type'] ?? '';

      totalAllocated += amount;
      if (redeemed) {
        totalRedeemed += amount;
      }

      if (type == 'enrollment') {
        enrollmentRewards++;
      } else if (type == 'grading') {
        gradingRewards++;
      }
    }

    return {
      'totalAllocated': totalAllocated,
      'totalRedeemed': totalRedeemed,
      'totalUnredeemed': totalAllocated - totalRedeemed,
      'enrollmentRewards': enrollmentRewards,
      'gradingRewards': gradingRewards,
      'percentageOfSupply': (totalAllocated / totalSupply) * 100,
    };
  }
}
