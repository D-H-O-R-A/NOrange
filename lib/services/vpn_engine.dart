import 'dart:convert';
import 'package:flutter/services.dart';
import '../helpers/pref.dart';
import '../models/vpn_status.dart';
import '../models/vpn_config.dart';

class VpnEngine {
  /// Channel names to native Android & iOS
  static const String _eventChannelVpnStage = "vpnStage";
  static const String _eventChannelVpnStatus = "vpnStatus";
  static const String _methodChannelVpnControl = "vpnControl";
  static const MethodChannel _channel = MethodChannel(_methodChannelVpnControl);

  static Stream<String>? _stageStream;
  static Stream<VpnStatus?>? _statusStream;

  static void setFloatingCommandListener(
      Future<void> Function(String cmd, String pkg, bool enabled) onCommand) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == "onFloatingCommand" && call.arguments is Map) {
        final map = call.arguments as Map;
        final cmd = (map['cmd'] ?? '').toString();
        final pkg = (map['package'] ?? '').toString();
        final enabled = map['enabled'] == true;
        await onCommand(cmd, pkg, enabled);
      }
    });
  }

  /// Shared broadcast stream of VPN Connection Stage
  static Stream<String> vpnStageSnapshot() {
    _stageStream ??= const EventChannel(_eventChannelVpnStage)
        .receiveBroadcastStream()
        .map((event) => event.toString())
        .asBroadcastStream();
    return _stageStream!;
  }

  /// Shared broadcast stream of VPN Connection Status
  static Stream<VpnStatus?> vpnStatusSnapshot() {
    _statusStream ??= const EventChannel(_eventChannelVpnStatus)
        .receiveBroadcastStream()
        .map((event) => VpnStatus.fromJson(jsonDecode(event.toString())))
        .asBroadcastStream();
    return _statusStream!;
  }

  /// Start VPN easily (supports Per-App Split Tunneling via allowed_packages)
  static Future<void> startVpn(VpnConfig vpnConfig,
      {List<String>? allowedPackages}) async {
    final targetPkgs = allowedPackages ?? Pref.allowedAppPackages;
    return _channel.invokeMethod(
      "start",
      {
        "config": vpnConfig.config,
        "country": vpnConfig.country,
        "username": vpnConfig.username,
        "password": vpnConfig.password,
        "dns1": Pref.customDns1,
        "dns2": Pref.customDns2,
        "allowed_packages": targetPkgs.isEmpty ? null : targetPkgs,
      },
    );
  }

  /// Stop VPN
  static Future<void> stopVpn() => _channel.invokeMethod("stop");

  /// Open VPN Settings / Kill Switch
  static Future<void> openKillSwitch() => _channel.invokeMethod("kill_switch");

  /// Export .ovpn profile (iOS / Android)
  static Future<void> exportOvpnProfile(VpnConfig vpnConfig) =>
      _channel.invokeMethod(
        "export_ovpn",
        {
          "config": vpnConfig.config,
          "country": vpnConfig.country,
        },
      );

  /// Trigger native to get stage connection
  static Future<void> refreshStage() => _channel.invokeMethod("refresh");

  /// Get latest stage
  static Future<String?> stage() => _channel.invokeMethod("stage");

  /// Check if vpn is connected
  static Future<bool> isConnected() =>
      stage().then((value) => value?.toLowerCase() == "connected");

  /// Retrieve real-time OpenVPN engine connection, handshake and error logs
  static Future<String> getVpnLogs() async {
    try {
      final logs = await _channel.invokeMethod<String>("get_vpn_logs");
      return logs ?? '';
    } catch (_) {
      return '';
    }
  }

  /// Clear OpenVPN log cache
  static Future<void> clearVpnLogs() async {
    try {
      await _channel.invokeMethod("clear_vpn_logs");
    } catch (_) {}
  }

  /// List installed launchable apps on device (including Base64 app logo) for Per-App VPN/Proxy
  static Future<List<Map<String, String>>> getInstalledApps() async {
    try {
      final jsonStr = await _channel.invokeMethod<String>("get_installed_apps");
      if (jsonStr == null || jsonStr.isEmpty) return [];
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded
          .map((e) => {
                'packageName': (e['packageName'] ?? '').toString(),
                'appName': (e['appName'] ?? '').toString(),
                'iconBase64': (e['iconBase64'] ?? '').toString(),
              })
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Scan active WebSocket & persistent TCP connections per app for Anti-Spyware inspection
  static Future<List<Map<String, dynamic>>> scanActiveWebSockets() async {
    try {
      final jsonStr =
          await _channel.invokeMethod<String>("scan_active_websockets");
      if (jsonStr == null || jsonStr.isEmpty) return [];
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Check if Android Wi-Fi Router / Hotspot is currently active
  static Future<bool> getWifiRouterState() async {
    try {
      final res = await _channel.invokeMethod<bool>("get_wifi_router_state");
      return res == true;
    } catch (_) {
      return false;
    }
  }

  /// Activate or deactivate the Android Wi-Fi Router / Hotspot
  static Future<bool> setWifiRouterEnabled(bool enabled) async {
    try {
      final res = await _channel.invokeMethod<bool>(
        "set_wifi_router_enabled",
        {"enabled": enabled},
      );
      return res == true;
    } catch (_) {
      return false;
    }
  }

  /// Scan Wi-Fi radio wave proximity & ARP clients
  static Future<List<Map<String, dynamic>>> scanWifiProximity() async {
    try {
      final jsonStr =
          await _channel.invokeMethod<String>("scan_wifi_proximity");
      if (jsonStr == null || jsonStr.isEmpty) return [];
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Open Android System Wi-Fi Hotspot / Tethering Settings
  static Future<void> openHotspotSettings() =>
      _channel.invokeMethod("open_hotspot_settings");

  /// Start Floating Overlay Widget (like screen recorder / accessibility bubble)
  static Future<bool> startFloatingWidget() async {
    final res = await _channel.invokeMethod<bool>("start_floating_widget");
    return res == true;
  }

  /// Stop Floating Overlay Widget
  static Future<void> stopFloatingWidget() =>
      _channel.invokeMethod("stop_floating_widget");

  /// Check if Floating Overlay Widget is running
  static Future<bool> isFloatingWidgetRunning() async {
    final res = await _channel.invokeMethod<bool>("is_floating_widget_running");
    return res == true;
  }

  /// Open Usage Access Settings for foreground app detection
  static Future<void> requestUsageStatsPermission() =>
      _channel.invokeMethod("request_usage_stats");

  /// Start Mock GPS Location injection
  static Future<bool> startMockGps(double lat, double lon) async {
    final res = await _channel.invokeMethod<bool>(
      "start_mock_gps",
      {"lat": lat, "lon": lon},
    );
    return res == true;
  }

  /// Stop Mock GPS Location injection
  static Future<void> stopMockGps() => _channel.invokeMethod("stop_mock_gps");

  /// Open Developer Options to set Mock Location App
  static Future<void> openMockLocationSettings() =>
      _channel.invokeMethod("open_mock_location_settings");

  /// Open About Phone Settings (Step 1 of Developer Mode activation guide)
  static Future<void> openDeviceInfoSettings() =>
      _channel.invokeMethod("open_device_info_settings");

  /// Pick an image from Gallery to use as the Virtualized Camera feed
  static Future<String?> pickVirtualCameraImage() =>
      _channel.invokeMethod<String>("pick_virtual_camera_image");

  /// Apply geometric transformations (pan, zoom/stretch, rotate, flip) to the Virtual Camera image
  static Future<String?> transformVirtualCameraImage({
    required double scaleX,
    required double scaleY,
    required double offsetX,
    required double offsetY,
    required double rotation,
    required bool flipH,
    required bool flipV,
  }) async {
    try {
      return await _channel.invokeMethod<String>(
        "transform_virtual_camera_image",
        {
          "scaleX": scaleX,
          "scaleY": scaleY,
          "offsetX": offsetX,
          "offsetY": offsetY,
          "rotation": rotation,
          "flipH": flipH,
          "flipV": flipV,
        },
      );
    } catch (_) {
      return null;
    }
  }

  /// Preview/Test the Virtualized Camera activity
  static Future<void> testVirtualCamera() =>
      _channel.invokeMethod("test_virtual_camera");

  /// Update persistent NOrange status notification & native floating widget telemetry
  static Future<void> updateServiceNotification({
    required String title,
    required String subtitle,
    required String details,
    required bool isActive,
    required String mode,
  }) async {
    try {
      await _channel.invokeMethod("update_service_notification", {
        "title": title,
        "subtitle": subtitle,
        "details": details,
        "isActive": isActive,
        "mode": mode,
      });
    } catch (_) {}
  }

  /// Clear persistent NOrange status notification
  static Future<void> clearServiceNotification() async {
    try {
      await _channel.invokeMethod("clear_service_notification");
    } catch (_) {}
  }

  /// All Stages of connection
  static const String vpnConnected = "connected";
  static const String vpnDisconnected = "disconnected";
  static const String vpnWaitConnection = "wait_connection";
  static const String vpnAuthenticating = "authenticating";
  static const String vpnReconnect = "reconnect";
  static const String vpnNoConnection = "no_connection";
  static const String vpnConnecting = "connecting";
  static const String vpnPrepare = "prepare";
  static const String vpnDenied = "denied";
}
