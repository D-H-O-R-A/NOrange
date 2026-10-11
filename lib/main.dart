import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'helpers/ad_helper.dart';
import 'helpers/config.dart';
import 'helpers/pref.dart';
import 'screens/splash_screen.dart';

//global object for accessing device screen size
late Size mq;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //enter full-screen
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

  //local storage
  try {
    await Pref.initializeHive();
  } catch (e) {
    debugPrint('Hive init error: $e');
  }

  //firebase initialization
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await Config.initConfig();
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  //ads initialization
  try {
    await AdHelper.initAds();
  } catch (e) {
    debugPrint('AdHelper init error: $e');
  }

  //for setting orientation to portrait only
  try {
    await SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  } catch (e) {
    debugPrint('Orientation error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Hide Protocol VPN',
      home: const SplashScreen(),

      //theme
      theme:
          ThemeData(appBarTheme: const AppBarTheme(centerTitle: true, elevation: 3)),

      themeMode: Pref.isDarkMode ? ThemeMode.dark : ThemeMode.light,

      //dark theme
      darkTheme: ThemeData(
          brightness: Brightness.dark,
          appBarTheme: const AppBarTheme(centerTitle: true, elevation: 3)),

      debugShowCheckedModeBanner: false,
    );
  }
}

extension AppTheme on ThemeData {
  Color get lightText => Pref.isDarkMode ? Colors.white70 : Colors.black54;
  Color get bottomNav => Pref.isDarkMode ? Colors.white12 : Colors.blue;
}
