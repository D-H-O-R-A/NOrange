import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../controllers/home_controller.dart';
import '../helpers/my_dialogs.dart';
import '../helpers/pref.dart';
import '../models/proxy_config.dart';
import '../models/vpn.dart';
import '../services/vpn_engine.dart';
import '../services/vpn_gateway_proxy_service.dart';
import '../theme/app_theme.dart';
import '../widgets/norange_logo.dart';
import '../widgets/norange_floating_widget.dart';

class AdvancedSettingsScreen extends StatefulWidget {
  final int initialTabIndex;

  const AdvancedSettingsScreen({super.key, this.initialTabIndex = 0});

  @override
  State<AdvancedSettingsScreen> createState() => _AdvancedSettingsScreenState();
}

class _AdvancedSettingsScreenState extends State<AdvancedSettingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final VpnGatewayProxyService _gateway = VpnGatewayProxyService.instance;
  final HomeController _homeController = Get.find<HomeController>();

  // Tab 1: Custom VPN state
  final RxList<Vpn> _customVpns = <Vpn>[].obs;
  final _dns1Controller = TextEditingController();
  final _dns2Controller = TextEditingController();

  // Tab 2 & 3: Gateway / Shareable VPN & Proxy Host state
  final _gatewayPortController = TextEditingController();
  final _gatewayUserController = TextEditingController();
  final _gatewayPassController = TextEditingController();
  final RxBool _gatewayRequireAuth = false.obs;
  final RxList<ProxyConfig> _proxies = <ProxyConfig>[].obs;
  final RxString _activeProxyId = ''.obs;

  // Tab 4: Wi-Fi Router, WebSocket Anti-Spyware & Wave Proximity Radar state
  final RxList<Map<String, dynamic>> _wifiProximityList =
      <Map<String, dynamic>>[].obs;
  final RxBool _isScanningWifi = false.obs;
  final RxString _routerSourceMode = 'Dados Móveis (4G/5G)'.obs;
  final RxMap<String, dynamic> _wifiRouterState = <String, dynamic>{}.obs;
  final RxList<Map<String, dynamic>> _activeWebSockets =
      <Map<String, dynamic>>[].obs;
  final RxBool _isScanningWebSockets = false.obs;

  // Tab 5: Floating Widget, Per-App VPN, Mock GPS & Virtual Camera state
  final RxBool _floatingRunning = false.obs;
  final RxList<Map<String, String>> _installedApps =
      <Map<String, String>>[].obs;
  final RxList<String> _selectedAllowedApps = <String>[].obs;
  final RxString _appSearchQuery = ''.obs;
  final RxBool _mockGpsActive = false.obs;
  final _mockLatController = TextEditingController();
  final _mockLonController = TextEditingController();
  final RxString _virtualCamPath = ''.obs;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _customVpns.assignAll(Pref.customVpnList);
    _proxies.assignAll(Pref.proxyList);
    _activeProxyId.value = Pref.activeProxyId;
    _dns1Controller.text = Pref.customDns1;
    _dns2Controller.text = Pref.customDns2;
    _gatewayPortController.text = _gateway.listeningPort.value.toString();
    _gatewayUserController.text = _gateway.authUser.value;
    _gatewayPassController.text = _gateway.authPass.value;
    _gatewayRequireAuth.value = _gateway.authUser.value.trim().isNotEmpty;

    _selectedAllowedApps.assignAll(Pref.allowedAppPackages);
    _mockLatController.text = Pref.mockLat.toStringAsFixed(6);
    _mockLonController.text = Pref.mockLon.toStringAsFixed(6);
    _virtualCamPath.value = Pref.virtualCameraImagePath;

    _gateway.refreshLocalIps();
    _gateway.refreshPublicIp();
    _loadInitialDeviceData();
  }

  Future<void> _loadInitialDeviceData() async {
    _floatingRunning.value = await VpnEngine.isFloatingWidgetRunning();
    await _refreshWifiRouterState();
    
    // Load heavy device lists progressively after frame rendering
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final apps = await VpnEngine.getInstalledApps();
      if (mounted) _installedApps.assignAll(apps);
      
      Future.delayed(const Duration(milliseconds: 300), () async {
        if (!mounted) return;
        await _scanWebSockets();
        await _scanWifiWaves();
      });
    });
  }

  Future<void> _refreshWifiRouterState() async {
    final isActive = await VpnEngine.getWifiRouterState();
    _wifiRouterState.assignAll({
      'routerActive': isActive,
      'wifiEnabled': isActive,
      'hotspotActive': isActive,
      'ssid': isActive ? 'Roteador Wi-Fi Ativo' : 'Roteador Inativo',
    });
  }

  bool get _isWifiRouterDetectedActive {
    final nativeActive = _wifiRouterState['routerActive'] == true ||
        _wifiRouterState['wifiEnabled'] == true ||
        _wifiRouterState['hotspotActive'] == true;
    return nativeActive || _gateway.isRunning.value;
  }

  Future<void> _scanWebSockets() async {
    if (_isScanningWebSockets.value) return;
    _isScanningWebSockets.value = true;
    final list = await VpnEngine.scanActiveWebSockets();
    _activeWebSockets.assignAll(list);
    _isScanningWebSockets.value = false;
  }

  Future<void> _scanWifiWaves() async {
    if (_isScanningWifi.value) return;
    _isScanningWifi.value = true;
    final res = await VpnEngine.scanWifiProximity();
    _wifiProximityList.assignAll(res);
    _isScanningWifi.value = false;
  }

  Widget _buildAppIconWidget(String? base64Str, {double size = 36}) {
    if (base64Str != null && base64Str.isNotEmpty) {
      try {
        final bytes = base64Decode(base64Str);
        return ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: Image.memory(
            bytes,
            width: size,
            height: size,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => HpIconBox(
              icon: Icons.android_rounded,
              color: HpColors.accentOrange,
              size: size,
            ),
          ),
        );
      } catch (_) {}
    }
    return HpIconBox(
      icon: Icons.apps_rounded,
      color: HpColors.accentOrange,
      size: size,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _dns1Controller.dispose();
    _dns2Controller.dispose();
    _gatewayPortController.dispose();
    _gatewayUserController.dispose();
    _gatewayPassController.dispose();
    _mockLatController.dispose();
    _mockLonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Central Avançada NOrange'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? HpColors.borderSubtle : HpColors.lightBorder,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              dividerColor: Colors.transparent,
              indicatorColor: HpColors.accentEmerald,
              indicatorWeight: 2.5,
              labelColor: HpColors.accentEmerald,
              unselectedLabelColor:
                  isDark ? HpColors.textSecondary : HpColors.lightTextSecondary,
              labelStyle: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
              onTap: (_) => HapticFeedback.selectionClick(),
              tabs: const [
                Tab(
                  child: Row(
                    children: [
                      Icon(Icons.vpn_key_rounded, size: 16),
                      SizedBox(width: 6),
                      Text('VPN Própria'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    children: [
                      Icon(Icons.wifi_tethering_rounded, size: 16),
                      SizedBox(width: 6),
                      Text('Hotspot VPN'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    children: [
                      Icon(Icons.hub_rounded, size: 16),
                      SizedBox(width: 6),
                      Text('Proxy'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    children: [
                      Icon(Icons.radar_rounded, size: 16),
                      SizedBox(width: 6),
                      Text('Roteador Wi-Fi & Radar'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome_motion_rounded, size: 16),
                      SizedBox(width: 6),
                      Text('Widget Flutuante / GPS / Cam'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildCustomVpnTab(isDark),
              _buildShareableVpnTab(isDark),
              _buildProxyCenterTab(isDark),
              _buildWifiRouterAndRadarTab(isDark),
              _buildFloatingAssistantAndPrivacyTab(isDark),
            ],
          ),
          NOrangeFloatingWidget(controller: _homeController),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 1: CONFIGURAR VPN PRÓPRIA & DNS AVANÇADO
  // ===========================================================================
  Widget _buildCustomVpnTab(bool isDark) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        HpSurface(
          padding: const EdgeInsets.all(18),
          borderRadius: HpRadius.lg,
          borderColor: HpColors.accentCyan.withOpacity(0.32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const HpIconBox(
                    icon: Icons.add_moderator_rounded,
                    color: HpColors.accentCyan,
                    size: 42,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Configurar Sua Própria VPN',
                          style: HpTextStyles.cardTitle,
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Perfis .OVPN ou túnel manual TCP/UDP',
                          style: TextStyle(
                            fontSize: 12,
                            color: HpColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _showAddCustomVpnModal,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Nova VPN'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Importe configurações OpenVPN (.OVPN) ou especifique IP, Porta, Protocolo (TCP/UDP) e credenciais para conectar seu dispositivo ao seu próprio servidor privado.',
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  color: isDark
                      ? HpColors.textSecondary
                      : HpColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const HpSectionLabel(label: 'Perfis de VPN Personalizados'),
        Obx(() {
          if (_customVpns.isEmpty) {
            return HpSurface(
              padding: const EdgeInsets.all(22),
              child: Center(
                child: Text(
                  'Nenhuma VPN própria cadastrada.\nToque em "+ Nova VPN" acima para adicionar seu servidor.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? HpColors.textMuted
                        : HpColors.lightTextSecondary,
                  ),
                ),
              ),
            );
          }

          return Column(
            children: _customVpns
                .map(
                  (v) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: HpSurface(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          const HpIconBox(
                            icon: Icons.shield_rounded,
                            color: HpColors.accentEmerald,
                            size: 40,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  v.countryLong,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14.5,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${v.ip}:${v.port} • ${v.protocol} • user: ${v.username}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                    color: isDark
                                        ? HpColors.textSecondary
                                        : HpColors.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Conectar a esta VPN',
                            icon: const Icon(
                              Icons.play_circle_fill_rounded,
                              color: HpColors.accentEmerald,
                              size: 30,
                            ),
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              Get.back();
                              _homeController.switchServerAndConnect(v);
                            },
                          ),
                          IconButton(
                            tooltip: 'Remover',
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: HpColors.accentCrimson,
                              size: 22,
                            ),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              _customVpns.remove(v);
                              Pref.customVpnList = _customVpns.toList();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          );
        }),
        const SizedBox(height: 18),
        const HpSectionLabel(label: 'Resolução DNS & Proteção de Queda'),
        HpSurface(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  HpIconBox(
                    icon: Icons.dns_rounded,
                    color: HpColors.accentCyan,
                    size: 36,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'DNS Criptografado & Kill Switch',
                    style: HpTextStyles.cardTitle,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _dns1Controller,
                      onChanged: (v) => Pref.customDns1 = v.trim(),
                      decoration: const InputDecoration(
                        labelText: 'DNS Primário',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _dns2Controller,
                      onChanged: (v) => Pref.customDns2 = v.trim(),
                      decoration: const InputDecoration(
                        labelText: 'DNS Secundário',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  ActionChip(
                    label: const Text('Cloudflare (1.1.1.1)'),
                    onPressed: () => _setDns('1.1.1.1', '1.0.0.1'),
                  ),
                  ActionChip(
                    label: const Text('Google (8.8.8.8)'),
                    onPressed: () => _setDns('8.8.8.8', '8.8.4.4'),
                  ),
                  ActionChip(
                    label: const Text('AdGuard (Anti-Ad/Tracker)'),
                    onPressed: () => _setDns('94.140.14.14', '94.140.15.15'),
                  ),
                ],
              ),
              const Divider(height: 28),
              Obx(
                () => SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Auto-Failover Inteligente',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Comuta automaticamente para outro nó caso a conexão oscile.',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: _homeController.autoFailover.value,
                  onChanged: (v) {
                    HapticFeedback.selectionClick();
                    _homeController.autoFailover.value = v;
                  },
                ),
              ),
              const Divider(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const HpIconBox(
                  icon: Icons.gpp_maybe_rounded,
                  color: HpColors.accentAmber,
                  size: 38,
                ),
                title: const Text(
                  'Kill Switch do Sistema (Always-On)',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                subtitle: const Text(
                  'Bloquear conexões fora da VPN nas configurações nativas do SO',
                  style: TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                onTap: () => VpnEngine.openKillSwitch(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _setDns(String d1, String d2) {
    _dns1Controller.text = d1;
    _dns2Controller.text = d2;
    Pref.customDns1 = d1;
    Pref.customDns2 = d2;
    MyDialogs.success(msg: 'DNS configurado para $d1 / $d2');
  }

  void _showAddCustomVpnModal() {
    final nameCtrl = TextEditingController();
    final ipCtrl = TextEditingController();
    final portCtrl = TextEditingController(text: '443');
    final userCtrl = TextEditingController(text: 'vpn');
    final passCtrl = TextEditingController(text: 'vpn');
    final ovpnCtrl = TextEditingController();
    final RxString protocol = 'TCP'.obs;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Adicionar VPN Própria',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Identificação (ex: Servidor Privado AWS)',
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: ipCtrl,
                      decoration: const InputDecoration(
                        labelText: 'IP ou Hostname',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: portCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Porta',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Obx(
                () => Row(
                  children: [
                    const Text(
                      'Protocolo:',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    const SizedBox(width: 10),
                    ChoiceChip(
                      label: const Text('TCP'),
                      selected: protocol.value == 'TCP',
                      showCheckmark: false,
                      onSelected: (_) => protocol.value = 'TCP',
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('UDP'),
                      selected: protocol.value == 'UDP',
                      showCheckmark: false,
                      onSelected: (_) => protocol.value = 'UDP',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: userCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Usuário (opcional)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: passCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Senha (opcional)',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: ovpnCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText:
                      'Configuração .OVPN completa (cole aqui ou deixe vazio)',
                  suffixIcon: IconButton(
                    tooltip: 'Colar da Área de Transferência',
                    icon: const Icon(Icons.paste_rounded),
                    onPressed: () async {
                      final clip = await Clipboard.getData('text/plain');
                      if (clip?.text != null) {
                        ovpnCtrl.text = clip!.text!;
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final name = nameCtrl.text.trim().isEmpty
                        ? 'VPN Personalizada'
                        : nameCtrl.text.trim();
                    String ip = ipCtrl.text.trim();
                    int port = int.tryParse(portCtrl.text.trim()) ?? 443;
                    String proto = protocol.value;
                    String ovpnContent = ovpnCtrl.text.trim();

                    if (ovpnContent.isEmpty && ip.isEmpty) {
                      MyDialogs.error(
                          msg:
                              'Informe o IP/Host ou cole uma configuração .OVPN.');
                      return;
                    }

                    if (ovpnContent.isEmpty) {
                      ovpnContent = '''
client
dev tun
proto ${proto.toLowerCase()}
remote $ip $port
resolv-retry infinite
nobind
persist-key
persist-tun
cipher AES-128-CBC
auth SHA1
verb 3
''';
                    }

                    final newVpn = Vpn(
                      hostname: name,
                      ip: ip.isEmpty ? 'custom.vpn' : ip,
                      ping: '15',
                      speed: 500000000,
                      countryLong: name,
                      countryShort: 'US',
                      numVpnSessions: 1,
                      openVPNConfigDataBase64:
                          base64Encode(utf8.encode(ovpnContent)),
                      protocol: proto,
                      port: port,
                      isVerifiedOnline: true,
                      username: userCtrl.text.trim(),
                      password: passCtrl.text.trim(),
                      isCustom: true,
                    );

                    _customVpns.insert(0, newVpn);
                    Pref.customVpnList = _customVpns.toList();

                    final mainList = Pref.vpnList;
                    mainList.insert(0, newVpn);
                    Pref.vpnList = mainList;

                    Navigator.pop(ctx);
                    MyDialogs.success(
                        msg: 'VPN "$name" adicionada com sucesso!');
                  },
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('Salvar VPN Própria'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 2: TORNAR CELULAR UMA VPN COMPARTILHÁVEL (HOTSPOT / GATEWAY VPN)
  // ===========================================================================
  Widget _buildShareableVpnTab(bool isDark) {
    return Obx(
      () => ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          HpSurface(
            padding: const EdgeInsets.all(18),
            borderRadius: HpRadius.lg,
            borderColor: _gateway.isRunning.value
                ? HpColors.accentEmerald.withOpacity(0.5)
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    HpIconBox(
                      icon: Icons.wifi_tethering_rounded,
                      color: _gateway.isRunning.value
                          ? HpColors.accentEmerald
                          : HpColors.accentCyan,
                      size: 44,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Compartilhar Conexão VPN do Celular',
                            style: HpTextStyles.cardTitle,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _gateway.isRunning.value
                                ? 'HOTSPOT VPN ATIVO • Público: ${_gateway.publicEndpoint}'
                                : 'Crie uma VPN pública/local pelo seu celular com inspeção ao vivo',
                            style: TextStyle(
                              fontSize: 12,
                              color: _gateway.isRunning.value
                                  ? HpColors.accentEmerald
                                  : HpColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _gateway.isRunning.value,
                      onChanged: (enable) async {
                        HapticFeedback.mediumImpact();
                        if (enable) {
                          final port =
                              int.tryParse(_gatewayPortController.text) ?? 8080;
                          if (_gatewayRequireAuth.value) {
                            _gateway.proxyUsername.value =
                                _gatewayUserController.text.trim();
                            _gateway.proxyPassword.value =
                                _gatewayPassController.text.trim();
                          } else {
                            _gateway.proxyUsername.value = '';
                            _gateway.proxyPassword.value = '';
                          }
                          final ok = await _homeController
                              .validateAndStartGatewayServer(
                            port: port,
                            isWifiRouter: false,
                          );
                          if (ok) {
                            MyDialogs.success(
                                msg:
                                    'Hotspot VPN ativo! IP Público: ${_gateway.publicEndpoint} | Local: ${_gateway.localEndpoint}');
                          }
                        } else {
                          await _gateway.stopServer();
                          _homeController.syncSystemNotificationAndWidget();
                        }
                      },
                    ),
                  ],
                ),
                const Divider(height: 24),
                // Public WAN IP & Local Hotspot IP Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? HpColors.bgSurface : HpColors.lightSurface,
                    borderRadius: BorderRadius.circular(HpRadius.sm),
                    border: Border.all(
                      color: HpColors.accentOrange.withOpacity(0.35),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.public_rounded,
                              color: HpColors.accentOrange, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'IP DE CONEXÃO PÚBLICA (VPN PÚBLICA / WAN)',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                    color: HpColors.accentOrange,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_gateway.publicEndpoint}  •  ${_gateway.publicCountry.value} (${_gateway.publicIsp.value})',
                                  style: HpTextStyles.mono.copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Copiar IP Público:Porta',
                            icon: const Icon(Icons.copy_rounded,
                                size: 17, color: HpColors.accentOrange),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(
                                  text: _gateway.publicEndpoint));
                              MyDialogs.success(
                                  msg:
                                      'IP Público ${_gateway.publicEndpoint} copiado!');
                            },
                          ),
                          IconButton(
                            tooltip: 'Atualizar IP Público',
                            icon: const Icon(CupertinoIcons.refresh,
                                size: 17, color: HpColors.accentCyan),
                            onPressed: () => _gateway.refreshPublicIp(),
                          ),
                        ],
                      ),
                      const Divider(height: 14),
                      Row(
                        children: [
                          const Icon(Icons.wifi_tethering_rounded,
                              color: HpColors.accentEmerald, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'IP Local / Hotspot: ${_gateway.localEndpoint}',
                              style: HpTextStyles.mono.copyWith(
                                fontSize: 12,
                                color: HpColors.accentEmerald,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              Clipboard.setData(
                                  ClipboardData(text: _gateway.localEndpoint));
                              MyDialogs.success(
                                  msg:
                                      'IP Local ${_gateway.localEndpoint} copiado!');
                            },
                            icon: const Icon(Icons.copy_rounded, size: 14),
                            label: const Text('Copiar Local'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // Optional Auth Configuration inside Hotspot VPN
                _buildGatewayAuthControlsSection(isDark),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _metricBox(
                        'IP Público',
                        _gateway.publicIp.value,
                        Icons.public_rounded,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _metricBox(
                        'Porta',
                        '${_gateway.listeningPort.value}',
                        Icons.tag_rounded,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _metricBox(
                        'Usuários',
                        '${_gateway.peerStats.length} (${_gateway.activeConnections.value})',
                        Icons.people_alt_rounded,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _metricBox(
                        'Tráfego',
                        _gateway.formattedBytesRelayed,
                        Icons.swap_vert_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final addr = _gateway.publicEndpoint;
                          Clipboard.setData(ClipboardData(text: addr));
                          MyDialogs.success(
                              msg: 'IP Público $addr copiado!');
                        },
                        icon: const Icon(Icons.copy_rounded, size: 17),
                        label: const Text('Copiar IP Público'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final ovpn = _gateway.generateShareableOvpnProfile(
                              _homeController.vpn.value);
                          Clipboard.setData(ClipboardData(text: ovpn));
                          MyDialogs.success(
                              msg:
                                  'Perfil .OVPN Cliente (Público + Local) copiado!');
                        },
                        icon: const Icon(Icons.share_rounded, size: 17),
                        label: const Text('Gerar .OVPN Cliente'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          // Connected Users, Accessed Domains & Live Traffic directly in Hotspot VPN tab!
          _buildConnectedPeersMonitorSection(
            isDark,
            sectionTitle:
                'Usuários Conectados na Sua VPN (${_gateway.peerStats.length}) • Tráfego: ${_gateway.formattedBytesRelayed}',
          ),
          const SizedBox(height: 18),
          const HpSectionLabel(label: 'Interfaces de Rede Detectadas'),
          HpSurface(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const HpIconBox(
                      icon: Icons.router_rounded,
                      color: HpColors.accentCyan,
                      size: 36,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Adaptadores Locais (Wi-Fi / Hotspot / TUN)',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.refresh, size: 18),
                      onPressed: () {
                        _gateway.refreshLocalIps();
                        _gateway.refreshPublicIp();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ..._gateway.localIps.map(
                  (ipInfo) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color:
                            isDark ? HpColors.bgSurface : HpColors.lightSurface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        ipInfo,
                        style: HpTextStyles.mono.copyWith(
                          color: HpColors.accentEmerald,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGatewayAuthControlsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const Icon(Icons.lock_person_rounded,
                  size: 16, color: HpColors.accentOrange),
              const SizedBox(width: 6),
              const Text(
                'Autenticação:',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                avatar: const Icon(Icons.lock_open_rounded, size: 15),
                label: const Text('Sem Senha (Aberto)'),
                selected: !_gatewayRequireAuth.value,
                showCheckmark: false,
                onSelected: (_) {
                  HapticFeedback.selectionClick();
                  _gatewayRequireAuth.value = false;
                  _gatewayUserController.clear();
                  _gatewayPassController.clear();
                  _gateway.proxyUsername.value = '';
                  _gateway.proxyPassword.value = '';
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                avatar: const Icon(Icons.verified_user_rounded, size: 15),
                label: const Text('Com Usuário e Senha'),
                selected: _gatewayRequireAuth.value,
                showCheckmark: false,
                onSelected: (_) {
                  HapticFeedback.selectionClick();
                  _gatewayRequireAuth.value = true;
                  if (_gatewayUserController.text.trim().isEmpty) {
                    _gatewayUserController.text = 'norange';
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _gatewayPortController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Porta (ex: 8080)',
                ),
              ),
            ),
            if (_gatewayRequireAuth.value) ...[
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _gatewayUserController,
                  onChanged: (v) => _gateway.proxyUsername.value = v.trim(),
                  decoration: const InputDecoration(
                    labelText: 'Usuário',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _gatewayPassController,
                  obscureText: true,
                  onChanged: (v) => _gateway.proxyPassword.value = v.trim(),
                  decoration: const InputDecoration(
                    labelText: 'Senha',
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildConnectedPeersMonitorSection(
    bool isDark, {
    required String sectionTitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HpSectionLabel(
          label: sectionTitle,
          trailing: _gateway.peerStats.isNotEmpty ? 'Zerar Dados' : null,
          onTrailingTap: () => _gateway.clearLogs(),
        ),
        HpSurface(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.visibility_rounded,
                      size: 16, color: HpColors.accentOrange),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Total de Usuários: ${_gateway.peerStats.length}  •  Conexões Ativas: ${_gateway.activeConnections.value}  •  Auth: ${_gateway.hasAuth ? "Protegido (${_gateway.authUser.value})" : "Aberto (Sem Senha)"}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: HpColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_gateway.peerStats.isEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? HpColors.bgSurface : HpColors.lightSurface,
                    borderRadius: BorderRadius.circular(HpRadius.sm),
                  ),
                  child: Text(
                    _gateway.isRunning.value
                        ? 'Servidor ativo em ${_gateway.publicEndpoint} (Local: ${_gateway.localEndpoint}).\nAssim que usuários conectarem na sua VPN/Proxy, você verá aqui o IP de cada usuário, tráfego (Download/Upload) e todos os sites/domínios e WebSockets que estão acessando.'
                        : 'Ative o servidor acima para monitorar em tempo real quantos usuários estão conectados, o que estão acessando e o consumo de tráfego.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: HpColors.textSecondary,
                    ),
                  ),
                )
              else
                ..._gateway.peerStats.values.map(
                  (peer) => Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color:
                          isDark ? HpColors.bgSurface : HpColors.lightSurface,
                      border: Border.all(
                          color: HpColors.accentEmerald.withOpacity(0.35)),
                      borderRadius: BorderRadius.circular(HpRadius.sm),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.person_pin_circle_rounded,
                              color: HpColors.accentEmerald,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Cliente: ${peer.ip}',
                                style: HpTextStyles.mono.copyWith(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            HpBadge(
                              text: ConnectedPeerStat.formatBytes(
                                  peer.totalBytes),
                              color: HpColors.accentEmerald,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.download_rounded,
                                  size: 13.5,
                                  color: HpColors.accentEmerald,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Down: ${ConnectedPeerStat.formatBytes(peer.bytesDownloaded)}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: HpColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.upload_rounded,
                                  size: 13.5,
                                  color: HpColors.accentOrange,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Up: ${ConnectedPeerStat.formatBytes(peer.bytesUploaded)}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: HpColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Sockets Ativos: ${peer.activeSockets}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: HpColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        if (peer.accessedDomains.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'O QUE ESTÁ ACESSANDO (DOMÍNIOS / IPS / WEBSOCKETS):',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.9,
                              color: HpColors.accentOrange,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: peer.accessedDomains
                                .map(
                                  (domain) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: HpColors.accentCyanDim,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      domain,
                                      style: HpTextStyles.mono.copyWith(
                                        fontSize: 10.5,
                                        color: HpColors.accentCyan,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              if (_gateway.connectionLogs.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'LOG DE TRÁFEGO & REQUISIÇÕES EM TEMPO REAL:',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.9,
                    color: HpColors.textMuted,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 110,
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF050507),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: HpColors.borderSubtle),
                  ),
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: _gateway.connectionLogs.length > 25
                        ? 25
                        : _gateway.connectionLogs.length,
                    itemBuilder: (_, idx) => Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        _gateway.connectionLogs[idx],
                        style: HpTextStyles.mono.copyWith(
                          fontSize: 10.5,
                          color: HpColors.accentEmerald,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _metricBox(String label, String value, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: isDark ? HpColors.bgSurface : HpColors.lightSurface,
        borderRadius: BorderRadius.circular(HpRadius.sm),
        border: Border.all(
          color: isDark ? HpColors.borderSubtle : HpColors.lightBorder,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: HpColors.accentCyan, size: 18),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: HpColors.textMuted),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 3: CENTRAL DE PROXY (SERVIDOR PROXY NO CELULAR + CLIENTE PROXY)
  // ===========================================================================
  Widget _buildProxyCenterTab(bool isDark) {
    return Obx(
      () => ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          HpSurface(
            padding: const EdgeInsets.all(18),
            borderRadius: HpRadius.lg,
            borderColor: _gateway.isRunning.value
                ? HpColors.accentEmerald.withOpacity(0.5)
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    HpIconBox(
                      icon: Icons.cell_tower_rounded,
                      color: _gateway.isRunning.value
                          ? HpColors.accentEmerald
                          : HpColors.accentIndigo,
                      size: 42,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tornar Celular um Proxy Conectável',
                            style: HpTextStyles.cardTitle,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _gateway.isRunning.value
                                ? 'ONLINE • Público: ${_gateway.publicEndpoint} | Local: ${_gateway.localEndpoint}'
                                : 'Servidor HTTP/HTTPS + SOCKS5 com IP Público, Auth opcional e Inspetor',
                            style: TextStyle(
                              fontSize: 12,
                              color: _gateway.isRunning.value
                                  ? HpColors.accentEmerald
                                  : HpColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Public WAN IP & Local Endpoint for Proxy Server
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? HpColors.bgSurface : HpColors.lightSurface,
                    borderRadius: BorderRadius.circular(HpRadius.sm),
                    border: Border.all(
                      color: HpColors.accentOrange.withOpacity(0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.public_rounded,
                          color: HpColors.accentOrange, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Proxy Público: ${_gateway.publicEndpoint}',
                              style: HpTextStyles.mono.copyWith(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: HpColors.accentOrange,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Proxy Local: ${_gateway.localEndpoint} • ${_gateway.publicCountry.value}',
                              style: HpTextStyles.mono.copyWith(
                                fontSize: 11.5,
                                color: HpColors.accentEmerald,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Copiar IP Público do Proxy',
                        icon: const Icon(Icons.copy_rounded,
                            size: 17, color: HpColors.accentOrange),
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: _gateway.publicEndpoint));
                          MyDialogs.success(
                              msg:
                                  'Proxy Público ${_gateway.publicEndpoint} copiado!');
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _buildGatewayAuthControlsSection(isDark),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _gateway.isRunning.value
                          ? HpColors.accentCrimson
                          : HpColors.accentEmerald,
                      foregroundColor: _gateway.isRunning.value
                          ? Colors.white
                          : const Color(0xFF04140D),
                    ),
                    onPressed: () async {
                      HapticFeedback.mediumImpact();
                      if (_gateway.isRunning.value) {
                        await _gateway.stopServer();
                        _homeController.syncSystemNotificationAndWidget();
                      } else {
                        final port =
                            int.tryParse(_gatewayPortController.text) ?? 8080;
                        if (_gatewayRequireAuth.value) {
                          _gateway.proxyUsername.value =
                              _gatewayUserController.text.trim();
                          _gateway.proxyPassword.value =
                              _gatewayPassController.text.trim();
                        } else {
                          _gateway.proxyUsername.value = '';
                          _gateway.proxyPassword.value = '';
                        }
                        final ok = await _homeController
                            .validateAndStartGatewayServer(
                          port: port,
                          isWifiRouter: false,
                        );
                        if (ok) {
                          MyDialogs.success(
                              msg:
                                  'Servidor Proxy HTTP/SOCKS5 ativo em ${_gateway.publicEndpoint} (Local: ${_gateway.localEndpoint})');
                        }
                      }
                    },
                    icon: Icon(_gateway.isRunning.value
                        ? Icons.stop_circle_outlined
                        : Icons.play_arrow_rounded),
                    label: Text(_gateway.isRunning.value
                        ? 'Encerrar Servidor Proxy do Celular'
                        : 'Iniciar Servidor Proxy (HTTP + SOCKS5)'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          // Connected Users, Accessed Domains & Live Traffic directly in Proxy tab!
          _buildConnectedPeersMonitorSection(
            isDark,
            sectionTitle:
                'Usuários Conectados no Seu Proxy (${_gateway.peerStats.length}) • Tráfego: ${_gateway.formattedBytesRelayed}',
          ),
          const SizedBox(height: 18),
          const HpSectionLabel(label: 'Proxies Externos de Saída (Outbound)'),
          HpSurface(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const HpIconBox(
                  icon: Icons.hub_rounded,
                  color: HpColors.accentCyan,
                  size: 40,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Adicionar Proxy Externo',
                        style: HpTextStyles.cardTitle,
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Encaminhe o túnel OpenVPN via proxy HTTP ou SOCKS5.',
                        style: TextStyle(
                          fontSize: 12,
                          color: HpColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showAddProxyModal,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Novo Proxy'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_proxies.isEmpty)
            HpSurface(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'Nenhum proxy externo cadastrado.\nToque em "+ Novo Proxy" para configurar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? HpColors.textMuted
                        : HpColors.lightTextSecondary,
                  ),
                ),
              ),
            )
          else
            Column(
              children: _proxies.map((proxy) {
                final isActive = _activeProxyId.value == proxy.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: HpSurface(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    borderColor: isActive
                        ? HpColors.accentEmerald.withOpacity(0.6)
                        : null,
                    child: Row(
                      children: [
                        HpIconBox(
                          icon: Icons.swap_horiz_rounded,
                          color: isActive
                              ? HpColors.accentEmerald
                              : HpColors.accentCyan,
                          size: 40,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${proxy.name} (${proxy.protocol})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14.5,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${proxy.host}:${proxy.port}'
                                '${proxy.lastPingMs != null ? " • ${proxy.lastPingMs} ms" : ""}',
                                style: HpTextStyles.mono.copyWith(
                                  color: HpColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Sondar Latência do Proxy',
                          icon: const Icon(
                            Icons.speed_rounded,
                            color: HpColors.accentAmber,
                          ),
                          onPressed: () => _testProxyLatency(proxy),
                        ),
                        Switch(
                          value: isActive,
                          onChanged: (val) async {
                            HapticFeedback.selectionClick();
                            if (val) {
                              final ok = await _homeController
                                  .validateAndActivateProxy(proxy);
                              if (ok) {
                                _activeProxyId.value = proxy.id;
                                MyDialogs.success(
                                    msg:
                                        'Proxy "${proxy.name}" ativado para conexões!');
                              }
                            } else {
                              _activeProxyId.value = '';
                              _homeController.deactivateProxy();
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: HpColors.accentCrimson,
                          ),
                          onPressed: () {
                            if (_activeProxyId.value == proxy.id) {
                              _activeProxyId.value = '';
                              _homeController.deactivateProxy();
                            }
                            _proxies.remove(proxy);
                            Pref.proxyList = _proxies.toList();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 4: ROTEADOR WI-FI, DETECTOR WEBSOCKET ANTI-SPYWARE & RADAR DE ONDAS
  // ===========================================================================
  Widget _buildWifiRouterAndRadarTab(bool isDark) {
    return Obx(
      () {
        final routerActive = _isWifiRouterDetectedActive;
        final ssid = (_wifiRouterState['ssid'] ?? 'Rede Wi-Fi').toString();

        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            // Wi-Fi Router Detection, Activate & Deactivate Card
            HpSurface(
              padding: const EdgeInsets.all(18),
              borderRadius: HpRadius.lg,
              borderColor: routerActive
                  ? HpColors.accentEmerald.withOpacity(0.55)
                  : HpColors.accentOrange.withOpacity(0.35),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      HpIconBox(
                        icon: routerActive
                            ? Icons.router_rounded
                            : Icons.wifi_off_rounded,
                        color: routerActive
                            ? HpColors.accentEmerald
                            : HpColors.accentOrange,
                        size: 42,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Controle do Roteador Wi-Fi & Hotspot',
                              style: HpTextStyles.cardTitle,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              routerActive
                                  ? 'DETECTADO ATIVO • $ssid (${_gateway.primaryIp})'
                                  : 'Roteador Wi-Fi desativado no momento',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: routerActive
                                    ? HpColors.accentEmerald
                                    : HpColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Verificar Status do Roteador Wi-Fi',
                        onPressed: () => _refreshWifiRouterState(),
                        icon: const Icon(CupertinoIcons.refresh, size: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        const Text(
                          'Fonte:',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 12.5),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Dados Móveis (4G/5G)'),
                          selected:
                              _routerSourceMode.value == 'Dados Móveis (4G/5G)',
                          showCheckmark: false,
                          onSelected: (_) =>
                              _routerSourceMode.value = 'Dados Móveis (4G/5G)',
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Repetidor Wi-Fi'),
                          selected:
                              _routerSourceMode.value == 'Repetidor Wi-Fi',
                          showCheckmark: false,
                          onSelected: (_) =>
                              _routerSourceMode.value = 'Repetidor Wi-Fi',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: HpColors.accentEmerald,
                            foregroundColor: const Color(0xFF04140D),
                          ),
                          onPressed: () async {
                            HapticFeedback.mediumImpact();
                            await VpnEngine.setWifiRouterEnabled(true);
                            if (!_gateway.isRunning.value) {
                              await _homeController
                                  .validateAndStartGatewayServer(
                                isWifiRouter: true,
                              );
                            }
                            await _refreshWifiRouterState();
                            MyDialogs.success(
                                msg: 'Roteador Wi-Fi + Inspetor ativado!');
                          },
                          icon: const Icon(Icons.wifi_tethering_rounded,
                              size: 18),
                          label: const Text('Ativar Roteador Wi-Fi'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: routerActive
                                ? HpColors.accentCrimson
                                : HpColors.bgElevated,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            HapticFeedback.heavyImpact();
                            if (_gateway.isRunning.value) {
                              await _gateway.stopServer();
                            }
                            await VpnEngine.setWifiRouterEnabled(false);
                            await _refreshWifiRouterState();
                            _homeController.syncSystemNotificationAndWidget();
                            MyDialogs.info(
                              msg:
                                  'Roteador Wi-Fi e compartilhamento desativados!',
                            );
                          },
                          icon: const Icon(Icons.wifi_tethering_off_rounded,
                              size: 18),
                          label: Text(routerActive
                              ? 'Desativar Roteador'
                              : 'Forçar Desativação'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // WebSocket & Persistent Socket Anti-Spyware Inspector
            _buildWebSocketAntiSpywareSection(isDark),

            const SizedBox(height: 18),

            // Connected Devices, Accessed Domains & Bandwidth Consumption
            _buildConnectedPeersMonitorSection(
              isDark,
              sectionTitle:
                  'Dispositivos Conectados (${_gateway.peerStats.length}) • Total: ${_gateway.formattedBytesRelayed}',
            ),


          const SizedBox(height: 18),

          // Wi-Fi Radio Wave Proximity Radar Card
          const HpSectionLabel(
            label: 'Radar de Proximidade Física por Ondas Wi-Fi',
          ),
          HpSurface(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const HpIconBox(
                      icon: Icons.radar_rounded,
                      color: HpColors.accentCyan,
                      size: 40,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Escaneamento de Ondas (FSPL)',
                            style: HpTextStyles.cardTitle,
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Estima a distância em metros via atenuação RSSI (dBm) e Frequência (MHz)',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: HpColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Escanear Ondas Wi-Fi',
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _scanWifiWaves();
                      },
                      icon: _isScanningWifi.value
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: HpColors.accentCyan,
                              ),
                            )
                          : const Icon(
                              CupertinoIcons.refresh_circled_solid,
                              color: HpColors.accentCyan,
                              size: 28,
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                WifiWaveRadarGraphic(
                  devices: _wifiProximityList,
                ),
                const SizedBox(height: 12),
                if (_wifiProximityList.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(
                      child: Text(
                        'Toque em atualizar para escanear as ondas Wi-Fi ao redor.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: HpColors.textMuted, fontSize: 12.5),
                      ),
                    ),
                  )
                else
                  ..._wifiProximityList.map((w) {
                    final int rssi =
                        int.tryParse((w['rssi'] ?? '-70').toString()) ?? -70;
                    final int freq =
                        int.tryParse((w['frequency'] ?? '2412').toString()) ??
                            2412;
                    final double dist = double.tryParse(
                            (w['distanceMeters'] ?? '2.5').toString()) ??
                        2.5;
                    final signalFactor =
                        ((100 + rssi).clamp(5, 70) / 70.0).clamp(0.08, 1.0);
                    final proximityLabel = dist < 2.0
                        ? 'IMEDIATO (<2m)'
                        : (dist < 8.0 ? 'PRÓXIMO' : 'DISTANTE');
                    final barColor = dist < 2.0
                        ? HpColors.accentEmerald
                        : (dist < 8.0
                            ? HpColors.accentAmber
                            : HpColors.accentCrimson);

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            isDark ? HpColors.bgSurface : HpColors.lightSurface,
                        borderRadius: BorderRadius.circular(HpRadius.sm),
                        border: Border.all(
                          color: isDark
                              ? HpColors.borderSubtle
                              : HpColors.lightBorder,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${w['name']} (${w['type']})',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ),
                              HpBadge(
                                text:
                                    '~${dist.toStringAsFixed(1)}m • $proximityLabel',
                                color: barColor,
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${w['address']}  •  $rssi dBm @ $freq MHz',
                            style: HpTextStyles.mono.copyWith(
                              fontSize: 11,
                              color: HpColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: signalFactor,
                              minHeight: 5,
                              color: barColor,
                              backgroundColor: barColor.withOpacity(0.14),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      );
      },
    );
  }

  Widget _buildWebSocketAntiSpywareSection(bool isDark) {
    final suspiciousCount = _activeWebSockets
        .where((c) => c['isSuspicious'] == true)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HpSectionLabel(
          label:
              'Detector WebSocket & Anti-Spyware (${_activeWebSockets.length} conexões)',
        ),
        HpSurface(
          padding: const EdgeInsets.all(16),
          borderColor: suspiciousCount > 0
              ? HpColors.accentCrimson.withOpacity(0.6)
              : HpColors.accentCyan.withOpacity(0.35),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  HpIconBox(
                    icon: suspiciousCount > 0
                        ? Icons.gpp_bad_rounded
                        : Icons.security_update_good_rounded,
                    color: suspiciousCount > 0
                        ? HpColors.accentCrimson
                        : HpColors.accentEmerald,
                    size: 40,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Monitor de WebSockets Ativos & Anti-Spyware',
                          style: HpTextStyles.cardTitle,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          suspiciousCount > 0
                              ? 'ALERTA: $suspiciousCount conexão(ões) suspeita(s) em segundo plano!'
                              : 'Verifica se conexões WebSocket (WSS/WS) estão sendo usadas, por qual app, para onde e para qual IP.',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: suspiciousCount > 0
                                ? FontWeight.w800
                                : FontWeight.w500,
                            color: suspiciousCount > 0
                                ? HpColors.accentCrimson
                                : HpColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Escanear Conexões WebSocket Agora',
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _scanWebSockets();
                    },
                    icon: _isScanningWebSockets.value
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: HpColors.accentOrange,
                            ),
                          )
                        : const Icon(
                            CupertinoIcons.refresh_circled_solid,
                            color: HpColors.accentOrange,
                            size: 28,
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_activeWebSockets.isEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? HpColors.bgSurface : HpColors.lightSurface,
                    borderRadius: BorderRadius.circular(HpRadius.sm),
                  ),
                  child: const Text(
                    'Nenhuma conexão WebSocket ativa detectada no momento. Toque em atualizar para reescanear a pilha de rede do aparelho.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: HpColors.textSecondary,
                    ),
                  ),
                )
              else
                ..._activeWebSockets.map((ws) {
                  final appName = (ws['appName'] ?? 'App').toString();
                  final pkg = (ws['packageName'] ?? '').toString();
                  final iconB64 = (ws['iconBase64'] ?? '').toString();
                  final remoteIp = (ws['remoteIp'] ?? '0.0.0.0').toString();
                  final remotePort = (ws['remotePort'] ?? 443).toString();
                  final targetHost = (ws['targetHost'] ?? remoteIp).toString();
                  final protocol = (ws['protocol'] ?? 'WSS://').toString();
                  final state = (ws['state'] ?? 'ESTABLISHED').toString();
                  final suspicious = ws['isSuspicious'] == true;
                  final riskReason =
                      (ws['riskReason'] ?? 'Conexão Verificada').toString();

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          isDark ? HpColors.bgSurface : HpColors.lightSurface,
                      borderRadius: BorderRadius.circular(HpRadius.sm),
                      border: Border.all(
                        color: suspicious
                            ? HpColors.accentCrimson.withOpacity(0.65)
                            : HpColors.borderSubtle,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _buildAppIconWidget(iconB64, size: 36),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    appName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                  Text(
                                    pkg,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: HpTextStyles.mono.copyWith(
                                      fontSize: 10.5,
                                      color: HpColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            HpBadge(
                              text: suspicious ? 'SUSPEITO' : state,
                              color: suspicious
                                  ? HpColors.accentCrimson
                                  : HpColors.accentEmerald,
                            ),
                          ],
                        ),
                        const Divider(height: 14),
                        Row(
                          children: [
                            const Icon(Icons.public_rounded,
                                size: 14, color: HpColors.accentCyan),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Para Onde (Destino): $targetHost',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.dns_rounded,
                                size: 14, color: HpColors.accentOrange),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'IP Remoto: $remoteIp:$remotePort  •  $protocol',
                                style: HpTextStyles.mono.copyWith(
                                  fontSize: 11.5,
                                  color: HpColors.accentOrange,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              suspicious
                                  ? Icons.warning_amber_rounded
                                  : Icons.verified_user_rounded,
                              size: 14,
                              color: suspicious
                                  ? HpColors.accentCrimson
                                  : HpColors.accentEmerald,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Diagnóstico: $riskReason',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: suspicious
                                      ? HpColors.accentCrimson
                                      : HpColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // TAB 5: WIDGET FLUTUANTE, VPN POR APP (COM LOGOS), MOCK GPS & CÂMERA VIRTUAL
  // ===========================================================================
  Widget _buildFloatingAssistantAndPrivacyTab(bool isDark) {
    return Obx(
      () {
        final query = _appSearchQuery.value.trim().toLowerCase();
        final filteredApps = _installedApps.where((app) {
          if (query.isEmpty) return true;
          final name = (app['appName'] ?? '').toLowerCase();
          final pkg = (app['packageName'] ?? '').toLowerCase();
          return name.contains(query) || pkg.contains(query);
        }).toList();

        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            // 1. Floating Assistant Overlay Bubble Card (NOrange Pod)
            HpSurface(
              padding: const EdgeInsets.all(18),
              borderRadius: HpRadius.lg,
              borderColor: _floatingRunning.value
                  ? HpColors.accentOrange.withOpacity(0.55)
                  : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const NOrangeLogo(size: 42),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Widget Flutuante NOrange Pod',
                              style: HpTextStyles.cardTitle,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _floatingRunning.value
                                  ? 'ATIVO • Cápsula NOrange sobreposta a qualquer app'
                                  : 'Controle VPN, Proxy, GPS e Câmera Virtual sobre qualquer app',
                              style: TextStyle(
                                fontSize: 12,
                                color: _floatingRunning.value
                                    ? HpColors.accentOrange
                                    : HpColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _floatingRunning.value,
                        onChanged: (enable) async {
                          HapticFeedback.mediumImpact();
                          if (enable) {
                            final started =
                                await VpnEngine.startFloatingWidget();
                            _floatingRunning.value = started;
                          } else {
                            await VpnEngine.stopFloatingWidget();
                            _floatingRunning.value = false;
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Use o Widget Flutuante para ligar/desligar VPN, Proxy e Hotspot, iniciar o Split Tunneling no app em foco, ou mover/alargar a foto da Câmera Virtualizada em tempo real durante fotos e lives.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: HpColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: () => VpnEngine.requestUsageStatsPermission(),
                      icon: const Icon(Icons.app_shortcut_rounded, size: 16),
                      label:
                          const Text('Permissão de Detecção de App em Foco'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 2. Per-App VPN / Proxy Split Tunneling Selector WITH APP LOGOS
            HpSectionLabel(
              label:
                  'Split Tunneling por App (${_selectedAllowedApps.isEmpty ? "Todos os Apps" : "${_selectedAllowedApps.length} pré-configurado(s)"})',
              trailing:
                  _selectedAllowedApps.isNotEmpty ? 'Limpar Seleção' : null,
              onTrailingTap: () {
                _selectedAllowedApps.clear();
                Pref.allowedAppPackages = [];
              },
            ),
            HpSurface(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Deixe pré-configurados os aplicativos (com seus ícones reais) que usarão o túnel VPN/Proxy, ou inicie diretamente pelo Widget Flutuante a qualquer momento:',
                    style:
                        TextStyle(fontSize: 12, color: HpColors.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    onChanged: (v) => _appSearchQuery.value = v,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search_rounded, size: 18),
                      hintText: 'Pesquisar aplicativo por nome ou pacote...',
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            Pref.allowedAppPackages =
                                _selectedAllowedApps.toList();
                            Get.back();
                            _homeController.connectToVpn();
                            MyDialogs.success(
                              msg: _selectedAllowedApps.isEmpty
                                  ? 'Iniciando VPN Global para todos os apps!'
                                  : 'Iniciando VPN pré-configurada para ${_selectedAllowedApps.length} app(s)!',
                            );
                          },
                          icon: const Icon(Icons.play_arrow_rounded, size: 18),
                          label: Text(_selectedAllowedApps.isEmpty
                              ? 'Iniciar VPN Global'
                              : 'Iniciar nos ${_selectedAllowedApps.length} Apps'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            HapticFeedback.mediumImpact();
                            Pref.allowedAppPackages =
                                _selectedAllowedApps.toList();
                            final started =
                                await VpnEngine.startFloatingWidget();
                            _floatingRunning.value = started;
                            if (started) {
                              MyDialogs.success(
                                msg:
                                    'Apps pré-configurados! Você também pode iniciar/alternar pelo Widget Flutuante NOrange.',
                              );
                            }
                          },
                          icon: const Icon(Icons.picture_in_picture_alt_rounded,
                              size: 17),
                          label: const Text('Iniciar no Widget'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 240,
                    child: _installedApps.isEmpty
                        ? const Center(
                            child: Text(
                              'Carregando lista de aplicativos com logos...',
                              style: TextStyle(color: HpColors.textMuted),
                            ),
                          )
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: filteredApps.length,
                            itemBuilder: (_, i) {
                              final app = filteredApps[i];
                              final pkg = app['packageName'] ?? '';
                              final name = app['appName'] ?? pkg;
                              final iconB64 = app['iconBase64'] ?? '';
                              final checked =
                                  _selectedAllowedApps.contains(pkg);
                              return CheckboxListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                                secondary:
                                    _buildAppIconWidget(iconB64, size: 36),
                                value: checked,
                                title: Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                subtitle: Text(
                                  pkg,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: HpTextStyles.mono.copyWith(
                                    fontSize: 10.5,
                                    color: HpColors.textMuted,
                                  ),
                                ),
                                onChanged: (val) {
                                  HapticFeedback.selectionClick();
                                  if (val == true) {
                                    if (!_selectedAllowedApps.contains(pkg)) {
                                      _selectedAllowedApps.add(pkg);
                                    }
                                  } else {
                                    _selectedAllowedApps.remove(pkg);
                                  }
                                  Pref.allowedAppPackages =
                                      _selectedAllowedApps.toList();
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 3. Mock GPS Location Spoofer Card (With Non-Dev Fallback + Step-by-Step Guide Modal)
            const HpSectionLabel(
                label: 'Simulador de Coordenadas GPS (Mock GPS)'),
            HpSurface(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      HpIconBox(
                        icon: Icons.edit_location_alt_rounded,
                        color: _mockGpsActive.value
                            ? HpColors.accentEmerald
                            : HpColors.accentAmber,
                        size: 40,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Substituir Coordenadas do GPS',
                              style: HpTextStyles.cardTitle,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _mockGpsActive.value
                                  ? 'ATIVO • Coordenada (${Pref.mockLat.toStringAsFixed(4)}, ${Pref.mockLon.toStringAsFixed(4)})'
                                  : 'Modo Híbrido (Sem Opções Dev p/ Túnel Web/App + GPS Nativo)',
                              style: TextStyle(
                                fontSize: 12,
                                color: _mockGpsActive.value
                                    ? HpColors.accentEmerald
                                    : HpColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _mockGpsActive.value,
                        onChanged: (enable) async {
                          HapticFeedback.mediumImpact();
                          final lat =
                              double.tryParse(_mockLatController.text) ??
                                  -23.550520;
                          final lon =
                              double.tryParse(_mockLonController.text) ??
                                  -46.633308;
                          Pref.mockLat = lat;
                          Pref.mockLon = lon;
                          if (enable) {
                            final ok = await VpnEngine.startMockGps(lat, lon);
                            _mockGpsActive.value = true;
                            if (ok) {
                              MyDialogs.success(
                                  msg:
                                      'GPS Nativo do Sistema + Geo-IP redirecionados para ($lat, $lon)!');
                            } else {
                              MyDialogs.info(
                                  msg:
                                      'Coordenada ($lat, $lon) ativada em Modo Interno (Sem Opções Dev)! Para substituir também em apps de mapas nativos, toque em "Passo a Passo: Como Ativar no Celular".');
                            }
                          } else {
                            await VpnEngine.stopMockGps();
                            _mockGpsActive.value = false;
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _mockLatController,
                          keyboardType: const TextInputType.numberWithOptions(
                              signed: true, decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Latitude Padrão',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _mockLonController,
                          keyboardType: const TextInputType.numberWithOptions(
                              signed: true, decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Longitude Padrão',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.my_location_rounded,
                            size: 14, color: HpColors.accentCyan),
                        label: const Text('Tóquio (JP)'),
                        onPressed: () => _setMockCoords(35.676200, 139.650300),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.my_location_rounded,
                            size: 14, color: HpColors.accentCyan),
                        label: const Text('Nova York (US)'),
                        onPressed: () => _setMockCoords(40.712776, -74.005974),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.my_location_rounded,
                            size: 14, color: HpColors.accentCyan),
                        label: const Text('Zurique (CH)'),
                        onPressed: () => _setMockCoords(47.376887, 8.541694),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.my_location_rounded,
                            size: 14, color: HpColors.accentCyan),
                        label: const Text('São Paulo (BR)'),
                        onPressed: () => _setMockCoords(-23.550520, -46.633308),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: HpColors.accentOrange,
                            foregroundColor: Colors.black,
                          ),
                          onPressed: _showMockGpsStepByStepModal,
                          icon: const Icon(Icons.help_outline_rounded, size: 18),
                          label: const Text(
                              'Passo a Passo: Como Ativar no Celular'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => VpnEngine.openMockLocationSettings(),
                        icon:
                            const Icon(Icons.developer_mode_rounded, size: 16),
                        label: const Text('Abrir Opções Dev'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 4. Virtualized Camera Photo Loader & Real-Time Interactive Transform Card
            const HpSectionLabel(
                label:
                    'Câmera Virtualizada (Tempo Real em Fotos, Lives e Apps)'),
            HpSurface(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      HpIconBox(
                        icon: Icons.camera_enhance_rounded,
                        color: HpColors.accentOrange,
                        size: 40,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Substituição de Câmera em Tempo Real',
                              style: HpTextStyles.cardTitle,
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Funciona em fotos, vídeos, lives e apps de câmera. Arraste ou faça pinça na imagem para mover/escalar ao vivo.',
                              style: TextStyle(
                                fontSize: 12,
                                color: HpColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (_virtualCamPath.value.isNotEmpty &&
                      File(_virtualCamPath.value).existsSync())
                    GestureDetector(
                      onPanUpdate: (details) {
                        final dx = (details.delta.dx / 150.0).clamp(-0.25, 0.25);
                        final dy = (details.delta.dy / 150.0).clamp(-0.25, 0.25);
                        _transformVcam(dx: dx, dy: dy);
                      },
                      child: Container(
                        height: 185,
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF060608),
                          borderRadius: BorderRadius.circular(HpRadius.sm),
                          border: Border.all(
                              color: HpColors.accentOrange.withOpacity(0.55)),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(HpRadius.sm),
                              child: Image.file(
                                File(_virtualCamPath.value),
                                key: ValueKey(
                                    '${_virtualCamPath.value}_${Pref.vcamScaleX}_${Pref.vcamScaleY}_${Pref.vcamOffsetX}_${Pref.vcamOffsetY}_${Pref.vcamRotation}_${Pref.vcamFlipH}_${Pref.vcamFlipV}'),
                                fit: BoxFit.contain,
                              ),
                            ),
                            Positioned(
                              bottom: 6,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.72),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.touch_app_rounded,
                                        size: 13, color: HpColors.accentOrange),
                                    SizedBox(width: 4),
                                    Text(
                                      'Arraste para mover em tempo real',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            HapticFeedback.lightImpact();
                            final path =
                                await VpnEngine.pickVirtualCameraImage();
                            if (path != null && path.isNotEmpty) {
                              _virtualCamPath.value = path;
                              Pref.virtualCameraImagePath = path;
                              Pref.virtualCameraEnabled = true;
                              MyDialogs.success(
                                  msg: 'Imagem ativa na Câmera Virtualizada!');
                            }
                          },
                          icon:
                              const Icon(Icons.photo_library_rounded, size: 18),
                          label: const Text('Definir Foto Agora'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: () => VpnEngine.testVirtualCamera(),
                        icon: const Icon(Icons.videocam_rounded, size: 18),
                        label: const Text('Estúdio Ao Vivo'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.arrow_back_rounded,
                            size: 15, color: HpColors.accentOrange),
                        label: const Text('Esquerda'),
                        onPressed: () => _transformVcam(dx: -0.10),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.arrow_forward_rounded,
                            size: 15, color: HpColors.accentOrange),
                        label: const Text('Direita'),
                        onPressed: () => _transformVcam(dx: 0.10),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.arrow_upward_rounded,
                            size: 15, color: HpColors.accentOrange),
                        label: const Text('Cima'),
                        onPressed: () => _transformVcam(dy: -0.10),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.arrow_downward_rounded,
                            size: 15, color: HpColors.accentOrange),
                        label: const Text('Baixo'),
                        onPressed: () => _transformVcam(dy: 0.10),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.zoom_in_rounded,
                            size: 15, color: HpColors.accentOrange),
                        label: const Text('Zoom +'),
                        onPressed: () => _transformVcam(dsx: 0.15, dsy: 0.15),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.zoom_out_rounded,
                            size: 15, color: HpColors.accentOrange),
                        label: const Text('Zoom -'),
                        onPressed: () => _transformVcam(dsx: -0.15, dsy: -0.15),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.swap_horiz_rounded,
                            size: 15, color: HpColors.accentOrange),
                        label: const Text('Alargar H'),
                        onPressed: () => _transformVcam(dsx: 0.18),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.compress_rounded,
                            size: 15, color: HpColors.accentOrange),
                        label: const Text('Estreitar H'),
                        onPressed: () => _transformVcam(dsx: -0.18),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.swap_vert_rounded,
                            size: 15, color: HpColors.accentOrange),
                        label: const Text('Alargar V'),
                        onPressed: () => _transformVcam(dsy: 0.18),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.unfold_less_rounded,
                            size: 15, color: HpColors.accentOrange),
                        label: const Text('Estreitar V'),
                        onPressed: () => _transformVcam(dsy: -0.18),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.rotate_right_rounded,
                            size: 15, color: HpColors.accentOrange),
                        label: const Text('Girar 90°'),
                        onPressed: () => _transformVcam(drot: 90),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.flip_rounded,
                            size: 15, color: HpColors.accentOrange),
                        label: const Text('Espelhar H'),
                        onPressed: () => _transformVcam(toggleFlipH: true),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.flip_camera_android_rounded,
                            size: 15, color: HpColors.accentOrange),
                        label: const Text('Espelhar V'),
                        onPressed: () => _transformVcam(toggleFlipV: true),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.restart_alt_rounded,
                            size: 15, color: HpColors.accentOrange),
                        label: const Text('Resetar'),
                        onPressed: () => _transformVcam(reset: true),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  void _showMockGpsStepByStepModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Como Substituir Coordenadas do GPS',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: HpColors.accentEmerald.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: HpColors.accentEmerald.withOpacity(0.4)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: HpColors.accentEmerald, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Modo Sem Opções do Desenvolvedor (Automático): O NOrange já aplica automaticamente a coordenada escolhida nas requisições de rede/túnel e cabeçalhos de geolocalização sem precisar ativar nada.',
                        style: TextStyle(fontSize: 12, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Passo a Passo para Ativar no GPS Nativo do Android (Mapas, Apps de Entrega e Redes Sociais):',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: HpColors.accentOrange,
                ),
              ),
              const SizedBox(height: 10),
              _buildStepRow(
                '1',
                'Abra "Sobre o Telefone" nas configurações do Android e toque 7 vezes seguidas em "Número da versão" (ou Versão do MIUI/OneUI) até aparecer "Você agora é um desenvolvedor!".',
              ),
              const SizedBox(height: 8),
              _buildStepRow(
                '2',
                'Toque no botão abaixo "Abrir Opções do Desenvolvedor" e role até a opção "Selecionar app de local fictício" (Mock Location App).',
              ),
              const SizedBox(height: 8),
              _buildStepRow(
                '3',
                'Selecione o aplicativo "NOrange" na lista e ative a chave "Substituir Coordenadas do GPS" aqui no app ou no Widget Flutuante.',
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        VpnEngine.openDeviceInfoSettings();
                      },
                      icon: const Icon(Icons.phone_android_rounded, size: 16),
                      label: const Text('1. Sobre o Telefone'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        VpnEngine.openMockLocationSettings();
                      },
                      icon: const Icon(Icons.developer_mode_rounded, size: 16),
                      label: const Text('2. Opções Dev'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepRow(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: HpColors.accentOrange,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12.5, height: 1.4),
          ),
        ),
      ],
    );
  }

  void _setMockCoords(double lat, double lon) {
    _mockLatController.text = lat.toStringAsFixed(6);
    _mockLonController.text = lon.toStringAsFixed(6);
    Pref.mockLat = lat;
    Pref.mockLon = lon;
    if (_mockGpsActive.value) {
      VpnEngine.startMockGps(lat, lon);
    }
    MyDialogs.success(msg: 'Coordenada GPS definida: $lat, $lon');
  }

  Future<void> _transformVcam({
    double dx = 0.0,
    double dy = 0.0,
    double dsx = 0.0,
    double dsy = 0.0,
    double drot = 0.0,
    bool toggleFlipH = false,
    bool toggleFlipV = false,
    bool reset = false,
  }) async {
    HapticFeedback.selectionClick();
    if (reset) {
      Pref.vcamScaleX = 1.0;
      Pref.vcamScaleY = 1.0;
      Pref.vcamOffsetX = 0.0;
      Pref.vcamOffsetY = 0.0;
      Pref.vcamRotation = 0.0;
      Pref.vcamFlipH = false;
      Pref.vcamFlipV = false;
    } else {
      Pref.vcamOffsetX = (Pref.vcamOffsetX + dx).clamp(-1.0, 1.0);
      Pref.vcamOffsetY = (Pref.vcamOffsetY + dy).clamp(-1.0, 1.0);
      Pref.vcamScaleX = (Pref.vcamScaleX + dsx).clamp(0.4, 3.0);
      Pref.vcamScaleY = (Pref.vcamScaleY + dsy).clamp(0.4, 3.0);
      Pref.vcamRotation = (Pref.vcamRotation + drot) % 360.0;
      if (toggleFlipH) Pref.vcamFlipH = !Pref.vcamFlipH;
      if (toggleFlipV) Pref.vcamFlipV = !Pref.vcamFlipV;
    }
    final outPath = await VpnEngine.transformVirtualCameraImage(
      scaleX: Pref.vcamScaleX,
      scaleY: Pref.vcamScaleY,
      offsetX: Pref.vcamOffsetX,
      offsetY: Pref.vcamOffsetY,
      rotation: Pref.vcamRotation,
      flipH: Pref.vcamFlipH,
      flipV: Pref.vcamFlipV,
    );
    if (outPath != null && outPath.isNotEmpty) {
      _virtualCamPath.value = '';
      _virtualCamPath.value = outPath;
    }
    if (mounted) setState(() {});
  }

  Future<void> _testProxyLatency(ProxyConfig proxy) async {
    final sw = Stopwatch()..start();
    try {
      final s = await Socket.connect(
        proxy.host,
        proxy.port,
        timeout: const Duration(seconds: 3),
      );
      sw.stop();
      await s.close();
      proxy.lastPingMs = sw.elapsedMilliseconds;
      _proxies.refresh();
      Pref.proxyList = _proxies.toList();
      MyDialogs.success(
          msg:
              'Proxy ${proxy.endpoint} ONLINE • Latência: ${proxy.lastPingMs} ms');
    } catch (_) {
      sw.stop();
      MyDialogs.error(
          msg: 'Proxy ${proxy.endpoint} inacessível ou offline.');
    }
  }

  void _showAddProxyModal() {
    final nameCtrl = TextEditingController();
    final hostCtrl = TextEditingController();
    final portCtrl = TextEditingController(text: '8080');
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final RxString protocol = 'HTTP'.obs;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Adicionar Servidor Proxy',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Identificação (ex: Proxy BR / SOCKS5 Privado)',
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: hostCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Host ou IP (ex: 192.168.1.15)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: portCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Porta',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Obx(
                () => Row(
                  children: [
                    const Text(
                      'Protocolo:',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    const SizedBox(width: 10),
                    ChoiceChip(
                      label: const Text('HTTP / HTTPS'),
                      selected: protocol.value == 'HTTP',
                      showCheckmark: false,
                      onSelected: (_) => protocol.value = 'HTTP',
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('SOCKS5'),
                      selected: protocol.value == 'SOCKS5',
                      showCheckmark: false,
                      onSelected: (_) => protocol.value = 'SOCKS5',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: userCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Usuário (opcional)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: passCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Senha (opcional)',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final host = hostCtrl.text.trim();
                    final port = int.tryParse(portCtrl.text.trim()) ?? 8080;
                    if (host.isEmpty) {
                      MyDialogs.error(msg: 'Informe o Host/IP do Proxy.');
                      return;
                    }
                    final proxy = ProxyConfig(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameCtrl.text.trim().isEmpty
                          ? '$host:$port'
                          : nameCtrl.text.trim(),
                      host: host,
                      port: port,
                      protocol: protocol.value,
                      username: userCtrl.text.trim(),
                      password: passCtrl.text.trim(),
                    );
                    _proxies.insert(0, proxy);
                    Pref.proxyList = _proxies.toList();
                    _activeProxyId.value = proxy.id;
                    Pref.activeProxyId = proxy.id;
                    Navigator.pop(ctx);
                    MyDialogs.success(
                        msg: 'Proxy "${proxy.name}" adicionado e ativado!');
                  },
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('Salvar e Ativar Proxy'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
