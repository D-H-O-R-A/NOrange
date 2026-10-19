import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../main.dart';
import '../theme/app_theme.dart';
import '../widgets/norange_logo.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _scaleAnim = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      Get.off(() => HomeScreen());
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: HpColors.bgCanvas,
      body: SafeArea(
        child: SizedBox.expand(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),

                // Center NOrange Emblem + Wordmark (properly centered & responsive)
                FadeTransition(
                  opacity: _fadeAnim,
                  child: ScaleTransition(
                    scale: _scaleAnim,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const NOrangeLogo(size: 108, showGlow: false),
                        const SizedBox(height: 22),
                        RichText(
                          textAlign: TextAlign.center,
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                              fontFamily: 'Roboto',
                            ),
                            children: [
                              TextSpan(
                                text: 'N',
                                style: TextStyle(color: HpColors.textPrimary),
                              ),
                              TextSpan(
                                text: 'Orange',
                                style: TextStyle(color: HpColors.accentOrange),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'STEALTH TUNNEL & NETWORK SUITE',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: HpColors.textSecondary,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom cryptographic boot telemetry
                FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 130,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(HpRadius.pill),
                          child: const LinearProgressIndicator(
                            minHeight: 3,
                            color: HpColors.accentOrange,
                            backgroundColor: HpColors.bgSurfaceHover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'INITIALIZING TUNNEL ENGINE • AES-256 / SOCKS5',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: HpColors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Desenvolvido por Diego Oris • diegooris.ch',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: HpColors.accentOrange,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
