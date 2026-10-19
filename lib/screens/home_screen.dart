import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../controllers/home_controller.dart';
import '../helpers/pref.dart';
import '../main.dart';
import '../models/vpn_status.dart';
import '../screens/socialmediadialog.dart';
import '../services/vpn_engine.dart';
import '../services/vpn_gateway_proxy_service.dart';
import '../theme/app_theme.dart';
import '../widgets/count_down_timer.dart';
import '../widgets/norange_logo.dart';
import '../widgets/home_card.dart';
import '../widgets/norange_floating_widget.dart';
import 'advanced_settings_screen.dart';
import 'location_screen.dart';
import 'network_test_screen.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final _controller = Get.put(HomeController());
  final _gateway = VpnGatewayProxyService.instance;

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // 1. ARCHITECTURAL COMMAND HEADER
                _buildTopBar(context, isDark),

                // 2. MAIN SCROLLABLE EXPERIENCE
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: HpSpacing.md,
                      vertical: HpSpacing.xs,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 6),

                        // HERO ORBITAL SHIELD CORE (Zero idle CPU overhead)
                        RepaintBoundary(
                          child: Obx(() => _buildHeroPowerCore(context, isDark)),
                        ),

                        const SizedBox(height: 18),

                        // 2x2 LIVE TELEMETRY BENTO GRID
                        const HpSectionLabel(
                          label: 'Telemetria de Sessão em Tempo Real',
                        ),
                        _buildTelemetryBentoGrid(context),

                        const SizedBox(height: 18),

                        // TACTICAL COMMAND SUITE (4 QUICK MODULES)
                        HpSectionLabel(
                          label: 'Suíte Tática & Rede Avançada',
                          trailing: 'Abrir Central',
                          onTrailingTap: () =>
                              Get.to(() => const AdvancedSettingsScreen()),
                        ),
                        Obx(() => _buildTacticalModulesGrid(context)),

                        const SizedBox(height: 44),
                      ],
                    ),
                  ),
                ),

                // 3. BOTTOM ACTIVE SERVER SELECTOR DOCK
                _buildBottomServerDock(context, isDark),
              ],
            ),

            // 4. INTERACTIVE DRAGGABLE NORANGE FLOATING WIDGET ("NOrange Pod")
            NOrangeFloatingWidget(controller: _controller),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              showSocialMediaDialog(context);
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                NOrangeLogo(size: 38),
                SizedBox(width: 10),
                NOrangeWordmark(
                  fontSize: 17,
                  subtitle: 'STEALTH NETWORK',
                ),
              ],
            ),
          ),

          const Spacer(),

          if (Platform.isIOS) ...[
            _TopActionButton(
              icon: CupertinoIcons.share,
              tooltip: 'Exportar Perfil .OVPN',
              onTap: () => _controller.exportCurrentProfile(),
            ),
            const SizedBox(width: 8),
          ],
          _TopActionButton(
            icon: CupertinoIcons.waveform_path_ecg,
            tooltip: 'Diagnóstico de Rede & IP',
            onTap: () => Get.to(() => const NetworkTestScreen()),
          ),
          const SizedBox(width: 8),
          _TopActionButton(
            icon: Icons.tune_rounded,
            tooltip: 'Central Avançada NOrange',
            highlight: true,
            onTap: () => Get.to(() => const AdvancedSettingsScreen()),
          ),
          const SizedBox(width: 8),
          _TopActionButton(
            icon: isDark
                ? CupertinoIcons.sun_max_fill
                : CupertinoIcons.moon_stars_fill,
            tooltip: 'Alternar Tema',
            onTap: () {
              HapticFeedback.selectionClick();
              Get.changeThemeMode(
                Pref.isDarkMode ? ThemeMode.light : ThemeMode.dark,
              );
              Pref.isDarkMode = !Pref.isDarkMode;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeroPowerCore(BuildContext context, bool isDark) {
    final state = _controller.vpnState.value;
    final isConnected = state == VpnEngine.vpnConnected;
    final isDisconnected = state == VpnEngine.vpnDisconnected ||
        state == VpnEngine.vpnDenied ||
        state == VpnEngine.vpnNoConnection;
    final stateColor = _controller.getButtonColor;

    final statusLabel = isConnected
        ? 'TUNNEL ENCRYPTED • AES-256'
        : isDisconnected
            ? 'STANDBY • UNPROTECTED'
            : state.replaceAll('_', ' ').toUpperCase();

    return HpSurface(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      borderRadius: HpRadius.xl,
      borderColor: isConnected
          ? HpColors.accentEmerald.withOpacity(0.45)
          : (isDark ? HpColors.borderSubtle : HpColors.lightBorder),
      child: Column(
        children: [
          // Top Security Badge & Smart Connect Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              HpBadge(
                text: statusLabel,
                color: stateColor,
                pulsingDot: true,
              ),
              InkWell(
                onTap: _controller.isSmartConnecting.value
                    ? null
                    : () {
                        HapticFeedback.mediumImpact();
                        _controller.smartConnect();
                      },
                borderRadius: BorderRadius.circular(HpRadius.pill),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark ? HpColors.bgSurface : HpColors.lightSurface,
                    borderRadius: BorderRadius.circular(HpRadius.pill),
                    border: Border.all(
                      color: HpColors.accentCyan.withOpacity(0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_controller.isSmartConnecting.value)
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.8,
                            color: HpColors.accentCyan,
                          ),
                        )
                      else
                        const Icon(
                          Icons.bolt_rounded,
                          size: 14,
                          color: HpColors.accentCyan,
                        ),
                      const SizedBox(width: 4),
                      Text(
                        _controller.isSmartConnecting.value
                            ? 'Roteando...'
                            : 'Smart Connect',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: HpColors.accentCyan,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ORBITAL POWER BUTTON (Lightweight state-driven AnimatedContainer)
          Semantics(
            button: true,
            label: _controller.getButtonText,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                _controller.connectToVpn();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                width: 158,
                height: 158,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: stateColor.withOpacity(0.05),
                  border: Border.all(
                    color: stateColor.withOpacity(0.22),
                    width: 1.2,
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: stateColor.withOpacity(0.12),
                    border: Border.all(
                      color: stateColor.withOpacity(0.36),
                      width: 1.2,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: stateColor,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isConnected
                              ? Icons.shield_rounded
                              : Icons.power_settings_new_rounded,
                          size: 32,
                          color: const Color(0xFF04120C),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _controller.getButtonText,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.3,
                            color: Color(0xFF04120C),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // SESSION CHRONOMETER
          CountDownTimer(
            startTimer: _controller.vpnState.value == VpnEngine.vpnConnected,
          ),

          const SizedBox(height: 4),

          // LIVE TELEMETRY HINT OR SUBTITLE
          Text(
            _controller.statusHint.value.isNotEmpty
                ? _controller.statusHint.value
                : (isConnected
                    ? 'Tráfego blindado via túnel criptografado'
                    : 'Toque no núcleo para iniciar o túnel ou use Smart Connect'),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color:
                  isDark ? HpColors.textSecondary : HpColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryBentoGrid(BuildContext context) {
    return Column(
      children: [
        Obx(() {
          final currentVpn = _controller.vpn.value;
          final hasServer = currentVpn.countryLong.isNotEmpty;
          return Row(
            children: [
              Expanded(
                child: HomeCard(
                  onTap: () => Get.to(() => LocationScreen()),
                  subtitle: hasServer
                      ? '${currentVpn.protocol}:${currentVpn.port} • ${currentVpn.numVpnSessions} conexões'
                      : 'LOCAL / NÓ',
                  title: hasServer
                      ? '${currentVpn.countryLong} (${currentVpn.countryShort})'
                      : 'Selecionar',
                  icon: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: HpColors.accentCyanDim,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(
                          color: HpColors.accentCyan.withOpacity(0.3)),
                    ),
                    child: (!hasServer || currentVpn.isCustom)
                        ? const Icon(
                            Icons.vpn_lock_rounded,
                            color: HpColors.accentCyan,
                            size: 20,
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(
                              'assets/flags/${currentVpn.countryShort.toLowerCase()}.png',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                CupertinoIcons.globe,
                                color: HpColors.accentCyan,
                                size: 20,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: HomeCard(
                  subtitle: hasServer
                      ? 'PING • ${currentVpn.latencyLabel}'
                      : 'PING / LATÊNCIA',
                  title: hasServer ? '${currentVpn.ping} ms' : '-- ms',
                  icon: const HpIconBox(
                    icon: Icons.speed_rounded,
                    color: HpColors.accentAmber,
                    size: 40,
                  ),
                ),
              ),
            ],
          );
        }),
        const SizedBox(height: 10),
        StreamBuilder<VpnStatus?>(
          initialData: VpnStatus(),
          stream: VpnEngine.vpnStatusSnapshot(),
          builder: (context, snapshot) => Row(
            children: [
              Expanded(
                child: HomeCard(
                  subtitle: 'DOWNLOAD',
                  title: snapshot.data?.byteIn ?? '0 kbps',
                  icon: const HpIconBox(
                    icon: Icons.south_west_rounded,
                    color: HpColors.accentEmerald,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: HomeCard(
                  subtitle: 'UPLOAD',
                  title: snapshot.data?.byteOut ?? '0 kbps',
                  icon: const HpIconBox(
                    icon: Icons.north_east_rounded,
                    color: HpColors.accentCyan,
                    size: 40,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTacticalModulesGrid(BuildContext context) {
    final gatewayRunning = _gateway.isRunning.value;
    final hasProxy = Pref.activeProxyId.isNotEmpty;
    final perAppCount = Pref.allowedAppPackages.length;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _TacticalModuleTile(
                icon: Icons.vpn_key_rounded,
                accent: HpColors.accentCyan,
                title: 'VPN Própria & DNS',
                subtitle: 'Perfis .OVPN, Kill Switch & DNS',
                onTap: () => Get.to(
                  () => const AdvancedSettingsScreen(initialTabIndex: 0),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _TacticalModuleTile(
                icon: Icons.wifi_tethering_rounded,
                accent: gatewayRunning
                    ? HpColors.accentEmerald
                    : HpColors.accentIndigo,
                title: 'Hotspot VPN & Proxy',
                subtitle: gatewayRunning
                    ? 'ATIVO • Porta ${_gateway.listeningPort.value}'
                    : (hasProxy
                        ? 'Proxy Externo Ativo'
                        : 'Gateway & SOCKS5/HTTP'),
                isLive: gatewayRunning || hasProxy,
                onTap: () => Get.to(
                  () => const AdvancedSettingsScreen(initialTabIndex: 1),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _TacticalModuleTile(
                icon: Icons.radar_rounded,
                accent: HpColors.accentEmerald,
                title: 'Roteador & Radar',
                subtitle: 'Tráfego Wi-Fi & Ondas RSSI (m)',
                onTap: () => Get.to(
                  () => const AdvancedSettingsScreen(initialTabIndex: 3),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _TacticalModuleTile(
                icon: Icons.auto_awesome_motion_rounded,
                accent: HpColors.accentAmber,
                title: 'Widget / GPS / Cam',
                subtitle: perAppCount > 0
                    ? '$perAppCount App(s) isolado(s) • GPS/Cam'
                    : 'Bolha Flutuante, GPS & Cam',
                isLive: perAppCount > 0,
                onTap: () => Get.to(
                  () => const AdvancedSettingsScreen(initialTabIndex: 4),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        HpSurface(
          onTap: () => showSocialMediaDialog(context),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          borderRadius: HpRadius.md,
          child: Row(
            children: [
              const Icon(
                Icons.verified_rounded,
                size: 17,
                color: HpColors.accentOrange,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: const Text(
                  'Desenvolvido por Diego Oris  •  diegooris.ch',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: HpColors.textSecondary,
                  ),
                ),
              ),
              const Icon(
                Icons.open_in_new_rounded,
                size: 14,
                color: HpColors.accentOrange,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomServerDock(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Obx(() {
        final v = _controller.vpn.value;
        final hasServer = v.countryLong.isNotEmpty;
        final totalServers = Pref.vpnList.length;
        return HpSurface(
          onTap: () => Get.to(() => LocationScreen()),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          borderRadius: HpRadius.lg,
          borderColor: HpColors.accentEmerald.withOpacity(0.32),
          color: isDark ? HpColors.bgSurface : HpColors.lightElevated,
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: HpColors.accentEmeraldDim,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  CupertinoIcons.globe,
                  color: HpColors.accentEmerald,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      hasServer
                          ? 'SERVIDOR ATIVO • ${v.ip} (${v.numVpnSessions} CONEXÕES)'
                          : 'REDE GLOBAL DE VPNS PÚBLICAS',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: isDark
                            ? HpColors.textMuted
                            : HpColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasServer
                          ? '${v.countryLong} • ${v.ping} ms (${v.protocol}:${v.port})'
                          : 'Explorar ${totalServers > 2 ? totalServers : "30+"} VPNs Públicas Disponíveis',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: HpColors.accentEmerald,
                  borderRadius: BorderRadius.circular(HpRadius.pill),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'SERVIDORES',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                        color: Color(0xFF04140D),
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: Color(0xFF04140D),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  void showSocialMediaDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const SocialMediaDialog();
      },
    );
  }
}

class _TopActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool highlight;

  const _TopActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(11),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: highlight
                ? HpColors.accentEmeraldDim
                : (isDark ? HpColors.bgElevated : HpColors.lightElevated),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: highlight
                  ? HpColors.accentEmerald.withOpacity(0.45)
                  : (isDark ? HpColors.borderSubtle : HpColors.lightBorder),
            ),
          ),
          child: Icon(
            icon,
            size: 19,
            color: highlight
                ? HpColors.accentEmerald
                : (isDark ? HpColors.textPrimary : HpColors.lightTextPrimary),
          ),
        ),
      ),
    );
  }
}

class _TacticalModuleTile extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isLive;

  const _TacticalModuleTile({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isLive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return HpSurface(
      onTap: onTap,
      padding: const EdgeInsets.all(13),
      borderRadius: HpRadius.md,
      borderColor: isLive ? accent.withOpacity(0.5) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              HpIconBox(icon: icon, color: accent, size: 34),
              if (isLive)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                )
              else
                Icon(
                  Icons.north_east_rounded,
                  size: 15,
                  color:
                      isDark ? HpColors.textMuted : HpColors.lightTextSecondary,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: isLive
                  ? accent
                  : (isDark
                      ? HpColors.textSecondary
                      : HpColors.lightTextSecondary),
              fontWeight: isLive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
