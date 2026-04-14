import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cover/core/theme/app_theme.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:go_router/go_router.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = 'Loading...';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _version = info.version;
      _buildNumber = info.buildNumber;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('About'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 32),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.systemOrange,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                CupertinoIcons.lock,
                size: 64,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Cover',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Version $_version ($_buildNumber)',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            _buildInfoCard(
              'Secure Vault',
              'Military-grade encryption for your photos, videos, documents, notes, passwords, and contacts.',
              CupertinoIcons.shield,
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              'Discreet Design',
              'Disguises as a calculator to protect your privacy from prying eyes.',
              CupertinoIcons.eye_slash,
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              'Biometric Support',
              'Secure authentication with fingerprint and face recognition.',
              CupertinoIcons.hand_draw,
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              'Intruder Detection',
              'Automatically captures photos of unauthorized access attempts.',
              CupertinoIcons.camera,
            ),
            const SizedBox(height: 32),
            const Divider(color: Colors.grey),
            const SizedBox(height: 32),
            _buildLinkRow(
              'Privacy Policy',
              'View our privacy policy',
              CupertinoIcons.doc_text,
              () {
                context.push('/vault/settings/privacy-policy');
              },
            ),
            const SizedBox(height: 16),
            _buildLinkRow(
              'Terms & Conditions',
              'View our terms and conditions',
              CupertinoIcons.gavel,
              () {
                context.push('/vault/settings/terms');
              },
            ),
            const SizedBox(height: 16),
            _buildLinkRow(
              'Website',
              'Visit our website',
              CupertinoIcons.globe,
              () {
                // Launch website
              },
            ),
            const SizedBox(height: 16),
            _buildLinkRow(
              'Support',
              'Get help and support',
              CupertinoIcons.question_circle,
              () {
                // Launch support
              },
            ),
            const SizedBox(height: 32),
            Text(
              '© 2024 Cover. All rights reserved.',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Made with ❤️ for privacy',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String description, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.systemOrange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppTheme.systemOrange,
              size: 24,
            ),
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
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkRow(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppTheme.systemOrange,
              size: 24,
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
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_forward,
              color: Colors.grey.shade600,
            ),
          ],
        ),
      ),
    );
  }
}
