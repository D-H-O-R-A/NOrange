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
    if (_controller.vpnList.length <= 5 && !_controller.isLoading.value) {
      _controller.getVpnData();
    }

    return Obx(() {
      final filtered = _controller.filteredVpnList;
      final isDark = Theme.of(context).brightness == Brightness.dark;

      return Scaffold(
        appBar: AppBar(
          title: Column(
            children: [
              const Text('VPNs Públicas Globais'),
              Text(
                '${filtered.length} servidores • ${_controller.totalActiveConnections} conexões ativas',
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
                      Text('Mais Conexões Ativas'),
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
            _networkSummaryStrip(isDark, filtered.length),
            _searchAndFilterBar(context, isDark),
            Expanded(
              child: _controller.isLoading.value && filtered.isEmpty
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

  Widget _networkSummaryStrip(bool isDark, int serverCount) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? HpColors.bgElevated : HpColors.lightElevated,
        borderRadius: BorderRadius.circular(HpRadius.md),
        border: Border.all(
          color: isDark ? HpColors.borderSubtle : HpColors.lightBorder,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryMetric(
            'VPNs Públicas',
            '$serverCount',
            HpColors.accentEmerald,
          ),
          _summaryMetric(
            'Conexões Ativas',
            '${_controller.totalActiveConnections}',
            HpColors.accentCyan,
          ),
          _summaryMetric(
            'Países',
            '${_controller.uniqueCountriesCount}',
            HpColors.accentIndigo,
          ),
          _summaryMetric(
            'Ping Médio',
            '${_controller.averagePingMs} ms',
            HpColors.accentAmber,
          ),
        ],
      ),
    );
  }

  Widget _summaryMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: HpColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _searchAndFilterBar(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
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
            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: 'Filtrar por país, sigla, host ou IP...',
              prefixIcon: const Icon(
                CupertinoIcons.search,
                size: 20,
                color: HpColors.accentOrange,
              ),
              suffixIcon: _controller.searchQuery.value.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () => _controller.searchQuery.value = '',
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _filterChip('all', 'Todos (${_controller.vpnList.length})'),
                const SizedBox(width: 8),
                _filterChip('online', 'Verificados Online'),
                const SizedBox(width: 8),
                _filterChip('favorites', 'Favoritos'),
                const SizedBox(width: 8),
                _filterChip('tcp', 'TCP Estável'),
                const SizedBox(width: 8),
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
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          color: selected ? const Color(0xFF09090B) : HpColors.textSecondary,
        ),
      ),
      selected: selected,
      selectedColor: HpColors.accentOrange,
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
            const Text(
              'SINCRONIZANDO MALHA GLOBAL DE VPNS',
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 1.5,
                color: HpColors.accentEmerald,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Carregando servidores públicos, conexões ativas e latência...',
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
                'Nenhum servidor encontrado para este filtro',
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
