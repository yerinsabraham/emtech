import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/certificate_model.dart';
import '../services/certificate_service.dart';

class CertificateVerificationPage extends StatefulWidget {
  final String? certificateNumber; // Pre-filled if coming from QR scan

  const CertificateVerificationPage({super.key, this.certificateNumber});

  @override
  State<CertificateVerificationPage> createState() => _CertificateVerificationPageState();
}

class _CertificateVerificationPageState extends State<CertificateVerificationPage> {
  final _formKey = GlobalKey<FormState>();
  final _certificateNumberController = TextEditingController();
  final CertificateService _certificateService = CertificateService();
  
  bool _isLoading = false;
  CertificateModel? _certificate;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.certificateNumber != null) {
      _certificateNumberController.text = widget.certificateNumber!;
      _verifyCertificate();
    }
  }

  @override
  void dispose() {
    _certificateNumberController.dispose();
    super.dispose();
  }

  Future<void> _verifyCertificate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _certificate = null;
    });

    try {
      final cert = await _certificateService.verifyCertificate(
        _certificateNumberController.text.trim(),
      );

      setState(() {
        _certificate = cert;
        if (cert == null) {
          _errorMessage = 'Certificate not found. Please check the certificate number.';
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error verifying certificate: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080C14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1120),
        elevation: 0,
        title: const Text('Verify Certificate'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Icon(
              Icons.verified_user,
              size: 64,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            const Text(
              'Certificate Verification',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter the certificate number to verify its authenticity',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),

            // Verification Form
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _certificateNumberController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Certificate Number',
                      hintText: 'EMC-2026-XXXXXX-XXXX-XXXXXX',
                      prefixIcon: const Icon(Icons.numbers, color: Colors.white54),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.blue),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a certificate number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _verifyCertificate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Verify Certificate',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Error Message
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Certificate Result
            if (_certificate != null) ...[
              _buildVerificationResult(_certificate!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationResult(CertificateModel certificate) {
    final isValid = certificate.status == CertificateStatus.issued;

    return Column(
      children: [
        // Status Banner
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isValid
                  ? [Colors.green.shade700, Colors.green.shade900]
                  : [Colors.red.shade700, Colors.red.shade900],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                isValid ? Icons.check_circle : Icons.cancel,
                color: Colors.white,
                size: 48,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isValid ? 'Valid Certificate' : 'Invalid Certificate',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isValid
                          ? 'This certificate has been verified.'
                          : 'This certificate has been revoked.',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Certificate Details Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A2744), Color(0xFF0F1B30)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isValid ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Certificate Information',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildInfoRow('Certificate Number', certificate.certificateNumber),
              _buildInfoRow('Student Name', certificate.studentName),
              _buildInfoRow('Course', certificate.courseName),
              _buildInfoRow('Grade', certificate.grade),
              _buildInfoRow('GPA', certificate.gpa.toStringAsFixed(2)),
              _buildInfoRow(
                'Completion Date',
                DateFormat('MMMM dd, yyyy').format(certificate.completionDate),
              ),
              _buildInfoRow('Semester', certificate.semester),
              _buildInfoRow('Issued By', certificate.issuedByName),
              _buildInfoRow(
                'Issue Date',
                DateFormat('MMMM dd, yyyy').format(certificate.issuedAt),
              ),
              _buildInfoRow('Type', certificate.typeDisplay),
              _buildInfoRow('Status', certificate.statusDisplay),
              
              if (certificate.status == CertificateStatus.revoked) ...[
                const Divider(color: Colors.white24, height: 32),
                const Text(
                  'Revocation Details',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (certificate.revokedAt != null)
                  _buildInfoRow(
                    'Revoked On',
                    DateFormat('MMMM dd, yyyy').format(certificate.revokedAt!),
                  ),
                if (certificate.revocationReason != null)
                  _buildInfoRow('Reason', certificate.revocationReason!),
              ],

              if (certificate.remarks != null) ...[
                const Divider(color: Colors.white24, height: 32),
                _buildInfoRow('Remarks', certificate.remarks!),
              ],
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Trust Indicators
        if (isValid) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info, color: Colors.blue),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'This certificate is issued by Emtech School and can be independently verified using the certificate number.',
                    style: TextStyle(color: Colors.blue, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
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
