import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../controllers/home_controller.dart';
import '../helpers/my_dialogs.dart';
import '../helpers/pref.dart';
import '../screens/advanced_settings_screen.dart';
import '../screens/network_test_screen.dart';
import '../services/vpn_engine.dart';
import '../services/vpn_gateway_proxy_service.dart';
import '../theme/app_theme.dart';
import 'norange_logo.dart';

/// Interactive, draggable, expandable NOrange Floating Widget ("NOrange Pod").
/// Provides:
/// 1. Live connection status & full telemetry (VPN, Proxy, Gateway, Wi-Fi Router)
///    with 1-tap Ligar/Desligar, Trocar Servidor/Modo, and Detalhes.
/// 2. Instant Virtual Camera Studio inside the widget: pick photo on the spot,
///    move (left/right/up/down), zoom/stretch (horizontal/vertical), rotate & flip.
/// 3. Mutual exclusion conflict validation across all network modes.
class NOrangeFloatingWidget extends StatefulWidget {
  final HomeController controller;

  const NOrangeFloatingWidget({
    super.key,
    required this.controller,
  });

  @override
  State<NOrangeFloatingWidget> createState() => _NOrangeFloatingWidgetState();
}

class _NOrangeFloatingWidgetState extends State<NOrangeFloatingWidget>
    with WidgetsBindingObserver {
  static double _savedRight = 14.0;
  static double _savedBottom = 100.0;

  bool _isExpanded = false;
  bool _isPressed = false;
  bool _nativeOverlayRunning = false;
  bool _mockGpsActive = false;
  bool _showFullDetails = true;
  bool _showVcamControls = false;

  // Virtual Camera state & real-time transform parameters
  bool _vcamEnabled = Pref.virtualCameraEnabled;
  String _vcamPath = Pref.virtualCameraImagePath;
  double _scaleX = Pref.vcamScaleX;
  double _scaleY = Pref.vcamScaleY;
  double _offsetX = Pref.vcamOffsetX;
  double _offsetY = Pref.vcamOffsetY;
  double _rotation = Pref.vcamRotation;
  bool _flipH = Pref.vcamFlipH;
  bool _flipV = Pref.vcamFlipV;
  int _imageVersion = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncStatus();
    }
  }

  Future<void> _syncStatus() async {
    _vcamEnabled = Pref.virtualCameraEnabled;
    _vcamPath = Pref.virtualCameraImagePath;
    _scaleX = Pref.vcamScaleX;
    _scaleY = Pref.vcamScaleY;
    _offsetX = Pref.vcamOffsetX;
    _offsetY = Pref.vcamOffsetY;
    _rotation = Pref.vcamRotation;
    _flipH = Pref.vcamFlipH;
    _flipV = Pref.vcamFlipV;

    if (Platform.isAndroid) {
      final running = await VpnEngine.isFloatingWidgetRunning();
      if (mounted) {
        setState(() => _nativeOverlayRunning = running);
      }
    }
  }

  Future<void> _applyVcamTransform() async {
    Pref.vcamScaleX = _scaleX;
    Pref.vcamScaleY = _scaleY;
    Pref.vcamOffsetX = _offsetX;
    Pref.vcamOffsetY = _offsetY;
    Pref.vcamRotation = _rotation;
    Pref.vcamFlipH = _flipH;
    Pref.vcamFlipV = _flipV;

    final updatedPath = await VpnEngine.transformVirtualCameraImage(
      scaleX: _scaleX,
      scaleY: _scaleY,
      offsetX: _offsetX,
      offsetY: _offsetY,
      rotation: _rotation,
      flipH: _flipH,
      flipV: _flipV,
    );
    if (updatedPath != null && updatedPath.isNotEmpty && mounted) {
      setState(() {
        _vcamPath = updatedPath;
        _imageVersion++;
      });
    }
  }

  Future<void> _pickVcamPhotoNow() async {
    HapticFeedback.mediumImpact();
    final path = await VpnEngine.pickVirtualCameraImage();
    if (path != null && path.isNotEmpty) {
      Pref.virtualCameraImagePath = path;
      Pref.virtualCameraEnabled = true;
      await VpnEngine.setVirtualCameraEnabled(true);
      setState(() {
        _vcamPath = path;
        _vcamEnabled = true;
        _showVcamControls = true;
        _imageVersion++;
      });
      await _applyVcamTransform();
      MyDialogs.success(
        msg: 'Imagem definida na Câmera Virtualizada! Use os controles para ajustar.',
      );
    }
  }

  void _resetVcamTransform() {
    HapticFeedback.selectionClick();
    setState(() {
      _scaleX = 1.0;
      _scaleY = 1.0;
      _offsetX = 0.0;
      _offsetY = 0.0;
      _rotation = 0.0;
      _flipH = false;
      _flipV = false;
    });
    _applyVcamTransform();
  }

  @override
  Widget build(BuildContext context) {
    if (_nativeOverlayRunning || !Pref.floatingWidgetEnabled) {
      return const SizedBox.shrink();
    }

    final media = MediaQuery.of(context);
    final size = media.size;
    final disableAnimations = media.disableAnimations;
    final animDuration = disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 200);

    final minRight = 10.0;
    final maxRight =
        (size.width - (_isExpanded ? 316.0 : 148.0)).clamp(10.0, size.width - 10.0);
    final minBottom = 90.0;
    final maxBottom =
        (size.height - media.padding.top - (_isExpanded ? 490.0 : 140.0))
            .clamp(90.0, size.height - 90.0);

    final effectiveRight =
        _isExpanded ? 12.0 : _savedRight.clamp(minRight, maxRight);
    final effectiveBottom = _savedBottom.clamp(minBottom, maxBottom);

    return Positioned(
      right: effectiveRight,
      bottom: effectiveBottom,
      child: RepaintBoundary(
        child: Obx(() {
          final nativeRunning =
              VpnEngine.isNativeFloatingWidgetRunning.value ||
              _nativeOverlayRunning;
          if (nativeRunning && !_isExpanded) {
            return const SizedBox.shrink(
              key: ValueKey('norange_pod_hidden_for_native'),
            );
          }

          final vpnConnected =
              widget.controller.vpnState.value == VpnEngine.vpnConnected;
          final gatewayRunning =
              VpnGatewayProxyService.instance.isRunning.value;
          final proxyActive =
              widget.controller.activeProxyIdRx.value.isNotEmpty;
          final anyNetworkActive =
              vpnConnected || gatewayRunning || proxyActive;
          final splitCount = Pref.allowedAppPackages.length;
          final anyTacticalActive = anyNetworkActive ||
              _nativeOverlayRunning ||
              _mockGpsActive ||
              _vcamEnabled ||
              splitCount > 0;

          return AnimatedSwitcher(
            duration: animDuration,
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: _isExpanded
                ? _buildExpandedPod(
                    context: context,
                    size: size,
                    vpnConnected: vpnConnected,
                    gatewayRunning: gatewayRunning,
                    proxyActive: proxyActive,
                    anyNetworkActive: anyNetworkActive,
                    splitCount: splitCount,
                  )
                : _buildCollapsedPill(
                    context: context,
                    size: size,
                    minBottom: minBottom,
                    maxBottom: maxBottom,
                    anyTacticalActive: anyTacticalActive,
                    anyNetworkActive: anyNetworkActive,
                    animDuration: animDuration,
                  ),
          );
        }),
      ),
    );
  }

  Widget _buildCollapsedPill({
    required BuildContext context,
    required Size size,
    required double minBottom,
    required double maxBottom,
    required bool anyTacticalActive,
    required bool anyNetworkActive,
    required Duration animDuration,
  }) {
    final modeBadge = widget.controller.vpnState.value == VpnEngine.vpnConnected
        ? 'VPN ON'
        : (VpnGatewayProxyService.instance.isRunning.value
            ? 'GATEWAY'
            : (widget.controller.activeProxyIdRx.value.isNotEmpty
                ? 'PROXY'
                : 'NOrange'));

    return GestureDetector(
      key: const ValueKey('norange_pill_collapsed'),
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapCancel: () => setState(() => _isPressed = false),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        HapticFeedback.selectionClick();
        _syncStatus();
        setState(() => _isExpanded = true);
      },
      onPanUpdate: (details) {
        setState(() {
          _savedRight = (_savedRight - details.delta.dx)
              .clamp(10.0, (size.width - 148.0).clamp(10.0, size.width));
          _savedBottom =
              (_savedBottom - details.delta.dy).clamp(minBottom, maxBottom);
        });
      },
      onPanEnd: (_) {
        setState(() {
          final midX = (size.width - 134.0) / 2;
          _savedRight = _savedRight > midX
              ? (size.width - 144.0).clamp(10.0, size.width)
              : 12.0;
        });
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration: animDuration,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7.5),
          decoration: BoxDecoration(
            color: const Color(0xF50A0B0F),
            borderRadius: BorderRadius.circular(HpRadius.pill),
            border: Border.all(
              color: anyTacticalActive
                  ? HpColors.accentOrange
                  : HpColors.borderStrong,
              width: 1.4,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x99000000),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const NOrangeLogo(
                size: 22,
                showContainer: false,
              ),
              const SizedBox(width: 7),
              Text(
                modeBadge,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: HpColors.textPrimary,
                ),
              ),
              const SizedBox(width: 7),
              Container(
                width: 7.5,
                height: 7.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: anyNetworkActive
                      ? HpColors.accentOrange
                      : (anyTacticalActive
                          ? HpColors.accentAmber
                          : HpColors.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedPod({
    required BuildContext context,
    required Size size,
    required bool vpnConnected,
    required bool gatewayRunning,
    required bool proxyActive,
    required bool anyNetworkActive,
    required int splitCount,
  }) {
    final maxPodHeight = (size.height * 0.68).clamp(320.0, 520.0);

    return Container(
      key: const ValueKey('norange_pod_expanded'),
      width: 304,
      constraints: BoxConstraints(maxHeight: maxPodHeight),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFA090A0E),
        borderRadius: BorderRadius.circular(HpRadius.lg),
        border: Border.all(
          color: HpColors.accentOrange.withOpacity(0.65),
          width: 1.3,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0xCC000000),
            blurRadius: 26,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              const NOrangeLogo(size: 24, showContainer: false),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NOrange Pod • Central Tática',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: HpColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Conexão, Diagnóstico & Câmera Virtual',
                      style: TextStyle(
                        fontSize: 10,
                        color: HpColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _isExpanded = false);
                },
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: HpColors.textSecondary,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. LIVE CONNECTION STATUS & QUICK CONTROLS (LIGAR / DESLIGAR / TROCAR / DETALHES)
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: const Color(0xFF12141B),
                      borderRadius: BorderRadius.circular(HpRadius.md),
                      border: Border.all(
                        color: anyNetworkActive
                            ? HpColors.accentOrange.withOpacity(0.55)
                            : HpColors.borderSubtle,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: anyNetworkActive
                                    ? HpColors.accentOrange
                                    : HpColors.textMuted,
                              ),
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                widget.controller.currentActiveModeTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: HpColors.textPrimary,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () => setState(
                                  () => _showFullDetails = !_showFullDetails),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                                child: Text(
                                  _showFullDetails ? 'Ocultar' : 'Detalhes',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: HpColors.accentOrange,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_showFullDetails) ...[
                          const SizedBox(height: 6),
                          Text(
                            widget.controller.currentConnectionFullDetails,
                            style: HpTextStyles.mono.copyWith(
                              fontSize: 10,
                              height: 1.38,
                              color: HpColors.textSecondary,
                            ),
                          ),
                        ],
                        const SizedBox(height: 9),
                        Row(
                          children: [
                            Expanded(
                              child: _MiniPodButton(
                                icon: anyNetworkActive
                                    ? Icons.power_settings_new_rounded
                                    : Icons.play_arrow_rounded,
                                label: anyNetworkActive ? 'Desligar' : 'Ligar',
                                primary: true,
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  widget.controller
                                      .toggleActiveNetworkModeFromNotification();
                                },
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _MiniPodButton(
                                icon: Icons.swap_horiz_rounded,
                                label: 'Trocar',
                                primary: false,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  widget.controller.switchServerOrModeQuickly();
                                },
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _MiniPodButton(
                                icon: Icons.analytics_outlined,
                                label: 'Diagnóstico',
                                primary: false,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _isExpanded = false);
                                  Get.to(() => const NetworkTestScreen());
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 2. VIRTUAL CAMERA LIVE IMAGE STUDIO (ATIVAR/DESATIVAR + DEFINIR FOTO NA HORA + MOVER/ALARGAR/GIRAR)
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: _vcamEnabled
                          ? HpColors.accentOrange.withOpacity(0.11)
                          : const Color(0xFF13151C),
                      borderRadius: BorderRadius.circular(HpRadius.md),
                      border: Border.all(
                        color: _vcamEnabled
                            ? HpColors.accentOrange.withOpacity(0.65)
                            : HpColors.borderSubtle,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.cameraswitch_outlined,
                              size: 17,
                              color: _vcamEnabled
                                  ? HpColors.accentOrange
                                  : HpColors.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() =>
                                    _showVcamControls = !_showVcamControls),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Virtualização de Imagem (Câmera)',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                        color: HpColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      _vcamPath.isEmpty
                                          ? 'Toque para definir foto na hora e ajustar'
                                          : (_vcamEnabled
                                              ? 'ATIVA • Toque para mover/alargar/girar'
                                              : 'Inativa • Foto carregada pronta'),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: HpColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 26,
                              child: Switch(
                                value: _vcamEnabled,
                                onChanged: (val) async {
                                  HapticFeedback.selectionClick();
                                  if (val && _vcamPath.isEmpty) {
                                    await _pickVcamPhotoNow();
                                    return;
                                  }
                                  Pref.virtualCameraEnabled = val;
                                  await VpnEngine.setVirtualCameraEnabled(val);
                                  setState(() {
                                    _vcamEnabled = val;
                                    if (val) _showVcamControls = true;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _MiniPodButton(
                                icon: Icons.add_photo_alternate_outlined,
                                label: _vcamPath.isEmpty
                                    ? 'Definir Imagem Agora'
                                    : 'Trocar Imagem',
                                primary: _vcamPath.isEmpty,
                                onTap: _pickVcamPhotoNow,
                              ),
                            ),
                            const SizedBox(width: 6),
                            _MiniPodButton(
                              icon: _showVcamControls
                                  ? Icons.expand_less_rounded
                                  : Icons.tune_rounded,
                              label: _showVcamControls ? 'Fechar Ajuste' : 'Ajustar',
                              primary: false,
                              onTap: () => setState(
                                  () => _showVcamControls = !_showVcamControls),
                            ),
                          ],
                        ),

                        // Interactive Image Transform Controls (Move Left/Right/Up/Down, Zoom, Stretch H/V, Flip/Rotate)
                        if (_showVcamControls) ...[
                          const SizedBox(height: 10),
                          if (_vcamPath.isNotEmpty &&
                              File(_vcamPath).existsSync())
                            GestureDetector(
                              onPanUpdate: (details) {
                                setState(() {
                                  _offsetX = (_offsetX + details.delta.dx / 120)
                                      .clamp(-1.0, 1.0);
                                  _offsetY = (_offsetY + details.delta.dy / 120)
                                      .clamp(-1.0, 1.0);
                                });
                              },
                              onPanEnd: (_) => _applyVcamTransform(),
                              child: Container(
                                height: 118,
                                width: double.infinity,
                                clipBehavior: Clip.hardEdge,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF060608),
                                  borderRadius:
                                      BorderRadius.circular(HpRadius.sm),
                                  border:
                                      Border.all(color: HpColors.borderStrong),
                                ),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.file(
                                      File(_vcamPath),
                                      key: ValueKey('vcam_$_imageVersion'),
                                      fit: BoxFit.contain,
                                    ),
                                    Positioned(
                                      left: 6,
                                      bottom: 5,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xCC08090C),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.open_with_rounded,
                                              size: 10,
                                              color: HpColors.accentOrange,
                                            ),
                                            SizedBox(width: 3),
                                            Text(
                                              'Arraste ou use os ícones abaixo',
                                              style: TextStyle(
                                                fontSize: 8.5,
                                                fontWeight: FontWeight.w700,
                                                color: HpColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            Container(
                              height: 64,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFF08090C),
                                borderRadius:
                                    BorderRadius.circular(HpRadius.sm),
                                border:
                                    Border.all(color: HpColors.borderSubtle),
                              ),
                              child: const Text(
                                'Selecione uma foto acima para visualizar e transformar',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: HpColors.textMuted,
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),
                          const Text(
                            'MOVER (ESQUERDA / DIREITA / CIMA / BAIXO):',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: HpColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: _TransformChip(
                                  icon: Icons.arrow_back_rounded,
                                  label: 'Esq',
                                  onTap: () {
                                    setState(() => _offsetX =
                                        (_offsetX - 0.10).clamp(-1.0, 1.0));
                                    _applyVcamTransform();
                                  },
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: _TransformChip(
                                  icon: Icons.arrow_forward_rounded,
                                  label: 'Dir',
                                  onTap: () {
                                    setState(() => _offsetX =
                                        (_offsetX + 0.10).clamp(-1.0, 1.0));
                                    _applyVcamTransform();
                                  },
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: _TransformChip(
                                  icon: Icons.arrow_upward_rounded,
                                  label: 'Cima',
                                  onTap: () {
                                    setState(() => _offsetY =
                                        (_offsetY - 0.10).clamp(-1.0, 1.0));
                                    _applyVcamTransform();
                                  },
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: _TransformChip(
                                  icon: Icons.arrow_downward_rounded,
                                  label: 'Baixo',
                                  onTap: () {
                                    setState(() => _offsetY =
                                        (_offsetY + 0.10).clamp(-1.0, 1.0));
                                    _applyVcamTransform();
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'AUMENTAR / ALARGAR (LADOS & ALTURA):',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: HpColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: _TransformChip(
                                  icon: Icons.zoom_in_rounded,
                                  label: 'Zoom +',
                                  onTap: () {
                                    setState(() {
                                      _scaleX =
                                          (_scaleX + 0.15).clamp(0.4, 3.0);
                                      _scaleY =
                                          (_scaleY + 0.15).clamp(0.4, 3.0);
                                    });
                                    _applyVcamTransform();
                                  },
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: _TransformChip(
                                  icon: Icons.zoom_out_rounded,
                                  label: 'Zoom -',
                                  onTap: () {
                                    setState(() {
                                      _scaleX =
                                          (_scaleX - 0.15).clamp(0.4, 3.0);
                                      _scaleY =
                                          (_scaleY - 0.15).clamp(0.4, 3.0);
                                    });
                                    _applyVcamTransform();
                                  },
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: _TransformChip(
                                  icon: Icons.swap_horiz_rounded,
                                  label: 'Alarg H',
                                  onTap: () {
                                    setState(() => _scaleX =
                                        (_scaleX + 0.18).clamp(0.4, 3.0));
                                    _applyVcamTransform();
                                  },
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: _TransformChip(
                                  icon: Icons.swap_vert_rounded,
                                  label: 'Alarg V',
                                  onTap: () {
                                    setState(() => _scaleY =
                                        (_scaleY + 0.18).clamp(0.4, 3.0));
                                    _applyVcamTransform();
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'VIRAR / ROTACIONAR / ESPELHAR:',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: HpColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: _TransformChip(
                                  icon: Icons.rotate_right_rounded,
                                  label: '90°',
                                  onTap: () {
                                    setState(() =>
                                        _rotation = (_rotation + 90) % 360);
                                    _applyVcamTransform();
                                  },
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: _TransformChip(
                                  icon: Icons.flip_rounded,
                                  label: 'Esp H',
                                  active: _flipH,
                                  onTap: () {
                                    setState(() => _flipH = !_flipH);
                                    _applyVcamTransform();
                                  },
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: _TransformChip(
                                  icon: Icons.flip_camera_android_rounded,
                                  label: 'Esp V',
                                  active: _flipV,
                                  onTap: () {
                                    setState(() => _flipV = !_flipV);
                                    _applyVcamTransform();
                                  },
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: _TransformChip(
                                  icon: Icons.restart_alt_rounded,
                                  label: 'Reset',
                                  onTap: _resetVcamTransform,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // 3. NATIVE OVERLAY & MOCK GPS QUICK ACTIONS
                  if (Platform.isAndroid)
                    _PodActionTile(
                      icon: Icons.layers_outlined,
                      title: 'Flutuar Sobre Outros Apps',
                      subtitle: _nativeOverlayRunning
                          ? 'Bolha nativa NOrange ativa'
                          : 'Ativar sobreposição do sistema',
                      active: _nativeOverlayRunning,
                      onTap: () async {
                        HapticFeedback.mediumImpact();
                        if (_nativeOverlayRunning) {
                          Pref.floatingWidgetEnabled = false;
                          await VpnEngine.stopFloatingWidget();
                          if (mounted) {
                            setState(() => _nativeOverlayRunning = false);
                          }
                        } else {
                          Pref.floatingWidgetEnabled = true;
                          final ok = await VpnEngine.startFloatingWidget();
                          if (mounted) {
                            setState(() => _nativeOverlayRunning = ok);
                          }
                        }
                      },
                    ),

                  _PodActionTile(
                    icon: Icons.my_location_rounded,
                    title: 'GPS Virtual Padrão',
                    subtitle: _mockGpsActive
                        ? 'Ativo (${Pref.mockLat.toStringAsFixed(2)}, ${Pref.mockLon.toStringAsFixed(2)})'
                        : 'Injetar coordenada padrão',
                    active: _mockGpsActive,
                    onTap: () async {
                      HapticFeedback.mediumImpact();
                      if (_mockGpsActive) {
                        await VpnEngine.stopMockGps();
                        if (mounted) setState(() => _mockGpsActive = false);
                      } else {
                        final ok = await VpnEngine.startMockGps(
                          Pref.mockLat,
                          Pref.mockLon,
                        );
                        if (mounted) setState(() => _mockGpsActive = ok);
                        if (ok) {
                          MyDialogs.success(
                            msg:
                                'GPS Virtual NOrange ativado em (${Pref.mockLat.toStringAsFixed(4)}, ${Pref.mockLon.toStringAsFixed(4)})',
                          );
                        }
                      }
                    },
                  ),

                  _PodActionTile(
                    icon: Icons.app_registration_rounded,
                    title: 'Central Avançada & Split VPN',
                    subtitle: splitCount > 0
                        ? '$splitCount app(s) isolado(s) • Abrir Central'
                        : 'Gateway VPN, Proxy, Roteador & Apps',
                    active: splitCount > 0,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _isExpanded = false);
                      Get.to(
                          () => const AdvancedSettingsScreen(initialTabIndex: 4));
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniPodButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool primary;
  final VoidCallback onTap;

  const _MiniPodButton({
    required this.icon,
    required this.label,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(HpRadius.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6.5),
        decoration: BoxDecoration(
          color: primary ? HpColors.accentOrange : const Color(0xFF1A1D26),
          borderRadius: BorderRadius.circular(HpRadius.sm),
          border: primary ? null : Border.all(color: HpColors.borderStrong),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13.5,
              color: primary ? const Color(0xFF08090C) : HpColors.textPrimary,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color:
                      primary ? const Color(0xFF08090C) : HpColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransformChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TransformChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = active ? HpColors.accentOrange : HpColors.textPrimary;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5.5, horizontal: 3),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active
              ? HpColors.accentOrange.withOpacity(0.22)
              : const Color(0xFF1A1D26),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: active ? HpColors.accentOrange : HpColors.borderSubtle,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 11.5, color: HpColors.accentOrange),
            const SizedBox(width: 2.5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9.0,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PodActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool active;
  final VoidCallback onTap;

  const _PodActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HpRadius.sm),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: active
                ? HpColors.accentOrange.withOpacity(0.14)
                : const Color(0xFF13151C),
            borderRadius: BorderRadius.circular(HpRadius.sm),
            border: Border.all(
              color: active
                  ? HpColors.accentOrange.withOpacity(0.65)
                  : HpColors.borderSubtle,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 17,
                color: active ? HpColors.accentOrange : HpColors.textSecondary,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: HpColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: HpColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color:
                      active ? HpColors.accentOrange : const Color(0xFF1D202A),
                  borderRadius: BorderRadius.circular(HpRadius.pill),
                ),
                child: Text(
                  active ? 'ON' : 'OFF',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: active
                        ? const Color(0xFF08090C)
                        : HpColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
