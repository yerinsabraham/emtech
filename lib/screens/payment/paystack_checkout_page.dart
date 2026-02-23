import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/payment_service.dart';
import '../../services/auth_service.dart';
import 'payment_success_page.dart';
import 'payment_failure_page.dart';

/// Real Paystack checkout page using the flutter_paystack SDK.
class PaystackCheckoutPage extends StatefulWidget {
  final String itemName;
  final String itemId;
  final double amount; // In EMC
  final String itemType; // 'course' | 'wallet'

  const PaystackCheckoutPage({
    super.key,
    required this.itemName,
    required this.itemId,
    required this.amount,
    required this.itemType,
  });

  @override
  State<PaystackCheckoutPage> createState() => _PaystackCheckoutPageState();
}

class _PaystackCheckoutPageState extends State<PaystackCheckoutPage> {
  bool _isProcessing = false;
  String _statusMessage = 'Preparing secure checkout…';

  // 1 EMC = 1 NGN (adjust here if the business rate changes)
  static const double _emcToNgn = 1.0;
  double get _amountNgn => widget.amount * _emcToNgn;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080C14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1120),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
        ),
        title: const Text(
          'Paystack Checkout',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildAmountCard(),
            const SizedBox(height: 24),
            _buildMethodsCard(),
            const SizedBox(height: 32),
            _buildPayButton(context),
            const SizedBox(height: 20),
            _buildSecurityNote(),
          ],
        ),
      ),
    );
  }

  // ── Amount card ────────────────────────────────────────────────────────────

  Widget _buildAmountCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A2744), Color(0xFF0F1B30)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text('Amount to Pay', style: TextStyle(color: Colors.white54, fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            '₦${_amountNgn.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '(${widget.amount.toStringAsFixed(0)} EMC)',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              widget.itemName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.blue, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ── Methods card ───────────────────────────────────────────────────────────

  Widget _buildMethodsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111C2F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1A2940)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Accepted Payment Methods',
            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _chip('💳 Card', Colors.blue),
              _chip('🏦 Bank Transfer', Colors.green),
              _chip('📱 USSD', Colors.orange),
              _chip('📲 Mobile Money', Colors.purple),
            ],
          ),
          if (_isProcessing) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Text(_statusMessage, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      );

  // ── Pay button ─────────────────────────────────────────────────────────────

  Widget _buildPayButton(BuildContext context) {
    return ElevatedButton(
      onPressed: _isProcessing ? null : () => _startPayment(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00C2FF),
        disabledBackgroundColor: const Color(0xFF1A2744),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _isProcessing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Text(
              'Pay ₦${_amountNgn.toStringAsFixed(2)} with Paystack',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
            ),
    );
  }

  // ── Security note ──────────────────────────────────────────────────────────

  Widget _buildSecurityNote() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.security, color: Colors.blue, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Payments are secured by Paystack. '
              'Your card details are never stored on our servers.',
              style: TextStyle(color: Colors.blue.shade200, fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // ── Payment logic ──────────────────────────────────────────────────────────

  Future<void> _startPayment(BuildContext context) async {
    final auth = context.read<AuthService>();
    final userId = auth.currentUser?.uid;
    final email = auth.currentUser?.email ?? auth.userModel?.email ?? '';

    if (userId == null || email.isEmpty) {
      _showError('You must be signed in to make a payment.');
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Connecting to Paystack…';
    });

    try {
      final service = PaymentService.instance;
      final reference = service.generateReference();

      setState(() => _statusMessage = 'Waiting for payment…');

      final response = await service.checkout(
        context: context,
        email: email,
        amountNgn: _amountNgn,
        reference: reference,
      );

      if (!mounted) return;

      if (response.success) {
        setState(() => _statusMessage = 'Finalising…');

        // Record to Firestore
        await service.recordPayment(
          userId: userId,
          reference: response.reference,
          amountNgn: _amountNgn,
          itemId: widget.itemId,
          itemType: widget.itemType,
          itemName: widget.itemName,
          paymentMethod: 'paystack',
        );

        // Post-payment action
        if (widget.itemType == 'course') {
          await service.enrollAfterPayment(
            userId: userId,
            courseId: widget.itemId,
            paymentReference: response.reference,
            isPaidCourse: widget.amount > 0,
            courseName: widget.itemName,
          );
        } else if (widget.itemType == 'wallet') {
          await service.topUpWalletAfterPayment(
            userId: userId,
            emcAmount: _amountNgn.toInt(),
            paymentReference: response.reference,
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
      } else {
        // Cancelled or declined
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentFailurePage(
              itemName: widget.itemName,
              amount: widget.amount,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('[PaystackCheckout] Payment error: $e');
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _statusMessage = 'An error occurred.';
      });
      _showError('Payment failed: $e\n\nPlease check your internet connection and try again.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }
}
