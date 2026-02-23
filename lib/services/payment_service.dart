import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_paystack_plus/flutter_paystack_plus.dart';
import 'package:http/http.dart' as http;
import 'notification_service.dart';
import 'achievement_service.dart';

/// Result of a Paystack checkout.
class PaystackResult {
  final bool success;
  final String reference;
  const PaystackResult({required this.success, required this.reference});
}

/// Handles Paystack checkout and post-payment actions (enrollment, wallet top-up).
///
/// Keys are loaded from Firebase Remote Config, with hardcoded test defaults
/// as a fallback so the app works even before Remote Config is first published.
class PaymentService {
  PaymentService._();
  static final PaymentService instance = PaymentService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  bool _keysLoaded = false;
  String _publicKey = 'pk_test_d7854421896c21ddaeb4f420f1940ce0e5090c99';
  String _secretKey = 'sk_test_ef6e93998ad1f1a722398d61e3a3c05333b68836';

  // ── Remote Config ──────────────────────────────────────────────────────────

  Future<void> _loadKeys() async {
    if (_keysLoaded) return;
    try {
      final rc = FirebaseRemoteConfig.instance;
      await rc.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 15),
        minimumFetchInterval: const Duration(hours: 1),
      ));
      await rc.setDefaults({
        'paystack_public_key':
            'pk_test_d7854421896c21ddaeb4f420f1940ce0e5090c99',
        'paystack_secret_key':
            'sk_test_ef6e93998ad1f1a722398d61e3a3c05333b68836',
      });
      await rc.fetchAndActivate();
      final pub = rc.getString('paystack_public_key');
      final sec = rc.getString('paystack_secret_key');
      if (pub.isNotEmpty) _publicKey = pub;
      if (sec.isNotEmpty) _secretKey = sec;
    } catch (e) {
      debugPrint('[PaymentService] Remote Config error: \$e');
    }
    _keysLoaded = true;
  }

  // ── Unique reference ───────────────────────────────────────────────────────

  String generateReference() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rng = Random.secure();
    final suffix =
        List.generate(10, (_) => chars[rng.nextInt(chars.length)]).join();
    return 'EMTX_${DateTime.now().millisecondsSinceEpoch}_$suffix';
  }

  // ── Paystack checkout ──────────────────────────────────────────────────────

  /// Launch the Paystack popup checkout.
  ///
  /// [amountNgn] is in Naira – this method converts to kobo internally.
  Future<PaystackResult> checkout({
    required BuildContext context,
    required String email,
    required double amountNgn,
    String? reference,
  }) async {
    try {
      await _loadKeys();

      // Validate inputs
      if (email.isEmpty) {
        throw Exception('Email is required for Paystack checkout');
      }
      if (amountNgn <= 0) {
        throw Exception('Amount must be greater than 0');
      }
      if (_publicKey.isEmpty) {
        throw Exception('Paystack public key not configured');
      }
      if (_secretKey.isEmpty) {
        throw Exception('Paystack secret key not configured');
      }

      final ref = reference ?? generateReference();
      final amountInKobo = (amountNgn * 100).toInt();
      final completer = Completer<PaystackResult>();

      debugPrint('[PaymentService] Initiating Paystack checkout');
      debugPrint('[PaymentService] Amount: ₦$amountNgn ($amountInKobo kobo)');
      debugPrint('[PaymentService] Reference: $ref');
      debugPrint('[PaymentService] Email: $email');
      debugPrint('[PaymentService] Public Key: ${_publicKey.substring(0, 10)}...');

      try {
        await FlutterPaystackPlus.openPaystackPopup(
          context: context,
          publicKey: _publicKey,
          secretKey: _secretKey,
          customerEmail: email,
          reference: ref,
          amount: amountInKobo.toString(),
          currency: 'NGN',
          callBackUrl: 'https://standard.paystack.co/close',
          onClosed: () {
            debugPrint('[PaymentService] Paystack popup closed');
            if (!completer.isCompleted) {
              completer.complete(PaystackResult(success: false, reference: ref));
            }
          },
          onSuccess: () async {
            debugPrint('[PaymentService] Paystack payment successful');
            if (!completer.isCompleted) {
              completer.complete(PaystackResult(success: true, reference: ref));
            }
          },
        );
      } catch (pluginError) {
        debugPrint('[PaymentService] Plugin error: $pluginError');
        if (!completer.isCompleted) {
          completer.completeError(pluginError);
        }
        rethrow;
      }

      return completer.future;
    } catch (e, stackTrace) {
      debugPrint('[PaymentService] Paystack checkout error: $e');
      debugPrint('[PaymentService] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Initialize a Paystack transaction via HTTP API (for webview checkout)
  ///
  /// Returns a map with:
  /// - success: bool
  /// - authorization_url: String (if successful)
  /// - reference: String
  /// - message: String (if failed)
  Future<Map<String, dynamic>> initializePaystackTransaction({
    required String email,
    required double amountNgn,
    required String reference,
  }) async {
    try {
      await _loadKeys();

      // Validate inputs
      if (email.isEmpty) {
        return {
          'success': false,
          'message': 'Email is required',
          'reference': reference,
        };
      }
      if (amountNgn <= 0) {
        return {
          'success': false,
          'message': 'Amount must be greater than 0',
          'reference': reference,
        };
      }
      if (_secretKey.isEmpty) {
        return {
          'success': false,
          'message': 'Paystack secret key not configured',
          'reference': reference,
        };
      }

      final amountInKobo = (amountNgn * 100).toInt();

      debugPrint('[PaymentService] Initializing Paystack transaction');
      debugPrint('[PaymentService] Amount: ₦$amountNgn ($amountInKobo kobo)');
      debugPrint('[PaymentService] Reference: $reference');
      debugPrint('[PaymentService] Email: $email');

      final response = await http.post(
        Uri.parse('https://api.paystack.co/transaction/initialize'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'amount': amountInKobo,
          'reference': reference,
          'currency': 'NGN',
          'callback_url': 'https://emtech-school.web.app/payment-callback',
        }),
      );

      debugPrint('[PaymentService] Response status: ${response.statusCode}');
      debugPrint('[PaymentService] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true) {
          final authUrl = data['data']['authorization_url'];
          final accessCode = data['data']['access_code'];
          
          debugPrint('[PaymentService] Transaction initialized successfully');
          debugPrint('[PaymentService] Authorization URL: $authUrl');
          
          return {
            'success': true,
            'authorization_url': authUrl,
            'access_code': accessCode,
            'reference': reference,
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Failed to initialize transaction',
            'reference': reference,
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Server returned ${response.statusCode}',
          'reference': reference,
        };
      }
    } catch (e, stackTrace) {
      debugPrint('[PaymentService] Initialize transaction error: $e');
      debugPrint('[PaymentService] Stack trace: $stackTrace');
      return {
        'success': false,
        'message': e.toString(),
        'reference': reference,
      };
    }
  }

  // ── Post-payment actions ───────────────────────────────────────────────────

  /// Write a payment record to the `payments` Firestore collection.
  Future<void> recordPayment({
    required String userId,
    required String reference,
    required double amountNgn,
    required String itemId,
    required String itemType, // 'course' | 'wallet'
    required String itemName,
    String paymentMethod = 'paystack',
  }) async {
    try {
      await _firestore.collection('payments').add({
        'userId': userId,
        'reference': reference,
        'amountNgn': amountNgn,
        'itemId': itemId,
        'itemType': itemType,
        'itemName': itemName,
        'paymentMethod': paymentMethod,
        'status': 'completed',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[PaymentService] recordPayment error: $e');
    }
  }

  /// Enroll a student in a course and allocate enrollment rewards.
  Future<void> enrollAfterPayment({
    required String userId,
    required String courseId,
    required String paymentReference,
    required bool isPaidCourse,
    String courseName = 'your course',
    int totalModules = 0,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'enrolledCourses': FieldValue.arrayUnion([courseId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Record enrollment document
      await _firestore.collection('enrollments').add({
        'userId': userId,
        'courseId': courseId,
        'courseName': courseName,
        'paymentReference': paymentReference,
        'enrolledAt': FieldValue.serverTimestamp(),
        'progress': 0,
        'completedModules': 0,
        'totalModules': totalModules,
        'status': 'active',
      });

      // Allocate sign-up reward (1000 EMC free / 2000 EMC paid)
      final reward = isPaidCourse ? 2000 : 1000;
      await _firestore.collection('users').doc(userId).update({
        'unredeemedEMC': FieldValue.increment(reward),
      });

      await _firestore.collection('rewards').add({
        'userId': userId,
        'type': 'enrollment_bonus',
        'amount': reward,
        'courseId': courseId,
        'reference': paymentReference,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Notify student of successful enrollment
      await _notificationService.createNotification(
        userId: userId,
        title: 'Enrollment Successful! 🎉',
        message: 'You are now enrolled in "$courseName". +${reward} EMC reward pending upon completion!',
        type: 'enrollment',
        actionUrl: '/course/$courseId',
      );

      // Trigger achievement check for enrollment
      unawaited(AchievementService().onEnrollment(userId, isPaid: isPaidCourse));
    } catch (e) {
      debugPrint('[PaymentService] enrollAfterPayment error: $e');
      rethrow;
    }
  }

  /// Credit the user's EMC wallet after a Paystack top-up.
  ///
  /// [emcAmount] is the number of EMC to credit (1 NGN = 1 EMC by default).
  Future<void> topUpWalletAfterPayment({
    required String userId,
    required int emcAmount,
    required String paymentReference,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'emcBalance': FieldValue.increment(emcAmount),
        'availableEMC': FieldValue.increment(emcAmount),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('wallet_transactions').add({
        'userId': userId,
        'type': 'top_up',
        'amount': emcAmount,
        'reference': paymentReference,
        'status': 'completed',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Notify student of wallet top-up
      await _notificationService.createNotification(
        userId: userId,
        title: 'Wallet Topped Up! 💰',
        message: '$emcAmount EMC has been added to your wallet.',
        type: 'payment',
        actionUrl: '/wallet',
      );
    } catch (e) {
      debugPrint('[PaymentService] topUpWalletAfterPayment error: $e');
      rethrow;
    }
  }
}
