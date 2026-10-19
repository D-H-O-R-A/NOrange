import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../services/vpn_engine.dart';
import '../theme/app_theme.dart';
import '../widgets/norange_logo.dart';

class MyDialogs {
  static void success({required String msg}) {
    HapticFeedback.lightImpact();
    Get.snackbar(
      'OPERAÇÃO CONCLUÍDA',
      msg,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderRadius: HpRadius.md,
      backgroundColor: HpColors.bgElevated.withOpacity(0.96),
      borderColor: HpColors.accentOrange.withOpacity(0.55),
      borderWidth: 1,
      colorText: HpColors.textPrimary,
      icon: const Icon(
        Icons.verified_rounded,
        color: HpColors.accentOrange,
        size: 22,
      ),
      titleText: const Text(
        'PROTOCOLO ATUALIZADO',
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: HpColors.accentOrange,
        ),
      ),
      messageText: Text(
        msg,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: HpColors.textPrimary,
        ),
      ),
      duration: const Duration(seconds: 3),
    );
  }

  static void error({required String msg}) {
    HapticFeedback.mediumImpact();
    Get.snackbar(
      'ALERTA DO SISTEMA',
      msg,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderRadius: HpRadius.md,
      backgroundColor: HpColors.bgElevated.withOpacity(0.96),
      borderColor: HpColors.accentCrimson.withOpacity(0.55),
      borderWidth: 1,
      colorText: HpColors.textPrimary,
      icon: const Icon(
        Icons.error_outline_rounded,
        color: HpColors.accentCrimson,
        size: 22,
      ),
      titleText: const Text(
        'FALHA DE EXECUÇÃO',
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: HpColors.accentCrimson,
        ),
      ),
      messageText: Text(
        msg,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: HpColors.textPrimary,
        ),
      ),
      duration: const Duration(seconds: 3),
    );
  }

  static void info({required String msg}) {
    HapticFeedback.selectionClick();
    Get.snackbar(
      'STATUS DE REDE',
      msg,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderRadius: HpRadius.md,
      backgroundColor: HpColors.bgElevated.withOpacity(0.96),
      borderColor: HpColors.accentCyan.withOpacity(0.45),
      borderWidth: 1,
      colorText: HpColors.textPrimary,
      icon: const Icon(
        Icons.radar_rounded,
        color: HpColors.accentCyan,
        size: 22,
      ),
      titleText: const Text(
        'TELEMETRIA NORANGE',
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: HpColors.accentCyan,
        ),
      ),
      messageText: Text(
        msg,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: HpColors.textPrimary,
        ),
      ),
      duration: const Duration(seconds: 3),
    );
  }

  /// Displays an explanatory conflict popup when the user attempts to activate
  /// two mutually exclusive network modes simultaneously.
  /// Returns `true` if the user chooses to automatically stop the conflicting
  /// mode and proceed, or `false` if they choose to keep the current mode.
  static Future<bool> showConflictPopup({
    required String conflictTitle,
    required String activeModeName,
    required String targetModeName,
    required String technicalExplanation,
    VoidCallback? onResolveConflict,
  }) async {
    HapticFeedback.heavyImpact();
    final res = await Get.dialog<bool>(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: HpColors.bgElevated,
            borderRadius: BorderRadius.circular(HpRadius.xl),
            border: Border.all(
              color: HpColors.accentOrange.withOpacity(0.65),
              width: 1.4,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0xBB000000),
                blurRadius: 28,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const NOrangeLogo(size: 38),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CONFLITO DE REDE DETECTADO',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.3,
                            color: HpColors.accentOrange,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          conflictTitle,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: HpColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: HpColors.bgSurface,
                  borderRadius: BorderRadius.circular(HpRadius.md),
                  border: Border.all(color: HpColors.borderSubtle),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.radio_button_checked_rounded,
                          size: 15,
                          color: HpColors.accentOrange,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Ativo agora: ',
                          style: TextStyle(
                            fontSize: 12,
                            color: HpColors.textSecondary,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            activeModeName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: HpColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.block_rounded,
                          size: 15,
                          color: HpColors.accentCrimson,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Tentativa: ',
                          style: TextStyle(
                            fontSize: 12,
                            color: HpColors.textSecondary,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            targetModeName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: HpColors.accentAmber,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'MOTIVO TÉCNICO:',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: HpColors.textMuted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                technicalExplanation,
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.45,
                  color: HpColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              if (onResolveConflict != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      Get.back(result: true);
                      onResolveConflict();
                    },
                    icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                    label: Text('Desligar $activeModeName e Ativar'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Get.back(result: false),
                  child: const Text('Manter Conexão Atual (Cancelar)'),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
    return res == true;
  }

  /// Displays an interactive security and responsibility modal explaining the real
  /// risks when turning the user's phone into a VPN Hotspot or public/local Proxy server.
  /// Requires explicit user checkbox consent before proceeding.
  static Future<bool> showServerSharingRiskWarning({
    required String modeTitle,
    required String modeDescription,
    required String portInfo,
    bool hasAuth = false,
  }) async {
    HapticFeedback.heavyImpact();
    final acceptedRisk = false.obs;

    final res = await Get.dialog<bool>(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 480,
            maxHeight: MediaQuery.of(Get.context!).size.height * 0.86,
          ),
          decoration: BoxDecoration(
            color: HpColors.bgElevated,
            borderRadius: BorderRadius.circular(HpRadius.xl),
            border: Border.all(
              color: HpColors.accentOrange.withOpacity(0.65),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pinned Warning Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: HpColors.accentOrange.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: HpColors.accentOrange.withOpacity(0.4),
                        ),
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        color: HpColors.accentOrange,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AVISO DE SEGURANÇA & RISCOS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              color: HpColors.accentOrange,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            modeTitle,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: HpColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Scrollable Risks Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        modeDescription,
                        style: const TextStyle(
                          fontSize: 13,
                          color: HpColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Critical Risks List
                      _buildRiskItem(
                        icon: Icons.public_rounded,
                        color: HpColors.accentCrimson,
                        title: 'Responsabilidade Legal pelo IP Público',
                        description:
                            'Todo o tráfego gerado por clientes conectados sairá pelo seu endereço IP e operadora. Qualquer requisição ou download feito por terceiros constará sob sua autoria perante provedores e autoridades.',
                      ),
                      const SizedBox(height: 10),
                      _buildRiskItem(
                        icon: Icons.data_usage_rounded,
                        color: HpColors.accentAmber,
                        title: 'Consumo de Franquia & Bateria',
                        description:
                            'Aparelhos conectados consumirão a franquia de dados do seu plano de celular e Wi-Fi, gerando aquecimento e drenagem acelerada da bateria.',
                      ),
                      const SizedBox(height: 10),
                      _buildRiskItem(
                        icon: hasAuth
                            ? Icons.lock_outline_rounded
                            : Icons.lock_open_rounded,
                        color: hasAuth
                            ? HpColors.accentEmerald
                            : HpColors.accentCrimson,
                        title: hasAuth
                            ? 'Protegido por Autenticação'
                            : 'Acesso Aberto (Sem Senha)',
                        description: hasAuth
                            ? 'Recomendado: Apenas dispositivos com usuário e senha autorizados conseguirão rotear pacotes.'
                            : 'ALERTA: Como não há senha configurada, qualquer pessoa na mesma rede ou com acesso ao IP/Porta ($portInfo) poderá navegar pelo seu celular como proxy aberto.',
                      ),
                      const SizedBox(height: 10),
                      _buildRiskItem(
                        icon: Icons.speed_rounded,
                        color: HpColors.accentCyan,
                        title: 'Sobrecarga e Latência Local',
                        description:
                            'Seu smartphone atuará como Gateway/Roteador de pacotes para múltiplos clientes, reduzindo a largura de banda e aumentando a latência dos seus próprios apps.',
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(height: 1),

              // Pinned Bottom Actions & Consent
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Consent Checkbox
                    Obx(
                      () => InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          acceptedRisk.value = !acceptedRisk.value;
                        },
                        borderRadius: BorderRadius.circular(HpRadius.sm),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: acceptedRisk.value,
                                  activeColor: HpColors.accentOrange,
                                  onChanged: (val) {
                                    HapticFeedback.selectionClick();
                                    acceptedRisk.value = val ?? false;
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Compreendo os riscos legais do meu IP, consumo de franquia e concordo em ativar.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: HpColors.textPrimary,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Action Buttons
                    Obx(
                      () => SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: acceptedRisk.value
                                ? HpColors.accentOrange
                                : HpColors.bgSurface,
                            foregroundColor: acceptedRisk.value
                                ? const Color(0xFF09090B)
                                : HpColors.textMuted,
                          ),
                          onPressed: acceptedRisk.value
                              ? () {
                                  HapticFeedback.mediumImpact();
                                  Get.back(result: true);
                                }
                              : null,
                          icon: const Icon(Icons.check_circle_outline_rounded,
                              size: 19),
                          label: const Text(
                            'CONCORDAR E ATIVAR SERVIDOR',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: TextButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Get.back(result: false);
                        },
                        child: const Text(
                          'Cancelar e Manter Desligado',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: HpColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
    return res == true;
  }

  static Widget _buildRiskItem({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(HpRadius.sm),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: HpColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static void showProgress() {
    Get.dialog(
      Center(
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: HpColors.bgElevated,
            borderRadius: BorderRadius.circular(HpRadius.lg),
            border: Border.all(color: HpColors.borderStrong),
          ),
          child: const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: HpColors.accentOrange,
            ),
          ),
        ),
      ),
      barrierColor: Colors.black54,
    );
  }

  /// Displays an interactive Connection Error Modal explaining the exact cause of failure,
  /// marking the node as [FORA DO AR], offering retry on the next available server,
  /// and providing a button to inspect real-time connection logs.
  static Future<void> showConnectionErrorModal({
    required String serverCountry,
    required String serverIp,
    required String errorMessage,
    required VoidCallback onConnectToAnother,
    required VoidCallback onViewLogs,
  }) async {
    HapticFeedback.heavyImpact();
    await Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 440),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: HpColors.bgElevated,
            borderRadius: BorderRadius.circular(HpRadius.xl),
            border: Border.all(
              color: HpColors.accentCrimson.withOpacity(0.7),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.65),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: HpColors.accentCrimson.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: HpColors.accentCrimson.withOpacity(0.4),
                      ),
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      color: HpColors.accentCrimson,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'FALHA NA CONEXÃO',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                                color: HpColors.accentCrimson,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: HpColors.accentCrimson.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'FORA DO AR',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: HpColors.accentCrimson,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$serverCountry ($serverIp)',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: HpColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Error details container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: HpColors.accentCrimson.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(HpRadius.md),
                  border: Border.all(
                    color: HpColors.accentCrimson.withOpacity(0.25),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: HpColors.accentCrimson,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        errorMessage,
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          color: HpColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              const Text(
                'Este nó foi temporariamente marcado como "Fora do Ar". Você pode alternar para outro nó público disponível ou verificar os logs.',
                style: TextStyle(
                  fontSize: 12,
                  color: HpColors.textMuted,
                  height: 1.35,
                ),
              ),

              const SizedBox(height: 20),

              // Primary Action: Connect to another server
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HpColors.accentOrange,
                    foregroundColor: const Color(0xFF09090B),
                  ),
                  onPressed: () {
                    Get.back();
                    onConnectToAnother();
                  },
                  icon: const Icon(Icons.swap_horiz_rounded, size: 20),
                  label: const Text(
                    'CONECTAR A OUTRO SERVIDOR',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Secondary Action: View Logs
              SizedBox(
                width: double.infinity,
                height: 42,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: HpColors.borderStrong),
                  ),
                  onPressed: () {
                    Get.back();
                    onViewLogs();
                  },
                  icon: const Icon(Icons.terminal_rounded, size: 18),
                  label: const Text(
                    'Ver Logs Técnicos da Conexão',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: HpColors.textSecondary,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 4),

              Center(
                child: TextButton(
                  onPressed: () => Get.back(),
                  child: const Text(
                    'Fechar',
                    style: TextStyle(
                      fontSize: 12,
                      color: HpColors.textMuted,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  /// Displays real-time OpenVPN logs in a monospace terminal modal with copy and clear actions.
  static Future<void> showVpnLogsModal(BuildContext context) async {
    HapticFeedback.selectionClick();
    final logsRx = ''.obs;
    final isLoading = true.obs;

    Future<void> fetchLogs() async {
      isLoading.value = true;
      final raw = await VpnEngine.getVpnLogs();
      logsRx.value = raw.trim().isEmpty
          ? 'Nenhum log registrado ainda. Conecte a um servidor para gerar dados.'
          : raw;
      isLoading.value = false;
    }

    fetchLogs();

    await Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 540,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF090B10),
            borderRadius: BorderRadius.circular(HpRadius.xl),
            border: Border.all(
              color: HpColors.borderStrong,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.7),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Terminal Header
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 12, 12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.terminal_rounded,
                      color: HpColors.accentOrange,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LOGS DA VPN EM TEMPO REAL',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              color: HpColors.accentOrange,
                            ),
                          ),
                          Text(
                            'OpenVPN Engine Telemetry',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Atualizar Logs',
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                      onPressed: fetchLogs,
                    ),
                    IconButton(
                      tooltip: 'Fechar',
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFF1E2330)),

              // Terminal Content
              Expanded(
                child: Obx(
                  () => isLoading.value
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: HpColors.accentOrange,
                            strokeWidth: 2,
                          ),
                        )
                      : Container(
                          width: double.infinity,
                          margin: const EdgeInsets.all(12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF030406),
                            borderRadius: BorderRadius.circular(HpRadius.md),
                            border: Border.all(color: const Color(0xFF1E2330)),
                          ),
                          child: SingleChildScrollView(
                            reverse: true,
                            child: SelectableText(
                              logsRx.value,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11.5,
                                height: 1.45,
                                color: Color(0xFF38BDF8),
                              ),
                            ),
                          ),
                        ),
                ),
              ),

              const Divider(height: 1, color: Color(0xFF1E2330)),

              // Terminal Footer Action Buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF2A2F3D)),
                          foregroundColor: HpColors.textSecondary,
                        ),
                        onPressed: () async {
                          await VpnEngine.clearVpnLogs();
                          fetchLogs();
                          MyDialogs.info(msg: 'Logs limpos com sucesso.');
                        },
                        icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                        label: const Text('Limpar Logs'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HpColors.accentOrange,
                          foregroundColor: const Color(0xFF09090B),
                        ),
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: logsRx.value));
                          HapticFeedback.lightImpact();
                          MyDialogs.success(
                              msg: 'Logs copiados para a área de transferência!');
                        },
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        label: const Text('Copiar Logs'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  /// Displays the full Terms of Use, Privacy Policy, and Public VPN Disclaimer modal.
  /// Clearly explains that servers are public academic nodes from VPN Gate (Tsukuba University, Japan)
  /// and warns against using for banking, personal sensitive accounts, or private data.
  static Future<void> showPublicVpnTermsAndPrivacyModal(
      BuildContext context) async {
    HapticFeedback.selectionClick();
    await Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 500,
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          decoration: BoxDecoration(
            color: HpColors.bgElevated,
            borderRadius: BorderRadius.circular(HpRadius.xl),
            border: Border.all(
              color: HpColors.accentOrange.withOpacity(0.65),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.65),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: HpColors.accentOrange.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: HpColors.accentOrange.withOpacity(0.4),
                        ),
                      ),
                      child: const Icon(
                        Icons.gavel_rounded,
                        color: HpColors.accentOrange,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TERMOS DE USO & POLÍTICA DE PRIVACIDADE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              color: HpColors.accentOrange,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Isenção de Responsabilidade VPN',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: HpColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Content Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Origin & Nature Banner
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: HpColors.accentCyan.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(HpRadius.md),
                          border: Border.all(
                            color: HpColors.accentCyan.withOpacity(0.3),
                          ),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.school_outlined,
                                color: HpColors.accentCyan, size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Origem dos Nós de VPN: Projeto Acadêmico',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: HpColors.accentCyan,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Os servidores VPN disponibilizados pelo NOrange são nós públicos originários do projeto de pesquisa acadêmica "VPN Gate Academic Experiment Project" da Universidade de Tsukuba (Japão), complementados por nós voluntários distribuídos globalmente.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: HpColors.textSecondary,
                                      height: 1.38,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Crucial Restriction: NO BANKING / NO SENSITIVE
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: HpColors.accentCrimson.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(HpRadius.md),
                          border: Border.all(
                            color: HpColors.accentCrimson.withOpacity(0.35),
                          ),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                color: HpColors.accentCrimson, size: 22),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'AVISO CRÍTICO: NÃO USE PARA DADOS SENSÍVEIS',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: HpColors.accentCrimson,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'NÃO RECOMENDAMOS o uso destas VPNs públicas para operações bancárias (Internet Banking, Pix), cartões de crédito, senhas pessoais críticas ou redes sociais privadas.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: HpColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      height: 1.38,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        '1. Ausência de Controle dos Nós de Saída',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: HpColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'A equipe NOrange NÃO é proprietária, NÃO opera e NÃO controla os servidores de saída. Cada nó é mantido por voluntários ou instituições independentes ao redor do mundo. Portanto, não garantimos segurança absoluta, criptografia contra inspeção na ponta de saída ou confidencialidade dos pacotes desemcapsulados pelo host de saída.',
                        style: TextStyle(
                          fontSize: 12,
                          color: HpColors.textSecondary,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 14),

                      const Text(
                        '2. Finalidade e Usos Recomendados',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: HpColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'As conexões VPN públicas são ideais para:\n'
                        '• Mascarar seu endereço IP contra rastreamento de sites;\n'
                        '• Contornar restrições geográficas e censura local;\n'
                        '• Testar conectividade e rotas internacionais;\n'
                        '• Navegar em sites abertos e conteúdo de streaming público.',
                        style: TextStyle(
                          fontSize: 12,
                          color: HpColors.textSecondary,
                          height: 1.45,
                        ),
                      ),

                      const SizedBox(height: 14),

                      const Text(
                        '3. Isenção Total de Garantias',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: HpColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'O serviço é fornecido "no estado em que se encontra" (AS IS). Nós públicos podem entrar ou sair do ar a qualquer momento. Ao utilizar o aplicativo, você concorda que o uso das VPNs públicas é de sua exclusiva responsabilidade.',
                        style: TextStyle(
                          fontSize: 12,
                          color: HpColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(height: 1),

              // Button
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HpColors.accentOrange,
                      foregroundColor: const Color(0xFF09090B),
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Get.back();
                    },
                    child: const Text(
                      'ENTENDI E CONCORDO',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }
}

