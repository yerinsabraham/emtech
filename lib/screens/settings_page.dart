import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _darkModeEnabled = true;
  bool _autoPlayVideos = false;
  String _language = 'English';
  String _downloadQuality = 'High (720p)';
  bool _privacyShowActivity = true;
  bool _privacyAllowAnalytics = true;
  bool _privacyPersonalisedContent = true;

  static const String _keyNotifications = 'settings_notifications';
  static const String _keyEmailNotif = 'settings_email_notif';
  static const String _keyPushNotif = 'settings_push_notif';
  static const String _keyAutoPlay = 'settings_autoplay';
  static const String _keyLanguage = 'settings_language';
  static const String _keyDownloadQuality = 'settings_download_quality';
  static const String _keyPrivacyActivity = 'settings_privacy_activity';
  static const String _keyPrivacyAnalytics = 'settings_privacy_analytics';
  static const String _keyPrivacyPersonalised = 'settings_privacy_personalised';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = prefs.getBool(_keyNotifications) ?? true;
      _emailNotifications = prefs.getBool(_keyEmailNotif) ?? true;
      _pushNotifications = prefs.getBool(_keyPushNotif) ?? true;
      _autoPlayVideos = prefs.getBool(_keyAutoPlay) ?? false;
      _language = prefs.getString(_keyLanguage) ?? 'English';
      _downloadQuality = prefs.getString(_keyDownloadQuality) ?? 'High (720p)';
      _privacyShowActivity = prefs.getBool(_keyPrivacyActivity) ?? true;
      _privacyAllowAnalytics = prefs.getBool(_keyPrivacyAnalytics) ?? true;
      _privacyPersonalisedContent = prefs.getBool(_keyPrivacyPersonalised) ?? true;
    });
  }

  Future<void> _savePref(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) await prefs.setBool(key, value);
    if (value is String) await prefs.setString(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final userModel = authService.userModel;

    return Scaffold(
      backgroundColor: const Color(0xFF080C14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1120),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Account Section
              _buildSectionHeader('Account'),
              _buildSettingsTile(
                icon: Icons.person_outline,
                title: 'Profile Information',
                subtitle: userModel?.email ?? 'Not logged in',
                onTap: () {
                  Navigator.pushNamed(context, '/edit-profile');
                },
              ),
              _buildSettingsTile(
                icon: Icons.lock_outline,
                title: 'Change Password',
                subtitle: 'Update your password',
                onTap: () {
                  _showChangePasswordDialog();
                },
              ),
              _buildSettingsTile(
                icon: Icons.security_outlined,
                title: 'Privacy & Security',
                subtitle: 'Manage data and security settings',
                onTap: () => _showPrivacySheet(),
              ),

              const SizedBox(height: 24),

              // Notifications Section
              _buildSectionHeader('Notifications'),
              _buildSwitchTile(
                icon: Icons.notifications_outlined,
                title: 'Enable Notifications',
                subtitle: 'Receive notifications from the app',
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() => _notificationsEnabled = value);
                  _savePref(_keyNotifications, value);
                },
              ),
              if (_notificationsEnabled) ...[
                _buildSwitchTile(
                  icon: Icons.email_outlined,
                  title: 'Email Notifications',
                  subtitle: 'Receive updates via email',
                  value: _emailNotifications,
                  onChanged: (value) {
                    setState(() => _emailNotifications = value);
                    _savePref(_keyEmailNotif, value);
                  },
                ),
                _buildSwitchTile(
                  icon: Icons.phone_android_outlined,
                  title: 'Push Notifications',
                  subtitle: 'Receive push notifications',
                  value: _pushNotifications,
                  onChanged: (value) {
                    setState(() => _pushNotifications = value);
                    _savePref(_keyPushNotif, value);
                  },
                ),
              ],

              const SizedBox(height: 24),

              // Appearance Section
              _buildSectionHeader('Appearance'),
              _buildSwitchTile(
                icon: Icons.dark_mode_outlined,
                title: 'Dark Mode',
                subtitle: 'Use dark theme (always on)',
                value: _darkModeEnabled,
                onChanged: (value) {
                  setState(() => _darkModeEnabled = value);
                  _savePref('settings_dark_mode', value);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Theme setting saved!')),
                  );
                },
              ),
              _buildSettingsTile(
                icon: Icons.language_outlined,
                title: 'Language',
                subtitle: _language,
                onTap: () {
                  _showLanguageDialog();
                },
              ),

              const SizedBox(height: 24),

              // Content & Media Section
              _buildSectionHeader('Content & Media'),
              _buildSwitchTile(
                icon: Icons.play_circle_outline,
                title: 'Auto-play Videos',
                subtitle: 'Automatically play course videos',
                value: _autoPlayVideos,
                onChanged: (value) {
                  setState(() => _autoPlayVideos = value);
                  _savePref(_keyAutoPlay, value);
                },
              ),
              _buildSettingsTile(
                icon: Icons.download_outlined,
                title: 'Download Quality',
                subtitle: _downloadQuality,
                onTap: () => _showDownloadQualityDialog(),
              ),

              const SizedBox(height: 24),

              // Support Section
              _buildSectionHeader('Support'),
              _buildSettingsTile(
                icon: Icons.help_outline,
                title: 'Help Center',
                subtitle: 'Get help and support',
                onTap: () {
                  Navigator.pushNamed(context, '/support');
                },
              ),
              _buildSettingsTile(
                icon: Icons.bug_report_outlined,
                title: 'Report a Problem',
                subtitle: 'Send feedback or report issues',
                onTap: () => _showReportDialog(),
              ),
              _buildSettingsTile(
                icon: Icons.info_outline,
                title: 'About',
                subtitle: 'App version 1.0.0',
                onTap: () {
                  _showAboutDialog();
                },
              ),

              const SizedBox(height: 32),

              // Danger Zone
              _buildSectionHeader('Danger Zone', color: Colors.red),
              _buildSettingsTile(
                icon: Icons.delete_forever_outlined,
                title: 'Delete Account',
                subtitle: 'Permanently delete your account',
                onTap: () {
                  _showDeleteAccountDialog();
                },
                isDestructive: true,
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          color: color ?? Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF111C2F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E2D4A), width: 0.5),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive ? Colors.red : Colors.white54,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive ? Colors.red : Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isDestructive ? Colors.red.withOpacity(0.7) : Colors.white54,
            fontSize: 12,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: isDestructive ? Colors.red : Colors.white24,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF111C2F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E2D4A), width: 0.5),
      ),
      child: SwitchListTile(
        secondary: Icon(icon, color: Colors.white54),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF3B82F6),
      ),
    );
  }

  void _showPrivacySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111C2F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Privacy & Security',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Control how your data is used in the app.',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 20),
              _buildSheetSwitch(
                setSheet,
                title: 'Show Activity Status',
                subtitle: 'Let others see when you were last active',
                value: _privacyShowActivity,
                onChanged: (v) {
                  setState(() => _privacyShowActivity = v);
                  setSheet(() {});
                  _savePref(_keyPrivacyActivity, v);
                },
              ),
              const SizedBox(height: 8),
              _buildSheetSwitch(
                setSheet,
                title: 'Analytics & Crash Reports',
                subtitle: 'Help improve the app by sharing anonymous usage data',
                value: _privacyAllowAnalytics,
                onChanged: (v) {
                  setState(() => _privacyAllowAnalytics = v);
                  setSheet(() {});
                  _savePref(_keyPrivacyAnalytics, v);
                },
              ),
              const SizedBox(height: 8),
              _buildSheetSwitch(
                setSheet,
                title: 'Personalised Content',
                subtitle: 'Tailor course and content recommendations to you',
                value: _privacyPersonalisedContent,
                onChanged: (v) {
                  setState(() => _privacyPersonalisedContent = v);
                  setSheet(() {});
                  _savePref(_keyPrivacyPersonalised, v);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSheetSwitch(
    StateSetter setSheet, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B1120),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E2D4A), width: 0.5),
      ),
      child: SwitchListTile(
        title: Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle,
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF3B82F6),
      ),
    );
  }

  void _showDownloadQualityDialog() {
    const qualities = [
      ('Low (360p)', 'Saves mobile data'),
      ('Medium (480p)', 'Balanced quality'),
      ('High (720p)', 'Recommended'),
      ('HD (1080p)', 'Best quality, uses more storage'),
    ];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111C2F),
        title: const Text('Download Quality',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: qualities
              .map((q) => RadioListTile<String>(
                    title: Text(q.$1,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 14)),
                    subtitle: Text(q.$2,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12)),
                    value: q.$1,
                    groupValue: _downloadQuality,
                    activeColor: const Color(0xFF3B82F6),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _downloadQuality = v);
                      _savePref(_keyDownloadQuality, v);
                      Navigator.pop(ctx);
                    },
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog() {
    final subjectController = TextEditingController();
    final messageController = TextEditingController();
    String selectedType = 'Bug';
    bool isSubmitting = false;
    final types = ['Bug', 'Feature Request', 'Content Issue', 'Account Issue', 'Other'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          backgroundColor: const Color(0xFF111C2F),
          title: const Text('Report a Problem',
              style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Type',
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  dropdownColor: const Color(0xFF0B1120),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Color(0xFF0B1120),
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: types
                      .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t,
                              style:
                                  const TextStyle(color: Colors.white))))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialog(() => selectedType = v);
                  },
                ),
                const SizedBox(height: 12),
                const Text('Subject',
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 6),
                TextField(
                  controller: subjectController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Brief description',
                    hintStyle: TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Color(0xFF0B1120),
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Details',
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 6),
                TextField(
                  controller: messageController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Describe the issue in detail…',
                    hintStyle: TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Color(0xFF0B1120),
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6)),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final subject = subjectController.text.trim();
                      final message = messageController.text.trim();
                      if (subject.isEmpty || message.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Please fill in all fields'),
                              backgroundColor: Colors.red),
                        );
                        return;
                      }
                      setDialog(() => isSubmitting = true);
                      try {
                        final user = FirebaseAuth.instance.currentUser;
                        await FirebaseFirestore.instance
                            .collection('supportTickets')
                            .add({
                          'userId': user?.uid ?? 'anonymous',
                          'userName': user?.displayName ?? 'Unknown',
                          'email': user?.email ?? '',
                          'type': selectedType,
                          'subject': subject,
                          'message': message,
                          'status': 'open',
                          'source': 'settings',
                          'createdAt': FieldValue.serverTimestamp(),
                        });
                        if (mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Report submitted. We\'ll look into it!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Failed to submit: $e'),
                                backgroundColor: Colors.red),
                          );
                        }
                      } finally {
                        setDialog(() => isSubmitting = false);
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF111C2F),
          title: const Text('Change Password', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  labelStyle: TextStyle(color: Colors.white54),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  labelStyle: TextStyle(color: Colors.white54),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  labelStyle: TextStyle(color: Colors.white54),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      final current = currentPasswordController.text.trim();
                      final newPass = newPasswordController.text.trim();
                      final confirm = confirmPasswordController.text.trim();

                      if (newPass != confirm) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Passwords do not match'), backgroundColor: Colors.red),
                        );
                        return;
                      }
                      if (newPass.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Password must be at least 6 characters'), backgroundColor: Colors.red),
                        );
                        return;
                      }

                      setDialogState(() => isLoading = true);
                      try {
                        final user = FirebaseAuth.instance.currentUser!;
                        final cred = EmailAuthProvider.credential(
                          email: user.email!,
                          password: current,
                        );
                        await user.reauthenticateWithCredential(cred);
                        await user.updatePassword(newPass);
                        if (mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Password changed successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } on FirebaseAuthException catch (e) {
                        final msg = e.code == 'wrong-password'
                            ? 'Current password is incorrect'
                            : e.message ?? 'Failed to change password';
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(msg), backgroundColor: Colors.red),
                          );
                        }
                      } finally {
                        setDialogState(() => isLoading = false);
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Change'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111C2F),
        title: const Text('Select Language', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption('English'),
            _buildLanguageOption('French'),
            _buildLanguageOption('Spanish'),
            _buildLanguageOption('German'),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String language) {
    return ListTile(
      title: Text(language, style: const TextStyle(color: Colors.white)),
      trailing: _language == language
          ? const Icon(Icons.check, color: Color(0xFF3B82F6))
          : null,
      onTap: () {
        setState(() => _language = language);
        _savePref(_keyLanguage, language);
        Navigator.pop(context);
      },
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111C2F),
        title: const Text('About EMTech School', style: TextStyle(color: Colors.white)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: 1.0.0', style: TextStyle(color: Colors.white)),
            SizedBox(height: 8),
            Text(
              'EMTech School is a modern online learning platform with blockchain-powered certificates and rewards.',
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 16),
            Text('© 2026 EMTech School', style: TextStyle(color: Colors.white54)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    final passwordController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF111C2F),
          title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This action is permanent and cannot be undone. All your data (profile, enrollments, EMC tokens) will be deleted.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              const Text('Enter your password to confirm:', style: TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(color: Colors.white54),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: isLoading
                  ? null
                  : () async {
                      setDialogState(() => isLoading = true);
                      try {
                        final user = FirebaseAuth.instance.currentUser!;
                        final cred = EmailAuthProvider.credential(
                          email: user.email!,
                          password: passwordController.text.trim(),
                        );
                        await user.reauthenticateWithCredential(cred);
                        // Delete Firestore data
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .delete();
                        // Delete Auth account
                        await user.delete();
                        if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
                      } on FirebaseAuthException catch (e) {
                        final msg = e.code == 'wrong-password'
                            ? 'Incorrect password'
                            : e.message ?? 'Failed to delete account';
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(msg), backgroundColor: Colors.red),
                          );
                        }
                      } finally {
                        setDialogState(() => isLoading = false);
                      }
                    },
              child: isLoading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Delete Forever'),
            ),
          ],
        ),
      ),
    );
  }
}
