import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/certificate_model.dart';
import '../../models/user_model.dart';
import '../../services/certificate_service.dart';

class MyCertificatesPage extends StatefulWidget {
  final UserModel userModel;

  const MyCertificatesPage({super.key, required this.userModel});

  @override
  State<MyCertificatesPage> createState() => _MyCertificatesPageState();
}

class _MyCertificatesPageState extends State<MyCertificatesPage> {
  final CertificateService _certificateService = CertificateService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080C14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1120),
        elevation: 0,
        title: const Text(
          'My Certificates',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: StreamBuilder<List<CertificateModel>>(
        stream: _certificateService.getStudentCertificates(widget.userModel.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading certificates',
                style: TextStyle(color: Colors.red[300]),
              ),
            );
          }

          final certificates = snapshot.data ?? [];

          if (certificates.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.workspace_premium, size: 80, color: Colors.white24),
                  const SizedBox(height: 16),
                  const Text(
                    'No Certificates Yet',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Complete courses to earn certificates',
                    style: TextStyle(color: Colors.white38, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: certificates.length,
            itemBuilder: (context, index) {
              final cert = certificates[index];
              return _CertificateCard(
                certificate: cert,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CertificateViewerPage(certificate: cert),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _CertificateCard extends StatelessWidget {
  final CertificateModel certificate;
  final VoidCallback onTap;

  const _CertificateCard({
    required this.certificate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A2744),
            const Color(0xFF0F1B30),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: certificate.isValid ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Certificate icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: certificate.isValid 
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    certificate.isValid ? Icons.workspace_premium : Icons.cancel,
                    color: certificate.isValid ? Colors.green : Colors.red,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                // Certificate details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        certificate.courseName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _InfoChip(
                            icon: Icons.grade,
                            label: 'Grade ${certificate.grade}',
                          ),
                          const SizedBox(width: 8),
                          _InfoChip(
                            icon: Icons.calendar_today,
                            label: DateFormat('MMM yyyy').format(certificate.completionDate),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        certificate.certificateNumber,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: certificate.isValid 
                        ? Colors.green.withOpacity(0.2)
                        : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    certificate.statusDisplay,
                    style: TextStyle(
                      color: certificate.isValid ? Colors.green : Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white54),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// CERTIFICATE VIEWER PAGE - Full certificate view with download
// ═══════════════════════════════════════════════════════════════════

class CertificateViewerPage extends StatelessWidget {
  final CertificateModel certificate;

  const CertificateViewerPage({super.key, required this.certificate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080C14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1120),
        elevation: 0,
        title: const Text('Certificate'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Download PDF',
            onPressed: () {
              // TODO: Implement PDF download
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PDF download coming soon!')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share',
            onPressed: () {
              // TODO: Implement sharing
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Share link: ${certificate.verificationUrl}'),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Certificate Design
            _CertificateDesign(certificate: certificate),
            const SizedBox(height: 32),
            // QR Code Section
            _buildQRCodeSection(),
            const SizedBox(height: 24),
            // Certificate Details
            _buildDetailsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildQRCodeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2744),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          const Text(
            'Scan to Verify',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: QrImageView(
              data: certificate.qrCodeData,
              version: QrVersions.auto,
              size: 200,
            ),
          ),
          const SizedBox(height: 12),
          SelectableText(
            certificate.verificationUrl,
            style: const TextStyle(
              color: Colors.blue,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2744),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Certificate Details',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _DetailRow('Certificate Number', certificate.certificateNumber),
          _DetailRow('Student Name', certificate.studentName),
          _DetailRow('Course', certificate.courseName),
          _DetailRow('Grade', certificate.grade),
          _DetailRow('GPA', certificate.gpa.toStringAsFixed(2)),
          _DetailRow('Completion Date', DateFormat('MMMM dd, yyyy').format(certificate.completionDate)),
          _DetailRow('Issued By', certificate.issuedByName),
          _DetailRow('Issued Date', DateFormat('MMMM dd, yyyy').format(certificate.issuedAt)),
          _DetailRow('Status', certificate.statusDisplay),
          if (certificate.remarks != null) 
            _DetailRow('Remarks', certificate.remarks!),
        ],
      ),
    );
  }

  Widget _DetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// CERTIFICATE DESIGN - Beautiful diploma-style certificate
// ═══════════════════════════════════════════════════════════════════

class _CertificateDesign extends StatelessWidget {
  final CertificateModel certificate;

  const _CertificateDesign({required this.certificate});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFF5), Color(0xFFFFF8DC)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: const Color(0xFFD4AF37), width: 4),
      ),
      child: Column(
        children: [
          // Header
          const Icon(
            Icons.school,
            size: 48,
            color: Color(0xFFD4AF37),
          ),
          const SizedBox(height: 8),
          const Text(
            'EMTECH SCHOOL',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Certificate of Completion',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF666666),
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 24),
          // Decorative line
          Container(
            width: 100,
            height: 2,
            color: const Color(0xFFD4AF37),
          ),
          const SizedBox(height: 24),
          // Main text
          const Text(
            'This is to certify that',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            certificate.studentName,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
              fontFamily: 'serif',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'has successfully completed the course',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            certificate.courseName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'with a grade of ${certificate.grade}',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 24),
          // Date and signatures
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Container(
                    width: 120,
                    height: 1,
                    color: const Color(0xFF666666),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMMM dd, yyyy').format(certificate.completionDate),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF666666),
                    ),
                  ),
                  const Text(
                    'Date',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF999999),
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Container(
                    width: 120,
                    height: 1,
                    color: const Color(0xFF666666),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    certificate.issuedByName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF666666),
                    ),
                  ),
                  const Text(
                    'Authorized Signature',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF999999),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Certificate number
          Text(
            'Certificate No: ${certificate.certificateNumber}',
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF999999),
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
