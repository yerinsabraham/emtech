import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/loan_model.dart';
import '../../models/loan_payment_model.dart';
import '../../models/user_model.dart';
import '../../services/loan_service.dart';

class LoanRepaymentPage extends StatefulWidget {
  final LoanModel loan;
  final UserModel userModel;

  const LoanRepaymentPage({
    super.key,
    required this.loan,
    required this.userModel,
  });

  @override
  State<LoanRepaymentPage> createState() => _LoanRepaymentPageState();
}

class _LoanRepaymentPageState extends State<LoanRepaymentPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final LoanService _loanService = LoanService();
  final _amountController = TextEditingController();
  bool _isProcessing = false;
  bool _payFull = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _amountController.text =
        widget.loan.monthlyPayment.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  // ── Computed helpers ──────────────────────────────────────────────────────

  bool get _isLate {
    final due = widget.loan.nextPaymentDue;
    if (due == null) return false;
    return DateTime.now().isAfter(due);
  }

  int get _daysLate {
    final due = widget.loan.nextPaymentDue;
    if (due == null || !_isLate) return 0;
    return DateTime.now().difference(due).inDays;
  }

  double get _penaltyPreview {
    final amount = double.tryParse(_amountController.text) ?? 0;
    return LoanPaymentModel.calculateLatePenalty(amount, _daysLate);
  }

  double get _progressPercent {
    if (widget.loan.totalPayments == 0) return 0;
    return (widget.loan.completedPayments / widget.loan.totalPayments)
        .clamp(0.0, 1.0);
  }

  // ── Payment handler ───────────────────────────────────────────────────────

  Future<void> _makePayment() async {
    final amount = _payFull
        ? widget.loan.outstandingBalance
        : (double.tryParse(_amountController.text) ?? 0);

    if (amount <= 0) {
      _showSnack('Please enter a valid amount', isError: true);
      return;
    }

    final totalWithPenalty = amount + (_isLate ? _penaltyPreview : 0);
    if (widget.userModel.availableEMC < totalWithPenalty) {
      _showSnack(
        'Insufficient EMC. You need ${totalWithPenalty.toStringAsFixed(0)} EMC but have ${widget.userModel.availableEMC.toStringAsFixed(0)} EMC',
        isError: true,
      );
      return;
    }

    // Confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _PaymentConfirmDialog(
        amount: amount,
        penalty: _isLate ? _penaltyPreview : 0,
        availableEMC: widget.userModel.availableEMC,
        isLate: _isLate,
        daysLate: _daysLate,
        isFullPayoff: _payFull,
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    try {
      await _loanService.makeLoanPayment(
        loanId: widget.loan.id,
        studentId: widget.userModel.uid,
        amount: amount,
      );

      if (mounted) {
        final isFullyPaid = amount >= widget.loan.outstandingBalance;
        _showSnack(
          isFullyPaid
              ? '🎉 Loan fully repaid! Congratulations!'
              : 'Payment of ${amount.toStringAsFixed(0)} EMC successful',
        );
        if (isFullyPaid) {
          Navigator.pop(context);
        }
        // Reset to monthly instalment amount
        _amountController.text =
            widget.loan.monthlyPayment.toStringAsFixed(0);
        setState(() => _payFull = false);
      }
    } catch (e) {
      if (mounted) {
        _showSnack(e.toString().replaceAll('Exception: ', ''),
            isError: true);
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final loan = widget.loan;

    return Scaffold(
      backgroundColor: const Color(0xFF080C14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1120),
        title: const Text('Loan Repayment',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF3B82F6),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(loan),
          _buildHistoryTab(loan),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Overview tab
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildOverviewTab(LoanModel loan) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Late warning ───────────────────────────────────────────────
          if (_isLate) _buildLateWarning(),

          // ── Balance card ───────────────────────────────────────────────
          _buildBalanceCard(loan),
          const SizedBox(height: 16),

          // ── Progress card ──────────────────────────────────────────────
          _buildProgressCard(loan),
          const SizedBox(height: 16),

          // ── Loan details ───────────────────────────────────────────────
          _buildDetailsCard(loan),
          const SizedBox(height: 20),

          // ── Make Payment section ───────────────────────────────────────
          if (loan.status == LoanStatus.active) ...[
            const Text(
              'Make a Payment',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildPaymentSection(loan),
          ],

          if (loan.status == LoanStatus.completed)
            _buildCompletedBanner(),
        ],
      ),
    );
  }

  Widget _buildLateWarning() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Color(0xFFEF4444), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payment Overdue',
                  style: TextStyle(
                    color: Color(0xFFEF4444),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '$_daysLate day${_daysLate == 1 ? '' : 's'} late · '
                  'Additional penalty applies',
                  style: const TextStyle(
                      color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(LoanModel loan) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A2744), Color(0xFF0D1B3E)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Outstanding Balance',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            '${loan.outstandingBalance.toStringAsFixed(2)} EMC',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _BalanceStat(
                  label: 'Total Borrowed',
                  value:
                      '${loan.approvedAmount.toStringAsFixed(0)} EMC',
                  color: const Color(0xFF3B82F6),
                ),
              ),
              Expanded(
                child: _BalanceStat(
                  label: 'Amount Paid',
                  value: '${loan.amountPaid.toStringAsFixed(0)} EMC',
                  color: const Color(0xFF10B981),
                ),
              ),
              Expanded(
                child: _BalanceStat(
                  label: 'Total Due',
                  value:
                      '${loan.totalAmountDue.toStringAsFixed(0)} EMC',
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
          if (loan.penaltyAmount > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber,
                      color: Color(0xFFEF4444), size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'Accumulated penalties: ${loan.penaltyAmount.toStringAsFixed(2)} EMC',
                    style: const TextStyle(
                        color: Color(0xFFEF4444), fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressCard(LoanModel loan) {
    final pct = (_progressPercent * 100).toStringAsFixed(0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111C2F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFF2A3F5F).withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Repayment Progress',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14),
              ),
              Text(
                '$pct%',
                style: const TextStyle(
                  color: Color(0xFF10B981),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _progressPercent,
              backgroundColor:
                  const Color(0xFF10B981).withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF10B981)),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${loan.completedPayments} of ${loan.totalPayments} payments',
                style:
                    const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              Text(
                '${loan.totalPayments - loan.completedPayments} remaining',
                style: const TextStyle(
                    color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(LoanModel loan) {
    final df = DateFormat('MMM d, yyyy');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111C2F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFF2A3F5F).withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          _DetailRow(
            icon: Icons.calendar_today_outlined,
            label: 'Next Payment Due',
            value: loan.nextPaymentDue != null
                ? df.format(loan.nextPaymentDue!)
                : '—',
            valueColor:
                _isLate ? const Color(0xFFEF4444) : Colors.white,
          ),
          const Divider(color: Color(0xFF1E3A5F), height: 20),
          _DetailRow(
            icon: Icons.payments_outlined,
            label: 'Monthly Instalment',
            value:
                '${loan.monthlyPayment.toStringAsFixed(2)} EMC',
            valueColor: const Color(0xFF3B82F6),
          ),
          const Divider(color: Color(0xFF1E3A5F), height: 20),
          _DetailRow(
            icon: Icons.percent,
            label: 'Interest Rate',
            value:
                '${(loan.interestRate * 100).toStringAsFixed(1)}% APR',
          ),
          const Divider(color: Color(0xFF1E3A5F), height: 20),
          _DetailRow(
            icon: Icons.schedule,
            label: 'Term',
            value: '${loan.termMonths} months',
          ),
          if (loan.missedPayments > 0) ...[
            const Divider(color: Color(0xFF1E3A5F), height: 20),
            _DetailRow(
              icon: Icons.error_outline,
              label: 'Missed Payments',
              value: '${loan.missedPayments}',
              valueColor: const Color(0xFFEF4444),
            ),
          ],
          const Divider(color: Color(0xFF1E3A5F), height: 20),
          _DetailRow(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Your EMC Balance',
            value:
                '${widget.userModel.availableEMC.toStringAsFixed(2)} EMC',
            valueColor: const Color(0xFF10B981),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection(LoanModel loan) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111C2F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pay full toggle
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pay off full balance',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Pay the entire outstanding amount',
                      style:
                          TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _payFull,
                activeThumbColor: Colors.white,
                activeTrackColor: const Color(0xFF3B82F6),
                onChanged: (v) {
                  setState(() {
                    _payFull = v;
                    if (v) {
                      _amountController.text =
                          loan.outstandingBalance.toStringAsFixed(0);
                    } else {
                      _amountController.text =
                          loan.monthlyPayment.toStringAsFixed(0);
                    }
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Amount field
          TextFormField(
            controller: _amountController,
            readOnly: _payFull,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: 'Payment Amount (EMC)',
              labelStyle: const TextStyle(color: Colors.white54),
              prefixIcon:
                  const Icon(Icons.token, color: Color(0xFFF59E0B)),
              filled: true,
              fillColor: const Color(0xFF0B1120),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),

          // Penalty preview
          if (_isLate && (_amountController.text.isNotEmpty)) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color:
                        const Color(0xFFEF4444).withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Late payment breakdown',
                    style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontWeight: FontWeight.w600,
                        fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  _BreakdownRow(
                    label: 'Payment amount',
                    value:
                        '${(double.tryParse(_amountController.text) ?? 0).toStringAsFixed(2)} EMC',
                  ),
                  _BreakdownRow(
                    label: 'Late penalty ($_daysLate days)',
                    value: '${_penaltyPreview.toStringAsFixed(2)} EMC',
                    isRed: true,
                  ),
                  const Divider(color: Color(0xFF3A1515), height: 12),
                  _BreakdownRow(
                    label: 'Total deducted',
                    value:
                        '${((double.tryParse(_amountController.text) ?? 0) + _penaltyPreview).toStringAsFixed(2)} EMC',
                    isBold: true,
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Quick amounts
          const Text(
            'Quick amounts',
            style:
                TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _QuickAmountChip(
                  label: 'Monthly (${loan.monthlyPayment.toStringAsFixed(0)})',
                  onTap: () {
                    setState(() {
                      _payFull = false;
                      _amountController.text =
                          loan.monthlyPayment.toStringAsFixed(0);
                    });
                  }),
              _QuickAmountChip(
                  label: '2× Monthly',
                  onTap: () {
                    setState(() {
                      _payFull = false;
                      _amountController.text =
                          (loan.monthlyPayment * 2).toStringAsFixed(0);
                    });
                  }),
              _QuickAmountChip(
                  label: 'Full balance',
                  onTap: () {
                    setState(() {
                      _payFull = true;
                      _amountController.text =
                          loan.outstandingBalance.toStringAsFixed(0);
                    });
                  }),
            ],
          ),

          const SizedBox(height: 18),

          // Pay button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _makePayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor:
                    const Color(0xFF3B82F6).withValues(alpha: 0.4),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send_rounded, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Pay Now',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedBanner() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFF10B981).withValues(alpha: 0.4)),
      ),
      child: const Column(
        children: [
          Icon(Icons.check_circle, color: Color(0xFF10B981), size: 48),
          SizedBox(height: 12),
          Text(
            'Loan Fully Repaid!',
            style: TextStyle(
              color: Color(0xFF10B981),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Congratulations on completing your loan repayment.',
            style: TextStyle(color: Colors.white54, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // History tab
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildHistoryTab(LoanModel loan) {
    final df = DateFormat('MMM d, yyyy');
    return StreamBuilder<List<LoanPaymentModel>>(
      stream: _loanService.getLoanPayments(loan.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
                color: Color(0xFF3B82F6)),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading history: ${snapshot.error}',
              style: const TextStyle(color: Colors.redAccent),
            ),
          );
        }
        final payments = snapshot.data ?? [];
        if (payments.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_outlined,
                    color: Colors.white24, size: 52),
                SizedBox(height: 12),
                Text(
                  'No payments made yet',
                  style: TextStyle(color: Colors.white38),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: payments.length,
          itemBuilder: (context, index) {
            final p = payments[index];
            return _PaymentHistoryCard(payment: p, df: df);
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Confirmation dialog
// ─────────────────────────────────────────────────────────────────────────────

class _PaymentConfirmDialog extends StatelessWidget {
  final double amount;
  final double penalty;
  final double availableEMC;
  final bool isLate;
  final int daysLate;
  final bool isFullPayoff;

  const _PaymentConfirmDialog({
    required this.amount,
    required this.penalty,
    required this.availableEMC,
    required this.isLate,
    required this.daysLate,
    required this.isFullPayoff,
  });

  @override
  Widget build(BuildContext context) {
    final total = amount + penalty;
    return AlertDialog(
      backgroundColor: const Color(0xFF111C2F),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Confirm Payment',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isFullPayoff)
            const _DialogInfoRow(
              label: 'Type',
              value: 'Full loan payoff',
              valueColor: Color(0xFF10B981),
            ),
          _DialogInfoRow(
            label: 'Payment amount',
            value: '${amount.toStringAsFixed(2)} EMC',
          ),
          if (isLate) ...[
            _DialogInfoRow(
              label: 'Late penalty ($daysLate days)',
              value: '${penalty.toStringAsFixed(2)} EMC',
              valueColor: const Color(0xFFEF4444),
            ),
            _DialogInfoRow(
              label: 'Total deducted',
              value: '${total.toStringAsFixed(2)} EMC',
              isBold: true,
            ),
          ],
          const SizedBox(height: 10),
          const Divider(color: Color(0xFF1E3A5F)),
          const SizedBox(height: 8),
          _DialogInfoRow(
            label: 'Your balance after',
            value:
                '${(availableEMC - total).toStringAsFixed(2)} EMC',
            valueColor: const Color(0xFFF59E0B),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel',
              style: TextStyle(color: Colors.white38)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Confirm Pay'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Payment history card
// ─────────────────────────────────────────────────────────────────────────────

class _PaymentHistoryCard extends StatelessWidget {
  final LoanPaymentModel payment;
  final DateFormat df;

  const _PaymentHistoryCard({required this.payment, required this.df});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111C2F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: payment.isLate
              ? const Color(0xFFEF4444).withValues(alpha: 0.3)
              : const Color(0xFF2A3F5F).withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (payment.isLate
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF10B981))
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(
              payment.isLate ? Icons.warning_amber : Icons.check_circle,
              color: payment.isLate
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF10B981),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${payment.amount.toStringAsFixed(2)} EMC',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (payment.isLate
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF10B981))
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        payment.isLate ? '⚠ Late' : '✓ On Time',
                        style: TextStyle(
                          color: payment.isLate
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF10B981),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Paid on ${df.format(payment.paidAt)}',
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _PillStat(
                      label:
                          'Principal: ${payment.principalPortion.toStringAsFixed(2)}',
                      color: const Color(0xFF3B82F6),
                    ),
                    const SizedBox(width: 6),
                    _PillStat(
                      label:
                          'Interest: ${payment.interestPortion.toStringAsFixed(2)}',
                      color: const Color(0xFFF59E0B),
                    ),
                    if (payment.penaltyAmount > 0) ...[
                      const SizedBox(width: 6),
                      _PillStat(
                        label:
                            'Penalty: ${payment.penaltyAmount.toStringAsFixed(2)}',
                        color: const Color(0xFFEF4444),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Balance after: ${payment.balanceAfterPayment.toStringAsFixed(2)} EMC',
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small reusable widgets
// ─────────────────────────────────────────────────────────────────────────────

class _BalanceStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _BalanceStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13)),
        const SizedBox(height: 2),
        Text(label,
            style:
                const TextStyle(color: Colors.white38, fontSize: 10)),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _DetailRow(
      {required this.icon,
      required this.label,
      required this.value,
      this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white38, size: 18),
        const SizedBox(width: 10),
        Text(label,
            style:
                const TextStyle(color: Colors.white54, fontSize: 13)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isRed;
  final bool isBold;
  const _BreakdownRow(
      {required this.label,
      required this.value,
      this.isRed = false,
      this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.white54, fontSize: 12)),
          Text(
            value,
            style: TextStyle(
              color: isRed ? const Color(0xFFEF4444) : Colors.white,
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAmountChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _QuickAmountChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.35)),
        ),
        child: Text(
          label,
          style: const TextStyle(
              color: Color(0xFF3B82F6),
              fontSize: 12,
              fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _PillStat extends StatelessWidget {
  final String label;
  final Color color;
  const _PillStat({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DialogInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;
  const _DialogInfoRow(
      {required this.label,
      required this.value,
      this.valueColor,
      this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.white54, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontWeight:
                  isBold ? FontWeight.bold : FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
