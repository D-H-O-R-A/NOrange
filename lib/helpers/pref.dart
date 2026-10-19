import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/proxy_config.dart';
import '../models/vpn.dart';

class Pref {
  static late Box _box;

  static Future<void> initializeHive() async {
    await Hive.initFlutter();
    _box = await Hive.openBox('data');
  }

  // for storing theme data (defaults to Obsidian Dark theme)
  static bool get isDarkMode => _box.get('isDarkMode') ?? true;
  static set isDarkMode(bool v) => _box.put('isDarkMode', v);

  // for storing single selected vpn details
  static Vpn get vpn => Vpn.fromJson(jsonDecode(_box.get('vpn') ?? '{}'));
  static set vpn(Vpn v) => _box.put('vpn', jsonEncode(v));

  // for storing vpn servers details
  static List<Vpn> get vpnList {
    List<Vpn> temp = [];
    final data = jsonDecode(_box.get('vpnList') ?? '[]');

    for (var i in data) {
      temp.add(Vpn.fromJson(i));
    }

    return temp;
  }

  static set vpnList(List<Vpn> v) {
    _box.put('vpnList', jsonEncode(v));
    _box.put('lastVpnFetchTime', DateTime.now().millisecondsSinceEpoch);
  }

  static int get lastVpnFetchTime =>
      int.tryParse((_box.get('lastVpnFetchTime') ?? '0').toString()) ?? 0;

  static List<String> get offlineVpnKeys {
    try {
      final List<dynamic> list =
          jsonDecode((_box.get('offlineVpnKeys') ?? '[]').toString());
      return list.map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }

  static void addOfflineServer(String uniqueKey) {
    if (uniqueKey.isEmpty) return;
    final list = offlineVpnKeys;
    if (!list.contains(uniqueKey)) {
      list.add(uniqueKey);
      _box.put('offlineVpnKeys', jsonEncode(list));
    }
  }

  static void removeOfflineServer(String uniqueKey) {
    final list = offlineVpnKeys;
    if (list.remove(uniqueKey)) {
      _box.put('offlineVpnKeys', jsonEncode(list));
    }
  }

  static bool isServerOffline(String uniqueKey) {
    return offlineVpnKeys.contains(uniqueKey);
  }

  // for storing custom user-configured VPN profiles
  static List<Vpn> get customVpnList {
    List<Vpn> temp = [];
    final data = jsonDecode(_box.get('customVpnList') ?? '[]');
    for (var i in data) {
      temp.add(Vpn.fromJson(i));
    }
    return temp;
  }

  static set customVpnList(List<Vpn> v) =>
      _box.put('customVpnList', jsonEncode(v));

  // for storing configured outbound proxies
  static List<ProxyConfig> get proxyList {
    List<ProxyConfig> temp = [];
    final data = jsonDecode(_box.get('proxyList') ?? '[]');
    for (var i in data) {
      temp.add(ProxyConfig.fromJson(i));
    }
    return temp;
  }

  static set proxyList(List<ProxyConfig> v) =>
      _box.put('proxyList', jsonEncode(v));

  // currently active outbound proxy ID (empty if disabled)
  static String get activeProxyId => (_box.get('activeProxyId') ?? '').toString();
  static set activeProxyId(String id) => _box.put('activeProxyId', id);

  static ProxyConfig? get activeProxy {
    final id = activeProxyId;
    if (id.isEmpty) return null;
    for (final p in proxyList) {
      if (p.id == id) return p;
    }
    return null;
  }

  // custom DNS settings
  static String get customDns1 =>
      (_box.get('customDns1') ?? '1.1.1.1').toString();
  static set customDns1(String v) => _box.put('customDns1', v);

  static String get customDns2 =>
      (_box.get('customDns2') ?? '8.8.8.8').toString();
  static set customDns2(String v) => _box.put('customDns2', v);

  // local shareable VPN / Proxy gateway port
  static int get gatewayPort =>
      int.tryParse((_box.get('gatewayPort') ?? '8080').toString()) ?? 8080;
  static set gatewayPort(int port) => _box.put('gatewayPort', port);

  // Per-App Split Tunneling allowed package names
  static List<String> get allowedAppPackages {
    final raw = _box.get('allowedAppPackages');
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    return [];
  }

  static set allowedAppPackages(List<String> pkgs) =>
      _box.put('allowedAppPackages', pkgs);

  // Default Mock GPS coordinates
  static double get mockLat =>
      double.tryParse((_box.get('mockLat') ?? '-23.550520').toString()) ??
      -23.550520;
  static set mockLat(double v) => _box.put('mockLat', v);

  static double get mockLon =>
      double.tryParse((_box.get('mockLon') ?? '-46.633308').toString()) ??
      -46.633308;
  static set mockLon(double v) => _box.put('mockLon', v);

  // Virtualized Camera photo path & real-time transform parameters
  static String get virtualCameraImagePath =>
      (_box.get('virtualCameraImagePath') ?? '').toString();
  static set virtualCameraImagePath(String p) =>
      _box.put('virtualCameraImagePath', p);

  static bool get virtualCameraEnabled =>
      _box.get('virtualCameraEnabled') == true;
  static set virtualCameraEnabled(bool v) =>
      _box.put('virtualCameraEnabled', v);

  static double get vcamScaleX =>
      double.tryParse((_box.get('vcamScaleX') ?? '1.0').toString()) ?? 1.0;
  static set vcamScaleX(double v) => _box.put('vcamScaleX', v);

  static double get vcamScaleY =>
      double.tryParse((_box.get('vcamScaleY') ?? '1.0').toString()) ?? 1.0;
  static set vcamScaleY(double v) => _box.put('vcamScaleY', v);

  static double get vcamOffsetX =>
      double.tryParse((_box.get('vcamOffsetX') ?? '0.0').toString()) ?? 0.0;
  static set vcamOffsetX(double v) => _box.put('vcamOffsetX', v);

  static double get vcamOffsetY =>
      double.tryParse((_box.get('vcamOffsetY') ?? '0.0').toString()) ?? 0.0;
  static set vcamOffsetY(double v) => _box.put('vcamOffsetY', v);

  static double get vcamRotation =>
      double.tryParse((_box.get('vcamRotation') ?? '0.0').toString()) ?? 0.0;
  static set vcamRotation(double v) => _box.put('vcamRotation', v);

  static bool get vcamFlipH => _box.get('vcamFlipH') == true;
  static set vcamFlipH(bool v) => _box.put('vcamFlipH', v);

  static bool get vcamFlipV => _box.get('vcamFlipV') == true;
  static set vcamFlipV(bool v) => _box.put('vcamFlipV', v);

  // for storing favorite server keys (ip:port/protocol)
  static List<String> get favoriteServers {
    final raw = _box.get('favoriteServers');
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    return [];
  }

  static set favoriteServers(List<String> keys) =>
      _box.put('favoriteServers', keys);

  static bool isFavorite(Vpn vpn) => favoriteServers.contains(vpn.uniqueKey);

  static bool toggleFavorite(Vpn vpn) {
    final current = List<String>.from(favoriteServers);
    final key = vpn.uniqueKey;
    if (current.contains(key)) {
      current.remove(key);
      favoriteServers = current;
      return false;
    } else {
      current.add(key);
      favoriteServers = current;
      return true;
    }
  }

  // for storing user preference for floating assistant widget
  static bool get floatingWidgetEnabled =>
      _box.get('floatingWidgetEnabled') == true;
  static set floatingWidgetEnabled(bool v) =>
      _box.put('floatingWidgetEnabled', v);
}
