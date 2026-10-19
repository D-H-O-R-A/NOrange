import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../controllers/location_controller.dart';
import '../main.dart';
import '../widgets/vpn_card.dart';

class LocationScreen extends StatelessWidget {
  LocationScreen({super.key});

  final _controller = Get.put(LocationController());

  @override
  Widget build(BuildContext context) {
    if (_controller.vpnList.isEmpty && !_controller.isLoading.value) {
      _controller.getVpnData();
    }

    return Obx(() {
      final filtered = _controller.filteredVpnList;
      return Scaffold(
        appBar: AppBar(
          title: Text('VPN Locations (${filtered.length})'),
          actions: [
            // Live Ping test button
            IconButton(
              tooltip: 'Testar Ping em Tempo Real',
              onPressed: _controller.isPinging.value
                  ? null
                  : () => _controller.testLivePing(),
              icon: _controller.isPinging.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.speed_rounded),
            ),
            // Sort menu
            PopupMenuButton<String>(
              tooltip: 'Ordenar Servidores',
              icon: const Icon(Icons.sort_rounded),
              onSelected: (val) => _controller.sortBy.value = val,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'recommended',
                  child: Text('⚡ Recomendados (Online + Rápido)'),
                ),
                const PopupMenuItem(
                  value: 'ping',
                  child: Text('📶 Menor Ping (Latência)'),
                ),
                const PopupMenuItem(
                  value: 'speed',
                  child: Text('🚀 Maior Velocidade'),
                ),
                const PopupMenuItem(
                  value: 'sessions',
                  child: Text('👥 Menos Sobrecarregados'),
                ),
              ],
            ),
          ],
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 10, right: 10),
          child: FloatingActionButton(
            onPressed: () => _controller.getVpnData(),
            child: const Icon(CupertinoIcons.refresh),
          ),
        ),
        body: Column(
          children: [
            _searchAndFilterBar(context),
            Expanded(
              child: _controller.isLoading.value
                  ? _loadingWidget()
                  : filtered.isEmpty
                      ? _noVPNFound()
                      : ListView.builder(
                          itemCount: filtered.length,
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.only(
                            top: mq.height * .01,
                            bottom: mq.height * .1,
                            left: mq.width * .04,
                            right: mq.width * .04,
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

  Widget _searchAndFilterBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: mq.width * .04, vertical: 8),
      child: Column(
        children: [
          // Search Field
          TextField(
            onChanged: (v) => _controller.searchQuery.value = v,
            decoration: InputDecoration(
              hintText: 'Buscar por país, código ou IP...',
              prefixIcon: const Icon(CupertinoIcons.search),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('all', 'Todos'),
                const SizedBox(width: 6),
                _filterChip('online', '🟢 Online Verificados'),
                const SizedBox(width: 6),
                _filterChip('favorites', '⭐ Favoritos'),
                const SizedBox(width: 6),
                _filterChip('tcp', '🛡️ TCP (Estável)'),
                const SizedBox(width: 6),
                _filterChip('udp', '⚡ UDP (Rápido)'),
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
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: selected,
      onSelected: (_) => _controller.selectedFilter.value = key,
    );
  }

  Widget _loadingWidget() => SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LottieBuilder.asset('assets/lottie/loading.json',
                width: mq.width * .65),
            const Text(
              'Buscando e verificando VPNs públicas... 🌐',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );

  Widget _noVPNFound() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Nenhuma VPN encontrada para este filtro 😔',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                _controller.selectedFilter.value = 'all';
                _controller.searchQuery.value = '';
                _controller.getVpnData();
              },
              icon: const Icon(CupertinoIcons.refresh),
              label: const Text('Recarregar Lista Completa'),
            ),
          ],
        ),
      );
}
