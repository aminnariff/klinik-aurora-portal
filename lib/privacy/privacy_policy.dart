import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/config/route_names.dart';
import 'package:klinik_aurora_portal/views/widgets/glass/app_glass.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';
import 'package:url_launcher/url_launcher.dart';

/// Privacy Policy Screen — redirects to single hosted online source of truth.
class PrivacyPolicy extends StatelessWidget {
  static const String routeName = '/privacy-policy';
  const PrivacyPolicy({super.key});

  @override
  Widget build(BuildContext context) {
    return const _HostedPolicyRedirectView(
      title: 'Privacy Policy',
      subtitle: 'PDPA 2010 & Act A1727 2024 Compliant',
      targetUrl: privacyPolicyUrl,
      icon: Icons.shield_outlined,
    );
  }
}

/// Terms & Conditions Screen — redirects to single hosted online source of truth.
class TermsAndConditions extends StatelessWidget {
  static const String routeName = '/terms-and-conditions';
  const TermsAndConditions({super.key});

  @override
  Widget build(BuildContext context) {
    return const _HostedPolicyRedirectView(
      title: 'Terms & Conditions',
      subtitle: 'Patient Membership & App Usage Terms',
      targetUrl: termsAndConditionsUrl,
      icon: Icons.description_outlined,
    );
  }
}

/// Refund / Cancellation Policy Screen — redirects to single hosted online source of truth.
class RefundPolicy extends StatelessWidget {
  static const String routeName = '/refund-policy';
  const RefundPolicy({super.key});

  @override
  Widget build(BuildContext context) {
    return const _HostedPolicyRedirectView(
      title: 'Refund & Cancellation Policy',
      subtitle: 'Transparent Appointment Booking & Deposit Safeguards',
      targetUrl: refundPolicyUrl,
      icon: Icons.receipt_long_outlined,
    );
  }
}

class _HostedPolicyRedirectView extends StatefulWidget {
  final String title;
  final String subtitle;
  final String targetUrl;
  final IconData icon;

  const _HostedPolicyRedirectView({
    required this.title,
    required this.subtitle,
    required this.targetUrl,
    required this.icon,
  });

  @override
  State<_HostedPolicyRedirectView> createState() => _HostedPolicyRedirectViewState();
}

class _HostedPolicyRedirectViewState extends State<_HostedPolicyRedirectView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openExternal();
    });
  }

  Future<void> _openExternal() async {
    final uri = Uri.parse(widget.targetUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, webOnlyWindowName: '_blank');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF070D12) : const Color(0xFFF8FAFC),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: AppGlassCard(
              auroraBorder: true,
              padding: const EdgeInsets.all(32),
              borderRadius: 24,
              blurSigma: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: primary.withValues(alpha: 0.2)),
                    ),
                    child: Icon(widget.icon, color: primary, size: 32),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.title,
                    style: AppTypography.displayMedium(context).copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.subtitle,
                    style: AppTypography.bodyMedium(context).copyWith(
                      fontSize: 12.5,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Klinik Aurora legal policies are centrally hosted online as the single source of truth.',
                          style: AppTypography.bodyMedium(context).copyWith(
                            fontSize: 13,
                            color: isDark ? Colors.white70 : Colors.black87,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          widget.targetUrl,
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                            color: primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: _openExternal,
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: Text('Open ${widget.title} in New Tab'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton(
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go(RouteNames.login);
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? Colors.white70 : appInkPrimary,
                        side: BorderSide(
                          color: isDark ? Colors.white24 : Colors.grey.shade300,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Back to Portal'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      _policyPill(context, 'Privacy Policy', privacyPolicyUrl),
                      _policyPill(context, 'Terms & Conditions', termsAndConditionsUrl),
                      _policyPill(context, 'Refund Policy', refundPolicyUrl),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aurora Medicare Sdn Bhd (SSM 201801020794)\n38 Jalan Sungai Burung Y32/Y, Bukit Rimau, 40460 Shah Alam, Selangor\n010-233 6855 • info@klinikaurora.my',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white38 : Colors.grey[500],
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _policyPill(BuildContext context, String label, String url) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCurrent = url == widget.targetUrl;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: isCurrent
          ? null
          : () async {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, webOnlyWindowName: '_blank');
              }
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isCurrent
              ? primary.withValues(alpha: 0.15)
              : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03)),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isCurrent ? primary : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
            color: isCurrent ? primary : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }
}
