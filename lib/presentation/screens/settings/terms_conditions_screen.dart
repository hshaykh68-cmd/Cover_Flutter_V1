import 'package:flutter/material.dart';
import 'package:cover/core/theme/app_theme.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Terms & Conditions',
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
              '1. Acceptance of Terms',
              'By downloading, accessing, or using the Cover mobile application ("the App"), you agree to be bound by these Terms & Conditions ("Terms"). If you do not agree to these Terms, please do not use the App. These Terms constitute a legally binding agreement between you and Cover ("we," "us," or "our").',
            ),
            _buildSection(
              '2. Description of Service',
              'Cover is a privacy-focused vault application that allows users to securely store photos, videos, documents, notes, passwords, and contacts. The App disguises itself as a calculator to provide discretion. All data is encrypted locally on your device using military-grade encryption.',
            ),
            _buildSection(
              '3. User Responsibilities',
              'As a user of the App, you agree to:\n\n'
              '- Provide accurate and current information\n'
              '- Maintain the security of your account credentials\n'
              '- Accept responsibility for all activities under your account\n'
              '- Comply with all applicable laws and regulations\n'
              '- Not use the App for any illegal or unauthorized purpose\n'
              '- Not attempt to reverse engineer, decompile, or disassemble the App\n'
              '- Not interfere with or disrupt the App or servers',
            ),
            _buildSection(
              '4. Security and Data Protection',
              'We implement industry-standard security measures to protect your data. However, you acknowledge that:\n\n'
              '- You are solely responsible for maintaining the confidentiality of your PIN and biometric authentication\n'
              '- We cannot guarantee absolute security of data transmitted over the internet\n'
              '- You should not share your vault PIN with anyone\n'
              '- Loss of your PIN may result in permanent loss of access to your vault data\n'
              '- We do not store your vault encryption keys and cannot recover your data if you forget your PIN',
            ),
            _buildSection(
              '5. Intellectual Property Rights',
              'The App and its original content, features, and functionality are and will remain the exclusive property of Cover and its licensors. The App is protected by copyright, trademark, and other laws of both the United States and foreign countries.\n\n'
              'You may not:\n'
              '- Modify, copy, adapt, reproduce, or distribute the App\n'
              '- Remove any copyright or other proprietary notices\n'
              '- Create derivative works based on the App\n'
              '- Use the App for commercial purposes without authorization',
            ),
            _buildSection(
              '6. Paid Services',
              'The App may offer premium features and subscriptions through in-app purchases. By making a purchase, you agree to pay the applicable fees and charges. All fees are non-refundable except as required by law or as otherwise stated in our refund policy.\n\n'
              'We reserve the right to modify pricing at any time. Any changes will be effective immediately upon posting to the App.',
            ),
            _buildSection(
              '7. Termination',
              'We may terminate or suspend your account and access to the App at any time, without prior notice, for any reason, including but not limited to:\n\n'
              '- Violation of these Terms\n'
              '- Fraudulent or illegal activity\n'
              '- Extended period of inactivity\n'
              '- Technical issues or security concerns\n\n'
              'Upon termination, your right to use the App will immediately cease. All provisions of the Terms which by their nature should survive termination shall survive, including ownership provisions, warranty disclaimers, and limitations of liability.',
            ),
            _buildSection(
              '8. Limitation of Liability',
              'To the maximum extent permitted by applicable law, Cover shall not be liable for any indirect, incidental, special, consequential, or punitive damages, including but not limited to loss of data, profits, goodwill, or other intangible losses, resulting from:\n\n'
              '- Your access to or use of or inability to access or use the App\n'
              '- Any conduct or content of any third party on the App\n'
              '- Any content obtained from the App\n'
              '- Unauthorized access, use, or alteration of your transmissions or content\n\n'
              'In no event shall Cover\'s total liability to you for all claims exceed the amount you paid, if any, for using the App.',
            ),
            _buildSection(
              '9. Disclaimer of Warranties',
              'The App is provided "as is" and "as available" without warranties of any kind, either express or implied, including but not limited to implied warranties of merchantability, fitness for a particular purpose, title, and non-infringement.\n\n'
              'We do not warrant that the App will function uninterrupted, secure, or error-free, that defects will be corrected, or that the App or the server that makes it available are free of viruses or other harmful components.',
            ),
            _buildSection(
              '10. Governing Law',
              'These Terms shall be governed by and construed in accordance with the laws of the United States, without regard to its conflict of law provisions. Any disputes arising under these Terms shall be subject to the exclusive jurisdiction of the courts located in the United States.',
            ),
            _buildSection(
              '11. Indemnification',
              'You agree to indemnify, defend, and hold harmless Cover and its affiliates, officers, directors, employees, agents, licensors, and suppliers from and against all claims, damages, obligations, losses, liabilities, costs, or debt, and expenses (including but not limited to attorney\'s fees) resulting from or arising out of your use of the App or violation of these Terms.',
            ),
            _buildSection(
              '12. Changes to Terms',
              'We reserve the right to modify these Terms at any time. All changes are effective immediately when we post them. Your continued use of the App following the posting of revised Terms means that you accept and agree to the changes.',
            ),
            _buildSection(
              '13. Contact Information',
              'If you have any questions about these Terms, please contact us:\n\n'
              'Email: legal@cover-app.com\n'
              'Website: www.cover-app.com/terms',
            ),
            const SizedBox(height: 32),
            Text(
              'By using Cover, you acknowledge that you have read, understood, and agree to be bound by these Terms & Conditions.',
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
