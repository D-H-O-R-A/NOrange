import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/home_controller.dart';
import '../helpers/pref.dart';
import '../main.dart';
import '../models/vpn_status.dart';
import '../screens/socialmediadialog.dart';
import '../services/vpn_engine.dart';
import '../services/vpn_gateway_proxy_service.dart';
import '../widgets/count_down_timer.dart';
import '../widgets/home_card.dart';
import 'advanced_settings_screen.dart';
import 'location_screen.dart';
import 'network_test_screen.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final _controller = Get.put(HomeController());
  final _gateway = VpnGatewayProxyService.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CupertinoNavigationBar(
        leading: GestureDetector(
          onTap: () {
            showSocialMediaDialog(context);
          },
          child: Image.asset(
            'assets/images/icons8-cardápio-50.png',
            width: 24,
            height: 24,
          ),
        ),
        middle: const Text('Hide Protocol VPN'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (Platform.isIOS) ...[
              GestureDetector(
                onTap: () => _controller.exportCurrentProfile(),
                child: const Icon(
                  CupertinoIcons.share,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
            ],
            // Advanced Settings / Custom VPN / Share VPN / Proxy button
            GestureDetector(
              onTap: () => Get.to(() => const AdvancedSettingsScreen()),
              child: const Icon(
                Icons.tune_rounded,
                size: 25,
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                Get.changeThemeMode(
                  Pref.isDarkMode ? ThemeMode.light : ThemeMode.dark,
                );
                Pref.isDarkMode = !Pref.isDarkMode;
              },
              child: const Icon(
                Icons.brightness_medium,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                Get.to(() => const NetworkTestScreen());
              },
              child: const Icon(
                CupertinoIcons.info,
                size: 25,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _changeLocation(context),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Main VPN Power Button & Quick Action Pills
          Obx(() => _vpnButton()),

          // Country & Ping Cards
          Obx(
            () => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                HomeCard(
                  title: _controller.vpn.value.countryLong.isEmpty
                      ? 'Country'
                      : _controller.vpn.value.countryLong,
                  subtitle: _controller.vpn.value.countryLong.isEmpty
                      ? 'FREE'
                      : '${_controller.vpn.value.protocol}:${_controller.vpn.value.port}',
                  icon: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blue,
                    backgroundImage: (_controller.vpn.value.countryLong.isEmpty ||
                            _controller.vpn.value.isCustom)
                        ? null
                        : AssetImage(
                            'assets/flags/${_controller.vpn.value.countryShort.toLowerCase()}.png',
                          ),
                    child: (_controller.vpn.value.countryLong.isEmpty ||
                            _controller.vpn.value.isCustom)
                        ? const Icon(Icons.vpn_lock_rounded,
                            size: 30, color: Colors.white)
                        : null,
                  ),
                ),
                HomeCard(
                  title: _controller.vpn.value.countryLong.isEmpty
                      ? '-- ms'
                      : '${_controller.vpn.value.ping} ms',
                  subtitle: 'PING',
                  icon: const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.orange,
                    child: Icon(Icons.equalizer_rounded,
                        size: 30, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          // Download & Upload Stream
          StreamBuilder<VpnStatus?>(
            initialData: VpnStatus(),
            stream: VpnEngine.vpnStatusSnapshot(),
            builder: (context, snapshot) => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                HomeCard(
                  title: snapshot.data?.byteIn ?? '0 kbps',
                  subtitle: 'DOWNLOAD',
                  icon: const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.lightGreen,
                    child: Icon(Icons.arrow_downward_rounded,
                        size: 30, color: Colors.white),
                  ),
                ),
                HomeCard(
                  title: snapshot.data?.byteOut ?? '0 kbps',
                  subtitle: 'UPLOAD',
                  icon: const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.arrow_upward_rounded,
                        size: 30, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _vpnButton() => Column(
        children: [
          Semantics(
            button: true,
            child: InkWell(
              onTap: () {
                _controller.connectToVpn();
              },
              borderRadius: BorderRadius.circular(100),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _controller.getButtonColor.withOpacity(.1),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _controller.getButtonColor.withOpacity(.3),
                  ),
                  child: Container(
                    width: mq.height * .14,
                    height: mq.height * .14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _controller.getButtonColor,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.power_settings_new,
                          size: 28,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _controller.getButtonText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Connection status pill
          Container(
            margin: EdgeInsets.only(
                top: mq.height * .012, bottom: mq.height * .006),
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            decoration: BoxDecoration(
              color: _controller.vpnState.value == VpnEngine.vpnConnected
                  ? Colors.green
                  : Colors.blue,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              _controller.vpnState.value == VpnEngine.vpnDisconnected
                  ? 'Not Connected'
                  : _controller.vpnState.value.replaceAll('_', ' ').toUpperCase(),
              style: const TextStyle(
                  fontSize: 12.5,
                  color: Colors.white,
                  fontWeight: FontWeight.w600),
            ),
          ),

          // Live status hint
          if (_controller.statusHint.value.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                _controller.statusHint.value,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.blueGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          // Count down timer
          Obx(() => CountDownTimer(
              startTimer:
                  _controller.vpnState.value == VpnEngine.vpnConnected)),

          const SizedBox(height: 6),

          // Smart Connect + Advanced VPN/Proxy quick action row
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _controller.isSmartConnecting.value
                    ? null
                    : () => _controller.smartConnect(),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  side: const BorderSide(color: Colors.blueAccent),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
                icon: _controller.isSmartConnecting.value
                    ? const SizedBox(
                        width: 13,
                        height: 13,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.bolt_rounded,
                        size: 16, color: Colors.blue),
                label: Text(
                  _controller.isSmartConnecting.value
                      ? 'Buscando...'
                      : 'Smart Connect',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => Get.to(
                    () => const AdvancedSettingsScreen(initialTabIndex: 0)),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  side: BorderSide(
                    color: _gateway.isRunning.value
                        ? Colors.green
                        : Colors.purple,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
                icon: Icon(
                  Icons.wifi_tethering_rounded,
                  size: 15,
                  color:
                      _gateway.isRunning.value ? Colors.green : Colors.purple,
                ),
                label: Text(
                  _gateway.isRunning.value
                      ? 'Gateway Ativo (${_gateway.listeningPort.value})'
                      : 'VPN Própria / Proxy',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: _gateway.isRunning.value ? Colors.green : null,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => Get.to(
                    () => const AdvancedSettingsScreen(initialTabIndex: 3)),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  side: const BorderSide(color: Colors.teal),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.radar_rounded,
                    size: 15, color: Colors.teal),
                label: const Text(
                  'Roteador Wi-Fi & Radar',
                  style: TextStyle(fontSize: 11.5),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => Get.to(
                    () => const AdvancedSettingsScreen(initialTabIndex: 4)),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  side: const BorderSide(color: Colors.deepOrange),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.bubble_chart_rounded,
                    size: 15, color: Colors.deepOrange),
                label: const Text(
                  'Widget Flutuante / GPS / Cam',
                  style: TextStyle(fontSize: 11.5),
                ),
              ),
            ],
          ),
        ],
      );

  Widget _changeLocation(BuildContext context) => SafeArea(
        child: Semantics(
          button: true,
          child: InkWell(
            onTap: () => Get.to(() => LocationScreen()),
            child: Container(
              color: Theme.of(context).bottomNav,
              padding: EdgeInsets.symmetric(horizontal: mq.width * .04),
              height: 60,
              child: Row(
                children: [
                  const Icon(CupertinoIcons.globe,
                      color: Colors.white, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Obx(
                      () => Text(
                        _controller.vpn.value.countryLong.isEmpty
                            ? 'Change Location'
                            : 'Location: ${_controller.vpn.value.countryLong} (${_controller.vpn.value.ping} ms)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.keyboard_arrow_right_rounded,
                        color: Colors.blue, size: 26),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  void showSocialMediaDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SocialMediaDialog();
      },
    );
  }
}
