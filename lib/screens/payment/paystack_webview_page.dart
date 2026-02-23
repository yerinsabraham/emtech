import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';
import '../../services/payment_service.dart';
import '../../services/auth_service.dart';
import 'payment_success_page.dart';
import 'payment_failure_page.dart';

/// Webview-based Paystack checkout page with back navigation
class PaystackWebViewPage extends StatefulWidget {
  final String itemName;
  final String itemId;
  final double amount; // In EMC
  final String itemType; // 'course' | 'wallet'

  const PaystackWebViewPage({
    super.key,
    required this.itemName,
    required this.itemId,
    required this.amount,
    required this.itemType,
  });

  @override
  State<PaystackWebViewPage> createState() => _PaystackWebViewPageState();
}

class _PaystackWebViewPageState extends State<PaystackWebViewPage> {
  late WebViewController _controller;
  bool _isLoading = true;
  bool _isProcessing = false;
  String _statusMessage = 'Initializing payment...';
  String? _authorizationUrl;
  String? _reference;
  double _loadingProgress = 0.0;

  static const double _emcToNgn = 1.0;
  double get _amountNgn => widget.amount * _emcToNgn;

  @override
  void initState() {
    super.initState();
    _initializePayment();
  }

  Future<void> _initializePayment() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Initializing payment...';
    });

    try {
      final auth = context.read<AuthService>();
      final userId = auth.currentUser?.uid;
      final email = auth.currentUser?.email ?? auth.userModel?.email ?? '';

      if (userId == null || email.isEmpty) {
        _showError('You must be signed in to make a payment.');
        return;
      }

      final service = PaymentService.instance;
      final reference = service.generateReference();

      setState(() {
        _reference = reference;
        _statusMessage = 'Connecting to Paystack...';
      });

      // Initialize Paystack transaction
      final result = await service.initializePaystackTransaction(
        email: email,
        amountNgn: _amountNgn,
        reference: reference,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          _authorizationUrl = result['authorization_url'];
          _isLoading = false;
        });
        _initializeWebView();
      } else {
        _showError(result['message'] ?? 'Failed to initialize payment');
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('[PaystackWebView] Initialization error: $e');
      if (!mounted) return;
      _showError('Failed to initialize payment: $e');
      Navigator.pop(context);
    }
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              _loadingProgress = progress / 100;
            });
          },
          onPageStarted: (String url) {
            debugPrint('[PaystackWebView] Page started: $url');
            _checkPaymentStatus(url);
          },
          onPageFinished: (String url) {
            debugPrint('[PaystackWebView] Page finished: $url');
            setState(() {
              _loadingProgress = 1.0;
            });
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('[PaystackWebView] Error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(_authorizationUrl!));
  }

  void _checkPaymentStatus(String url) {
    // Check if payment was successful or failed based on URL
    if (url.contains('emtech-school.web.app/payment-callback')) {
      // Custom callback URL - check for reference or trxref parameter
      if (url.contains('?')) {
        final uri = Uri.parse(url);
        final reference = uri.queryParameters['reference'];
        final trxref = uri.queryParameters['trxref'];

        // If reference or trxref exists, payment was initiated successfully
        if (reference != null && reference.isNotEmpty ||
            trxref != null && trxref.isNotEmpty) {
          debugPrint(
            '[PaystackWebView] Payment callback received with reference: $reference',
          );
          _handlePaymentSuccess();
        } else {
          _handlePaymentFailure();
        }
      }
    } else if (url.contains('success') ||
        (url.contains('callback') && url.contains('status=success'))) {
      _handlePaymentSuccess();
    } else if (url.contains('cancel') || url.contains('failed')) {
      _handlePaymentFailure();
    }
  }

  Future<void> _handlePaymentSuccess() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Verifying payment...';
    });

    try {
      final auth = context.read<AuthService>();
      final userId = auth.currentUser?.uid;

      if (userId == null || _reference == null) {
        throw Exception('User ID or reference not found');
      }

      final service = PaymentService.instance;

      // Verify payment with Paystack API
      final verification = await service.verifyPaystackTransaction(
        reference: _reference!,
      );

      if (!verification['success']) {
        throw Exception(
          verification['message'] ?? 'Payment verification failed',
        );
      }

      setState(() {
        _statusMessage = 'Processing payment...';
      });

      // Record payment
      await service.recordPayment(
        userId: userId,
        reference: _reference!,
        amountNgn: _amountNgn,
        itemId: widget.itemId,
        itemType: widget.itemType,
        itemName: widget.itemName,
        paymentMethod: 'paystack',
      );

      // Post-payment actions
      if (widget.itemType == 'course') {
        await service.enrollAfterPayment(
          userId: userId,
          courseId: widget.itemId,
          paymentReference: _reference!,
          isPaidCourse: widget.amount > 0,
          courseName: widget.itemName,
        );
      } else if (widget.itemType == 'wallet') {
        await service.topUpWalletAfterPayment(
          userId: userId,
          emcAmount: _amountNgn.toInt(),
          paymentReference: _reference!,
        );
        await auth.reloadUserData();
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentSuccessPage(
            itemName: widget.itemName,
            amount: widget.amount,
            paymentMethod: 'Paystack',
          ),
        ),
      );
    } catch (e) {
      debugPrint('[PaystackWebView] Payment processing error: $e');
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentFailurePage(
            itemName: widget.itemName,
            amount: widget.amount,
            errorMessage: 'Payment verification failed: $e',
          ),
        ),
      );
    }
  }

  void _handlePaymentFailure() {
    if (_isProcessing) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentFailurePage(
          itemName: widget.itemName,
          amount: widget.amount,
          errorMessage: 'Payment was cancelled or declined.',
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080C14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1120),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _isProcessing
              ? null
              : () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: const Color(0xFF111C2F),
                      title: const Text(
                        'Cancel Payment?',
                        style: TextStyle(color: Colors.white),
                      ),
                      content: const Text(
                        'Are you sure you want to cancel this payment?',
                        style: TextStyle(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('No'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Yes, Cancel',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
        ),
        title: const Text(
          'Secure Payment',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: _isProcessing
                ? null
                : () {
                    Navigator.pop(context);
                  },
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    _statusMessage,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Amount card at top
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 20,
                  ),
                  color: const Color(0xFF111C2F),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.itemName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Amount: ₦${_amountNgn.toStringAsFixed(2)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.security,
                              size: 14,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Secured',
                              style: TextStyle(
                                color: Colors.blue.shade300,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Loading progress bar
                if (_loadingProgress < 1.0)
                  LinearProgressIndicator(
                    value: _loadingProgress,
                    backgroundColor: const Color(0xFF1A2940),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.blue,
                    ),
                  ),
                // WebView
                Expanded(
                  child: _authorizationUrl != null
                      ? WebViewWidget(controller: _controller)
                      : const Center(
                          child: Text(
                            'Loading payment page...',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}
