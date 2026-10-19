import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../theme/app_theme.dart';

class WatchAdDialog extends StatelessWidget {
  final VoidCallback onComplete;

  const WatchAdDialog({super.key, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: isDark ? HpColors.bgElevated : HpColors.lightElevated,
          borderRadius: BorderRadius.circular(HpRadius.lg),
          border: Border.all(
            color: isDark ? HpColors.borderStrong : HpColors.lightBorder,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                HpIconBox(
                  icon: Icons.palette_outlined,
                  color: HpColors.accentEmerald,
                  size: 38,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Change Theme',
                    style: HpTextStyles.cardTitle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Watch an Ad to Change App Theme.',
              style: TextStyle(
                fontSize: 13.5,
                color: isDark
                    ? HpColors.textSecondary
                    : HpColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    Get.back();
                    onComplete();
                  },
                  child: const Text('Watch Ad'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
