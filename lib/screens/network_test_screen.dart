import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../apis/apis.dart';
import '../helpers/my_dialogs.dart';
import '../main.dart';
import '../models/ip_details.dart';
import '../models/network_data.dart';
import '../theme/app_theme.dart';
import '../widgets/network_card.dart';

class NetworkTestScreen extends StatelessWidget {
  const NetworkTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;
    final ipData = IPDetails.fromJson({}).obs;
    APIs.getIPDetails(ipData: ipData);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnóstico de Rede & IP'),
        actions: [
          IconButton(
            tooltip: 'Atualizar Telemetria',
            onPressed: () {
              HapticFeedback.mediumImpact();
              ipData.value = IPDetails.fromJson({});
              APIs.getIPDetails(ipData: ipData);
            },
            icon: const Icon(CupertinoIcons.refresh),
          ),
        ],
      ),
      body: Obx(
        () => ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 36),
          children: [
            // Hero Public IP Banner
            HpSurface(
              padding: const EdgeInsets.all(20),
              borderRadius: HpRadius.lg,
              borderColor: HpColors.accentEmerald.withOpacity(0.35),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const HpBadge(
                        text: 'ENDEREÇO IP PÚBLICO VISÍVEL',
                        color: HpColors.accentEmerald,
                        pulsingDot: true,
                      ),
                      IconButton(
                        tooltip: 'Copiar IP',
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: ipData.value.query));
                          MyDialogs.success(
                              msg: 'IP ${ipData.value.query} copiado!');
                        },
                        icon: const Icon(
                          Icons.copy_rounded,
                          size: 18,
                          color: HpColors.accentEmerald,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ipData.value.query,
                    style: HpTextStyles.displayTimer.copyWith(
                      fontSize: 28,
                      color: isDark
                          ? HpColors.textPrimary
                          : HpColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Toque em qualquer cartão abaixo para copiar a informação para a área de transferência.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? HpColors.textSecondary
                          : HpColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const HpSectionLabel(label: 'Roteamento & Geolocalização Externa'),

            // IP Address
            NetworkCard(
              data: NetworkData(
                title: 'Endereço IPv4 / IPv6',
                subtitle: ipData.value.query,
                icon: const Icon(
                  CupertinoIcons.shield_lefthalf_fill,
                  color: HpColors.accentEmerald,
                ),
              ),
            ),

            // ISP
            NetworkCard(
              data: NetworkData(
                title: 'Provedor / ASN (ISP)',
                subtitle: ipData.value.isp,
                icon: const Icon(
                  Icons.hub_rounded,
                  color: HpColors.accentCyan,
                ),
              ),
            ),

            // Location
            NetworkCard(
              data: NetworkData(
                title: 'Localização Detectada',
                subtitle: ipData.value.country.isEmpty
                    ? 'Sincronizando geolocalização...'
                    : '${ipData.value.city}, ${ipData.value.regionName}, ${ipData.value.country}',
                icon: const Icon(
                  CupertinoIcons.location_solid,
                  color: HpColors.accentAmber,
                ),
              ),
            ),

            // Pin code
            NetworkCard(
              data: NetworkData(
                title: 'Código Postal',
                subtitle: ipData.value.zip,
                icon: const Icon(
                  CupertinoIcons.map_pin_ellipse,
                  color: HpColors.accentIndigo,
                ),
              ),
            ),

            // Timezone
            NetworkCard(
              data: NetworkData(
                title: 'Fuso Horário de Rede',
                subtitle: ipData.value.timezone,
                icon: const Icon(
                  CupertinoIcons.clock_fill,
                  color: HpColors.accentEmerald,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
