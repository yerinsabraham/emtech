import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/loan_service.dart';
import '../../models/loan_model.dart';

class AdminLoansTab extends StatefulWidget {
  const AdminLoansTab({super.key});

  @override
  State<AdminLoansTab> createState() => _AdminLoansTabState();
}

class _AdminLoansTabState extends State<AdminLoansTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final LoanService _loanService = LoanService();
  final _fmt = NumberFormat('#,##0.00');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          indicatorColor: Colors.blue,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
            Tab(text: 'All'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _LoansList(status: LoanStatus.pending, onAction: _handleAction),
              _LoansList(status: LoanStatus.active, onAction: _handleAction),
              _LoansList(status: LoanStatus.completed, onAction: _handleAction),
              _LoansList(status: null, onAction: _handleAction),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleAction(LoanModel loan, String action) async {
    final authService = context.read<AuthService>();
    final adminId = authService.userModel?.uid ?? '';

    switch (action) {
      case 'approve':
        await _showApproveDialog(loan, adminId);
        break;
      case 'reject':
        await _showRejectDialog(loan, adminId);
        break;
      case 'disburse':
        await _showDisburseDialog(loan, adminId);
        break;
      case 'details':
        _showDetailsSheet(loan);
        break;
    }
  }

  Future<void> _showApproveDialog(LoanModel loan, String adminId) async {
    final amountCtrl = TextEditingController(text: loan.requestedAmount.toStringAsFixed(0));
    final notesCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111C2F),
        title: const Text('Approve Loan', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Student: ${loan.studentName}', style: const TextStyle(color: Colors.white70)),
            Text('Requested: ${_fmt.format(loan.requestedAmount)} EMC', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Approved Amount (EMC)',
                labelStyle: TextStyle(color: Colors.white54),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: notesCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Admin Notes (optional)',
                labelStyle: TextStyle(color: Colors.white54),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final adminName = context.read<AuthService>().userModel?.name ?? 'Admin';
                await _loanService.approveLoan(
                  loanId: loan.id,
                  adminId: adminId,
                  adminName: adminName,
                  approvedAmount: double.tryParse(amountCtrl.text) ?? loan.requestedAmount,
                  adminNotes: notesCtrl.text.isEmpty ? null : notesCtrl.text,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Loan approved!'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRejectDialog(LoanModel loan, String adminId) async {
    final reasonCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111C2F),
        title: const Text('Reject Loan', style: TextStyle(color: Colors.red)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Student: ${loan.studentName}', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Rejection reason',
                labelStyle: TextStyle(color: Colors.white54),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              if (reasonCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              try {
                await _loanService.rejectLoan(
                  loanId: loan.id,
                  reason: reasonCtrl.text.trim(),
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Loan rejected'), backgroundColor: Colors.red),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDisburseDialog(LoanModel loan, String adminId) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111C2F),
        title: const Text('Disburse Funds', style: TextStyle(color: Colors.white)),
        content: Text(
          'Disburse ${_fmt.format(loan.approvedAmount)} EMC to ${loan.studentName}?\n\nThis will add the EMC to the student\'s wallet.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _loanService.disburseLoan(
                  loanId: loan.id,
                  adminId: adminId,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Funds disbursed!'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Disburse'),
          ),
        ],
      ),
    );
  }

  void _showDetailsSheet(LoanModel loan) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111C2F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Loan Details — ${loan.studentName}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _row('Status', loan.status.toString().split('.').last.toUpperCase()),
            _row('Requested', '${_fmt.format(loan.requestedAmount)} EMC'),
            _row('Approved', '${_fmt.format(loan.approvedAmount)} EMC'),
            _row('Purpose', loan.purpose),
            _row('Term', '${loan.termMonths} months'),
            _row('Interest', '${(loan.interestRate * 100).toStringAsFixed(1)}% APR'),
            _row('Outstanding', '${_fmt.format(loan.outstandingBalance)} EMC'),
            _row('Amount Paid', '${_fmt.format(loan.amountPaid)} EMC'),
            _row('Applied', DateFormat('MMM d, yyyy').format(loan.appliedAt)),
            if (loan.adminNotes != null) _row('Notes', loan.adminNotes!),
            if (loan.rejectionReason != null) _row('Rejection', loan.rejectionReason!),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 13))),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
class _LoansList extends StatelessWidget {
  final LoanStatus? status;
  final Future<void> Function(LoanModel, String) onAction;

  const _LoansList({required this.status, required this.onAction});

  @override
  Widget build(BuildContext context) {
    Query query =
        FirebaseFirestore.instance.collection('loans').orderBy('appliedAt', descending: true);

    if (status != null) {
      query = query.where('status', isEqualTo: status!.toString().split('.').last);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('${snap.error}', style: const TextStyle(color: Colors.red)));
        }

        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.account_balance, color: Colors.white24, size: 48),
                const SizedBox(height: 12),
                Text(
                  status == null ? 'No loans yet' : 'No ${status!.toString().split('.').last} loans',
                  style: const TextStyle(color: Colors.white38),
                ),
              ],
            ),
          );
        }

        final loans = docs.map((d) {
          try {
            return LoanModel.fromFirestore(d);
          } catch (_) {
            return null;
          }
        }).whereType<LoanModel>().toList();

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: loans.length,
          itemBuilder: (ctx, i) => _LoanCard(loan: loans[i], onAction: onAction),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────
class _LoanCard extends StatelessWidget {
  final LoanModel loan;
  final Future<void> Function(LoanModel, String) onAction;

  const _LoanCard({required this.loan, required this.onAction});

  Color _statusColor(LoanStatus s) {
    switch (s) {
      case LoanStatus.pending:
        return Colors.orange;
      case LoanStatus.approved:
        return Colors.blue;
      case LoanStatus.disbursed:
      case LoanStatus.active:
        return Colors.green;
      case LoanStatus.completed:
        return Colors.teal;
      case LoanStatus.rejected:
      case LoanStatus.defaulted:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(loan.status);
    final fmt = NumberFormat('#,##0');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111C2F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(loan.studentName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  loan.status.toString().split('.').last.toUpperCase(),
                  style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _chip(Icons.monetization_on, '${fmt.format(loan.requestedAmount)} EMC requested'),
              const SizedBox(width: 8),
              _chip(Icons.schedule, '${loan.termMonths}mo'),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Purpose: ${loan.purpose}',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            'Applied: ${DateFormat('MMM d, yyyy').format(loan.appliedAt)}',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 10),
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => onAction(loan, 'details'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white54,
                  side: const BorderSide(color: Colors.white12),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Details', style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 6),
              if (loan.status == LoanStatus.pending) ...[
                ElevatedButton(
                  onPressed: () => onAction(loan, 'reject'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Reject', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 6),
                ElevatedButton(
                  onPressed: () => onAction(loan, 'approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Approve', style: TextStyle(fontSize: 12)),
                ),
              ],
              if (loan.status == LoanStatus.approved)
                ElevatedButton(
                  onPressed: () => onAction(loan, 'disburse'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Disburse', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white38, size: 13),
        const SizedBox(width: 3),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}
