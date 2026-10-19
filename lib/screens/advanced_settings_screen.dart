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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Central Avançada Hide Protocol'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.vpn_key_rounded), text: 'VPN Própria'),
            Tab(icon: Icon(Icons.wifi_tethering_rounded), text: 'Hotspot VPN'),
            Tab(icon: Icon(Icons.hub_rounded), text: 'Proxy'),
            Tab(
                icon: Icon(Icons.radar_rounded),
                text: 'Roteador Wi-Fi & Radar'),
            Tab(
                icon: Icon(Icons.auto_awesome_motion_rounded),
                text: 'Widget Flutuante / GPS / Cam'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCustomVpnTab(),
          _buildShareableVpnTab(),
          _buildProxyCenterTab(),
          _buildWifiRouterAndRadarTab(),
          _buildFloatingAssistantAndPrivacyTab(),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 1: CONFIGURAR VPN PRÓPRIA & DNS AVANÇADO
  // ===========================================================================
  Widget _buildCustomVpnTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 3,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.add_moderator_rounded,
                        color: Colors.blue, size: 26),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Configurar Sua Própria VPN',
                        style: TextStyle(
                            fontSize: 16.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _showAddCustomVpnModal,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Nova VPN'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Adicione servidores OpenVPN próprios via arquivo/texto .OVPN ou configurando IP, Porta, Protocolo (TCP/UDP) e credenciais.',
                  style: TextStyle(fontSize: 13, color: Colors.blueGrey),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        Obx(() {
          if (_customVpns.isEmpty) {
            return Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    'Nenhuma VPN própria cadastrada ainda.\nToque em "+ Nova VPN" acima para adicionar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Text(
                  'Minhas VPNs Configuradas',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              ..._customVpns.map(
                (v) => Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.withOpacity(0.15),
                      child:
                          const Icon(Icons.shield_rounded, color: Colors.blue),
                    ),
                    title: Text(
                      v.countryLong,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${v.ip}:${v.port} • ${v.protocol} • Usuário: ${v.username}',
                      style: const TextStyle(fontSize: 12.5),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Conectar a esta VPN',
                          icon: const Icon(Icons.play_circle_fill_rounded,
                              color: Colors.green, size: 30),
                          onPressed: () {
                            Get.back();
                            _homeController.switchServerAndConnect(v);
                          },
                        ),
                        IconButton(
                          tooltip: 'Remover',
                          icon: const Icon(Icons.delete_outline_rounded,
                              color: Colors.redAccent),
                          onPressed: () {
                            _customVpns.remove(v);
                            Pref.customVpnList = _customVpns.toList();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        }),

        const SizedBox(height: 16),

        Card(
          elevation: 3,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.dns_rounded, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'DNS Personalizado & Segurança',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _dns1Controller,
                        decoration: const InputDecoration(
                          labelText: 'DNS Primário',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _dns2Controller,
                        decoration: const InputDecoration(
                          labelText: 'DNS Secundário',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
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
                      label: const Text('AdGuard (Bloqueio Ads)'),
                      onPressed: () => _setDns('94.140.14.14', '94.140.15.15'),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Obx(
                  () => SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Auto-Failover Inteligente'),
                    subtitle: const Text(
                        'Troca automaticamente de servidor caso a conexão caia ou demore.'),
                    value: _homeController.autoFailover.value,
                    onChanged: (v) => _homeController.autoFailover.value = v,
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading:
                      const Icon(Icons.security_rounded, color: Colors.orange),
                  title: const Text('Kill Switch do Sistema (Sempre Ativo)'),
                  subtitle: const Text(
                      'Abrir configurações nativas de VPN do sistema operacional'),
                  trailing: const Icon(Icons.open_in_new_rounded),
                  onTap: () => VpnEngine.openKillSwitch(),
                ),
              ],
            ),
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
    MyDialogs.success(msg: 'DNS atualizado para $d1 / $d2');
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Adicionar VPN Própria',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nome do Servidor (ex: Minha VPN Casa / AWS)',
                  border: OutlineInputBorder(),
                  isDense: true,
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
                        border: OutlineInputBorder(),
                        isDense: true,
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
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Obx(
                () => Row(
                  children: [
                    const Text('Protocolo: ',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('TCP'),
                      selected: protocol.value == 'TCP',
                      onSelected: (_) => protocol.value = 'TCP',
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('UDP'),
                      selected: protocol.value == 'UDP',
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
                        border: OutlineInputBorder(),
                        isDense: true,
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
                        border: OutlineInputBorder(),
                        isDense: true,
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
                      'Conteúdo do Arquivo .OVPN (Cole aqui ou deixe em branco)',
                  border: const OutlineInputBorder(),
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
              const SizedBox(height: 14),
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
  Widget _buildShareableVpnTab() {
    return Obx(
      () => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: _gateway.isRunning.value
                            ? Colors.green.withOpacity(0.15)
                            : Colors.blue.withOpacity(0.15),
                        child: Icon(
                          Icons.wifi_tethering_rounded,
                          color: _gateway.isRunning.value
                              ? Colors.green
                              : Colors.blue,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Compartilhar Conexão VPN do Celular',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _gateway.isRunning.value
                                  ? 'ATIVO • Compartilhando em ${_gateway.primaryIp}:${_gateway.listeningPort.value}'
                                  : 'Desativado • Toque para transformar seu celular em Gateway VPN',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: _gateway.isRunning.value
                                    ? Colors.green
                                    : Colors.blueGrey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _gateway.isRunning.value,
                        activeColor: Colors.green,
                        onChanged: (enable) async {
                          if (enable) {
                            final port =
                                int.tryParse(_gatewayPortController.text) ??
                                    8080;
                            final ok = await _gateway.startServer(
                              port: port,
                              username: _gatewayUserController.text,
                              password: _gatewayPassController.text,
                            );
                            if (ok) {
                              MyDialogs.success(
                                  msg:
                                      'Celular agora é um Gateway VPN compartilhável em ${_gateway.primaryIp}:${_gateway.listeningPort.value}!');
                            } else {
                              MyDialogs.error(
                                  msg:
                                      'Não foi possível abrir a porta $port.');
                            }
                          } else {
                            await _gateway.stopServer();
                          }
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _metricBox('IP do Celular', _gateway.primaryIp,
                          Icons.smartphone_rounded),
                      _metricBox('Porta Gateway',
                          '${_gateway.listeningPort.value}', Icons.numbers),
                      _metricBox('Conectados',
                          '${_gateway.activeConnections.value}', Icons.people),
                      _metricBox('Tráfego', _gateway.formattedBytesRelayed,
                          Icons.swap_vert_rounded),
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
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          label: const Text('Copiar IP:Porta'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final ovpn = _gateway.generateShareableOvpnProfile(
                                _homeController.vpn.value);
                            Clipboard.setData(ClipboardData(text: ovpn));
                            MyDialogs.success(
                                msg:
                                    'Perfil .OVPN compartilhável copiado! Envie para outro dispositivo importar no OpenVPN.');
                          },
                          icon: const Icon(Icons.share_rounded, size: 18),
                          label: const Text('Gerar .OVPN Cliente'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.router_rounded, color: Colors.blue),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Interfaces de Rede do Celular (Wi-Fi / Hotspot / TUN)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(CupertinoIcons.refresh, size: 20),
                        onPressed: () => _gateway.refreshLocalIps(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ..._gateway.localIps.map(
                    (ipInfo) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text('• $ipInfo',
                          style: const TextStyle(
                              fontFamily: 'monospace', fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricBox(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }

  // ===========================================================================
  // TAB 3: CENTRAL DE PROXY (SERVIDOR PROXY NO CELULAR + CLIENTE PROXY)
  // ===========================================================================
  Widget _buildProxyCenterTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 3,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Obx(
              () => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.cell_tower_rounded,
                          color: Colors.purple, size: 26),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tornar Celular um Proxy Conectável',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _gateway.isRunning.value
                                  ? 'Servidor Proxy ONLINE em ${_gateway.primaryIp}:${_gateway.listeningPort.value}'
                                  : 'Hospede um servidor HTTP/HTTPS + SOCKS5 no seu celular',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: _gateway.isRunning.value
                                    ? Colors.green
                                    : Colors.blueGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _gatewayPortController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Porta Proxy',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _gatewayUserController,
                          decoration: const InputDecoration(
                            labelText: 'Usuário (Opcional)',
                            border: OutlineInputBorder(),
                            isDense: true,
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
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _gateway.isRunning.value
                            ? Colors.redAccent
                            : Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
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
                          ? 'Parar Servidor Proxy do Celular'
                          : 'Iniciar Servidor Proxy no Celular (HTTP + SOCKS5)'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 3,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.hub_rounded, color: Colors.blue, size: 26),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Configurar / Adicionar Proxy Externo',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _showAddProxyModal,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Adicionar Proxy'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Adicione proxies HTTP ou SOCKS5. Quando ativado, o tráfego da VPN será tunelado através do proxy selecionado.',
                  style: TextStyle(fontSize: 12.5, color: Colors.blueGrey),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Obx(() {
          if (_proxies.isEmpty) {
            return Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    'Nenhum proxy externo adicionado ainda.\nToque em "+ Adicionar Proxy" para cadastrar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            );
          }

          return Column(
            children: _proxies.map((proxy) {
              final isActive = _activeProxyId.value == proxy.id;
              return Card(
                elevation: isActive ? 5 : 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: isActive
                      ? const BorderSide(color: Colors.green, width: 1.8)
                      : BorderSide.none,
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isActive
                        ? Colors.green.withOpacity(0.15)
                        : Colors.blue.withOpacity(0.15),
                    child: Icon(
                      Icons.swap_horiz_rounded,
                      color: isActive ? Colors.green : Colors.blue,
                    ),
                  ),
                  title: Text(
                    '${proxy.name} (${proxy.protocol})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${proxy.host}:${proxy.port}'
                    '${proxy.lastPingMs != null ? " • Ping: ${proxy.lastPingMs} ms" : ""}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Testar Conexão com o Proxy',
                        icon: const Icon(Icons.speed_rounded,
                            color: Colors.orange),
                        onPressed: () => _testProxyLatency(proxy),
                      ),
                      Switch(
                        value: isActive,
                        activeColor: Colors.green,
                        onChanged: (val) {
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
                        icon: const Icon(Icons.delete_outline_rounded,
                            color: Colors.redAccent),
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
  Widget _buildWifiRouterAndRadarTab() {
    return Obx(
      () => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Wi-Fi Router & Bridge Control Card
          Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.router_rounded,
                          color: Colors.teal, size: 28),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Iniciar Roteador Wi-Fi Inteligente',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Compartilhe Dados Móveis (4G/5G) ou Repetidor Wi-Fi com inspeção de tráfego em tempo real',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.blueGrey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Fonte de Rede: ',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('📶 Dados Móveis'),
                        selected: _routerSourceMode.value ==
                            'Dados Móveis (4G/5G)',
                        onSelected: (_) =>
                            _routerSourceMode.value = 'Dados Móveis (4G/5G)',
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('📡 Repetidor Wi-Fi'),
                        selected:
                            _routerSourceMode.value == 'Repetidor Wi-Fi',
                        onSelected: (_) =>
                            _routerSourceMode.value = 'Repetidor Wi-Fi',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            if (!_gateway.isRunning.value) {
                              await _gateway.startServer();
                            }
                            await VpnEngine.openHotspotSettings();
                          },
                          icon: const Icon(Icons.wifi_tethering_rounded),
                          label: const Text('Ativar Roteador Wi-Fi + Inspetor'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Connected Devices, Accessed Domains & Bandwidth Consumption
          Card(
            elevation: 3,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Dispositivos Conectados (${_gateway.peerStats.length})',
                        style: const TextStyle(
                            fontSize: 15.5, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Total: ${_gateway.formattedBytesRelayed}',
                        style: const TextStyle(
                            fontSize: 13,
                            color: Colors.teal,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Veja o IP de cada aparelho, o quanto estão consumindo (Download/Upload) e exatamente os sites/serviços que estão acessando:',
                    style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 10),
                  if (_gateway.peerStats.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _gateway.isRunning.value
                            ? 'Roteador/Inspetor ativo em ${_gateway.primaryIp}:${_gateway.listeningPort.value}.\nAssim que dispositivos trafegarem dados, aparecerão aqui.'
                            : 'Ative o Roteador/Gateway acima para monitorar dispositivos conectados e o que estão acessando.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 12.5, color: Colors.blueGrey),
                      ),
                    )
                  else
                    ..._gateway.peerStats.values.map(
                      (peer) => Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.teal.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.devices_rounded,
                                    color: Colors.teal, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Dispositivo: ${peer.ip}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.withOpacity(0.14),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Consumo: ${ConnectedPeerStat.formatBytes(peer.totalBytes)}',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '⬇️ Down: ${ConnectedPeerStat.formatBytes(peer.bytesDownloaded)}   •   '
                              '⬆️ Up: ${ConnectedPeerStat.formatBytes(peer.bytesUploaded)}   •   '
                              'Conexões Ativas: ${peer.activeSockets}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.blueGrey),
                            ),
                            if (peer.accessedDomains.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              const Text(
                                '🌐 O que está acessando agora:',
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: peer.accessedDomains
                                    .map(
                                      (domain) => Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.12),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          domain,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontFamily: 'monospace',
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
          ),

          const SizedBox(height: 14),

          // Wi-Fi Radio Wave Proximity Radar Card
          Card(
            elevation: 3,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.radar_rounded,
                          color: Colors.deepOrange, size: 26),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Radar de Proximidade por Ondas Wi-Fi',
                              style: TextStyle(
                                  fontSize: 15.5, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Calcula a distância física (metros) dos dispositivos via atenuação de onda (RSSI dBm & Frequência MHz)',
                              style: TextStyle(
                                  fontSize: 11.5, color: Colors.blueGrey),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Escanear Ondas Wi-Fi',
                        onPressed: _scanWifiWaves,
                        icon: _isScanningWifi.value
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(CupertinoIcons.refresh_circled_solid,
                                color: Colors.deepOrange, size: 28),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_wifiProximityList.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Center(
                        child: Text(
                          'Toque no botão de atualizar acima para escanear as ondas Wi-Fi ao redor.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 12.5),
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
                          ? 'Muito Próximo (<2m)'
                          : (dist < 8.0 ? 'Próximo' : 'Distante');
                      final barColor = dist < 2.0
                          ? Colors.green
                          : (dist < 8.0 ? Colors.orange : Colors.redAccent);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '📡 ${w['name']} (${w['type']})',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13.5),
                                  ),
                                ),
                                Text(
                                  '~${dist.toStringAsFixed(1)} m ($proximityLabel)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.5,
                                    color: barColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'MAC/IP: ${w['address']}  •  Onda: $rssi dBm @ $freq MHz',
                              style: const TextStyle(
                                  fontSize: 11.5, color: Colors.blueGrey),
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: signalFactor,
                                minHeight: 6,
                                color: barColor,
                                backgroundColor: barColor.withOpacity(0.15),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 5: WIDGET FLUTUANTE, VPN POR APP, MOCK GPS & CÂMERA VIRTUALIZADA
  // ===========================================================================
  Widget _buildFloatingAssistantAndPrivacyTab() {
    return Obx(
      () => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Floating Assistant Overlay Bubble Card
          Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.indigo.withOpacity(0.15),
                        child: const Icon(Icons.bubble_chart_rounded,
                            color: Colors.indigo, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Widget Flutuante (Assistente Global)',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _floatingRunning.value
                                  ? 'ATIVO • Botão flutuante visível sobre outros apps'
                                  : 'Fica sobre outros apps (igual gravador de tela / acessibilidade)',
                              style: TextStyle(
                                fontSize: 12,
                                color: _floatingRunning.value
                                    ? Colors.green
                                    : Colors.blueGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _floatingRunning.value,
                        activeColor: Colors.green,
                        onChanged: (enable) async {
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
                  const SizedBox(height: 10),
                  const Text(
                    'Ao abrir qualquer aplicativo no celular, toque na bolha flutuante "🛡️ VPN" para:\n'
                    '• Isolar a VPN/Proxy somente para o tráfego daquele app em foco;\n'
                    '• Ligar/Desligar a coordenada GPS falsa na hora;\n'
                    '• Ativar a Câmera Virtualizada.',
                    style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => VpnEngine.requestUsageStatsPermission(),
                      icon: const Icon(Icons.app_shortcut_rounded, size: 18),
                      label: const Text(
                          'Conceder Permissão para Detectar App em Foco'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // 2. Per-App VPN / Proxy Split Tunneling Selector
          Card(
            elevation: 3,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.apps_outage_rounded, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'VPN/Proxy Somente por App (${_selectedAllowedApps.isEmpty ? "Todos os Apps" : "${_selectedAllowedApps.length} selecionado(s)"})',
                          style: const TextStyle(
                              fontSize: 15.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (_selectedAllowedApps.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            _selectedAllowedApps.clear();
                            Pref.allowedAppPackages = [];
                          },
                          child: const Text('Limpar'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Selecione os aplicativos abaixo se desejar que a VPN/Proxy funcione SOMENTE para o tráfego deles:',
                    style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 165,
                    child: _installedApps.isEmpty
                        ? const Center(
                            child: Text(
                              'Carregando aplicativos instalados...',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _installedApps.length,
                            itemBuilder: (_, i) {
                              final app = _installedApps[i];
                              final pkg = app['packageName'] ?? '';
                              final name = app['appName'] ?? pkg;
                              final checked =
                                  _selectedAllowedApps.contains(pkg);
                              return CheckboxListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                value: checked,
                                title: Text(name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
                                subtitle: Text(pkg,
                                    style: const TextStyle(fontSize: 11)),
                                onChanged: (val) {
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
          ),

          const SizedBox(height: 14),

          // 3. Mock GPS Location Spoofer Card
          Card(
            elevation: 3,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.edit_location_alt_rounded,
                          color: Colors.orange, size: 26),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Alterar Localização GPS (Coordenada Padrão)',
                          style: TextStyle(
                              fontSize: 15.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Switch(
                        value: _mockGpsActive.value,
                        activeColor: Colors.orange,
                        onChanged: (enable) async {
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
                            _mockGpsActive.value = ok;
                            if (ok) {
                              MyDialogs.success(
                                  msg:
                                      'GPS alterado para ($lat, $lon) com sucesso!');
                            }
                          } else {
                            await VpnEngine.stopMockGps();
                            _mockGpsActive.value = false;
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _mockLatController,
                          keyboardType: const TextInputType.numberWithOptions(
                              signed: true, decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Latitude Padrão',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _mockLonController,
                          keyboardType: const TextInputType.numberWithOptions(
                              signed: true, decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Longitude Padrão',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      ActionChip(
                        label: const Text('🇯🇵 Tóquio'),
                        onPressed: () => _setMockCoords(35.676200, 139.650300),
                      ),
                      ActionChip(
                        label: const Text('🇺🇸 Nova York'),
                        onPressed: () => _setMockCoords(40.712776, -74.005974),
                      ),
                      ActionChip(
                        label: const Text('🇨🇭 Zurique'),
                        onPressed: () => _setMockCoords(47.376887, 8.541694),
                      ),
                      ActionChip(
                        label: const Text('🇧🇷 São Paulo'),
                        onPressed: () =>
                            _setMockCoords(-23.550520, -46.633308),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => VpnEngine.openMockLocationSettings(),
                      icon: const Icon(Icons.developer_mode_rounded, size: 16),
                      label: const Text(
                          'Abrir Opções do Desenvolvedor (Local Fictício)'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // 4. Virtualized Camera Photo Loader Card
          Card(
            elevation: 3,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.camera_enhance_rounded,
                          color: Colors.purple, size: 26),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Câmera Virtualizada (Substituir Foto da Câmera)',
                          style: TextStyle(
                              fontSize: 15.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Carregue uma foto da sua galeria para aparecer na câmera virtualizada ao invés de tirar uma foto ao vivo quando solicitada:',
                    style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 12),
                  if (_virtualCamPath.value.isNotEmpty &&
                      File(_virtualCamPath.value).existsSync())
                    Container(
                      height: 160,
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.purple),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            final path =
                                await VpnEngine.pickVirtualCameraImage();
                            if (path != null && path.isNotEmpty) {
                              _virtualCamPath.value = path;
                              Pref.virtualCameraImagePath = path;
                              MyDialogs.success(
                                  msg:
                                      'Foto carregada na Câmera Virtualizada!');
                            }
                          },
                          icon: const Icon(Icons.photo_library_rounded,
                              size: 18),
                          label: const Text('Carregar Foto p/ Câmera'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => VpnEngine.testVirtualCamera(),
                        icon: const Icon(Icons.preview_rounded, size: 18),
                        label: const Text('Testar Câmera'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
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
    MyDialogs.success(msg: 'Coordenada padrão definida: $lat, $lon');
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
              'Proxy ${proxy.endpoint} está ONLINE! Latência: ${proxy.lastPingMs} ms');
    } catch (_) {
      sw.stop();
      MyDialogs.error(
          msg: 'Proxy ${proxy.endpoint} não respondeu ou está offline.');
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Adicionar Novo Servidor Proxy',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nome do Proxy (ex: Proxy BR / Proxy Celular 2)',
                  border: OutlineInputBorder(),
                  isDense: true,
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
                        border: OutlineInputBorder(),
                        isDense: true,
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
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Obx(
                () => Row(
                  children: [
                    const Text('Tipo de Proxy: ',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('HTTP / HTTPS'),
                      selected: protocol.value == 'HTTP',
                      onSelected: (_) => protocol.value = 'HTTP',
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('SOCKS5'),
                      selected: protocol.value == 'SOCKS5',
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
                        border: OutlineInputBorder(),
                        isDense: true,
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
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
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
