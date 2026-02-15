import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/scholarship_model.dart';
import '../../models/grade_model.dart';
import '../../services/scholarship_service.dart';

class AdminScholarshipTab extends StatefulWidget {
  const AdminScholarshipTab({super.key});

  @override
  State<AdminScholarshipTab> createState() => _AdminScholarshipTabState();
}

class _AdminScholarshipTabState extends State<AdminScholarshipTab> {
  final ScholarshipService _scholarshipService = ScholarshipService();
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF080C14),
      child: Column(
        children: [
          _buildHeader(),
          _buildFilterTabs(),
          Expanded(
            child: _buildScholarshipsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1120),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.school, color: Colors.amber, size: 28),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scholarship Management',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Manage deposits and graduation processing',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _showCreateScholarshipDialog(),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('New Scholarship'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1120),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildFilterChip('all', 'All'),
          _buildFilterChip('pending', 'Pending Deposit'),
          _buildFilterChip('deposited', 'Active'),
          _buildFilterChip('ready', 'Ready for Graduation'),
          _buildFilterChip('released', 'Released'),
          _buildFilterChip('forfeited', 'Forfeited'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = value;
          });
        },
        selectedColor: Colors.blue,
        backgroundColor: const Color(0xFF1A1F2E),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.white70,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildScholarshipsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _buildQuery(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.white70),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        final scholarships = snapshot.data?.docs ?? [];

        if (scholarships.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.school_outlined,
                  size: 64,
                  color: Colors.white.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No scholarships found',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: scholarships.length,
          itemBuilder: (context, index) {
            final scholarship = ScholarshipModel.fromFirestore(scholarships[index]);
            return _buildScholarshipCard(scholarship);
          },
        );
      },
    );
  }

  Stream<QuerySnapshot> _buildQuery() {
    Query query = FirebaseFirestore.instance.collection('scholarships');

    switch (_selectedFilter) {
      case 'pending':
        query = query.where('depositStatus', isEqualTo: 'pending');
        break;
      case 'deposited':
        query = query.where('depositStatus', isEqualTo: 'deposited')
                     .where('hasGraduated', isEqualTo: false);
        break;
      case 'ready':
        query = query.where('depositStatus', isEqualTo: 'deposited')
                     .where('hasGraduated', isEqualTo: false);
        // Filter in UI for students ready to graduate
        break;
      case 'released':
        query = query.where('depositStatus', isEqualTo: 'released');
        break;
      case 'forfeited':
        query = query.where('depositStatus', isEqualTo: 'forfeited');
        break;
    }

    return query.orderBy('createdAt', descending: true).snapshots();
  }

  Widget _buildScholarshipCard(ScholarshipModel scholarship) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1F2E),
            const Color(0xFF0B1120),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(scholarship.depositStatus).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showScholarshipDetails(scholarship),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.school,
                        color: Colors.amber,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            scholarship.studentName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            scholarship.studentEmail,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(scholarship.depositStatus),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildInfoChip(
                      icon: Icons.style,
                      label: scholarship.typeDisplay,
                      color: Colors.purple,
                    ),
                    _buildInfoChip(
                      icon: Icons.percent,
                      label: '${scholarship.percentage.toStringAsFixed(0)}% Scholarship',
                      color: Colors.blue,
                    ),
                    _buildInfoChip(
                      icon: Icons.attach_money,
                      label: '\$${scholarship.scholarshipAmount.toStringAsFixed(0)}',
                      color: Colors.green,
                    ),
                    if (scholarship.depositRequired > 0)
                      _buildInfoChip(
                        icon: Icons.account_balance_wallet,
                        label: 'Deposit: \$${scholarship.depositRequired.toStringAsFixed(0)}',
                        color: Colors.orange,
                      ),
                  ],
                ),
                if (scholarship.depositRequired > 0) ...[
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: scholarship.depositPaid / scholarship.depositRequired,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      scholarship.depositPaid >= scholarship.depositRequired
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Paid: \$${scholarship.depositPaid.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      Text(
                        'Remaining: \$${scholarship.remainingDeposit.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ],
                if (scholarship.depositStatus == ScholarshipDepositStatus.deposited &&
                    !scholarship.hasGraduated) ...[
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => _showProcessGraduationDialog(scholarship),
                    icon: const Icon(Icons.school, size: 18),
                    label: const Text('Process Graduation'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      minimumSize: const Size(double.infinity, 40),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ScholarshipDepositStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(status),
          width: 1,
        ),
      ),
      child: Text(
        status.toString().split('.').last.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _getStatusColor(status),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ScholarshipDepositStatus status) {
    switch (status) {
      case ScholarshipDepositStatus.pending:
        return Colors.orange;
      case ScholarshipDepositStatus.deposited:
        return Colors.blue;
      case ScholarshipDepositStatus.released:
        return Colors.green;
      case ScholarshipDepositStatus.forfeited:
        return Colors.red;
    }
  }

  void _showScholarshipDetails(ScholarshipModel scholarship) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF0B1120),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.school,
                      color: Colors.amber,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Scholarship Details',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildDetailSection('Student Information', [
                  _buildDetailRow('Name', scholarship.studentName),
                  _buildDetailRow('Email', scholarship.studentEmail),
                ]),
                const SizedBox(height: 16),
                _buildDetailSection('Scholarship Information', [
                  _buildDetailRow('Type', scholarship.typeDisplay),
                  _buildDetailRow('Percentage', '${scholarship.percentage.toStringAsFixed(0)}%'),
                  _buildDetailRow('Original Tuition', '\$${scholarship.originalTuitionFee.toStringAsFixed(2)}'),
                  _buildDetailRow('Scholarship Amount', '\$${scholarship.scholarshipAmount.toStringAsFixed(2)}'),
                ]),
                if (scholarship.depositRequired > 0) ...[
                  const SizedBox(height: 16),
                  _buildDetailSection('Deposit Information', [
                    _buildDetailRow('Deposit Required', '\$${scholarship.depositRequired.toStringAsFixed(2)}'),
                    _buildDetailRow('Deposit Paid', '\$${scholarship.depositPaid.toStringAsFixed(2)}'),
                    _buildDetailRow('Remaining', '\$${scholarship.remainingDeposit.toStringAsFixed(2)}'),
                    _buildDetailRow('Status', scholarship.depositStatus.toString().split('.').last),
                  ]),
                ],
                const SizedBox(height: 16),
                _buildDetailSection('Academic Requirements', [
                  _buildDetailRow('Minimum GPA', scholarship.minimumGradeRequired.toString()),
                  _buildDetailRow('Minimum Grade', scholarship.minimumLetterGrade ?? 'C'),
                  if (scholarship.finalGPA != null)
                    _buildDetailRow('Final GPA', scholarship.finalGPA!.toStringAsFixed(2)),
                ]),
                if (scholarship.hasGraduated) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scholarship.meetsMinimumRequirement
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: scholarship.meetsMinimumRequirement
                            ? Colors.green.withOpacity(0.3)
                            : Colors.red.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              scholarship.meetsMinimumRequirement
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color: scholarship.meetsMinimumRequirement
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              scholarship.meetsMinimumRequirement
                                  ? 'Graduated - Requirements Met'
                                  : 'Graduated - Requirements Not Met',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: scholarship.meetsMinimumRequirement
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ],
                        ),
                        if (scholarship.graduationDate != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Graduation Date: ${DateFormat('MMM d, y').format(scholarship.graduationDate!)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                    if (scholarship.depositStatus == ScholarshipDepositStatus.deposited &&
                        !scholarship.hasGraduated) ...[
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showProcessGraduationDialog(scholarship);
                        },
                        icon: const Icon(Icons.school),
                        label: const Text('Process Graduation'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateScholarshipDialog() {
    // Create scholarship form dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Create scholarship feature - coming soon'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showProcessGraduationDialog(ScholarshipModel scholarship) {
    final gpaController = TextEditingController();
    LetterGrade? selectedGrade;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF0B1120),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.school, color: Colors.blue),
              SizedBox(width: 12),
              Text(
                'Process Graduation',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Student: ${scholarship.studentName}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: gpaController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Final GPA',
                    labelStyle: const TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<LetterGrade>(
                  value: selectedGrade,
                  dropdownColor: const Color(0xFF1A1F2E),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Final Letter Grade',
                    labelStyle: const TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                    ),
                  ),
                  items: LetterGrade.values.map((grade) {
                    return DropdownMenuItem(
                      value: grade,
                      child: Text(grade.toString().split('.').last),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedGrade = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Minimum Requirements:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Minimum GPA: ${scholarship.minimumGradeRequired}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      Text(
                        '• Minimum Grade: ${scholarship.minimumLetterGrade}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Deposit Amount: \$${scholarship.depositPaid.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (gpaController.text.isEmpty || selectedGrade == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in all fields'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final gpa = double.tryParse(gpaController.text);
                if (gpa == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Invalid GPA value'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.pop(context);

                try {
                  await _scholarshipService.processGraduation(
                    scholarshipId: scholarship.id,
                    finalGPA: gpa,
                    finalGrade: selectedGrade!.toString().split('.').last,
                    processedById: 'admin', // TODO: Get actual admin ID
                  );

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Graduation processed successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: const Text('Process'),
            ),
          ],
        ),
      ),
    );
  }
}
