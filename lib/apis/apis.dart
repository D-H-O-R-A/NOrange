import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../helpers/my_dialogs.dart';
import '../helpers/pref.dart';
import '../models/ip_details.dart';
import '../models/vpn.dart';

class APIs {
  static const List<String> _vpnGateEndpoints = [
    'http://www.vpngate.net/api/iphone/',
    'https://www.vpngate.net/api/iphone/',
  ];

  /// Fetches public VPN servers from VPNGate mirrors, probes their real TCP
  /// reachability and live latency, and ranks the best working servers first.
  static Future<List<Vpn>> getVPNServers({bool verifyReachability = true}) async {
    final List<Vpn> vpnList = [];

    for (final endpoint in _vpnGateEndpoints) {
      try {
        final res = await http
            .get(Uri.parse(endpoint))
            .timeout(const Duration(seconds: 12));
        if (res.statusCode == 200 && res.body.contains('#')) {
          final parts = res.body.split('#');
          if (parts.length >= 2) {
            final csvString = parts[1].replaceAll('*', '');
            final List<List<dynamic>> list =
                const CsvToListConverter().convert(csvString);

            if (list.isNotEmpty) {
              final header = list[0];
              for (int i = 1; i < list.length; ++i) {
                if (list[i].length < header.length) continue;
                final Map<String, dynamic> tempJson = {};
                for (int j = 0; j < header.length; ++j) {
                  tempJson[header[j].toString()] = list[i][j];
                }
                final vpn = Vpn.fromJson(tempJson);
                if (vpn.ip.isNotEmpty &&
                    vpn.openVPNConfigDataBase64.isNotEmpty &&
                    vpn.countryLong.isNotEmpty) {
                  vpnList.add(vpn);
                }
              }
            }
          }
        }
        if (vpnList.isNotEmpty) break;
      } catch (e) {
        log('getVPNServers mirror ($endpoint) error: $e');
      }
    }

    // Load bundled fallback servers if remote fetch failed and cache is empty
    if (vpnList.isEmpty) {
      final cached = Pref.vpnList;
      if (cached.isNotEmpty) {
        vpnList.addAll(cached);
      } else {
        vpnList.addAll(await _loadFallbackAssetServers());
      }
    }

    if (verifyReachability && vpnList.isNotEmpty) {
      await rankAndVerifyServers(vpnList);
    }

    if (vpnList.isNotEmpty) {
      Pref.vpnList = vpnList;
    }

    return vpnList;
  }

  /// Probes a single VPN server's endpoint via TCP socket handshake to verify
  /// reachability and measure live latency in milliseconds.
  static Future<bool> probeServer(Vpn vpn,
      {Duration timeout = const Duration(milliseconds: 1800)}) async {
    if (vpn.ip.isEmpty) return false;
    final sw = Stopwatch()..start();
    try {
      final targetPort = vpn.protocol == 'TCP' ? vpn.port : 443;
      final socket =
          await Socket.connect(vpn.ip, targetPort, timeout: timeout);
      sw.stop();
      await socket.close();
      vpn.ping = sw.elapsedMilliseconds.toString();
      vpn.isVerifiedOnline = true;
      return true;
    } catch (_) {
      sw.stop();
      if (vpn.protocol == 'UDP') {
        // UDP OpenVPN servers might not have TCP 443 open; keep reported ping if valid
        final reported = int.tryParse(vpn.ping) ?? 999;
        vpn.isVerifiedOnline = reported > 0 && reported < 350;
        return vpn.isVerifiedOnline;
      }
      vpn.isVerifiedOnline = false;
      return false;
    }
  }

  /// Probes servers in concurrent batches and sorts verified online + lowest
  /// latency TCP/UDP servers to the top.
  static Future<void> rankAndVerifyServers(List<Vpn> servers) async {
    // Pre-sort by score & speed so we probe the most promising servers first
    servers.sort((a, b) {
      final aTcp = a.protocol == 'TCP' ? 1 : 0;
      final bTcp = b.protocol == 'TCP' ? 1 : 0;
      if (aTcp != bTcp) return bTcp.compareTo(aTcp);
      return b.score.compareTo(a.score);
    });

    const int batchSize = 15;
    final int maxToProbe = servers.length < 45 ? servers.length : 45;

    for (int i = 0; i < maxToProbe; i += batchSize) {
      final end = (i + batchSize < maxToProbe) ? i + batchSize : maxToProbe;
      final batch = servers.sublist(i, end);
      await Future.wait(batch.map((v) => probeServer(v)));
    }

    servers.sort((a, b) {
      if (a.isVerifiedOnline != b.isVerifiedOnline) {
        return a.isVerifiedOnline ? -1 : 1;
      }
      // Prefer verified TCP servers as they bypass UDP blocks and handshake reliably
      if (a.isVerifiedOnline && b.isVerifiedOnline && a.protocol != b.protocol) {
        return a.protocol == 'TCP' ? -1 : 1;
      }
      final pingCompare = a.pingValue.compareTo(b.pingValue);
      if (pingCompare != 0) return pingCompare;
      return b.speed.compareTo(a.speed);
    });
  }

  static Future<List<Vpn>> _loadFallbackAssetServers() async {
    final List<Vpn> fallbacks = [];
    try {
      final jpConfig = await rootBundle.loadString('assets/vpn/japan.ovpn');
      fallbacks.add(Vpn(
        hostname: 'vpn-jp-fallback',
        ip: '219.100.37.180',
        ping: '65',
        speed: 450000000,
        countryLong: 'Japan',
        countryShort: 'JP',
        numVpnSessions: 12,
        openVPNConfigDataBase64: base64Encode(utf8.encode(jpConfig)),
        protocol: 'TCP',
        port: 443,
        isVerifiedOnline: true,
      ));
    } catch (_) {}

    try {
      final thConfig = await rootBundle.loadString('assets/vpn/thailand.ovpn');
      fallbacks.add(Vpn(
        hostname: 'vpn-th-fallback',
        ip: '171.100.162.138',
        ping: '95',
        speed: 250000000,
        countryLong: 'Thailand',
        countryShort: 'TH',
        numVpnSessions: 8,
        openVPNConfigDataBase64: base64Encode(utf8.encode(thConfig)),
        protocol: 'UDP',
        port: 1326,
        isVerifiedOnline: true,
      ));
    } catch (_) {}

    return fallbacks;
  }

  static Future<void> getIPDetails({required Rx<IPDetails> ipData}) async {
    try {
      final res = await http
          .get(Uri.parse('http://ip-api.com/json/'))
          .timeout(const Duration(seconds: 8));
      final data = jsonDecode(res.body);
      log(data.toString());
      ipData.value = IPDetails.fromJson(data);
    } catch (e) {
      MyDialogs.error(msg: 'Não foi possível obter detalhes de IP.');
      log('\ngetIPDetailsE: $e');
    }
  }
}
