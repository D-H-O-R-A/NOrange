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
  DateTime? _connectingStartTime;
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
    if (servers.isNotEmpty &&
        (vpn.value.openVPNConfigDataBase64.isEmpty ||
            vpn.value.ip == '177.54.144.28' ||
            vpn.value.countryLong == 'Brazil')) {
      vpn.value = servers.first;
      Pref.vpn = servers.first;
    }
    // Refresh live VPNGate nodes in background without blocking initial catalog
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
          'Protegido • ${vpn.value.countryLong} (${vpn.value.ping} ms)';
    } else if (normalized == VpnEngine.vpnDisconnected ||
        normalized == VpnEngine.vpnDenied ||
        normalized == VpnEngine.vpnNoConnection) {
      _connectionWatchdog?.cancel();
      liveByteIn.value = '0 kbps';
      liveByteOut.value = '0 kbps';
      liveDuration.value = '00:00:00';

      // OpenVPN initial startup reset emits "disconnected" or "no_connection" within the first 5s.
      // Do not treat initial engine boot reset as a connection failure.
      final elapsedMs = _connectingStartTime != null
          ? DateTime.now().difference(_connectingStartTime!).inMilliseconds
          : 99999;
      final isInitialBootReset = (normalized == VpnEngine.vpnDisconnected ||
              normalized == VpnEngine.vpnNoConnection) &&
          elapsedMs < 5000;

      if (_isConnectingAttempt &&
          !_userRequestedStop &&
          !isInitialBootReset &&
          normalized != VpnEngine.vpnDenied) {
        _isConnectingAttempt = false;
        statusHint.value = '';
        Pref.addOfflineServer(vpn.value.uniqueKey);
        _handleConnectionFailure(
          vpn.value,
          normalized == VpnEngine.vpnNoConnection
              ? 'Falha de rede ou sem conexão com a internet detectada.'
              : 'O servidor OpenVPN em ${vpn.value.countryLong} (${vpn.value.ip}) falhou ou não respondeu ao handshake. Marcado temporariamente como Fora do Ar.',
        );
      } else if (!isInitialBootReset) {
        _isConnectingAttempt = false;
        statusHint.value = '';
      }
    }
    syncSystemNotificationAndWidget();
  }

  void _handleConnectionFailure(Vpn target, String errorMsg) {
    if (Get.context != null) {
      MyDialogs.showConnectionErrorModal(
        serverCountry: target.countryLong,
        serverIp: target.ip,
        errorMessage: errorMsg,
        onConnectToAnother: () => switchServerOrModeQuickly(),
        onViewLogs: () => MyDialogs.showVpnLogsModal(Get.context!),
      );
    } else {
      MyDialogs.error(msg: errorMsg);
    }
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

  /// Validates conflicts and explains risks before turning the phone into a Shareable VPN / Proxy Gateway or Wi-Fi Router.
  Future<bool> validateAndStartGatewayServer({
    int? port,
    bool isWifiRouter = false,
    bool skipRiskPrompt = false,
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
          final agreed = await MyDialogs.showServerSharingRiskWarning(
            modeTitle: targetLabel,
            modeDescription:
                'Ao ativar o compartilhamento, outros aparelhos utilizarão o seu IP e tráfego de dados para acessar a internet.',
            portInfo: 'Porta: ${port ?? Pref.gatewayPort}',
            hasAuth: _gateway.hasAuth,
          );
          if (!agreed) return;

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
          final agreed = await MyDialogs.showServerSharingRiskWarning(
            modeTitle: targetLabel,
            modeDescription:
                'Ao ativar o compartilhamento, outros aparelhos utilizarão o seu IP e tráfego de dados para acessar a internet.',
            portInfo: 'Porta: ${port ?? Pref.gatewayPort}',
            hasAuth: _gateway.hasAuth,
          );
          if (!agreed) return;

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

    // Prompt user with full risk & legal responsibility explanation before enabling
    if (!skipRiskPrompt) {
      final agreed = await MyDialogs.showServerSharingRiskWarning(
        modeTitle: targetLabel,
        modeDescription: isWifiRouter
            ? 'Ao transformar seu celular em Roteador Wi-Fi / Hotspot com Gateway de rede, outros aparelhos e pessoas conectadas utilizarão o seu plano de internet e o seu endereço IP público para navegar.'
            : 'Ao transformar seu celular em um Servidor VPN ou Proxy HTTP/SOCKS5 para outros usuários, o seu endereço IP público e seus dados móveis serão utilizados como rota de saída na internet.',
        portInfo: 'Porta: ${port ?? Pref.gatewayPort}',
        hasAuth: _gateway.hasAuth,
      );
      if (!agreed) return false;
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

    // Filter out servers marked as offline unless all are marked
    final onlinePool = pool.where((v) => !Pref.isServerOffline(v.uniqueKey)).toList();
    final effectivePool = onlinePool.isNotEmpty ? onlinePool : pool;

    final sameCountry = effectivePool
        .where((v) =>
            v.countryLong.toLowerCase() == vpn.value.countryLong.toLowerCase() &&
            v.uniqueKey != vpn.value.uniqueKey)
        .toList();

    final nextVpn = sameCountry.isNotEmpty
        ? sameCountry.first
        : effectivePool[(effectivePool.indexWhere((v) => v.uniqueKey == vpn.value.uniqueKey) + 1) % effectivePool.length];

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
        candidates = await APIs.getVPNServers(verifyReachability: false);
      }

      if (candidates.isEmpty) {
        MyDialogs.info(
            msg: 'Nenhum servidor encontrado no momento. Tente atualizar.');
        isSmartConnecting.value = false;
        statusHint.value = '';
        return;
      }

      final nonOffline = candidates.where((v) => !Pref.isServerOffline(v.uniqueKey)).toList();
      final poolToUse = nonOffline.isNotEmpty ? nonOffline : candidates;

      final best = poolToUse.firstWhere(
        (v) => !_failedServerKeys.contains(v.uniqueKey),
        orElse: () => poolToUse.first,
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

    _connectingStartTime = DateTime.now();
    _isConnectingAttempt = true;
    final proxy = Pref.activeProxy;
    final proxyLabel =
        proxy != null ? ' via Proxy ${proxy.host}:${proxy.port}' : '';
    statusHint.value =
        'Conectando a ${target.countryLong} (${target.protocol}:${target.port})$proxyLabel...';
    vpnState.value = VpnEngine.vpnPrepare;

    _startWatchdog(target);
    await VpnEngine.startVpn(vpnConfig);
    syncSystemNotificationAndWidget();
  }

  void _startWatchdog(Vpn currentTarget) {
    _connectionWatchdog?.cancel();
    _connectionWatchdog = Timer(const Duration(seconds: 18), () async {
      if (vpnState.value != VpnEngine.vpnConnected && !_userRequestedStop) {
        _failedServerKeys.add(currentTarget.uniqueKey);
        Pref.addOfflineServer(currentTarget.uniqueKey);
        await VpnEngine.stopVpn();
        _isConnectingAttempt = false;
        vpnState.value = VpnEngine.vpnDisconnected;
        statusHint.value = '';
        syncSystemNotificationAndWidget();
        _handleConnectionFailure(
          currentTarget,
          'Tempo limite de conexão esgotado (18s). O servidor não respondeu ao handshake e foi marcado temporariamente como Fora do Ar.',
        );
      }
    });
  }

  Future<void> _triggerAutoFailover() async {
    _failoverAttempts++;
    _failedServerKeys.add(vpn.value.uniqueKey);
    Pref.addOfflineServer(vpn.value.uniqueKey);
    statusHint.value =
        'Servidor ocupado. Alternando para servidor rápido (#$_failoverAttempts)...';

    List<Vpn> pool = Pref.vpnList;
    if (pool.isEmpty) {
      pool = await APIs.getVPNServers(verifyReachability: false);
    }

    final nonOffline = pool.where((v) => !Pref.isServerOffline(v.uniqueKey)).toList();
    final effectivePool = nonOffline.isNotEmpty ? nonOffline : pool;

    for (final candidate in effectivePool) {
      if (_failedServerKeys.contains(candidate.uniqueKey)) continue;
      vpn.value = candidate;
      Pref.vpn = candidate;
      await _startConnectionWithServer(candidate);
      return;
    }

    _isConnectingAttempt = false;
    vpnState.value = VpnEngine.vpnDisconnected;
    statusHint.value = '';
    syncSystemNotificationAndWidget();
    _handleConnectionFailure(
      vpn.value,
      'Não foi possível conectar após múltiplas tentativas. Tente atualizar a lista de nós públicos.',
    );
  }

  void showVpnLogs(BuildContext context) {
    MyDialogs.showVpnLogsModal(context);
  }

  void showTermsAndPrivacy(BuildContext context) {
    MyDialogs.showPublicVpnTermsAndPrivacyModal(context);
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
