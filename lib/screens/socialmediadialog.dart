import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';
import '../widgets/norange_logo.dart';

class SocialMediaDialog extends StatelessWidget {
  const SocialMediaDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? HpColors.bgElevated : HpColors.lightElevated,
          borderRadius: BorderRadius.circular(HpRadius.xl),
          border: Border.all(
            color: isDark ? HpColors.borderStrong : HpColors.lightBorder,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.55),
              blurRadius: 32,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const NOrangeLogo(size: 46),
                const SizedBox(width: 14),
                const Expanded(
                  child: NOrangeWordmark(
                    fontSize: 18,
                    subtitle: 'Tactical Privacy & Network Suite • v1.0',
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: HpColors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'Arquitetura avançada de tunelamento OpenVPN, Gateway compartilhável, Proxy HTTP/SOCKS5, Radar de Ondas Wi-Fi, Detector Anti-Spyware WebSocket e Câmera Virtualizada em tempo real.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: HpColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? HpColors.bgSurface : HpColors.lightSurface,
                borderRadius: BorderRadius.circular(HpRadius.md),
                border: Border.all(
                  color: HpColors.accentOrange.withOpacity(0.45),
                ),
              ),
              child: Row(
                children: [
                  const HpIconBox(
                    icon: Icons.verified_rounded,
                    color: HpColors.accentOrange,
                    size: 38,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DESENVOLVIDO POR',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: HpColors.accentOrange,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Diego Oris',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'diegooris.ch • Principal Software & Security Engineer',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark
                                ? HpColors.textSecondary
                                : HpColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'WEBSITE OFICIAL & LINKEDIN DO AUTOR',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.3,
                color: HpColors.textMuted,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ChannelTile(
                    label: 'diegooris.ch',
                    subtitle: 'Website Oficial',
                    icon: Icons.language_rounded,
                    accentColor: HpColors.accentOrange,
                    onTap: () => _openUrl('https://diegooris.ch'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ChannelTile(
                    label: 'Diego Oris',
                    subtitle: 'LinkedIn Oficial',
                    icon: Icons.work_outline_rounded,
                    accentColor: HpColors.accentCyan,
                    onTap: () =>
                        _openUrl('https://br.linkedin.com/in/diegoorisderoa'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    HapticFeedback.selectionClick();
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _ChannelTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const _ChannelTile({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(HpRadius.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: isDark ? HpColors.bgSurface : HpColors.lightSurface,
          borderRadius: BorderRadius.circular(HpRadius.sm),
          border: Border.all(
            color: accentColor.withOpacity(0.38),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 26,
              color: accentColor,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.5,
                color: HpColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
