import 'package:flutter/material.dart';
import 'package:cover/core/theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy Policy',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last Updated: ${DateTime.now().toString().split(' ')[0]}',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
            const SizedBox(height: 24),
            _buildSection(
              '1. Introduction',
              'Cover ("we," "our," or "the App") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application. Please read this policy carefully. If you do not agree with the terms of this privacy policy, please do not access the app.',
            ),
            _buildSection(
              '2. Information We Collect',
              'We may collect information about you in a variety of ways. The app collects information that you voluntarily provide to us when you download and use the app, including:\n\n'
              '- Account Information: When you create an account, we may collect your unique device identifier and authentication credentials.\n'
              '- Vault Data: You may store photos, videos, documents, notes, passwords, and contacts within the secure vault. All data is encrypted locally on your device.\n'
              '- Device Information: We may collect information about the mobile device you use to access the app, including the hardware model, operating system version, and unique device identifiers.\n'
              '- Usage Data: We may collect information about how you use the app, such as features you use and actions you take within the app.',
            ),
            _buildSection(
              '3. How We Use Your Information',
              'We use the information we collect in the following ways:\n\n'
              '- To provide, maintain, and improve our services\n'
              '- To process transactions and send you related information\n'
              '- To monitor and analyze trends, usage, and activities\n'
              '- To detect, prevent, and address technical issues\n'
              '- To provide you with personalized content and recommendations\n'
              '- To comply with legal obligations and enforce our agreements',
            ),
            _buildSection(
              '4. Data Security',
              'We value your trust in providing us your Personal Information, thus we are striving to use commercially acceptable means of protecting it. However, please remember that no method of transmission over the Internet or method of electronic storage is 100% secure and reliable, and we cannot guarantee its absolute security.\n\n'
              'All data stored in the vault is encrypted using AES-256-GCM encryption with PBKDF2 key derivation. Your encryption key is stored securely using the device\'s secure storage mechanisms. We do not have access to your vault encryption keys or the content of your vault.',
            ),
            _buildSection(
              '5. Data Retention and Deletion',
              'We retain your Personal Information for as long as necessary to provide our services and fulfill the purposes outlined in this Privacy Policy, unless a longer retention period is required or permitted by law.\n\n'
              'You may request deletion of your account and all associated data at any time. Upon deletion, all data stored in your vault will be permanently removed from your device. Please note that deleted data may persist in backup copies for a limited period.',
            ),
            _buildSection(
              '6. Third-Party Services',
              'We may employ third-party companies and services to facilitate our service, to provide the service on our behalf, to perform service-related services, or to assist us in analyzing how our service is used. These third parties have access to your Personal Information only to perform these tasks on our behalf and are obligated not to disclose or use it for any other purpose.\n\n'
              'We use the following third-party services:\n'
              '- Firebase: For analytics and crash reporting\n'
              '- AdMob: For displaying advertisements\n'
              '- Google Play Billing: For in-app purchases',
            ),
            _buildSection(
              '7. Children\'s Privacy',
              'Our service does not address anyone under the age of 13 ("Children"). We do not knowingly collect personally identifiable information from anyone under the age of 13. If you are a parent or guardian and you are aware that your child has provided us with Personal Information, please contact us.',
            ),
            _buildSection(
              '8. Changes to This Privacy Policy',
              'We may update our Privacy Policy from time to time. Thus, you are advised to review this page periodically for any changes. We will notify you of any changes by posting the new Privacy Policy on this page. These changes are effective immediately after they are posted on this page.',
            ),
            _buildSection(
              '9. Contact Us',
              'If you have any questions or concerns about this Privacy Policy, please contact us at:\n\n'
              'Email: privacy@cover-app.com\n'
              'Website: www.cover-app.com/privacy',
            ),
            const SizedBox(height: 32),
            Text(
              'By using Cover, you agree to this Privacy Policy.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.systemOrange,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            color: Colors.grey.shade300,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
