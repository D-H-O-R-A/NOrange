import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../controllers/location_controller.dart';
import '../main.dart';
import '../theme/app_theme.dart';
import '../widgets/vpn_card.dart';

class LocationScreen extends StatelessWidget {
  LocationScreen({super.key});

  final _controller = Get.put(LocationController());

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;
    if (_controller.vpnList.isEmpty && !_controller.isLoading.value) {
      _controller.getVpnData();
    }

    return Obx(() {
      final filtered = _controller.filteredVpnList;
      final isDark = Theme.of(context).brightness == Brightness.dark;

      return Scaffold(
        appBar: AppBar(
          title: Column(
            children: [
              const Text('Nós de Saída Globais'),
              Text(
                '${filtered.length} servidores disponíveis',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? HpColors.textSecondary
                      : HpColors.lightTextSecondary,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Sondar Latência TCP em Tempo Real',
              onPressed: _controller.isPinging.value
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      _controller.testLivePing();
                    },
              icon: _controller.isPinging.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: HpColors.accentEmerald,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.speed_rounded, color: HpColors.accentCyan),
            ),
            PopupMenuButton<String>(
              tooltip: 'Ordenar Nós',
              icon: const Icon(Icons.tune_rounded),
              onSelected: (val) {
                HapticFeedback.selectionClick();
                _controller.sortBy.value = val;
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'recommended',
                  child: Row(
                    children: [
                      Icon(Icons.bolt_rounded,
                          size: 18, color: HpColors.accentEmerald),
                      SizedBox(width: 10),
                      Text('Recomendados (Online + Rápido)'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'ping',
                  child: Row(
                    children: [
                      Icon(Icons.sensors_rounded,
                          size: 18, color: HpColors.accentCyan),
                      SizedBox(width: 10),
                      Text('Menor Latência (Ping)'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'speed',
                  child: Row(
                    children: [
                      Icon(Icons.speed_rounded,
                          size: 18, color: HpColors.accentAmber),
                      SizedBox(width: 10),
                      Text('Maior Largura de Banda'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'sessions',
                  child: Row(
                    children: [
                      Icon(Icons.people_outline_rounded,
                          size: 18, color: HpColors.accentIndigo),
                      SizedBox(width: 10),
                      Text('Menor Carga de Sessões'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 10, right: 6),
          child: FloatingActionButton.extended(
            onPressed: () {
              HapticFeedback.mediumImpact();
              _controller.getVpnData();
            },
            icon: const Icon(CupertinoIcons.refresh, size: 18),
            label: const Text(
              'ATUALIZAR REDE',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            _searchAndFilterBar(context, isDark),
            Expanded(
              child: _controller.isLoading.value
                  ? _loadingWidget(isDark)
                  : filtered.isEmpty
                      ? _noVPNFound(isDark)
                      : ListView.builder(
                          itemCount: filtered.length,
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.only(
                            top: 6,
                            bottom: mq.height * .12,
                            left: 16,
                            right: 16,
                          ),
                          itemBuilder: (ctx, i) => VpnCard(
                            vpn: filtered[i],
                            locationController: _controller,
                          ),
                        ),
            ),
          ],
        ),
      );
    });
  }

  Widget _searchAndFilterBar(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? HpColors.borderSubtle : HpColors.lightBorder,
          ),
        ),
      ),
      child: Column(
        children: [
          TextField(
            onChanged: (v) => _controller.searchQuery.value = v,
            decoration: const InputDecoration(
              hintText: 'Filtrar por país, sigla ou endereço IP...',
              prefixIcon: Icon(
                CupertinoIcons.search,
                size: 18,
                color: HpColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _filterChip('all', 'Todos'),
                const SizedBox(width: 6),
                _filterChip('online', 'Verificados Online'),
                const SizedBox(width: 6),
                _filterChip('favorites', 'Favoritos'),
                const SizedBox(width: 6),
                _filterChip('tcp', 'TCP Estável'),
                const SizedBox(width: 6),
                _filterChip('udp', 'UDP Rápido'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String key, String label) {
    final selected = _controller.selectedFilter.value == key;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) {
        HapticFeedback.selectionClick();
        _controller.selectedFilter.value = key;
      },
    );
  }

  Widget _loadingWidget(bool isDark) => SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LottieBuilder.asset(
              'assets/lottie/loading.json',
              width: mq.width * .55,
            ),
            const SizedBox(height: 12),
            Text(
              'SONDANDO NÓS GLOBAIS',
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 1.5,
                color: HpColors.accentEmerald,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Verificando alcance TCP/UDP e latência em tempo real...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? HpColors.textSecondary
                    : HpColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      );

  Widget _noVPNFound(bool isDark) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const HpIconBox(
                icon: Icons.dns_outlined,
                color: HpColors.accentAmber,
                size: 56,
              ),
              const SizedBox(height: 16),
              const Text(
                'Nenhum nó encontrado para este filtro',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Limpe os filtros ativos ou atualize a malha de servidores.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? HpColors.textSecondary
                      : HpColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: () {
                  _controller.selectedFilter.value = 'all';
                  _controller.searchQuery.value = '';
                  _controller.getVpnData();
                },
                icon: const Icon(CupertinoIcons.refresh, size: 18),
                label: const Text('Restaurar Malha Completa'),
              ),
            ],
          ),
        ),
      );
}
