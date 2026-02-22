import 'package:flutter/material.dart';
import '../../models/loan_model.dart';
import '../../models/user_model.dart';
import '../../models/grade_model.dart';
import '../../services/loan_service.dart';
import '../../services/staking_service.dart';
import '../../services/grading_service.dart';

class LoanApplicationPage extends StatefulWidget {
  final UserModel userModel;

  const LoanApplicationPage({super.key, required this.userModel});

  @override
  State<LoanApplicationPage> createState() => _LoanApplicationPageState();
}

class _LoanApplicationPageState extends State<LoanApplicationPage> {
  final _formKey = GlobalKey<FormState>();
  final LoanService _loanService = LoanService();
  final StakingService _stakingService = StakingService();
  final GradingService _gradingService = GradingService();

  final _amountController = TextEditingController();
  final _purposeController = TextEditingController();
  int _selectedTermMonths = 12;

  bool _isLoading = false;
  double _maxLoanAmount = 0;
  double _userGPA = 0;
  int _stakingDays = 0;
  bool _qualifies = false;

  @override
  void initState() {
    super.initState();
    _checkQualification();
  }

  Future<void> _checkQualification() async {
    setState(() => _isLoading = true);

    try {
      // Get GPA
      _userGPA = await _gradingService.calculateGPA(widget.userModel.uid);

      // Get staking info
      _stakingDays = await _stakingService.getLongestStakingDuration(widget.userModel.uid);
      final stakingTier = await _stakingService.getUserStakingTier(widget.userModel.uid);

      // Get grades
      final grades = await _gradingService.getStudentGrades(widget.userModel.uid).first;
      LetterGrade? highestGrade;
      if (grades.isNotEmpty) {
        highestGrade = grades
            .map((g) => g.grade)
            .reduce((a, b) => (a.index < b.index) ? a : b);
      }

      // Check qualification
      _qualifies = LoanModel.checkQualification(
        gpa: _userGPA,
        highestGrade: highestGrade,
        stakingDays: _stakingDays,
        kycVerified: widget.userModel.kycVerified,
        hasReference: false,
      );

      // Calculate max loan
      _maxLoanAmount = LoanModel.calculateMaxLoanAmount(
        gpa: _userGPA,
        tier: stakingTier,
        stakingDays: _stakingDays,
      );
    } catch (e) {
      // Handle error
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: const Text('Apply for Loan'),
        backgroundColor: const Color(0xFF1A2744),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Qualification Status
                    _buildQualificationCard(),
                    const SizedBox(height: 24),

                    if (_qualifies) ...[
                      // Loan Amount
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Loan Amount (EMC)',
                          labelStyle: const TextStyle(color: Colors.white54),
                          hintText: 'Max: ${_maxLoanAmount.toStringAsFixed(0)} EMC',
                          hintStyle: const TextStyle(color: Colors.white24),
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: const Color(0xFF1A2744),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an amount';
                          }
                          final amount = double.tryParse(value);
                          if (amount == null || amount <= 0) {
                            return 'Invalid amount';
                          }
                          if (amount > _maxLoanAmount) {
                            return 'Exceeds maximum: ${_maxLoanAmount.toStringAsFixed(0)} EMC';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Term Selection
                      const Text(
                        'Loan Term',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [6, 12, 18, 24].map((months) {
                          final isSelected = _selectedTermMonths == months;
                          return ChoiceChip(
                            label: Text('$months months'),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() => _selectedTermMonths = months);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Purpose
                      TextFormField(
                        controller: _purposeController,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Loan Purpose',
                          labelStyle: TextStyle(color: Colors.white54),
                          hintText: 'e.g., Course fees, equipment purchase',
                          hintStyle: TextStyle(color: Colors.white24),
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Color(0xFF1A2744),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter loan purpose';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Loan Summary
                      _buildLoanSummary(),
                      const SizedBox(height: 24),

                      // Submit Button
                      ElevatedButton(
                        onPressed: _submitLoanApplication,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text('Submit Application', style: TextStyle(fontSize: 16)),
                      ),
                    ] else ...[
                      // Requirements not met
                      _buildRequirementsGuide(),
                    ],

                    const SizedBox(height: 24),

                    // My Loans
                    const Text(
                      'My Loans',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildMyLoans(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildQualificationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _qualifies ? const Color(0xFF10B981).withOpacity(0.1) : const Color(0xFFEF4444).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _qualifies ? const Color(0xFF10B981) : const Color(0xFFEF4444),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _qualifies ? Icons.check_circle : Icons.cancel,
                color: _qualifies ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              ),
              const SizedBox(width: 8),
              Text(
                _qualifies ? 'You Qualify for a Loan!' : 'Not Qualified Yet',
                style: TextStyle(
                  color: _qualifies ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildQualificationRow('GPA', _userGPA.toStringAsFixed(2), _userGPA >= 2.0),
          _buildQualificationRow('KYC Verified', widget.userModel.kycVerified ? 'Yes' : 'No', widget.userModel.kycVerified),
          _buildQualificationRow('Staking Duration', '$_stakingDays days', _stakingDays >= 30),
          if (_qualifies)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Max Loan Amount: ${_maxLoanAmount.toStringAsFixed(0)} EMC',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQualificationRow(String label, String value, bool meets) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54)),
          Row(
            children: [
              Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Icon(
                meets ? Icons.check : Icons.close,
                size: 16,
                color: meets ? Colors.green : Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoanSummary() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final monthlyPayment = LoanModel.calculateMonthlyPayment(amount, 0.08, _selectedTermMonths);
    final totalRepayment = monthlyPayment * _selectedTermMonths;
    final totalInterest = totalRepayment - amount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2744),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Loan Summary',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const Divider(color: Colors.white24),
          _buildSummaryRow('Principal Amount', '${amount.toStringAsFixed(0)} EMC'),
          _buildSummaryRow('Interest Rate', '8% APR'),
          _buildSummaryRow('Term', '$_selectedTermMonths months'),
          _buildSummaryRow('Monthly Payment', '${monthlyPayment.toStringAsFixed(0)} EMC'),
          _buildSummaryRow('Total Interest', '${totalInterest.toStringAsFixed(0)} EMC'),
          const Divider(color: Colors.white24),
          _buildSummaryRow('Total Repayment', '${totalRepayment.toStringAsFixed(0)} EMC', isBold: true),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white54,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementsGuide() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2744),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How to Qualify',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildRequirement('Maintain GPA ≥ 2.0 OR achieve Grade B or better'),
          _buildRequirement('Complete KYC verification'),
          _buildRequirement('Stake EMC for 30+ days OR get lecturer reference'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Navigate to staking page
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)),
            child: const Text('Start Staking to Qualify'),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirement(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.white54, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }

  Widget _buildMyLoans() {
    return StreamBuilder<List<LoanModel>>(
      stream: _loanService.getStudentLoans(widget.userModel.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        final loans = snapshot.data ?? [];

        if (loans.isEmpty) {
          return const Text('No loans yet', style: TextStyle(color: Colors.white54));
        }

        return Column(
          children: loans.map((loan) {
            return Card(
              color: const Color(0xFF1A2744),
              child: ListTile(
                title: Text(
                  '${loan.approvedAmount > 0 ? loan.approvedAmount : loan.requestedAmount} EMC',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  loan.statusDisplay,
                  style: const TextStyle(color: Colors.white54),
                ),
                trailing: loan.status == LoanStatus.active
                    ? ElevatedButton(
                        onPressed: () {
                          // Navigate to payment page
                        },
                        child: const Text('Pay'),
                      )
                    : null,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> _submitLoanApplication() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final amount = double.parse(_amountController.text);

      await _loanService.applyForLoan(
        studentId: widget.userModel.uid,
        studentName: widget.userModel.name,
        requestedAmount: amount,
        termMonths: _selectedTermMonths,
        purpose: _purposeController.text,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loan application submitted successfully!')),
      );

      _amountController.clear();
      _purposeController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
