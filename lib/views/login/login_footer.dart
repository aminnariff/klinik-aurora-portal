import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/views/widgets/motion/emil_motion.dart';
import 'package:url_launcher/url_launcher.dart';

/// Everything under the login card: password help, the product tour, and legal links.
class LoginFooter extends StatelessWidget {
  final VoidCallback onResetPassword;

  const LoginFooter({super.key, required this.onResetPassword});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Trouble signing in?', style: TextStyle(fontSize: 12.5, color: appInkMuted)),
            const SizedBox(width: 5),
            _HoverLink(
              label: 'Reset password',
              onTap: onResetPassword,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: primaryAccessibleText),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const _ProductTourCard(),
        const SizedBox(height: 22),
        const _LegalLinks(),
      ],
    );
  }
}

Future<void> _openExternal(Uri uri) async {
  if (await canLaunchUrl(uri)) await launchUrl(uri, webOnlyWindowName: '_blank');
}

/// Compact glass card that opens the product tour in a new tab.
class _ProductTourCard extends StatefulWidget {
  const _ProductTourCard();

  @override
  State<_ProductTourCard> createState() => _ProductTourCardState();
}

class _ProductTourCardState extends State<_ProductTourCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduced = MediaQuery.disableAnimationsOf(context);
    final duration = reduced ? Duration.zero : const Duration(milliseconds: 180);
    final hairline = isDark ? const Color(0x1AFFFFFF) : const Color(0x140F172A);

    return Semantics(
      button: true,
      label: 'Take the product tour. Opens in a new tab.',
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: EmilPressable(
          onTap: () => _openExternal(productTourUri),
          // Glow sits outside the clip; the frosted fill matches the login card.
          child: AnimatedContainer(
            duration: duration,
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: _hovered ? primary.withValues(alpha: isDark ? 0.25 : 0.12) : Colors.transparent,
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: AnimatedContainer(
                  duration: duration,
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? (_hovered ? const Color(0xF217242D) : const Color(0xE0111B22))
                        : (_hovered ? const Color(0xF2FFFFFF) : const Color(0xCCFFFFFF)),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _hovered ? primary.withValues(alpha: 0.45) : hairline),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(11),
                          gradient: LinearGradient(
                            colors: [const Color(0xFFDF6E98), primary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primary.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'New here? Take the guided tour',
                              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: appInkPrimary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Watch each task, then try it with sample data.',
                              style: TextStyle(fontSize: 12, height: 1.35, color: appInkMuted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      AnimatedSlide(
                        duration: duration,
                        curve: Curves.easeOut,
                        offset: Offset(_hovered ? 0.2 : 0, 0),
                        child: Icon(Icons.arrow_forward_rounded, size: 18, color: primaryAccessibleText),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LegalLinks extends StatelessWidget {
  const _LegalLinks();

  @override
  Widget build(BuildContext context) {
    final dot = Text('·', style: TextStyle(fontSize: 12, color: appInkMuted.withValues(alpha: 0.6)));
    final style = TextStyle(fontSize: 11.5, color: appInkMuted);
    Widget link(String label, String url) =>
        _HoverLink(label: label, style: style, hoverColor: appInkSecondary, onTap: () => _openExternal(Uri.parse(url)));
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: [
        link('Privacy Policy', privacyPolicyUrl),
        dot,
        link('Terms & Conditions', termsAndConditionsUrl),
        dot,
        link('Refund Policy', refundPolicyUrl),
      ],
    );
  }
}

/// Text link that underlines on hover (and keyboard focus).
class _HoverLink extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final TextStyle style;
  final Color? hoverColor;

  const _HoverLink({required this.label, required this.onTap, required this.style, this.hoverColor});

  @override
  State<_HoverLink> createState() => _HoverLinkState();
}

class _HoverLinkState extends State<_HoverLink> {
  bool _active = false;

  @override
  Widget build(BuildContext context) {
    final color = _active ? (widget.hoverColor ?? widget.style.color) : widget.style.color;
    return Semantics(
      link: true,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowHoverHighlight: (v) => setState(() => _active = v),
        onShowFocusHighlight: (v) => setState(() => _active = v),
        actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onTap())},
        child: GestureDetector(
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Text(
              widget.label,
              style: widget.style.copyWith(
                color: color,
                decoration: _active ? TextDecoration.underline : TextDecoration.none,
                decorationColor: color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
