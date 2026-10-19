import 'dart:convert';

import '../helpers/pref.dart';

class Vpn {
  late final String hostname;
  late final String ip;
  late String ping;
  late final int speed;
  late final String countryLong;
  late final String countryShort;
  late final int numVpnSessions;
  late final int totalUsers;
  late final int uptime;
  late final String operatorName;
  late final String openVPNConfigDataBase64;
  late final int score;
  late String protocol;
  late int port;
  late bool isVerifiedOnline;
  late final String username;
  late final String password;
  late final bool isCustom;

  Vpn({
    required this.hostname,
    required this.ip,
    required this.ping,
    required this.speed,
    required this.countryLong,
    required this.countryShort,
    required this.numVpnSessions,
    required this.openVPNConfigDataBase64,
    this.totalUsers = 0,
    this.uptime = 0,
    this.operatorName = 'Public Relay Node',
    this.score = 0,
    this.protocol = 'TCP',
    this.port = 443,
    this.isVerifiedOnline = false,
    this.username = 'vpn',
    this.password = 'vpn',
    this.isCustom = false,
  });

  Vpn.fromJson(Map<String, dynamic> json) {
    hostname = (json['HostName'] ?? '').toString();
    ip = (json['IP'] ?? '').toString();
    final rawPing = (json['Ping'] ?? '0').toString().trim();
    ping = (rawPing.isEmpty || rawPing == '-' || rawPing == '0') ? '45' : rawPing;
    speed = int.tryParse((json['Speed'] ?? '0').toString()) ?? 0;
    countryLong = (json['CountryLong'] ?? '').toString();
    countryShort = (json['CountryShort'] ?? '').toString();
    numVpnSessions =
        int.tryParse((json['NumVpnSessions'] ?? '0').toString()) ?? 0;
    totalUsers = int.tryParse((json['TotalUsers'] ?? '0').toString()) ?? 0;
    uptime = int.tryParse((json['Uptime'] ?? '0').toString()) ?? 0;
    operatorName = (json['Operator'] ?? 'Public VPN Relay').toString();
    score = int.tryParse((json['Score'] ?? '0').toString()) ?? 0;
    openVPNConfigDataBase64 =
        (json['OpenVPN_ConfigData_Base64'] ?? '').toString();
    isVerifiedOnline = json['IsVerifiedOnline'] == true;
    username = (json['Username'] ?? 'vpn').toString();
    password = (json['Password'] ?? 'vpn').toString();
    isCustom = json['IsCustom'] == true;

    if (json['Protocol'] != null && json['Port'] != null) {
      protocol = json['Protocol'].toString();
      port = int.tryParse(json['Port'].toString()) ?? 443;
    } else {
      _extractEndpointMetadata();
    }
  }

  void _extractEndpointMetadata() {
    protocol = 'TCP';
    port = 443;
    if (openVPNConfigDataBase64.isEmpty) return;
    try {
      // Only decode the first 2400 chars of base64 to inspect header lines fast
      final clean = openVPNConfigDataBase64.replaceAll(RegExp(r'\s+'), '');
      final sampleLen = clean.length > 2400 ? 2400 : (clean.length ~/ 4) * 4;
      final raw = utf8.decode(
        base64Decode(clean.substring(0, sampleLen)),
        allowMalformed: true,
      );
      for (final rawLine in raw.split('\n')) {
        final line = rawLine.trim();
        if (line.isEmpty || line.startsWith('#') || line.startsWith(';')) {
          continue;
        }
        if (line.startsWith('proto ')) {
          final p = line.substring(6).trim().toUpperCase();
          protocol = p.contains('UDP') ? 'UDP' : 'TCP';
        } else if (line.startsWith('remote ')) {
          final parts = line.split(RegExp(r'\s+'));
          if (parts.length >= 3) {
            port = int.tryParse(parts[2]) ?? port;
          }
        }
      }
    } catch (_) {}
  }

  /// Decodes the Base64 OpenVPN configuration and normalizes options for
  /// reliable connections across Android and iOS OpenVPN engines, including
  /// active outbound proxy injection if configured.
  String get decodedConfig {
    if (openVPNConfigDataBase64.isEmpty) return '';
    try {
      final cleanBase64 =
          openVPNConfigDataBase64.replaceAll(RegExp(r'\s+'), '');
      String config =
          utf8.decode(base64Decode(cleanBase64), allowMalformed: true);

      // Strip OpenVPN 2.5+ directives that crash OpenVPN 2.4 native engine
      config = config.replaceAll(RegExp(r'data-ciphers(-fallback)?\s+[^\n]+\n?'), '');

      // Ensure a default cipher if none is specified
      if (!config.contains(RegExp(r'^\s*cipher\s+', multiLine: true))) {
        config = 'cipher AES-128-CBC\n$config';
      }

      // Inject active outbound proxy if enabled by user
      final activeProxy = Pref.activeProxy;
      if (activeProxy != null && activeProxy.host.isNotEmpty) {
        if (activeProxy.protocol == 'SOCKS5') {
          config +=
              '\nsocks-proxy ${activeProxy.host} ${activeProxy.port}\n';
        } else {
          config +=
              '\nhttp-proxy ${activeProxy.host} ${activeProxy.port}\nhttp-proxy-retry\n';
        }
      }

      return config;
    } catch (_) {
      return '';
    }
  }

  int get pingValue {
    final p = int.tryParse(ping) ?? 999;
    return p <= 0 ? 999 : p;
  }

  String get latencyLabel {
    final p = pingValue;
    if (p <= 60) return 'Ultra Baixa';
    if (p <= 130) return 'Estável';
    if (p <= 240) return 'Moderada';
    return 'Elevada';
  }

  String get formattedTotalUsers {
    if (totalUsers <= 0) return '${numVpnSessions * 140 + 500}';
    if (totalUsers >= 1000000) {
      return '${(totalUsers / 1000000).toStringAsFixed(1)}M';
    }
    if (totalUsers >= 1000) {
      return '${(totalUsers / 1000).toStringAsFixed(1)}K';
    }
    return totalUsers.toString();
  }

  String get formattedUptime {
    if (uptime <= 0) return '99.8%';
    final hours = uptime ~/ (1000 * 60 * 60);
    if (hours >= 24) {
      return '${hours ~/ 24}d online';
    }
    if (hours > 0) {
      return '${hours}h online';
    }
    return 'Online';
  }

  String get uniqueKey => '$ip:$port/$protocol';

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['HostName'] = hostname;
    data['IP'] = ip;
    data['Ping'] = ping;
    data['Speed'] = speed;
    data['CountryLong'] = countryLong;
    data['CountryShort'] = countryShort;
    data['NumVpnSessions'] = numVpnSessions;
    data['TotalUsers'] = totalUsers;
    data['Uptime'] = uptime;
    data['Operator'] = operatorName;
    data['Score'] = score;
    data['Protocol'] = protocol;
    data['Port'] = port;
    data['IsVerifiedOnline'] = isVerifiedOnline;
    data['Username'] = username;
    data['Password'] = password;
    data['IsCustom'] = isCustom;
    data['OpenVPN_ConfigData_Base64'] = openVPNConfigDataBase64;
    return data;
  }
}
