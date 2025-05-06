import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms and Conditions')),
      body: Markdown(
        data: '''
**Last Updated:** 24th April 2025

## 1. Acceptance of Terms
By accessing or using Skillpe, operated by Nolan Edutech Private Limited ("we", "us", or "our"), you agree to be bound by these Terms and Conditions ("Terms"). If you do not agree to these Terms, you may not access or use our services.

## 2. Eligibility
You must be at least 13 years old to use Skillpe. By using our services, you represent and warrant that you meet this age requirement.

## 3. Account Registration
To access certain features, you may need to register for an account. You agree to:
* Provide accurate and complete information during registration
* Maintain the confidentiality of your account credentials
* Notify us immediately of any unauthorized use of your account

You are solely responsible for all activities that occur under your account. We are not liable for any loss or damage arising from your failure to comply with these obligations.

## 4. Subscription and Payment
Skillpe operates exclusively on a subscription-based model. By subscribing, you gain access to premium content and features for the duration of your subscription period.

* **Auto-Renewal:** Subscriptions automatically renew at the end of each billing cycle (e.g., monthly, quarterly, annually) unless canceled prior to the renewal date.
* **Billing:** Payments are processed through authorized platforms (e.g., Google Play, App Store).
* **Price Changes:** We reserve the right to change our subscription plans or adjust pricing at our sole discretion. Any changes will take effect after providing notice to you.

## 5. User Conduct
By using Skillpe, you acknowledge and agree that the content provided is for informational and educational purposes only. This content is not intended as, and shall not be understood or construed as, financial, investment, trading, or any other form of professional advice. We are not financial advisors, and the information provided through the Service is not a substitute for advice from a qualified professional.

Nolan Edutech Private Limited is not responsible for any investment decisions or outcomes resulting from your use of the educational content on Skillpe.

You agree that you will use the Service responsibly and in compliance with these Terms. **You agree not to:**
* Use the Service for any unlawful purpose or in violation of any applicable local, state, national, or international law
* Post, upload, transmit, or distribute any content that is harmful, offensive, obscene, defamatory, infringing, or otherwise objectionable
* Attempt to interfere with or disrupt the operation of the Service or the servers or networks connected to the Service
* Attempt to gain unauthorized access to any portion of the Service, other user accounts, or any systems or networks connected to the Service
* Engage in any conduct that restricts or inhibits any other user from using or enjoying the Service

We reserve the right to suspend or terminate your access to the Service at our sole discretion, without notice, for any conduct that we believe violates these Terms or is harmful to other users of the Service, us, or third parties, or for any other reason.

## 6. Intellectual Property
All content on Skillpe, including but not limited to text, graphics, logos, and software, is the property of Nolan Edutech Private Limited or its licensors and is protected by applicable intellectual property laws. You may not reproduce, distribute, modify, or create derivative works of any content without our prior written consent.

## 7. User-Generated Content
You may be able to submit content to Skillpe, including comments, feedback, and other materials. By submitting content, you grant us a non-exclusive, royalty-free, perpetual, and worldwide license to use, reproduce, modify, and display such content in connection with our services. You are solely responsible for your content and the consequences of submitting it. We reserve the right to remove any content that violates these Terms or is otherwise objectionable.

## 8. Third-Party Services
Skillpe may contain links to third-party websites or services. We are not responsible for the content, policies, or practices of any third-party services. Your interactions with third-party services are governed by their terms and policies. We encourage you to review the terms and policies of any third-party services you access through Skillpe.

## 9. Termination
We reserve the right to suspend or terminate your access to Skillpe at our sole discretion, without notice, for conduct that we believe violates these Terms or is harmful to other users or us. Upon termination, your right to use Skillpe will immediately cease. All provisions of these Terms which by their nature should survive termination shall survive, including ownership provisions, warranty disclaimers, indemnity, and limitations of liability.

## 10. Disclaimer of Warranties
Skillpe is provided "as is" without warranties of any kind. We do not guarantee that our services will be uninterrupted or error-free. We disclaim all warranties, express or implied, including, but not limited to, implied warranties of merchantability and fitness for a particular purpose.

## 11. Limitation of Liability
To the fullest extent permitted by law, Nolan Edutech Private Limited shall not be liable for any indirect, incidental, or consequential damages arising from your use of Skillpe. Our total liability to you for any damages arising from or related to these Terms or your use of Skillpe shall not exceed the amount you have paid to us in the past twelve months.

## 12. Changes to Terms
We may update these Terms from time to time. Continued use of Skillpe after changes constitutes acceptance of the new Terms. We will notify you of any material changes by posting the new Terms on our website or through other communication channels.

## 13. Governing Law
These Terms are governed by the laws of India. Any disputes arising under these Terms shall be subject to the exclusive jurisdiction of the courts located in Bangalore.

## 14. Contact Us
For any questions regarding these Terms, please contact us at: [support@Skillpe.ai](mailto:support@Skillpe.ai)
''',
        selectable: true,
        padding: const EdgeInsets.all(28.0),
      ),
    );
  }
}
