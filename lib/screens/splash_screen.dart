import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../main.dart';
import '../theme/app_theme.dart';
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
      duration: const Duration(milliseconds: 950),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _scaleAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _animController.forward();

    Future.delayed(const Duration(milliseconds: 1600), () {
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
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Subtle radial ambient light in the deep obsidian canvas
          Positioned(
            top: mq.height * 0.18,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    HpColors.accentEmerald.withOpacity(0.11),
                    HpColors.accentCyan.withOpacity(0.04),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Center emblem + brand identity
          FadeTransition(
            opacity: _fadeAnim,
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: HpColors.bgElevated,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: HpColors.accentEmerald.withOpacity(0.35),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: HpColors.accentEmerald.withOpacity(0.14),
                          blurRadius: 36,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'HIDE PROTOCOL',
                    style: TextStyle(
                      color: HpColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'ZERO-TRUST NETWORK & PRIVACY ARCHITECTURE',
                    style: TextStyle(
                      color: HpColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.8,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom cryptographic boot telemetry
          Positioned(
            bottom: mq.height * 0.07,
            left: 32,
            right: 32,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                children: [
                  SizedBox(
                    width: 120,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(HpRadius.pill),
                      child: LinearProgressIndicator(
                        minHeight: 2.5,
                        color: HpColors.accentEmerald,
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
                      letterSpacing: 1.4,
                    ),
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
