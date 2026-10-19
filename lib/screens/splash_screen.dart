import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../main.dart';
import '../theme/app_theme.dart';
import '../widgets/hide_protocol_logo.dart';
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
      duration: const Duration(milliseconds: 850),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _scaleAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _animController.forward();

    Future.delayed(const Duration(milliseconds: 1450), () {
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
          // Center vector emblem + brand identity in Black, Graphite & Orange
          FadeTransition(
            opacity: _fadeAnim,
            child: ScaleTransition(
              scale: _scaleAnim,
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HideProtocolLogo(size: 104),
                  SizedBox(height: 24),
                  Text(
                    'HIDE PROTOCOL',
                    style: TextStyle(
                      color: HpColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3.5,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'STEALTH TUNNEL & NETWORK COMMAND',
                    style: TextStyle(
                      color: HpColors.accentOrange,
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
                      child: const LinearProgressIndicator(
                        minHeight: 2.5,
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
