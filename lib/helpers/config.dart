import 'dart:developer';

import 'package:firebase_remote_config/firebase_remote_config.dart';

class Config {
  static final _config = FirebaseRemoteConfig.instance;

  static const _defaultValues = {
    "interstitial_ad": "ca-app-pub-3940256099942544/1033173712",
    "native_ad": "ca-app-pub-3940256099942544/2247696110",
    "rewarded_ad": "ca-app-pub-3940256099942544/5224354917",
    "show_ads": false
  };

  static Future<void> initConfig() async {
    try {
      await _config.setConfigSettings(RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 5),
          minimumFetchInterval: const Duration(minutes: 30)));

      await _config.setDefaults(_defaultValues);
      await _config.fetchAndActivate();
      log('Remote Config Data: ${_config.getBool('show_ads')}');

      _config.onConfigUpdated.listen((event) async {
        try {
          await _config.activate();
          log('Updated: ${_config.getBool('show_ads')}');
        } catch (e) {
          log('Config activate error: $e');
        }
      });
    } catch (e) {
      log('Remote Config init failed (using defaults): $e');
    }
  }

  static bool get _showAd {
    try {
      return _config.getBool('show_ads');
    } catch (_) {
      return false;
    }
  }

  //ad ids
  static String get nativeAd {
    try {
      final id = _config.getString('native_ad');
      return id.isNotEmpty ? id : _defaultValues["native_ad"] as String;
    } catch (_) {
      return _defaultValues["native_ad"] as String;
    }
  }

  static String get interstitialAd {
    try {
      final id = _config.getString('interstitial_ad');
      return id.isNotEmpty ? id : _defaultValues["interstitial_ad"] as String;
    } catch (_) {
      return _defaultValues["interstitial_ad"] as String;
    }
  }

  static String get rewardedAd {
    try {
      final id = _config.getString('rewarded_ad');
      return id.isNotEmpty ? id : _defaultValues["rewarded_ad"] as String;
    } catch (_) {
      return _defaultValues["rewarded_ad"] as String;
    }
  }

  static bool get hideAds => !_showAd;
}
