import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: Markdown(
        data: '''
Last Updated: 24th April 2025

## 1. Introduction
Nolan Edutech Private Limited ("we," "our," or "us") operates Skillpe ("Service"), a subscription-based online learning platform. We are committed to protecting your privacy and ensuring that your personal information is handled in a safe and responsible manner. This Privacy Policy outlines how we collect, use, disclose, and safeguard your information when you use our Service.

## 2. Information We Collect
We may collect the following types of information:

* **Personal Information:** Name, email address, phone number, billing address, and payment details.
* **Usage Data:** Information about how you use our Service, including access times, pages viewed, and the resources you access.
* **Device Information:** IP address, browser type, operating system, and device identifiers.

## 3. How We Use Your Information
We use the collected information for the following purposes:

* To provide and maintain our Service.
* To process transactions and send related information.
* To communicate with you, including sending updates and promotional materials.
* To personalize your experience and improve our Service.
* To enforce our Terms and Conditions and comply with legal obligations.

## 4. Sharing Your Information
We do not sell or rent your personal information to third parties. We may share your information with:

* **Service Providers:** Third-party vendors who assist in providing our Service, such as payment processors and hosting services.
* **Legal Requirements:** If required by law or in response to valid requests by public authorities.

## 5. Data Security
We implement industry-standard technical and organizational measures designed to protect your personal information from unauthorized access, use, alteration, or disclosure. However, no method of transmission over the internet or method of electronic storage is entirely secure, and we cannot guarantee absolute security.

## 6. Your Rights
Depending on your jurisdiction, you may have the right to:

* Access the personal information we hold about you.
* Request correction or deletion of your personal information.
* Object to or restrict the processing of your personal information.
* Withdraw consent at any time, where processing is based on consent.

To exercise these rights, please contact us at [Insert Contact Information].

## 7. Data Retention
We retain your personal information only for as long as necessary to fulfill the purposes outlined in this Privacy Policy, unless a longer retention period is required or permitted by law.

## 8. Children's Privacy
Our Service is not intended for individuals under the age of 13. We do not knowingly collect personal information from children under 13. If we become aware that we have collected such information, we will take steps to delete it promptly.

## 9. Changes to This Privacy Policy
We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page. Changes are effective when they are posted.

## 10. Contact Us
If you have any questions or concerns about this Privacy Policy, please contact us:

Nolan Edutech Private Limited  
support@Skillpe.ai
''',
        selectable: true,
        padding: const EdgeInsets.all(28.0),
      ),
    );
  }
}
