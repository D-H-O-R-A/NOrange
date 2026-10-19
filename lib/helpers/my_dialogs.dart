import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

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
}
