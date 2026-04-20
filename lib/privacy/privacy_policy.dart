import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';

// Brand colours (mirrored from color.dart to avoid circular deps)
const _kPrimary = Color(0xFFDF6E98);
const _kSecondary = Color(0xFF6AD1E3);

class PrivacyPolicy extends StatelessWidget {
  static String routeName = '/privacy-policy';
  const PrivacyPolicy({super.key});

  @override
  Widget build(BuildContext context) {
    return _PolicyScaffold(
      title: 'Privacy Policy',
      body: [
        const _PolicyHeader(
          title: 'Privacy Policy',
          subtitle: 'Klinik Aurora Mobile App',
          effectiveDate: '01/03/2026',
          lastUpdated: '01/03/2026',
        ),
        _PolicySection(
          title: 'Introduction',
          children: [
            const _BodyText(
              'Klinik Aurora respects your privacy and is committed to protecting your personal data. This Privacy Policy explains how Klinik Aurora collects, uses, discloses, stores, and safeguards your personal data when you use the Klinik Aurora Mobile App and related clinic services.',
            ),
          ],
        ),
        _PolicySection(
          title: '1. Personal Data We Collect',
          children: [
            const _BodyText('We may collect and process the following personal data:'),
            const SizedBox(height: 8),
            const _BulletItem(
              'Identity and contact information such as your full name, phone number, email address, address, date of birth, gender, and identification details where necessary.',
            ),
            const _BulletItem(
              'Patient information such as pregnancy-related information, maternal health information, child or infant details, medical history, allergies, medications, vaccination information, symptoms, consultation records, and appointment notes.',
            ),
            const _BulletItem(
              'Dependant information where you register a child, baby, or dependant under your account.',
            ),
            const _BulletItem(
              'Appointment and booking information such as appointment date, time, preferred doctor, booking confirmations, cancellations, and attendance history.',
            ),
            const _BulletItem(
              'Payment and transaction information such as booking fee payment status, transaction references, and refund status. We do not intentionally store full card details unless expressly stated and handled through a secure payment provider.',
            ),
            const _BulletItem(
              'Technical and usage information such as device type, app version, IP address, crash logs, access times, and app activity.',
            ),
          ],
        ),
        _PolicySection(
          title: '2. How We Collect Your Data',
          children: [
            const _BodyText(
              'We may collect your personal data directly from you when you create an account, book an appointment, make payment, contact us, or use the App. We may also receive data from your parent, spouse, legal guardian, authorised representative, healthcare providers, laboratories, or payment and technology service providers where relevant.',
            ),
          ],
        ),
        _PolicySection(
          title: '3. How We Use Your Data',
          children: [
            const _BodyText('We may use your personal data for the following purposes:'),
            const SizedBox(height: 8),
            const _BulletItem('To create and manage your account.'),
            const _BulletItem('To register you or your dependant as a patient.'),
            const _BulletItem('To schedule, confirm, reschedule, and manage appointments.'),
            const _BulletItem('To provide healthcare-related administrative support and patient follow-up.'),
            const _BulletItem('To process booking fees, payments, and approved refunds.'),
            const _BulletItem('To communicate appointment reminders, service notices, and important updates.'),
            const _BulletItem('To improve our App, services, and patient experience.'),
            const _BulletItem('To maintain clinic, billing, and patient records.'),
            const _BulletItem('To comply with legal and regulatory obligations.'),
            const _BulletItem('To prevent fraud, misuse, and unauthorised access.'),
          ],
        ),
        _PolicySection(
          title: '4. Sharing of Personal Data',
          children: [
            const _BodyText('We may share your personal data only where necessary with:'),
            const SizedBox(height: 8),
            const _BulletItem('Doctors, nurses, and authorised Klinik Aurora personnel.'),
            const _BulletItem('Laboratories, pharmacies, hospitals, or diagnostic partners involved in your care.'),
            const _BulletItem('Payment gateway providers and financial service providers.'),
            const _BulletItem(
              'Cloud hosting providers, IT support providers, notification providers, and software service providers.',
            ),
            const _BulletItem('Professional advisers, auditors, insurers, and legal counsel.'),
            const _BulletItem('Government authorities, regulators, or enforcement bodies where required by law.'),
            const SizedBox(height: 8),
            const _BodyText('We do not sell your personal data.'),
          ],
        ),
        _PolicySection(
          title: '5. Children and Dependants',
          children: [
            const _BodyText(
              'As Klinik Aurora provides services for mothers, babies, and children, we may process personal data relating to minors and dependants. By submitting a child\'s or dependant\'s information, you confirm that you are the parent, legal guardian, or otherwise authorised to do so.',
            ),
          ],
        ),
        _PolicySection(
          title: '6. Data Security',
          children: [
            const _BodyText(
              'We take reasonable administrative, technical, and organisational measures to protect your personal data, including access controls, secure systems, and internal confidentiality measures. However, no method of transmission or storage is completely secure, and we cannot guarantee absolute security.',
            ),
          ],
        ),
        _PolicySection(
          title: '7. Data Retention',
          children: [
            const _BodyText(
              'We retain personal data only for as long as necessary for the purposes described in this Privacy Policy, including medical, billing, legal, audit, operational, and regulatory requirements.',
            ),
          ],
        ),
        _PolicySection(
          title: '8. Your Rights',
          children: [
            const _BodyText(
              'Subject to applicable law, you may request access to your personal data, request correction of inaccurate data, withdraw consent where applicable, and contact us regarding how your data is used. Please note that withdrawing consent may affect our ability to provide certain services.',
            ),
          ],
        ),
        _PolicySection(
          title: '9. Marketing and Notifications',
          children: [
            const _BodyText(
              'We may send service-related notifications such as appointment confirmations, reminders, payment updates, follow-up notices, and operational announcements. Promotional communications will only be sent where permitted by law or where you have consented.',
            ),
          ],
        ),
        _PolicySection(
          title: '10. Changes to This Privacy Policy',
          children: [
            const _BodyText(
              'We may update this Privacy Policy from time to time. Any updates will be posted in the App or on our official channels. Continued use of the App after such updates constitutes your acceptance of the revised Privacy Policy.',
            ),
          ],
        ),
        const _ContactCard(
          sectionTitle: '11. Contact Us',
          intro:
              'If you have any questions, requests, or complaints regarding this Privacy Policy or your personal data, please contact:',
        ),
        _RelatedPolicies(
          links: const [
            _PolicyLink(label: 'Terms & Conditions', routeName: '/terms-and-conditions'),
            _PolicyLink(label: 'Refund / Cancellation Policy', routeName: '/refund-policy'),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class TermsAndConditions extends StatelessWidget {
  static String routeName = '/terms-and-conditions';
  const TermsAndConditions({super.key});

  @override
  Widget build(BuildContext context) {
    return _PolicyScaffold(
      title: 'Terms & Conditions',
      body: [
        const _PolicyHeader(
          title: 'Terms & Conditions',
          subtitle: 'Klinik Aurora Mobile App',
          effectiveDate: '01/03/2026',
          lastUpdated: '01/03/2026',
        ),
        _PolicySection(
          title: 'Introduction',
          children: [
            const _BodyText(
              'These Terms & Conditions govern your use of the Klinik Aurora Mobile App. By accessing or using the App, you agree to be bound by these Terms and our Privacy Policy.',
            ),
          ],
        ),
        _PolicySection(
          title: '1. Use of the App',
          children: [
            const _BodyText(
              'The App is intended to help users manage clinic-related services including account registration, patient profile management, appointment booking, and relevant communications. The App does not replace medical examination, diagnosis, or emergency care.',
            ),
          ],
        ),
        _PolicySection(
          title: '2. Eligibility',
          children: [
            const _BodyText(
              'You must ensure that all information submitted through the App is accurate, current, and complete. If you register or manage a child or dependant profile, you confirm that you are the parent, legal guardian, or otherwise authorised to do so.',
            ),
          ],
        ),
        _PolicySection(
          title: '3. Appointments',
          children: [
            const _BodyText(
              'Appointments made through the App are subject to doctor availability, clinic operating hours, verification of details, and payment of any required booking fee. A booking is only confirmed once confirmation is issued through the App or by Klinik Aurora.',
            ),
          ],
        ),
        _PolicySection(
          title: '4. Late Arrival and No-Show',
          children: [
            const _BodyText(
              'Patients are encouraged to arrive at least 10 to 15 minutes before the scheduled appointment time. Late arrival may result in shortened consultation time, rescheduling, or treatment of the booking as a missed appointment, depending on doctor availability and clinic operations.',
            ),
          ],
        ),
        _PolicySection(
          title: '5. Payments',
          children: [
            const _BodyText(
              'Certain appointments or services may require a booking fee, deposit, or payment. Applicable charges will be shown before payment confirmation where relevant.',
            ),
          ],
        ),
        _PolicySection(
          title: '6. Medical Disclaimer',
          children: [
            const _BodyText(
              'The App is intended for administrative and appointment-related purposes. Information in the App is for general informational purposes only and does not constitute medical advice, diagnosis, or treatment. In case of emergency, please seek immediate treatment at the nearest hospital or call emergency services.',
            ),
          ],
        ),
        _PolicySection(
          title: '7. User Responsibilities',
          children: [
            const _BodyText(
              'You are responsible for maintaining the confidentiality of your login credentials and for all activities carried out under your account. You must not misuse the App, provide false information, impersonate others, or attempt unauthorised access to any part of the system.',
            ),
          ],
        ),
        _PolicySection(
          title: '8. Intellectual Property',
          children: [
            const _BodyText(
              'All content, trademarks, logos, text, graphics, and software in the App are owned by or licensed to Klinik Aurora and may not be copied, reproduced, or distributed without prior written consent.',
            ),
          ],
        ),
        _PolicySection(
          title: '9. Limitation of Liability',
          children: [
            const _BodyText(
              'To the fullest extent permitted by law, Klinik Aurora shall not be liable for any indirect, incidental, or consequential loss arising from the use of the App, service interruptions, or reliance on general information made available through the App.',
            ),
          ],
        ),
        _PolicySection(
          title: '10. Changes to the Terms',
          children: [
            const _BodyText(
              'Klinik Aurora may update these Terms from time to time. Continued use of the App after updates are posted constitutes acceptance of the revised Terms.',
            ),
          ],
        ),
        const _ContactCard(
          sectionTitle: '11. Contact Us',
          intro: 'For questions about these Terms & Conditions, please contact:',
        ),
        _RelatedPolicies(
          links: const [
            _PolicyLink(label: 'Privacy Policy', routeName: '/privacy-policy'),
            _PolicyLink(label: 'Refund / Cancellation Policy', routeName: '/refund-policy'),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class RefundPolicy extends StatelessWidget {
  static String routeName = '/refund-policy';
  const RefundPolicy({super.key});

  @override
  Widget build(BuildContext context) {
    return _PolicyScaffold(
      title: 'Refund / Cancellation Policy',
      body: [
        const _PolicyHeader(
          title: 'Refund / Cancellation Policy',
          subtitle: 'Klinik Aurora Mobile App',
          effectiveDate: '01/03/2026',
          lastUpdated: '01/03/2026',
        ),
        _PolicySection(
          title: '1. Scope',
          children: [
            const _BodyText(
              'This Policy applies to appointment bookings made through the Klinik Aurora Mobile App where a booking fee, deposit, or advance payment is required.',
            ),
          ],
        ),
        _PolicySection(
          title: '2. Booking Fee',
          children: [
            const _BodyText(
              'Some appointments may require a booking fee or deposit to secure the appointment slot. The applicable amount will be displayed before payment confirmation.',
            ),
          ],
        ),
        _PolicySection(
          title: '3. Refund Eligibility',
          children: [
            const _BodyText('Refunds may be considered in the following cases:'),
            const SizedBox(height: 8),
            const _BulletItem('Duplicate payment.'),
            const _BulletItem('Payment was successful but no booking was created.'),
            const _BulletItem('Appointment is cancelled by Klinik Aurora.'),
            const _BulletItem('Doctor is unavailable and no suitable replacement or rescheduled slot is accepted.'),
            const _BulletItem('Other special cases approved by Klinik Aurora.'),
          ],
        ),
        _PolicySection(
          title: '4. Non-Refundable Situations',
          children: [
            const _BodyText(
              'Booking fees may be non-refundable or only partially refundable in situations including but not limited to:',
            ),
            const SizedBox(height: 8),
            const _BulletItem('Patient no-show.'),
            const _BulletItem('Late cancellation.'),
            const _BulletItem('Repeated missed appointments.'),
            const _BulletItem('Incorrect booking details submitted by the user.'),
            const _BulletItem('Change of mind after the allowed cancellation window.'),
          ],
        ),
        _PolicySection(
          title: '5. Cancellation by Patient',
          children: [
            const _BodyText(
              'To be considered for a refund, cancellation should be made at least 24 hours before the scheduled appointment time, unless otherwise stated by Klinik Aurora.',
            ),
          ],
        ),
        _PolicySection(
          title: '6. Cancellation by Klinik Aurora',
          children: [
            const _BodyText(
              'If Klinik Aurora needs to cancel or reschedule an appointment due to doctor unavailability, emergencies, or operational reasons, patients may be offered a replacement slot, credit toward a future appointment, or a refund where applicable.',
            ),
          ],
        ),
        _PolicySection(
          title: '7. Refund Processing Time',
          children: [
            const _BodyText(
              'Where a refund is approved, it will be processed to the original payment method where possible. Approved refunds will generally be processed within 7 to 14 working days, subject to bank, card issuer, e-wallet provider, or payment gateway processing times.',
            ),
          ],
        ),
        _PolicySection(
          title: '8. How to Request a Refund',
          children: [
            const _BodyText(
              'Refund requests may be submitted through the App where available or by contacting Klinik Aurora support. Please include the patient name, appointment date and time, payment reference, and reason for the refund request.',
            ),
          ],
        ),
        const _ContactCard(
          sectionTitle: '9. Contact Us',
          intro: 'For refund or cancellation enquiries, please contact:',
        ),
        _RelatedPolicies(
          links: const [
            _PolicyLink(label: 'Privacy Policy', routeName: '/privacy-policy'),
            _PolicyLink(label: 'Terms & Conditions', routeName: '/terms-and-conditions'),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ── Shared private widgets ────────────────────────────────────────────────────

class _PolicyScaffold extends StatelessWidget {
  final String title;
  final List<Widget> body;

  const _PolicyScaffold({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFCEEF5), Color(0xFFEDF9FB), Colors.white],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),
          Positioned(top: -60, right: -60, child: _GlowOrb(color: _kPrimary.withValues(alpha: 0.15), size: 220)),
          Positioned(bottom: 100, left: -40, child: _GlowOrb(color: _kSecondary.withValues(alpha: 0.12), size: 160)),
          SingleChildScrollView(
            padding: EdgeInsets.all(screenPadding),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: body),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _PolicyHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String effectiveDate;
  final String lastUpdated;

  const _PolicyHeader({
    required this.title,
    required this.subtitle,
    required this.effectiveDate,
    required this.lastUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_kPrimary, Color(0xFFE88FB0), _kSecondary],
                stops: [0.0, 0.5, 1.0],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: _kPrimary.withValues(alpha: 0.30), blurRadius: 24, offset: const Offset(0, 8)),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.shield_outlined, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: AppTypography.displayMedium(context).copyWith(color: Colors.white)),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: AppTypography.bodyMedium(
                              context,
                            ).copyWith(color: Colors.white.withValues(alpha: 0.85)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.0),
                        Colors.white.withValues(alpha: 0.4),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _DateBadge(label: 'Effective', date: effectiveDate),
                    const SizedBox(width: 10),
                    _DateBadge(label: 'Last Updated', date: lastUpdated),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DateBadge extends StatelessWidget {
  final String label;
  final String date;
  const _DateBadge({required this.label, required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today_rounded, size: 11, color: Colors.white.withValues(alpha: 0.85)),
          const SizedBox(width: 5),
          Text(
            '$label: $date',
            style: AppTypography.bodyMedium(
              context,
            ).copyWith(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _PolicySection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.2),
              boxShadow: [
                BoxShadow(color: _kPrimary.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 4)),
              ],
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 4,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [_kPrimary, _kSecondary],
                      ),
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppTypography.bodyMedium(
                              context,
                            ).copyWith(fontWeight: FontWeight.w700, color: _kPrimary),
                          ),
                          const SizedBox(height: 10),
                          ...children,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BodyText extends StatelessWidget {
  final String text;
  const _BodyText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTypography.bodyMedium(context).copyWith(height: 1.6), textAlign: TextAlign.justify);
  }
}

class _BulletItem extends StatelessWidget {
  final String text;
  const _BulletItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7, right: 10),
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [_kPrimary, _kSecondary]),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(child: Text(text, style: AppTypography.bodyMedium(context).copyWith(height: 1.55))),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final String sectionTitle;
  final String intro;

  const _ContactCard({required this.sectionTitle, required this.intro});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_kSecondary.withValues(alpha: 0.12), _kPrimary.withValues(alpha: 0.08)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kSecondary.withValues(alpha: 0.3), width: 1.2),
              boxShadow: [
                BoxShadow(color: _kSecondary.withValues(alpha: 0.10), blurRadius: 16, offset: const Offset(0, 4)),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [_kPrimary, _kSecondary]),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Text(sectionTitle, style: AppTypography.bodyMedium(context).copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(intro, style: AppTypography.bodyMedium(context).copyWith(height: 1.5)),
                const SizedBox(height: 14),
                _ContactRow(
                  icon: Icons.location_on_outlined,
                  text:
                      'Klinik Aurora (HQ)\n38 Jalan Sungai Burung Y32/Y Bukit Rimau, Seksyen 32,\n40460 Shah Alam, Selangor',
                ),
                const SizedBox(height: 10),
                _ContactRow(icon: Icons.phone_outlined, text: '010-233 6855'),
                const SizedBox(height: 10),
                _ContactRow(icon: Icons.email_outlined, text: 'info@klinikaurora.my'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _ContactRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 15, color: _kPrimary),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: AppTypography.bodyMedium(context).copyWith(height: 1.5))),
      ],
    );
  }
}

class _PolicyLink {
  final String label;
  final String routeName;
  const _PolicyLink({required this.label, required this.routeName});
}

class _RelatedPolicies extends StatelessWidget {
  final List<_PolicyLink> links;
  const _RelatedPolicies({required this.links});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.75), width: 1.2),
            boxShadow: [
              BoxShadow(color: _kPrimary.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 3)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        const LinearGradient(colors: [_kPrimary, _kSecondary]).createShader(bounds),
                    child: const Icon(Icons.link_rounded, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Related Policies',
                    style: AppTypography.bodyMedium(context).copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: links.map((link) {
                  return _GradientChip(label: link.label, onTap: () => context.go(link.routeName));
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradientChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _GradientChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_kPrimary, _kSecondary]),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: _kPrimary.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.open_in_new_rounded, color: Colors.white, size: 13),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppTypography.bodyMedium(
                context,
              ).copyWith(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
