import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/certificate_model.dart';
import '../../services/certificate_service.dart';

class LecturerCertificatesTab extends StatefulWidget {
  const LecturerCertificatesTab({super.key});

  @override
  State<LecturerCertificatesTab> createState() => _LecturerCertificatesTabState();
}

class _LecturerCertificatesTabState extends State<LecturerCertificatesTab> {
  final CertificateService _certificateService = CertificateService();
  String _selectedCourseFilter = 'all';
  String _selectedStatusFilter = 'all';
  
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser == null) {
      return const Center(
        child: Text(
          'Please log in to view certificates',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return Container(
      color: const Color(0xFF080C14),
      child: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: _buildCertificatesList(currentUser.uid),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
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
          Expanded(
            child: _buildCourseFilter(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatusFilter(),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseFilter() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('courses')
          .where('lecturerId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final courses = snapshot.data?.docs ?? [];
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F2E),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCourseFilter,
              dropdownColor: const Color(0xFF1A1F2E),
              isExpanded: true,
              style: const TextStyle(color: Colors.white),
              onChanged: (value) {
                setState(() {
                  _selectedCourseFilter = value ?? 'all';
                });
              },
              items: [
                const DropdownMenuItem(
                  value: 'all',
                  child: Text('All Courses'),
                ),
                ...courses.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return DropdownMenuItem(
                    value: doc.id,
                    child: Text(data['title'] ?? 'Unknown Course'),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedStatusFilter,
          dropdownColor: const Color(0xFF1A1F2E),
          isExpanded: true,
          style: const TextStyle(color: Colors.white),
          onChanged: (value) {
            setState(() {
              _selectedStatusFilter = value ?? 'all';
            });
          },
          items: const [
            DropdownMenuItem(value: 'all', child: Text('All Status')),
            DropdownMenuItem(value: 'issued', child: Text('Issued')),
            DropdownMenuItem(value: 'revoked', child: Text('Revoked')),
            DropdownMenuItem(value: 'pending', child: Text('Pending')),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificatesList(String lecturerId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _buildQuery(lecturerId),
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

        final certificates = snapshot.data?.docs ?? [];

        if (certificates.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.workspace_premium_outlined,
                  size: 64,
                  color: Colors.white.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No certificates found',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Certificates will appear here when students complete your courses',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: certificates.length,
          itemBuilder: (context, index) {
            final cert = CertificateModel.fromFirestore(certificates[index]);
            return _buildCertificateCard(cert);
          },
        );
      },
    );
  }

  Stream<QuerySnapshot> _buildQuery(String lecturerId) {
    Query query = FirebaseFirestore.instance
        .collection('certificates')
        .where('issuedBy', isEqualTo: lecturerId);

    if (_selectedCourseFilter != 'all') {
      query = query.where('courseId', isEqualTo: _selectedCourseFilter);
    }

    if (_selectedStatusFilter != 'all') {
      query = query.where('status', isEqualTo: _selectedStatusFilter);
    }

    return query.orderBy('issuedAt', descending: true).snapshots();
  }

  Widget _buildCertificateCard(CertificateModel certificate) {
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
          color: _getStatusColor(certificate.status).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showCertificateDetails(certificate),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getStatusColor(certificate.status).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getStatusIcon(certificate.status),
                        color: _getStatusColor(certificate.status),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            certificate.studentName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            certificate.courseName,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(certificate.status),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(
                  color: Colors.white.withOpacity(0.1),
                  height: 1,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildInfoChip(
                      icon: Icons.grade,
                      label: 'Grade: ${certificate.grade}',
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    _buildInfoChip(
                      icon: Icons.stars,
                      label: 'GPA: ${certificate.gpa.toStringAsFixed(1)}',
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 8),
                    _buildInfoChip(
                      icon: Icons.calendar_today,
                      label: DateFormat('MMM d, y').format(certificate.issuedAt),
                      color: Colors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Certificate #: ${certificate.certificateNumber}',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: Colors.white.withOpacity(0.5),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(CertificateStatus status) {
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
          fontSize: 12,
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

  Color _getStatusColor(CertificateStatus status) {
    switch (status) {
      case CertificateStatus.issued:
        return Colors.green;
      case CertificateStatus.revoked:
        return Colors.red;
      case CertificateStatus.pending:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(CertificateStatus status) {
    switch (status) {
      case CertificateStatus.issued:
        return Icons.verified;
      case CertificateStatus.revoked:
        return Icons.cancel;
      case CertificateStatus.pending:
        return Icons.pending;
    }
  }

  void _showCertificateDetails(CertificateModel certificate) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF0B1120),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.workspace_premium,
                    color: _getStatusColor(certificate.status),
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Certificate Details',
                      style: const TextStyle(
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
              _buildDetailRow('Student', certificate.studentName),
              _buildDetailRow('Email', certificate.studentEmail),
              _buildDetailRow('Course', certificate.courseName),
              _buildDetailRow('Semester', certificate.semester),
              _buildDetailRow('Grade', certificate.grade),
              _buildDetailRow('GPA', certificate.gpa.toStringAsFixed(2)),
              _buildDetailRow('Certificate Number', certificate.certificateNumber),
              _buildDetailRow('Type', certificate.type.toString().split('.').last),
              _buildDetailRow('Status', certificate.statusDisplay),
              _buildDetailRow('Issued At', DateFormat('MMM d, y - h:mm a').format(certificate.issuedAt)),
              _buildDetailRow('Completion Date', DateFormat('MMM d, y').format(certificate.completionDate)),
              
                if (certificate.status == CertificateStatus.revoked && certificate.revocationReason != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Revocation Details',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Reason: ${certificate.revocationReason}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      if (certificate.revokedAt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Revoked At: ${DateFormat('MMM d, y - h:mm a').format(certificate.revokedAt!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.6),
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
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _copyVerificationUrl(certificate.certificateNumber);
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy Verification URL'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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

  void _copyVerificationUrl(String certificateNumber) {
    final url = 'https://emtech.school/verify-certificate/$certificateNumber';
    // In a real app, use clipboard package to copy
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Verification URL copied: $url'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
