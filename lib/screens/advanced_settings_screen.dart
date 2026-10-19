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
import '../widgets/hide_protocol_logo.dart';

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
  final RxList<ProxyConfig> _proxies = <ProxyConfig>[].obs;
  final RxString _activeProxyId = ''.obs;

  // Tab 4: Wi-Fi Router & Wave Proximity Radar state
  final RxList<Map<String, dynamic>> _wifiProximityList =
      <Map<String, dynamic>>[].obs;
  final RxBool _isScanningWifi = false.obs;
  final RxString _routerSourceMode = 'Dados Móveis (4G/5G)'.obs;

  // Tab 5: Floating Widget, Per-App VPN, Mock GPS & Virtual Camera state
  final RxBool _floatingRunning = false.obs;
  final RxList<Map<String, String>> _installedApps =
      <Map<String, String>>[].obs;
  final RxList<String> _selectedAllowedApps = <String>[].obs;
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

    _selectedAllowedApps.assignAll(Pref.allowedAppPackages);
    _mockLatController.text = Pref.mockLat.toStringAsFixed(6);
    _mockLonController.text = Pref.mockLon.toStringAsFixed(6);
    _virtualCamPath.value = Pref.virtualCameraImagePath;

    _gateway.refreshLocalIps();
    _loadInitialDeviceData();
  }

  Future<void> _loadInitialDeviceData() async {
    _floatingRunning.value = await VpnEngine.isFloatingWidgetRunning();
    final apps = await VpnEngine.getInstalledApps();
    _installedApps.assignAll(apps);
    await _scanWifiWaves();
  }

  Future<void> _scanWifiWaves() async {
    if (_isScanningWifi.value) return;
    _isScanningWifi.value = true;
    final res = await VpnEngine.scanWifiProximity();
    _wifiProximityList.assignAll(res);
    _isScanningWifi.value = false;
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
        title: const Text('Central Avançada Hide Protocol'),
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
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCustomVpnTab(isDark),
          _buildShareableVpnTab(isDark),
          _buildProxyCenterTab(isDark),
          _buildWifiRouterAndRadarTab(isDark),
          _buildFloatingAssistantAndPrivacyTab(isDark),
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
                                ? 'GATEWAY ATIVO • ${_gateway.primaryIp}:${_gateway.listeningPort.value}'
                                : 'Transforme seu celular em um Gateway VPN compartilhável',
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
                          final ok = await _gateway.startServer(
                            port: port,
                            username: _gatewayUserController.text,
                            password: _gatewayPassController.text,
                          );
                          if (ok) {
                            MyDialogs.success(
                                msg:
                                    'Gateway VPN compartilhável ativo em ${_gateway.primaryIp}:${_gateway.listeningPort.value}!');
                          } else {
                            MyDialogs.error(
                                msg: 'Não foi possível abrir a porta $port.');
                          }
                        } else {
                          await _gateway.stopServer();
                        }
                      },
                    ),
                  ],
                ),
                const Divider(height: 26),
                Row(
                  children: [
                    Expanded(
                      child: _metricBox(
                        'IP Local',
                        _gateway.primaryIp,
                        Icons.smartphone_rounded,
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
                        'Peers',
                        '${_gateway.activeConnections.value}',
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final addr =
                              '${_gateway.primaryIp}:${_gateway.listeningPort.value}';
                          Clipboard.setData(ClipboardData(text: addr));
                          MyDialogs.success(msg: 'Endereço $addr copiado!');
                        },
                        icon: const Icon(Icons.copy_rounded, size: 17),
                        label: const Text('Copiar IP:Porta'),
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
                                  'Perfil .OVPN Cliente copiado! Importe em outro aparelho.');
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
                      onPressed: () => _gateway.refreshLocalIps(),
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
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        HpSurface(
          padding: const EdgeInsets.all(18),
          borderRadius: HpRadius.lg,
          child: Obx(
            () => Column(
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
                                ? 'ONLINE em ${_gateway.primaryIp}:${_gateway.listeningPort.value}'
                                : 'Servidor multi-protocolo HTTP/HTTPS + SOCKS5',
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
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _gatewayPortController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Porta Proxy',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _gatewayUserController,
                        decoration: const InputDecoration(
                          labelText: 'Usuário (Opcional)',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _gatewayPassController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Senha (Opcional)',
                        ),
                      ),
                    ),
                  ],
                ),
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
                      } else {
                        final port =
                            int.tryParse(_gatewayPortController.text) ?? 8080;
                        final ok = await _gateway.startServer(
                          port: port,
                          username: _gatewayUserController.text,
                          password: _gatewayPassController.text,
                        );
                        if (ok) {
                          MyDialogs.success(
                              msg:
                                  'Servidor Proxy HTTP/SOCKS5 ativo em ${_gateway.primaryIp}:$port');
                        } else {
                          MyDialogs.error(msg: 'Erro ao iniciar porta $port.');
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
        Obx(() {
          if (_proxies.isEmpty) {
            return HpSurface(
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
            );
          }

          return Column(
            children: _proxies.map((proxy) {
              final isActive = _activeProxyId.value == proxy.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: HpSurface(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  borderColor:
                      isActive ? HpColors.accentEmerald.withOpacity(0.6) : null,
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
                        onChanged: (val) {
                          HapticFeedback.selectionClick();
                          if (val) {
                            _activeProxyId.value = proxy.id;
                            Pref.activeProxyId = proxy.id;
                            MyDialogs.success(
                                msg:
                                    'Proxy "${proxy.name}" ativado para conexões!');
                          } else {
                            _activeProxyId.value = '';
                            Pref.activeProxyId = '';
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
                            Pref.activeProxyId = '';
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
          );
        }),
      ],
    );
  }

  // ===========================================================================
  // TAB 4: ROTEADOR WI-FI, INSPETOR DE DISPOSITIVOS & RADAR DE ONDAS WI-FI
  // ===========================================================================
  Widget _buildWifiRouterAndRadarTab(bool isDark) {
    return Obx(
      () => ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          // Wi-Fi Router & Bridge Control Card
          HpSurface(
            padding: const EdgeInsets.all(18),
            borderRadius: HpRadius.lg,
            borderColor: HpColors.accentEmerald.withOpacity(0.32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    HpIconBox(
                      icon: Icons.router_rounded,
                      color: HpColors.accentEmerald,
                      size: 42,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Roteador Wi-Fi & Inspetor de Tráfego',
                            style: HpTextStyles.cardTitle,
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Compartilhe Dados Móveis ou Wi-Fi monitorando consumo e domínios',
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
                        selected: _routerSourceMode.value == 'Repetidor Wi-Fi',
                        showCheckmark: false,
                        onSelected: (_) =>
                            _routerSourceMode.value = 'Repetidor Wi-Fi',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      HapticFeedback.mediumImpact();
                      if (!_gateway.isRunning.value) {
                        await _gateway.startServer();
                      }
                      await VpnEngine.openHotspotSettings();
                    },
                    icon: const Icon(Icons.wifi_tethering_rounded, size: 18),
                    label: const Text('Ativar Roteador Wi-Fi + Inspetor'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Connected Devices, Accessed Domains & Bandwidth Consumption
          HpSectionLabel(
            label:
                'Dispositivos Conectados (${_gateway.peerStats.length}) • Total: ${_gateway.formattedBytesRelayed}',
          ),
          HpSurface(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Monitoramento em tempo real de IP, Download/Upload e domínios/hosts acessados por cada dispositivo conectado:',
                  style: TextStyle(fontSize: 12, color: HpColors.textSecondary),
                ),
                const SizedBox(height: 12),
                if (_gateway.peerStats.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color:
                          isDark ? HpColors.bgSurface : HpColors.lightSurface,
                      borderRadius: BorderRadius.circular(HpRadius.sm),
                    ),
                    child: Text(
                      _gateway.isRunning.value
                          ? 'Inspetor ativo em ${_gateway.primaryIp}:${_gateway.listeningPort.value}.\nAssim que dispositivos trafegarem pacotes, serão listados abaixo.'
                          : 'Inicie o Roteador/Gateway acima para inspecionar os aparelhos conectados e o tráfego em tempo real.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12.5,
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
                                Icons.devices_rounded,
                                color: HpColors.accentEmerald,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  peer.ip,
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
                          Text(
                            '↓ ${ConnectedPeerStat.formatBytes(peer.bytesDownloaded)}   •   '
                            '↑ ${ConnectedPeerStat.formatBytes(peer.bytesUploaded)}   •   '
                            'Sockets: ${peer.activeSockets}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: HpColors.textSecondary,
                            ),
                          ),
                          if (peer.accessedDomains.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            const Text(
                              'DOMÍNIOS / DESTINOS ACESSADOS:',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                                color: HpColors.textMuted,
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
              ],
            ),
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
      ),
    );
  }

  // ===========================================================================
  // TAB 5: WIDGET FLUTUANTE, VPN POR APP, MOCK GPS & CÂMERA VIRTUALIZADA
  // ===========================================================================
  Widget _buildFloatingAssistantAndPrivacyTab(bool isDark) {
    return Obx(
      () => ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Floating Assistant Overlay Bubble Card
          HpSurface(
            padding: const EdgeInsets.all(18),
            borderRadius: HpRadius.lg,
            borderColor: _floatingRunning.value
                ? HpColors.accentEmerald.withOpacity(0.5)
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    HpIconBox(
                      icon: Icons.bubble_chart_rounded,
                      color: _floatingRunning.value
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
                            'Widget Flutuante Tático',
                            style: HpTextStyles.cardTitle,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _floatingRunning.value
                                ? 'ATIVO • Bolha flutuante sobreposta aos apps'
                                : 'Assistente rápido sobre qualquer aplicativo aberto',
                            style: TextStyle(
                              fontSize: 12,
                              color: _floatingRunning.value
                                  ? HpColors.accentEmerald
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
                          final started = await VpnEngine.startFloatingWidget();
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
                  'Toque na bolha "🛡️ VPN" enquanto usa outro aplicativo para isolar a VPN/Proxy exclusivamente para o app em foco, ativar a coordenada GPS padrão ou acionar a Câmera Virtualizada.',
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
                    label: const Text('Permissão de Detecção de App em Foco'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // 2. Per-App VPN / Proxy Split Tunneling Selector
          HpSectionLabel(
            label:
                'Split Tunneling por App (${_selectedAllowedApps.isEmpty ? "Global" : "${_selectedAllowedApps.length} selecionado(s)"})',
            trailing: _selectedAllowedApps.isNotEmpty ? 'Limpar Seleção' : null,
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
                  'Selecione aplicativos específicos para que o túnel VPN/Proxy passe somente pelo tráfego deles:',
                  style: TextStyle(fontSize: 12, color: HpColors.textSecondary),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 180,
                  child: _installedApps.isEmpty
                      ? const Center(
                          child: Text(
                            'Carregando lista de pacotes instalados...',
                            style: TextStyle(color: HpColors.textMuted),
                          ),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: _installedApps.length,
                          itemBuilder: (_, i) {
                            final app = _installedApps[i];
                            final pkg = app['packageName'] ?? '';
                            final name = app['appName'] ?? pkg;
                            final checked = _selectedAllowedApps.contains(pkg);
                            return CheckboxListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              value: checked,
                              title: Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              subtitle: Text(
                                pkg,
                                style: HpTextStyles.mono.copyWith(
                                  fontSize: 10.5,
                                  color: HpColors.textMuted,
                                ),
                              ),
                              onChanged: (val) {
                                HapticFeedback.selectionClick();
                                if (val == true) {
                                  _selectedAllowedApps.add(pkg);
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

          // 3. Mock GPS Location Spoofer Card
          const HpSectionLabel(label: 'Simulador de Coordenadas GPS (Mock GPS)'),
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
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Substituir Coordenada GPS',
                            style: HpTextStyles.cardTitle,
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Injeta latitude e longitude personalizadas no GPS do sistema',
                            style: TextStyle(
                              fontSize: 12,
                              color: HpColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _mockGpsActive.value,
                      onChanged: (enable) async {
                        HapticFeedback.mediumImpact();
                        final lat = double.tryParse(_mockLatController.text) ??
                            -23.550520;
                        final lon = double.tryParse(_mockLonController.text) ??
                            -46.633308;
                        Pref.mockLat = lat;
                        Pref.mockLon = lon;
                        if (enable) {
                          final ok = await VpnEngine.startMockGps(lat, lon);
                          _mockGpsActive.value = ok;
                          if (ok) {
                            MyDialogs.success(
                                msg:
                                    'GPS redirecionado para ($lat, $lon) com sucesso!');
                          }
                        } else {
                          await VpnEngine.stopMockGps();
                          _mockGpsActive.value = false;
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),
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
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => VpnEngine.openMockLocationSettings(),
                    icon: const Icon(Icons.developer_mode_rounded, size: 16),
                    label: const Text(
                        'Configurar App de Local Fictício (Opções Dev)'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // 4. Virtualized Camera Photo Loader Card
          const HpSectionLabel(label: 'Câmera Virtualizada (Injeção de Imagem)'),
          HpSurface(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    HpIconBox(
                      icon: Icons.camera_enhance_rounded,
                      color: HpColors.accentCyan,
                      size: 40,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Substituição de Captura de Câmera',
                            style: HpTextStyles.cardTitle,
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Retorna uma imagem pré-carregada quando um app solicita foto',
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
                  Container(
                    height: 165,
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(HpRadius.sm),
                      border: Border.all(
                          color: HpColors.accentEmerald.withOpacity(0.5)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(HpRadius.sm),
                      child: Image.file(
                        File(_virtualCamPath.value),
                        fit: BoxFit.cover,
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
                            MyDialogs.success(
                                msg: 'Imagem ativa na Câmera Virtualizada!');
                          }
                        },
                        icon: const Icon(Icons.photo_library_rounded, size: 18),
                        label: const Text('Selecionar Foto'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: () => VpnEngine.testVirtualCamera(),
                      icon: const Icon(Icons.preview_rounded, size: 18),
                      label: const Text('Testar Captura'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
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
