import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../controllers/home_controller.dart';
import '../controllers/location_controller.dart';
import '../models/vpn.dart';
import '../theme/app_theme.dart';

class VpnCard extends StatelessWidget {
  final Vpn vpn;
  final LocationController? locationController;

  const VpnCard({super.key, required this.vpn, this.locationController});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    final isSelected = controller.vpn.value.uniqueKey == vpn.uniqueKey;
    final pingMs = vpn.pingValue;
    final pingColor = pingMs <= 100
        ? HpColors.accentEmerald
        : (pingMs <= 240 ? HpColors.accentAmber : HpColors.accentCrimson);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: HpSurface(
        onTap: () {
          HapticFeedback.mediumImpact();
          Get.back();
          controller.switchServerAndConnect(vpn);
        },
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        borderRadius: HpRadius.md,
        borderColor: isSelected
            ? HpColors.accentEmerald.withOpacity(0.65)
            : (isDark ? HpColors.borderSubtle : HpColors.lightBorder),
        color: isSelected
            ? (isDark ? HpColors.bgSurface : HpColors.lightSurface)
            : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Country Flag with online status dot
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 40,
                  width: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? HpColors.borderStrong : HpColors.lightBorder,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: vpn.isCustom
                        ? Container(
                            color: HpColors.accentCyanDim,
                            child: const Icon(
                              Icons.vpn_lock_rounded,
                              color: HpColors.accentCyan,
                              size: 20,
                            ),
                          )
                        : Image.asset(
                            'assets/flags/${vpn.countryShort.toLowerCase()}.png',
                            height: 40,
                            width: 54,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 40,
                              width: 54,
                              color: HpColors.accentCyanDim,
                              child: const Icon(
                                CupertinoIcons.globe,
                                color: HpColors.accentCyan,
                                size: 20,
                              ),
                            ),
                          ),
                  ),
                ),
                Positioned(
                  right: -3,
                  bottom: -3,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: vpn.isVerifiedOnline
                          ? HpColors.accentEmerald
                          : HpColors.accentAmber,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            isDark ? HpColors.bgElevated : HpColors.lightElevated,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 12),

            // Country/Location, Host/IP, Total Connections, Speed & Uptime
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Country Name (Code) + Protocol:Port
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '${vpn.countryLong} (${vpn.countryShort.toUpperCase()})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: vpn.protocol == 'TCP'
                              ? HpColors.accentCyanDim
                              : HpColors.accentEmeraldDim,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          '${vpn.protocol}:${vpn.port}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                            color: vpn.protocol == 'TCP'
                                ? HpColors.accentCyan
                                : HpColors.accentEmerald,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Row 2: Hostname • IP • Operator/Location detail
                  Text(
                    '${vpn.ip} • ${vpn.hostname.isNotEmpty ? vpn.hostname : vpn.operatorName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: isDark
                          ? HpColors.textSecondary
                          : HpColors.lightTextSecondary,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Row 3: Active Connections + Total Users + Speed + Uptime
                  Wrap(
                    spacing: 10,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            CupertinoIcons.person_2_fill,
                            color: HpColors.accentEmerald,
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${vpn.numVpnSessions} conexões (${vpn.formattedTotalUsers} total)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? HpColors.textPrimary
                                  : HpColors.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.bolt_rounded,
                            color: HpColors.accentCyan,
                            size: 14,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${_formatBytes(vpn.speed, 1)} • ${vpn.formattedUptime}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? HpColors.textMuted
                                  : HpColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Ping / Latency badge & Favorite star
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: pingColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(HpRadius.sm),
                    border: Border.all(color: pingColor.withOpacity(0.32)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.sensors_rounded,
                              size: 12, color: pingColor),
                          const SizedBox(width: 4),
                          Text(
                            '${vpn.ping} ms',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: pingColor,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                        ],
                      ),
                      Text(
                        vpn.latencyLabel,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: pingColor.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                if (locationController != null)
                  InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      locationController!.toggleFavorite(vpn);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6, left: 6),
                      child: Icon(
                        locationController!.isFavorite(vpn)
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: locationController!.isFavorite(vpn)
                            ? HpColors.accentAmber
                            : HpColors.textMuted,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatBytes(int bytes, int decimals) {
    if (bytes <= 0) return '100 Mbps';
    const suffixes = ['Bps', 'Kbps', 'Mbps', 'Gbps', 'Tbps'];
    var i = (log(bytes) / log(1024)).floor();
    if (i >= suffixes.length) i = suffixes.length - 1;
    return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
  }
}
