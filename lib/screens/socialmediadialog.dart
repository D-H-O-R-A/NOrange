import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';
import '../widgets/hide_protocol_logo.dart';

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
                const HideProtocolLogo(size: 46),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HIDE // PROTOCOL',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Tactical Privacy & Network Suite • v1.0',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: HpColors.textSecondary,
                        ),
                      ),
                    ],
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
              'Arquitetura avançada de tunelamento OpenVPN, Gateway compartilhável, Proxy HTTP/SOCKS5, Radar de Ondas Wi-Fi e isolamento por aplicativo.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: HpColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'CANAIS OFICIAIS & ECOSSISTEMA',
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
                    label: 'Telegram',
                    imageAsset: 'assets/images/telegram.png',
                    onTap: () => _openUrl('https://t.me/hideprotocol'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ChannelTile(
                    label: 'X / Twitter',
                    imageAsset: 'assets/images/x.png',
                    onTap: () => _openUrl('https://x.com/HideProtocol'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ChannelTile(
                    label: 'Website',
                    imageAsset: 'assets/images/website.png',
                    onTap: () => _openUrl('https://hideprotocol.com/'),
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
  final String imageAsset;
  final VoidCallback onTap;

  const _ChannelTile({
    required this.label,
    required this.imageAsset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(HpRadius.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? HpColors.bgSurface : HpColors.lightSurface,
          borderRadius: BorderRadius.circular(HpRadius.sm),
          border: Border.all(
            color: isDark ? HpColors.borderSubtle : HpColors.lightBorder,
          ),
        ),
        child: Column(
          children: [
            Image.asset(
              imageAsset,
              width: 26,
              height: 26,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
