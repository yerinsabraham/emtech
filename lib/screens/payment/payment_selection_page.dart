import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/payment_service.dart';
import 'paystack_webview_page.dart';
import 'payment_success_page.dart';

class PaymentSelectionPage extends StatelessWidget {
  final String itemType; // 'course' or 'wallet'
  final String itemId;
  final String itemName;
  final double amount; // In EMC
  final String? thumbnail;

  const PaymentSelectionPage({
    super.key,
    required this.itemType,
    required this.itemId,
    required this.itemName,
    required this.amount,
    this.thumbnail,
  });

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final userModel = authService.userModel;
    final emcBalance = userModel?.emcBalance ?? 0;
    final canPayWithEMC = emcBalance >= amount;

    return Scaffold(
      backgroundColor: const Color(0xFF080C14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1120),
        elevation: 0,
        title: const Text(
          'Payment Method',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item Details Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF111C2F),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1A2940), width: 1),
              ),
              child: Row(
                children: [
                  if (thumbnail != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        thumbnail!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 60,
                          height: 60,
                          color: const Color(0xFF1A2940),
                          child: const Icon(Icons.image, color: Colors.white30),
                        ),
                      ),
                    ),
                  if (thumbnail != null) const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          itemName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          itemType == 'course' ? 'Course Purchase' : 'Add Funds',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green, width: 1),
                    ),
                    child: Text(
                      '${amount.toStringAsFixed(0)} EMC',
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Your Balance
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF111C2F),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1A2940), width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Your EMC Balance',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${emcBalance.toStringAsFixed(0)} EMC',
                    style: TextStyle(
                      color: canPayWithEMC ? Colors.green : Colors.orange,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Payment Methods
            const Text(
              'Select Payment Method',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            // Pay with EMC Balance
            _buildPaymentOption(
              context,
              icon: Icons.account_balance_wallet,
              iconColor: Colors.green,
              title: 'Pay with EMC Balance',
              subtitle: canPayWithEMC
                  ? 'Pay using your EMC wallet'
                  : 'Insufficient balance',
              enabled: canPayWithEMC,
              onTap: () => _payWithEMC(context),
            ),
            const SizedBox(height: 12),

            // Pay with Paystack
            _buildPaymentOption(
              context,
              icon: Icons.credit_card,
              iconColor: Colors.blue,
              title: 'Pay with Paystack',
              subtitle: 'Pay with card, bank transfer, or USSD',
              enabled: true,
              onTap: () => _payWithPaystack(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF111C2F),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: enabled ? iconColor.withValues(alpha: 0.3) : const Color(0xFF1A2940),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: enabled ? Colors.white54 : Colors.white24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _payWithEMC(BuildContext context) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111C2F),
        title: const Text(
          'Confirm Payment',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Pay ${amount.toStringAsFixed(0)} EMC for $itemName?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    final auth = context.read<AuthService>();
    final userId = auth.currentUser?.uid;
    if (userId == null) return;

    // Deduct EMC tokens from wallet
    final success = await auth.spendEmcTokens(
      amount.toInt(),
      'Paid for: $itemName',
    );

    if (!context.mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Insufficient EMC balance.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Post-payment action
    final service = PaymentService.instance;
    final reference = service.generateReference();
    try {
      await service.recordPayment(
        userId: userId,
        reference: reference,
        amountNgn: 0,
        itemId: itemId,
        itemType: itemType,
        itemName: itemName,
        paymentMethod: 'emc_balance',
      );

      if (itemType == 'course') {
        await service.enrollAfterPayment(
          userId: userId,
          courseId: itemId,
          paymentReference: reference,
          isPaidCourse: amount > 0,
          courseName: itemName,
        );
      }
    } catch (_) { /* Non-fatal; payment already deducted */ }

    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentSuccessPage(
          itemName: itemName,
          amount: amount,
          paymentMethod: 'EMC Balance',
        ),
      ),
    );
  }

  Future<void> _payWithPaystack(BuildContext context) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaystackWebViewPage(
          itemName: itemName,
          itemId: itemId,
          amount: amount,
          itemType: itemType,
        ),
      ),
    );
  }
}
