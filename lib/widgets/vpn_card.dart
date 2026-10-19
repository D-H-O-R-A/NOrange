import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/home_controller.dart';
import '../controllers/location_controller.dart';
import '../main.dart';
import '../models/vpn.dart';

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
        ? Colors.green
        : (pingMs <= 240 ? Colors.orange : Colors.redAccent);

    return Card(
      elevation: isSelected ? 6 : 3,
      margin: EdgeInsets.symmetric(vertical: mq.height * .008),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: isSelected
            ? const BorderSide(color: Colors.blueAccent, width: 1.8)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          Get.back();
          controller.switchServerAndConnect(vpn);
        },
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Country Flag with online status dot
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(.5),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.asset(
                        'assets/flags/${vpn.countryShort.toLowerCase()}.png',
                        height: 38,
                        width: 54,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 38,
                          width: 54,
                          color: Colors.blue.withOpacity(0.15),
                          child: const Icon(CupertinoIcons.globe,
                              color: Colors.blue),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -3,
                    bottom: -3,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color:
                            vpn.isVerifiedOnline ? Colors.green : Colors.amber,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 12),

              // Country, IP, Protocol & Speed
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            vpn.countryLong,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: vpn.protocol == 'TCP'
                                ? Colors.blue.withOpacity(0.14)
                                : Colors.purple.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${vpn.protocol}:${vpn.port}',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: vpn.protocol == 'TCP'
                                  ? Colors.blue
                                  : Colors.purple,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.speed_rounded,
                            color: Colors.blue, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          _formatBytes(vpn.speed, 1),
                          style: const TextStyle(fontSize: 12.5),
                        ),
                        const SizedBox(width: 10),
                        Icon(CupertinoIcons.person_2_fill,
                            color: Colors.blueGrey.shade400, size: 14),
                        const SizedBox(width: 3),
                        Text(
                          '${vpn.numVpnSessions}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Ping badge & Favorite button
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: pingColor.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.network_cell, size: 13, color: pingColor),
                        const SizedBox(width: 3),
                        Text(
                          '${vpn.ping} ms',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: pingColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (locationController != null)
                    InkWell(
                      onTap: () => locationController!.toggleFavorite(vpn),
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6, left: 6),
                        child: Icon(
                          locationController!.isFavorite(vpn)
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: locationController!.isFavorite(vpn)
                              ? Colors.amber
                              : Colors.grey,
                          size: 22,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatBytes(int bytes, int decimals) {
    if (bytes <= 0) return "0 Bps";
    const suffixes = ['Bps', "Kbps", "Mbps", "Gbps", "Tbps"];
    var i = (log(bytes) / log(1024)).floor();
    if (i >= suffixes.length) i = suffixes.length - 1;
    return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
  }
}
