import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

/// Alternative Paystack checkout using web redirect (more reliable)
class PaystackWebCheckout {
  static Future<PaystackWebResult> initializeTransaction({
    required String email,
    required int amountInKobo,
    required String reference,
    required String publicKey,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.paystack.co/transaction/initialize'),
        headers: {
          'Authorization': 'Bearer $publicKey',
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

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true) {
          final authUrl = data['data']['authorization_url'];
          final accessCode = data['data']['access_code'];
          return PaystackWebResult(
            success: true,
            authorizationUrl: authUrl,
            accessCode: accessCode,
            reference: reference,
          );
        }
      }

      return PaystackWebResult(
        success: false,
        error: 'Failed to initialize payment',
        reference: reference,
      );
    } catch (e) {
      return PaystackWebResult(
        success: false,
        error: e.toString(),
        reference: reference,
      );
    }
  }

  static Future<void> openInBrowser(BuildContext context, String url) async {
    try {
      // Copy URL to clipboard as fallback
      await Clipboard.setData(ClipboardData(text: url));
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment URL copied. Opening browser...'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      // TODO: Implement url_launcher if needed
      debugPrint('[PaystackWeb] Payment URL: $url');
    } catch (e) {
      debugPrint('[PaystackWeb] Error opening browser: $e');
    }
  }
}

class PaystackWebResult {
  final bool success;
  final String? authorizationUrl;
  final String? accessCode;
  final String reference;
  final String? error;

  PaystackWebResult({
    required this.success,
    this.authorizationUrl,
    this.accessCode,
    required this.reference,
    this.error,
  });
}
