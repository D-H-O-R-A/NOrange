import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../theme/app_theme.dart';

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
      borderColor: HpColors.accentEmerald.withOpacity(0.45),
      borderWidth: 1,
      colorText: HpColors.textPrimary,
      icon: const Icon(
        Icons.verified_rounded,
        color: HpColors.accentEmerald,
        size: 22,
      ),
      titleText: const Text(
        'PROTOCOLO ATUALIZADO',
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: HpColors.accentEmerald,
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
        'TELEMETRIA HIDE PROTOCOL',
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
              color: HpColors.accentEmerald,
            ),
          ),
        ),
      ),
      barrierColor: Colors.black54,
    );
  }
}
