import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../helpers/my_dialogs.dart';
import '../models/network_data.dart';
import '../theme/app_theme.dart';

class NetworkCard extends StatelessWidget {
  final NetworkData data;

  const NetworkCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = data.icon.color ?? HpColors.accentCyan;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: HpSurface(
        onTap: data.subtitle.isNotEmpty
            ? () {
                Clipboard.setData(ClipboardData(text: data.subtitle));
                MyDialogs.info(msg: '${data.title} copiado: ${data.subtitle}');
              }
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        borderRadius: HpRadius.md,
        child: Row(
          children: [
            HpIconBox(
              icon: data.icon.icon ?? Icons.info_outline_rounded,
              color: iconColor,
              size: 42,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: isDark
                          ? HpColors.textMuted
                          : HpColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.subtitle.isEmpty ? 'Sincronizando...' : data.subtitle,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.copy_rounded,
              size: 16,
              color: isDark ? HpColors.textMuted : HpColors.lightTextSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
