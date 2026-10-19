import 'package:get/get.dart';

import '../apis/apis.dart';
import '../helpers/pref.dart';
import '../models/vpn.dart';

class LocationController extends GetxController {
  final RxList<Vpn> vpnList = <Vpn>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isPinging = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString selectedFilter = 'all'.obs; // all, online, favorites, tcp, udp
  final RxString sortBy = 'recommended'.obs; // recommended, ping, speed, sessions
  final RxList<String> favoriteKeys = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    favoriteKeys.assignAll(Pref.favoriteServers);
    final custom = Pref.customVpnList;
    final cached = Pref.vpnList;
    final combined = <Vpn>[
      ...custom,
      ...cached.where((c) => !custom.any((u) => u.uniqueKey == c.uniqueKey)),
    ];
    if (combined.isNotEmpty) {
      vpnList.assignAll(combined);
    }
  }

  Future<void> getVpnData() async {
    isLoading.value = true;
    final servers = await APIs.getVPNServers(verifyReachability: true);
    final custom = Pref.customVpnList;
    vpnList.assignAll([
      ...custom,
      ...servers.where((s) => !custom.any((u) => u.uniqueKey == s.uniqueKey)),
    ]);
    isLoading.value = false;
  }

  Future<void> testLivePing() async {
    if (isPinging.value || vpnList.isEmpty) return;
    isPinging.value = true;
    await APIs.rankAndVerifyServers(vpnList);
    Pref.vpnList = vpnList.toList();
    vpnList.refresh();
    isPinging.value = false;
  }

  void toggleFavorite(Vpn vpn) {
    Pref.toggleFavorite(vpn);
    favoriteKeys.assignAll(Pref.favoriteServers);
    vpnList.refresh();
  }

  bool isFavorite(Vpn vpn) => favoriteKeys.contains(vpn.uniqueKey);

  List<Vpn> get filteredVpnList {
    final query = searchQuery.value.trim().toLowerCase();
    final filter = selectedFilter.value;

    final list = vpnList.where((vpn) {
      if (query.isNotEmpty) {
        final matchesCountry = vpn.countryLong.toLowerCase().contains(query) ||
            vpn.countryShort.toLowerCase().contains(query);
        final matchesIp = vpn.ip.toLowerCase().contains(query) ||
            vpn.hostname.toLowerCase().contains(query);
        if (!matchesCountry && !matchesIp) return false;
      }

      switch (filter) {
        case 'online':
          return vpn.isVerifiedOnline;
        case 'favorites':
          return favoriteKeys.contains(vpn.uniqueKey);
        case 'tcp':
          return vpn.protocol.toUpperCase() == 'TCP';
        case 'udp':
          return vpn.protocol.toUpperCase() == 'UDP';
        default:
          return true;
      }
    }).toList();

    switch (sortBy.value) {
      case 'ping':
        list.sort((a, b) => a.pingValue.compareTo(b.pingValue));
        break;
      case 'speed':
        list.sort((a, b) => b.speed.compareTo(a.speed));
        break;
      case 'sessions':
        list.sort((a, b) => a.numVpnSessions.compareTo(b.numVpnSessions));
        break;
      case 'recommended':
      default:
        list.sort((a, b) {
          if (a.isVerifiedOnline != b.isVerifiedOnline) {
            return a.isVerifiedOnline ? -1 : 1;
          }
          if (a.isVerifiedOnline &&
              b.isVerifiedOnline &&
              a.protocol != b.protocol) {
            return a.protocol == 'TCP' ? -1 : 1;
          }
          return a.pingValue.compareTo(b.pingValue);
        });
        break;
    }

    return list;
  }
}
