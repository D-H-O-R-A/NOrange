import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../main.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      //exit full-screen
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

      //navigate to home
      Get.off(() => HomeScreen());
    });
  }

  @override
  Widget build(BuildContext context) {
    //initializing media query (for getting device screen size)
    mq = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF212121),
      body: Stack(
        children: [
          //app logo
          Positioned(
              left: mq.width * .3,
              top: mq.height * .2,
              width: mq.width * .4,
              child: Image.asset('assets/images/logo.png')),

          //label
          Positioned(
              bottom: mq.height * .15,
              width: mq.width,
              child: const Text(
                'WELCOME TO HIDE VPN',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white, // Set text color to white for contrast
                    letterSpacing: 1),
              ))
        ],
      ),
    );
  }
}
