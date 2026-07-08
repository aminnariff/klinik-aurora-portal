import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:klinik_aurora_portal/controllers/auth/auth_controller.dart';
import 'package:klinik_aurora_portal/views/login/login_page.dart';
import 'package:provider/provider.dart';

class NoPermission extends StatelessWidget {
  static const routeName = '/no-permission';
  static const displayName = 'no-permission';

  const NoPermission({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Animated gradient background ──────────────────────────
          Positioned.fill(child: _AnimatedGradientBackground()),

          // ── Decorative blobs ───────────────────────────────────────
          Positioned(top: -120, right: -100, child: _Bloob(size: 340, color: Colors.white.withAlpha(8))),
          Positioned(bottom: -160, left: -120, child: _Bloob(size: 420, color: Colors.white.withAlpha(6))),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.35,
            left: -80,
            child: _Bloob(size: 200, color: const Color(0xFFDF184A).withAlpha(20)),
          ),

          // ── Content ────────────────────────────────────────────────
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Lock icon with glow ────────────────────────────
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFDF184A), Color(0xFFB01030)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFFDF184A).withAlpha(100), blurRadius: 48, spreadRadius: 8),
                      ],
                    ),
                    child: const Center(child: Icon(Icons.gpp_bad_rounded, size: 56, color: Colors.white)),
                  ),

                  const SizedBox(height: 40),

                  // ── HEADLINE ───────────────────────────────────────
                  const Text(
                    'ACCESS DENIED',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 6,
                      height: 1.1,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Sub-headline ───────────────────────────────────
                  const Text(
                    'You Shall Not Pass',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Color(0x99FFFFFF),
                      fontStyle: FontStyle.italic,
                      letterSpacing: 2,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ── Status badge ───────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(20),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withAlpha(30)),
                    ),
                    child: const Text(
                      '403 FORBIDDEN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xCCFFFFFF),
                        letterSpacing: 3,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Description ────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(10),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withAlpha(15)),
                    ),
                    child: Text(
                      'The page you tried to access is restricted. '
                      'If you believe this is an error, please contact '
                      'your administrator to request the appropriate permissions.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, height: 1.6, color: Colors.white.withAlpha(180)),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ── Action buttons ─────────────────────────────────
                  SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () => context.goNamed(LoginPage.routeName),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFFDF184A),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 1),
                            ),
                            child: const Text('GO TO LOGIN'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              context.read<AuthController>().logout(context);
                              context.pushReplacementNamed(LoginPage.routeName, extra: true);
                            },
                            icon: const Icon(Icons.logout_rounded, size: 18),
                            label: const Text('LOG OUT'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white.withAlpha(200),
                              side: BorderSide(color: Colors.white.withAlpha(50)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, letterSpacing: 1),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Top bar ───────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.goNamed(LoginPage.routeName),
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      context.read<AuthController>().logout(context);
                      context.pushReplacementNamed(LoginPage.routeName, extra: true);
                    },
                    icon: const Icon(Icons.logout_rounded, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Animated gradient background ──────────────────────────────────────────────
class _AnimatedGradientBackground extends StatefulWidget {
  @override
  State<_AnimatedGradientBackground> createState() => _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<_AnimatedGradientBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _CustomAnimatedBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(const Color(0xFF1A0A0A), const Color(0xFF2D0A1A), _controller.value)!,
                Color.lerp(const Color(0xFF2D0A1A), const Color(0xFF0D0D1A), _controller.value)!,
                Color.lerp(const Color(0xFF0D0D1A), const Color(0xFF1A0A0A), _controller.value)!,
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── AnimatedBuilder for non-ticker animations ─────────────────────────────────
class _CustomAnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;

  const _CustomAnimatedBuilder({required super.listenable, required this.builder});

  @override
  Widget build(BuildContext context) {
    return builder(context, null);
  }
}

// ── Decorative bloobs ─────────────────────────────────────────────────────────
class _Bloob extends StatelessWidget {
  final double size;
  final Color color;

  const _Bloob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: pi / 4,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(size * 0.6)),
      ),
    );
  }
}
