import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../apis/apis.dart';
import '../helpers/my_dialogs.dart';
import '../helpers/pref.dart';
import '../models/vpn.dart';
import '../models/vpn_config.dart';
import '../services/vpn_engine.dart';

class HomeController extends GetxController {
  final Rx<Vpn> vpn = Pref.vpn.obs;
  final vpnState = VpnEngine.vpnDisconnected.obs;
  final RxBool isSmartConnecting = false.obs;
  final RxBool autoFailover = true.obs;
  final RxString statusHint = ''.obs;

  StreamSubscription<String>? _stageSub;
  Timer? _connectionWatchdog;
  bool _userRequestedStop = false;
  bool _isConnectingAttempt = false;
  int _failoverAttempts = 0;
  final Set<String> _failedServerKeys = {};

  @override
  void onInit() {
    super.onInit();
    _stageSub = VpnEngine.vpnStageSnapshot().listen(_onStageChanged);
    VpnEngine.refreshStage();
    _ensureInitialServer();

    VpnEngine.setFloatingCommandListener((cmd, pkg, enabled) async {
      if (cmd == 'toggle_app_vpn') {
        if (enabled && pkg.isNotEmpty) {
          Pref.allowedAppPackages = [pkg];
          if (vpnState.value != VpnEngine.vpnDisconnected) {
            await VpnEngine.stopVpn();
            await Future.delayed(const Duration(milliseconds: 700));
          }
          await _startConnectionWithServer(vpn.value);
        } else {
          Pref.allowedAppPackages = [];
          await VpnEngine.stopVpn();
          vpnState.value = VpnEngine.vpnDisconnected;
        }
      }
    });
  }

  @override
  void onClose() {
    _stageSub?.cancel();
    _connectionWatchdog?.cancel();
    super.onClose();
  }

  Future<void> _ensureInitialServer() async {
    if (vpn.value.openVPNConfigDataBase64.isNotEmpty) return;
    List<Vpn> servers = Pref.vpnList;
    if (servers.isEmpty) {
      servers = await APIs.getVPNServers();
    }
    if (servers.isNotEmpty && vpn.value.openVPNConfigDataBase64.isEmpty) {
      vpn.value = servers.first;
      Pref.vpn = servers.first;
    }
  }

  void _onStageChanged(String stage) {
    final normalized = stage.toLowerCase();
    vpnState.value = normalized;

    if (normalized == VpnEngine.vpnConnected) {
      _connectionWatchdog?.cancel();
      _isConnectingAttempt = false;
      _failoverAttempts = 0;
      statusHint.value =
          'Protegido • ${vpn.value.protocol}:${vpn.value.port} (${vpn.value.ping} ms)';
    } else if (normalized == VpnEngine.vpnDisconnected ||
        normalized == VpnEngine.vpnDenied ||
        normalized == VpnEngine.vpnNoConnection) {
      _connectionWatchdog?.cancel();
      if (_isConnectingAttempt &&
          !_userRequestedStop &&
          normalized != VpnEngine.vpnDenied &&
          autoFailover.value &&
          _failoverAttempts < 2) {
        _triggerAutoFailover();
      } else {
        _isConnectingAttempt = false;
        statusHint.value = '';
      }
    }
  }

  Future<void> connectToVpn() async {
    // If currently connected or in the middle of connecting, stop/cancel
    if (vpnState.value != VpnEngine.vpnDisconnected &&
        vpnState.value != VpnEngine.vpnDenied &&
        vpnState.value != VpnEngine.vpnNoConnection) {
      _userRequestedStop = true;
      _isConnectingAttempt = false;
      _connectionWatchdog?.cancel();
      statusHint.value = '';
      await VpnEngine.stopVpn();
      vpnState.value = VpnEngine.vpnDisconnected;
      return;
    }

    if (vpn.value.openVPNConfigDataBase64.isEmpty) {
      await smartConnect();
      return;
    }

    _userRequestedStop = false;
    _failoverAttempts = 0;
    _failedServerKeys.clear();
    await _startConnectionWithServer(vpn.value);
  }

  Future<void> switchServerAndConnect(Vpn selectedVpn) async {
    _userRequestedStop = true;
    _isConnectingAttempt = false;
    _connectionWatchdog?.cancel();

    vpn.value = selectedVpn;
    Pref.vpn = selectedVpn;

    if (vpnState.value != VpnEngine.vpnDisconnected) {
      await VpnEngine.stopVpn();
      vpnState.value = VpnEngine.vpnDisconnected;
      await Future.delayed(const Duration(milliseconds: 900));
    }

    _userRequestedStop = false;
    _failoverAttempts = 0;
    _failedServerKeys.clear();
    await _startConnectionWithServer(selectedVpn);
  }

  /// Automatically finds the lowest-latency reachable server and connects.
  Future<void> smartConnect() async {
    if (isSmartConnecting.value) return;
    isSmartConnecting.value = true;
    statusHint.value = 'Buscando melhor servidor público online...';

    try {
      if (vpnState.value != VpnEngine.vpnDisconnected) {
        _userRequestedStop = true;
        await VpnEngine.stopVpn();
        await Future.delayed(const Duration(milliseconds: 600));
      }

      List<Vpn> candidates = Pref.vpnList;
      if (candidates.isEmpty) {
        candidates = await APIs.getVPNServers(verifyReachability: true);
      } else {
        await APIs.rankAndVerifyServers(candidates);
        Pref.vpnList = candidates;
      }

      if (candidates.isEmpty) {
        MyDialogs.info(
            msg: 'Nenhum servidor encontrado no momento. Tente atualizar.');
        isSmartConnecting.value = false;
        statusHint.value = '';
        return;
      }

      final best = candidates.firstWhere(
        (v) => v.isVerifiedOnline && !_failedServerKeys.contains(v.uniqueKey),
        orElse: () => candidates.first,
      );

      vpn.value = best;
      Pref.vpn = best;
      isSmartConnecting.value = false;

      _userRequestedStop = false;
      _failoverAttempts = 0;
      await _startConnectionWithServer(best);
    } catch (e) {
      isSmartConnecting.value = false;
      statusHint.value = '';
      MyDialogs.error(msg: 'Falha ao buscar servidor inteligente.');
    }
  }

  Future<void> _startConnectionWithServer(Vpn target) async {
    statusHint.value =
        'Verificando ${target.countryLong} (${target.ip}:${target.port})...';
    vpnState.value = VpnEngine.vpnPrepare;

    final reachable = await APIs.probeServer(
      target,
      timeout: const Duration(milliseconds: 2200),
    );

    if (!reachable && autoFailover.value && _failoverAttempts < 2) {
      _failedServerKeys.add(target.uniqueKey);
      await _triggerAutoFailover();
      return;
    }

    final config = target.decodedConfig;
    if (config.isEmpty) {
      vpnState.value = VpnEngine.vpnDisconnected;
      statusHint.value = '';
      MyDialogs.error(msg: 'Configuração OpenVPN inválida para este servidor.');
      return;
    }

    final vpnConfig = VpnConfig(
      country: target.countryLong,
      username: target.username.isEmpty ? 'vpn' : target.username,
      password: target.password.isEmpty ? 'vpn' : target.password,
      config: config,
    );

    _isConnectingAttempt = true;
    final proxy = Pref.activeProxy;
    final proxyLabel =
        proxy != null ? ' via Proxy ${proxy.host}:${proxy.port}' : '';
    statusHint.value =
        'Conectando a ${target.countryLong} (${target.protocol}:${target.port})$proxyLabel...';

    _startWatchdog(target);
    await VpnEngine.startVpn(vpnConfig);
  }

  void _startWatchdog(Vpn currentTarget) {
    _connectionWatchdog?.cancel();
    _connectionWatchdog = Timer(const Duration(seconds: 16), () async {
      if (vpnState.value != VpnEngine.vpnConnected && !_userRequestedStop) {
        _failedServerKeys.add(currentTarget.uniqueKey);
        await VpnEngine.stopVpn();
        if (autoFailover.value && _failoverAttempts < 2) {
          await _triggerAutoFailover();
        } else {
          _isConnectingAttempt = false;
          vpnState.value = VpnEngine.vpnDisconnected;
          statusHint.value = '';
          MyDialogs.info(
              msg:
                  'O servidor demorou para responder. Use "Smart Connect" ou escolha outro servidor.');
        }
      }
    });
  }

  Future<void> _triggerAutoFailover() async {
    _failoverAttempts++;
    _failedServerKeys.add(vpn.value.uniqueKey);
    statusHint.value =
        'Servidor ocupado. Alternando para servidor rápido (#$_failoverAttempts)...';

    List<Vpn> pool = Pref.vpnList;
    if (pool.isEmpty) {
      pool = await APIs.getVPNServers(verifyReachability: true);
    }

    for (final candidate in pool) {
      if (_failedServerKeys.contains(candidate.uniqueKey)) continue;
      final ok = await APIs.probeServer(
        candidate,
        timeout: const Duration(milliseconds: 1800),
      );
      if (ok) {
        vpn.value = candidate;
        Pref.vpn = candidate;
        await _startConnectionWithServer(candidate);
        return;
      } else {
        _failedServerKeys.add(candidate.uniqueKey);
      }
    }

    _isConnectingAttempt = false;
    vpnState.value = VpnEngine.vpnDisconnected;
    statusHint.value = '';
    MyDialogs.info(
        msg: 'Não foi possível conectar. Atualize a lista de servidores.');
  }

  Future<void> exportCurrentProfile() async {
    if (vpn.value.openVPNConfigDataBase64.isEmpty) {
      MyDialogs.info(msg: 'Selecione um servidor VPN primeiro.');
      return;
    }
    final vpnConfig = VpnConfig(
      country: vpn.value.countryLong,
      username: 'vpn',
      password: 'vpn',
      config: vpn.value.decodedConfig,
    );
    await VpnEngine.exportOvpnProfile(vpnConfig);
  }

  // vpn buttons color
  Color get getButtonColor {
    switch (vpnState.value) {
      case VpnEngine.vpnDisconnected:
      case VpnEngine.vpnDenied:
      case VpnEngine.vpnNoConnection:
        return Colors.blue;

      case VpnEngine.vpnConnected:
        return Colors.green;

      default:
        return Colors.orangeAccent;
    }
  }

  // vpn button text
  String get getButtonText {
    switch (vpnState.value) {
      case VpnEngine.vpnDisconnected:
      case VpnEngine.vpnDenied:
      case VpnEngine.vpnNoConnection:
        return 'Tap to Connect';

      case VpnEngine.vpnConnected:
        return 'Disconnect';

      default:
        return 'Cancel / Stop';
    }
  }
}
