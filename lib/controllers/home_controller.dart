import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../apis/apis.dart';
import '../helpers/my_dialogs.dart';
import '../helpers/pref.dart';
import '../models/proxy_config.dart';
import '../models/vpn.dart';
import '../models/vpn_config.dart';
import '../models/vpn_status.dart';
import '../screens/advanced_settings_screen.dart';
import '../screens/network_test_screen.dart';
import '../services/vpn_engine.dart';
import '../services/vpn_gateway_proxy_service.dart';

class HomeController extends GetxController {
  final Rx<Vpn> vpn = Pref.vpn.obs;
  final vpnState = VpnEngine.vpnDisconnected.obs;
  final RxBool isSmartConnecting = false.obs;
  final RxBool autoFailover = true.obs;
  final RxString statusHint = ''.obs;
  final RxString activeProxyIdRx = Pref.activeProxyId.obs;

  // Live telemetry fields for Notification Bar & Floating Widget
  final RxString liveByteIn = '0 kbps'.obs;
  final RxString liveByteOut = '0 kbps'.obs;
  final RxString liveDuration = '00:00:00'.obs;

  StreamSubscription<String>? _stageSub;
  StreamSubscription<VpnStatus?>? _statusSub;
  Timer? _connectionWatchdog;
  bool _userRequestedStop = false;
  bool _isConnectingAttempt = false;
  int _failoverAttempts = 0;
  final Set<String> _failedServerKeys = {};

  VpnGatewayProxyService get _gateway => VpnGatewayProxyService.instance;

  @override
  void onInit() {
    super.onInit();
    _stageSub = VpnEngine.vpnStageSnapshot().listen(_onStageChanged);
    _statusSub = VpnEngine.vpnStatusSnapshot().listen(_onVpnStatusChanged);
    VpnEngine.refreshStage();
    _ensureInitialServer();

    // Sync notification whenever gateway server state changes
    ever(_gateway.isRunning, (_) => syncSystemNotificationAndWidget());

    VpnEngine.setFloatingCommandListener((cmd, pkg, enabled) async {
      switch (cmd) {
        case 'toggle_app_vpn':
          if (enabled && pkg.isNotEmpty) {
            if (_gateway.isRunning.value) {
              final resolved = await MyDialogs.showConflictPopup(
                conflictTitle: 'Gateway Compartilhado Ativo',
                activeModeName:
                    'Celular como VPN/Gateway (${_gateway.primaryIp}:${_gateway.listeningPort.value})',
                targetModeName: 'VPN Isolada por App ($pkg)',
                technicalExplanation:
                    'Por motivos técnicos, não é possível iniciar um túnel VPN cliente por aplicativo enquanto o seu celular está atuando como Servidor/Gateway VPN compartilhável para outros dispositivos.',
                onResolveConflict: () async {
                  await _gateway.stopServer();
                  await _activateAppVpnForPackage(pkg);
                },
              );
              if (!resolved) return;
            } else {
              await _activateAppVpnForPackage(pkg);
            }
          } else {
            Pref.allowedAppPackages = [];
            await VpnEngine.stopVpn();
            vpnState.value = VpnEngine.vpnDisconnected;
            syncSystemNotificationAndWidget();
          }
          break;

        case 'toggle_connection':
          await toggleActiveNetworkModeFromNotification();
          break;

        case 'switch_connection':
          await switchServerOrModeQuickly();
          break;

        case 'open_details':
          Get.to(() => const NetworkTestScreen());
          break;

        case 'open_vcam_studio':
          Get.to(() => const AdvancedSettingsScreen(initialTabIndex: 4));
          break;
      }
    });
  }

  Future<void> _activateAppVpnForPackage(String pkg) async {
    Pref.allowedAppPackages = [pkg];
    if (vpnState.value != VpnEngine.vpnDisconnected) {
      await VpnEngine.stopVpn();
      await Future.delayed(const Duration(milliseconds: 700));
    }
    await _startConnectionWithServer(vpn.value);
  }

  @override
  void onClose() {
    _stageSub?.cancel();
    _statusSub?.cancel();
    _connectionWatchdog?.cancel();
    super.onClose();
  }

  void _onVpnStatusChanged(VpnStatus? status) {
    if (status == null) return;
    final bIn = (status.byteIn ?? '').trim();
    final bOut = (status.byteOut ?? '').trim();
    final dur = (status.duration ?? '').trim();
    if (bIn.isNotEmpty) liveByteIn.value = bIn;
    if (bOut.isNotEmpty) liveByteOut.value = bOut;
    if (dur.isNotEmpty) liveDuration.value = dur;
    if (vpnState.value == VpnEngine.vpnConnected) {
      syncSystemNotificationAndWidget();
    }
  }

  Future<void> _ensureInitialServer() async {
    List<Vpn> servers = await APIs.ensureMinimumGlobalCatalog();
    if (servers.isNotEmpty && vpn.value.openVPNConfigDataBase64.isEmpty) {
      vpn.value = servers.first;
      Pref.vpn = servers.first;
    }
    // Refresh live VPNGate nodes in background without blocking initial 55+ catalog
    APIs.getVPNServers(verifyReachability: false);
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
      liveByteIn.value = '0 kbps';
      liveByteOut.value = '0 kbps';
      liveDuration.value = '00:00:00';
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
    syncSystemNotificationAndWidget();
  }

  // ===========================================================================
  // MUTUAL EXCLUSION & CONFLICT VALIDATION ENGINE (ALL SCENARIOS)
  // ===========================================================================

  /// Validates conflicts before starting the Client VPN.
  Future<bool> _validateBeforeStartingClientVpn() async {
    // Conflict 1: Phone is currently acting as a Shareable VPN Gateway / Wi-Fi Router
    if (_gateway.isRunning.value) {
      final resolved = await MyDialogs.showConflictPopup(
        conflictTitle: 'Celular Atuando como VPN / Gateway',
        activeModeName:
            'Servidor VPN/Proxy Local (${_gateway.primaryIp}:${_gateway.listeningPort.value})',
        targetModeName: 'VPN Cliente (${vpn.value.countryLong})',
        technicalExplanation:
            'Por motivos técnicos, você não pode conectar o seu celular como cliente de outra VPN enquanto ele está hospedando um Gateway VPN/Proxy compartilhável ou Roteador Inspetor. Isso causaria colisão na tabela de roteamento NAT e loop de túnel.',
        onResolveConflict: () async {
          await _gateway.stopServer();
          await connectToVpn(skipValidation: true);
        },
      );
      return resolved;
    }

    // Conflict 2: Standalone Outbound Proxy is currently enabled
    final activeProxy = Pref.activeProxy;
    if (activeProxy != null) {
      final resolved = await MyDialogs.showConflictPopup(
        conflictTitle: 'Proxy Cliente Exclusivo Ativo',
        activeModeName: 'Proxy ${activeProxy.displayTitle}',
        targetModeName: 'VPN Cliente (${vpn.value.countryLong})',
        technicalExplanation:
            'Há um Proxy Cliente externo ativo (${activeProxy.host}:${activeProxy.port}). Iniciar um túnel OpenVPN completo simultaneamente gera conflito de rota padrão (Default Gateway) e interceptação de sockets. Desative o Proxy Cliente para iniciar a VPN.',
        onResolveConflict: () async {
          Pref.activeProxyId = '';
          activeProxyIdRx.value = '';
          syncSystemNotificationAndWidget();
          await connectToVpn(skipValidation: true);
        },
      );
      return resolved;
    }

    return true;
  }

  /// Validates conflicts before turning the phone into a Shareable VPN / Proxy Gateway or Wi-Fi Router.
  Future<bool> validateAndStartGatewayServer({
    int? port,
    bool isWifiRouter = false,
  }) async {
    final targetLabel = isWifiRouter
        ? 'Roteador Wi-Fi + Inspetor de Rede'
        : 'Celular como VPN/Proxy Compartilhável';

    // Conflict 1: Client VPN is currently connected or connecting
    if (vpnState.value != VpnEngine.vpnDisconnected &&
        vpnState.value != VpnEngine.vpnDenied &&
        vpnState.value != VpnEngine.vpnNoConnection) {
      await MyDialogs.showConflictPopup(
        conflictTitle: 'VPN Cliente Já Está Conectada',
        activeModeName:
            'VPN Cliente (${vpn.value.countryLong} • ${vpn.value.ip})',
        targetModeName: targetLabel,
        technicalExplanation:
            'Por motivos técnicos, não há como tornar o seu celular uma VPN/Gateway compartilhável ou Roteador Inspetor estando conectado a outra VPN externa. A interface tun0 sequestra a rota padrão e impede que outros dispositivos usem seu celular como gateway.',
        onResolveConflict: () async {
          _userRequestedStop = true;
          _isConnectingAttempt = false;
          _connectionWatchdog?.cancel();
          await VpnEngine.stopVpn();
          vpnState.value = VpnEngine.vpnDisconnected;
          await Future.delayed(const Duration(milliseconds: 500));
          await _gateway.startServer(port: port ?? Pref.gatewayPort);
          syncSystemNotificationAndWidget();
          MyDialogs.success(
            msg:
                '$targetLabel iniciado em ${_gateway.primaryIp}:${_gateway.listeningPort.value}',
          );
        },
      );
      return false;
    }

    // Conflict 2: Outbound Proxy is active
    final activeProxy = Pref.activeProxy;
    if (activeProxy != null) {
      await MyDialogs.showConflictPopup(
        conflictTitle: 'Proxy Cliente Externo Ativo',
        activeModeName: 'Proxy ${activeProxy.displayTitle}',
        targetModeName: targetLabel,
        technicalExplanation:
            'O seu celular está configurado para redirecionar conexões para um Proxy externo (${activeProxy.host}:${activeProxy.port}). Para hospedar um Servidor VPN/Proxy limpo e estável para outros aparelhos, é necessário desativar o Proxy Cliente primeiro.',
        onResolveConflict: () async {
          Pref.activeProxyId = '';
          activeProxyIdRx.value = '';
          await _gateway.startServer(port: port ?? Pref.gatewayPort);
          syncSystemNotificationAndWidget();
          MyDialogs.success(
            msg:
                '$targetLabel iniciado em ${_gateway.primaryIp}:${_gateway.listeningPort.value}',
          );
        },
      );
      return false;
    }

    final ok = await _gateway.startServer(port: port ?? Pref.gatewayPort);
    syncSystemNotificationAndWidget();
    return ok;
  }

  /// Validates conflicts before activating an Outbound Proxy Client.
  Future<bool> validateAndActivateProxy(ProxyConfig proxy) async {
    // Conflict 1: Loopback check (pointing client proxy to phone's own local gateway IP/port)
    if ((proxy.host == '127.0.0.1' ||
            proxy.host == 'localhost' ||
            _gateway.localIps.contains(proxy.host)) &&
        proxy.port == _gateway.listeningPort.value &&
        _gateway.isRunning.value) {
      await MyDialogs.showConflictPopup(
        conflictTitle: 'Loopback Infinito Detectado',
        activeModeName:
            'Gateway Local (${_gateway.primaryIp}:${_gateway.listeningPort.value})',
        targetModeName: 'Proxy Cliente (${proxy.host}:${proxy.port})',
        technicalExplanation:
            'Você está tentando conectar o Proxy Cliente ao próprio endereço e porta do servidor Gateway local do seu celular. Isso criaria um loop infinito de pacotes (Loopback Storm).',
        onResolveConflict: () async {
          await _gateway.stopServer();
          Pref.activeProxyId = proxy.id;
          activeProxyIdRx.value = proxy.id;
          syncSystemNotificationAndWidget();
          MyDialogs.success(msg: 'Proxy ${proxy.displayTitle} ativado!');
        },
      );
      return false;
    }

    // Conflict 2: Client VPN is currently connected
    if (vpnState.value != VpnEngine.vpnDisconnected &&
        vpnState.value != VpnEngine.vpnDenied &&
        vpnState.value != VpnEngine.vpnNoConnection) {
      await MyDialogs.showConflictPopup(
        conflictTitle: 'Túnel VPN Cliente Ativo',
        activeModeName: 'VPN Cliente (${vpn.value.countryLong})',
        targetModeName: 'Proxy Cliente (${proxy.displayTitle})',
        technicalExplanation:
            'A VPN Cliente já está criptografando e roteando todo o tráfego do dispositivo. Ativar um Proxy Cliente separado enquanto a VPN está conectada causa conflito de roteamento. Desligue a VPN Cliente para usar apenas o Proxy.',
        onResolveConflict: () async {
          _userRequestedStop = true;
          await VpnEngine.stopVpn();
          vpnState.value = VpnEngine.vpnDisconnected;
          Pref.activeProxyId = proxy.id;
          activeProxyIdRx.value = proxy.id;
          syncSystemNotificationAndWidget();
          MyDialogs.success(msg: 'Proxy ${proxy.displayTitle} ativado!');
        },
      );
      return false;
    }

    // Conflict 3: Local Shareable Gateway is running
    if (_gateway.isRunning.value) {
      await MyDialogs.showConflictPopup(
        conflictTitle: 'Servidor Gateway Compartilhado Ativo',
        activeModeName:
            'Gateway Local (${_gateway.primaryIp}:${_gateway.listeningPort.value})',
        targetModeName: 'Proxy Cliente (${proxy.displayTitle})',
        technicalExplanation:
            'O celular está hospedando um Gateway compartilhável. Por segurança de roteamento, não é permitido ativar um Proxy Cliente externo ao mesmo tempo.',
        onResolveConflict: () async {
          await _gateway.stopServer();
          Pref.activeProxyId = proxy.id;
          activeProxyIdRx.value = proxy.id;
          syncSystemNotificationAndWidget();
          MyDialogs.success(msg: 'Proxy ${proxy.displayTitle} ativado!');
        },
      );
      return false;
    }

    Pref.activeProxyId = proxy.id;
    activeProxyIdRx.value = proxy.id;
    syncSystemNotificationAndWidget();
    return true;
  }

  void deactivateProxy() {
    Pref.activeProxyId = '';
    activeProxyIdRx.value = '';
    syncSystemNotificationAndWidget();
  }

  // ===========================================================================
  // PERSISTENT NOTIFICATION BAR & FLOATING WIDGET TELEMETRY SYNC
  // ===========================================================================

  String get currentActiveModeTitle {
    if (vpnState.value == VpnEngine.vpnConnected) {
      return 'VPN Ativa • ${vpn.value.countryLong}';
    } else if (vpnState.value == VpnEngine.vpnConnecting ||
        vpnState.value == VpnEngine.vpnPrepare ||
        vpnState.value == VpnEngine.vpnAuthenticating) {
      return 'Conectando VPN • ${vpn.value.countryLong}';
    } else if (_gateway.isRunning.value) {
      return 'Gateway / Roteador • ${_gateway.primaryIp}:${_gateway.listeningPort.value}';
    } else if (Pref.activeProxy != null) {
      final p = Pref.activeProxy!;
      return 'Proxy Ativo • ${p.type} ${p.host}:${p.port}';
    }
    return 'NOrange Standby • Desprotegido';
  }

  String get currentConnectionFullDetails {
    final splitApps = Pref.allowedAppPackages.length;
    final splitText =
        splitApps > 0 ? 'Isolado ($splitApps app)' : 'Túnel Global';

    if (vpnState.value == VpnEngine.vpnConnected) {
      final v = vpn.value;
      return 'Endpoint: ${v.ip}:${v.port} (${v.protocol}) • Ping: ${v.ping}ms (${v.latencyLabel})\n'
          'Velocidade: DL ${liveByteIn.value} | UL ${liveByteOut.value} • Sessão: ${liveDuration.value}\n'
          'Escopo: $splitText • DNS: ${Pref.customDns1} • Sessões Públicas: ${v.numVpnSessions}';
    } else if (_gateway.isRunning.value) {
      return 'Host Local: ${_gateway.primaryIp}:${_gateway.listeningPort.value} (HTTP/SOCKS5/OVPN)\n'
          'Clientes Conectados: ${_gateway.peerStats.length} (${_gateway.activeConnections.value} conexões ativas)\n'
          'Tráfego Relayed: ${_gateway.formattedBytesRelayed} • DNS: ${Pref.customDns1}';
    } else if (Pref.activeProxy != null) {
      final p = Pref.activeProxy!;
      return 'Servidor Proxy: ${p.host}:${p.port} • Protocolo: ${p.type}\n'
          'Autenticação: ${p.hasAuth ? "Ativa (${p.username})" : "Sem senha"} • Escopo: $splitText\n'
          'DNS Primário: ${Pref.customDns1} • Status: Encaminhamento Ativo';
    }
    final v = vpn.value;
    return 'Pronto para conectar • Servidor selecionado: ${v.countryLong} (${v.ip}:${v.port})\n'
        'Ping estimado: ${v.ping} ms • Toque em Ligar ou Trocar Servidor.';
  }

  bool get isAnyNetworkModeActive =>
      vpnState.value == VpnEngine.vpnConnected ||
      vpnState.value == VpnEngine.vpnConnecting ||
      _gateway.isRunning.value ||
      Pref.activeProxy != null;

  Future<void> syncSystemNotificationAndWidget() async {
    activeProxyIdRx.value = Pref.activeProxyId;
    final active = isAnyNetworkModeActive;
    final mode = vpnState.value == VpnEngine.vpnConnected
        ? 'vpn'
        : (_gateway.isRunning.value
            ? 'gateway'
            : (Pref.activeProxy != null ? 'proxy' : 'idle'));

    await VpnEngine.updateServiceNotification(
      title: currentActiveModeTitle,
      subtitle: active ? 'Conexão NOrange em operação' : 'NOrange em espera',
      details: currentConnectionFullDetails,
      isActive: active,
      mode: mode,
    );
  }

  /// Toggles whichever network mode is active (or starts VPN if idle) from Notification / Widget.
  Future<void> toggleActiveNetworkModeFromNotification() async {
    if (vpnState.value != VpnEngine.vpnDisconnected) {
      await connectToVpn();
    } else if (_gateway.isRunning.value) {
      await _gateway.stopServer();
      syncSystemNotificationAndWidget();
      MyDialogs.info(msg: 'Gateway / Roteador NOrange desligado.');
    } else if (Pref.activeProxy != null) {
      deactivateProxy();
      MyDialogs.info(msg: 'Proxy Cliente NOrange desligado.');
    } else {
      await connectToVpn();
    }
  }

  /// Quickly switches to the next best public VPN server (or next proxy if in proxy mode).
  Future<void> switchServerOrModeQuickly() async {
    if (Pref.activeProxy != null && Pref.proxyList.length > 1) {
      final list = Pref.proxyList;
      final idx = list.indexWhere((p) => p.id == Pref.activeProxyId);
      final next = list[(idx + 1) % list.length];
      Pref.activeProxyId = next.id;
      activeProxyIdRx.value = next.id;
      syncSystemNotificationAndWidget();
      MyDialogs.success(
        msg: 'Proxy alternado para ${next.displayTitle}',
      );
      return;
    }

    List<Vpn> pool = Pref.vpnList;
    if (pool.isEmpty) {
      pool = await APIs.getVPNServers(verifyReachability: false);
    }
    if (pool.isEmpty) return;

    final curIdx = pool.indexWhere((v) => v.uniqueKey == vpn.value.uniqueKey);
    final nextVpn = pool[(curIdx + 1) % pool.length];
    MyDialogs.info(
      msg:
          'Alternando para ${nextVpn.countryLong} (${nextVpn.ip} • ${nextVpn.ping} ms)...',
    );
    await switchServerAndConnect(nextVpn);
  }

  // ===========================================================================
  // CORE VPN CONNECTION FLOW
  // ===========================================================================

  Future<void> connectToVpn({bool skipValidation = false}) async {
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
      syncSystemNotificationAndWidget();
      return;
    }

    if (!skipValidation) {
      final allowed = await _validateBeforeStartingClientVpn();
      if (!allowed) return;
    }

    if (vpn.value.openVPNConfigDataBase64.isEmpty) {
      await smartConnect(skipValidation: true);
      return;
    }

    _userRequestedStop = false;
    _failoverAttempts = 0;
    _failedServerKeys.clear();
    await _startConnectionWithServer(vpn.value);
  }

  Future<void> switchServerAndConnect(Vpn selectedVpn) async {
    final allowed = await _validateBeforeStartingClientVpn();
    if (!allowed) return;

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
  Future<void> smartConnect({bool skipValidation = false}) async {
    if (isSmartConnecting.value) return;
    if (!skipValidation) {
      final allowed = await _validateBeforeStartingClientVpn();
      if (!allowed) return;
    }

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
    syncSystemNotificationAndWidget();

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
      syncSystemNotificationAndWidget();
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
    syncSystemNotificationAndWidget();
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
          syncSystemNotificationAndWidget();
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
    syncSystemNotificationAndWidget();
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
        return const Color(0xFFFF6B00); // Solar Orange primary action

      case VpnEngine.vpnConnected:
        return const Color(0xFFFF7A1A); // Active Encrypted Orange

      default:
        return const Color(0xFFFF9E3D); // Handshaking Warm Amber
    }
  }

  // vpn button text
  String get getButtonText {
    switch (vpnState.value) {
      case VpnEngine.vpnDisconnected:
      case VpnEngine.vpnDenied:
      case VpnEngine.vpnNoConnection:
        return 'CONNECT';

      case VpnEngine.vpnConnected:
        return 'PROTECTED';

      default:
        return 'CANCEL';
    }
  }
}
