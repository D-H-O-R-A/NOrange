import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'helpers/ad_helper.dart';
import 'helpers/config.dart';
import 'helpers/pref.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

//global object for accessing device screen size
late Size mq;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure edge-to-edge obsidian system chrome
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: HpColors.bgCanvas,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Initialize local Hive storage
  try {
    await Pref.initializeHive();
  } catch (e) {
    debugPrint('Hive init error: $e');
  }

  // Set orientation to portrait only
  try {
    await SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  } catch (e) {
    debugPrint('Orientation error: $e');
  }

  // Mount UI immediately to avoid any startup freeze or ANR
  runApp(const MyApp());

  // Asynchronous background initialization for external services
  Future.microtask(() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 4));
      await Config.initConfig().timeout(const Duration(seconds: 4));
    } catch (e) {
      debugPrint('Firebase background init: $e');
    }

    try {
      await AdHelper.initAds().timeout(const Duration(seconds: 4));
    } catch (e) {
      debugPrint('AdHelper background init: $e');
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'NOrange',
      home: const SplashScreen(),
      theme: HpTheme.lightTheme,
      darkTheme: HpTheme.darkTheme,
      themeMode: Pref.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 260),
      debugShowCheckedModeBanner: false,
    );
  }
}

extension AppTheme on ThemeData {
  Color get lightText =>
      brightness == Brightness.dark ? HpColors.textSecondary : HpColors.lightTextSecondary;
  Color get bottomNav =>
      brightness == Brightness.dark ? HpColors.bgElevated : HpColors.lightElevated;
}
