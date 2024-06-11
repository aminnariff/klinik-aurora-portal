import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';

class PrivacyPolicy extends StatelessWidget {
  static String routeName = '/privacy-policy';
  const PrivacyPolicy({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(screenPadding),
        child: Column(
          children: [
            Text(
              'Privacy Policy for Klinik Aurora Mobile App\n',
              style: AppTypography.displayMedium(context),
              textAlign: TextAlign.center,
            ),
            RichText(
              textAlign: TextAlign.justify,
              text: TextSpan(
                style: AppTypography.bodyMedium(context),
                children: <TextSpan>[
                  TextSpan(
                    text: '\n1. Introduction\n',
                    style: AppTypography.bodyMedium(context).apply(fontWeightDelta: 1),
                  ),
                  const TextSpan(
                    text:
                        'Welcome to the Klinik Aurora Mobile App. This Privacy Policy describes how we collect, use, disclose, and safeguard your information when you use our mobile application. By using the app, you agree to the terms of this Privacy Policy.\n',
                  ),
                  TextSpan(
                    text: '\n2. Information We Collect\n',
                    style: AppTypography.bodyMedium(context).apply(fontWeightDelta: 1),
                  ),
                  const TextSpan(
                      text: 'We may collect the following types of information:\n'
                          '  - Personal Information: Name, email address, phone number, and other contact details.\n'
                          '  - Usage Data: Information about how you use the app, such as access times and pages viewed.\n'),
                  TextSpan(
                    text: '\n3. How We Use Your Information\n',
                    style: AppTypography.bodyMedium(context).apply(fontWeightDelta: 1),
                  ),
                  const TextSpan(
                    text: 'We use the information we collect for various purposes, including:\n'
                        '  - To provide, operate, and maintain the app.\n'
                        '  - To improve, personalize, and expand our app.\n'
                        '  - To understand and analyze how you use our app.\n'
                        '  - To communicate with you, either directly or through one of our partners, including for customer service, to provide you with updates and other information relating to the app, and for marketing and promotional purposes.\n'
                        '  - To process your transactions and manage your orders.\n',
                  ),
                  TextSpan(
                    text: '\n4. Sharing Your Information\n',
                    style: AppTypography.bodyMedium(context).apply(fontWeightDelta: 1),
                  ),
                  const TextSpan(
                    text: 'We may share your information in the following situations:\n'
                        '  - With Service Providers: We may share your information with third-party service providers to perform certain services on our behalf.\n'
                        '  - For Business Transfers: We may share or transfer your information in connection with, or during negotiations of, any merger, sale of company assets, financing, or acquisition of all or a portion of our business to another company.\n'
                        '  - With Affiliates: We may share your information with our affiliates, in which case we will require those affiliates to honor this Privacy Policy.\n'
                        '  - With Your Consent: We may disclose your personal information for any other purpose with your consent.\n',
                  ),
                  TextSpan(
                    text: '\n5. Security of Your Information\n',
                    style: AppTypography.bodyMedium(context).apply(fontWeightDelta: 1),
                  ),
                  const TextSpan(
                    text:
                        'We use administrative, technical, and physical security measures to help protect your personal information. While we have taken reasonable steps to secure the personal information you provide to us, please be aware that despite our efforts, no security measures are perfect or impenetrable, and no method of data transmission can be guaranteed against any interception or other type of misuse.\n',
                  ),
                  TextSpan(
                    text: '\n6. Retention of Your Information\n',
                    style: AppTypography.bodyMedium(context).apply(fontWeightDelta: 1),
                  ),
                  const TextSpan(
                    text:
                        'We will retain your personal information only for as long as is necessary for the purposes set out in this Privacy Policy, or as required by law.\n',
                  ),
                  TextSpan(
                    text: '\n7. Your Data Protection Rights\n',
                    style: AppTypography.bodyMedium(context).apply(fontWeightDelta: 1),
                  ),
                  const TextSpan(
                    text: 'Depending on your location, you may have the following data protection rights:\n'
                        '  - The right to access – You have the right to request copies of your personal information.\n'
                        '  - The right to rectification – You have the right to request that we correct any information you believe is inaccurate or complete information you believe is incomplete.\n'
                        '  - The right to erasure – You have the right to request that we erase your personal data, under certain conditions.\n'
                        '  - The right to restrict processing – You have the right to request that we restrict the processing of your personal data, under certain conditions.\n'
                        '  - The right to object to processing – You have the right to object to our processing of your personal data, under certain conditions.\n'
                        '  - The right to data portability – You have the right to request that we transfer the data that we have collected to another organization, or directly to you, under certain conditions.\n',
                  ),
                  TextSpan(
                    text: '\n8. Changes to This Privacy Policy\n',
                    style: AppTypography.bodyMedium(context).apply(fontWeightDelta: 1),
                  ),
                  const TextSpan(
                    text:
                        'We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page. You are advised to review this Privacy Policy periodically for any changes. Changes to this Privacy Policy are effective when they are posted on this page.\n',
                  ),
                  TextSpan(
                    text: '\n9. Contact Us\n',
                    style: AppTypography.bodyMedium(context).apply(fontWeightDelta: 1),
                  ),
                  const TextSpan(
                    text:
                        'If you have any questions about this Privacy Policy, please contact us at info@klinikaurora.my.\n',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
