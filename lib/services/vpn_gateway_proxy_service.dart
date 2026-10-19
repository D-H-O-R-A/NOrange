import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:get/get.dart';

import '../helpers/pref.dart';
import '../models/vpn.dart';

class ConnectedPeerStat {
  final String ip;
  int bytesUploaded = 0;
  int bytesDownloaded = 0;
  int activeSockets = 0;
  final List<String> accessedDomains = [];
  DateTime lastActivity = DateTime.now();

  ConnectedPeerStat({required this.ip});

  int get totalBytes => bytesUploaded + bytesDownloaded;

  void recordDomain(String hostPort) {
    lastActivity = DateTime.now();
    accessedDomains.remove(hostPort);
    accessedDomains.insert(0, hostPort);
    if (accessedDomains.length > 12) {
      accessedDomains.removeRange(12, accessedDomains.length);
    }
  }

  static String formatBytes(int b) {
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
    return '${(b / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

class VpnGatewayProxyService extends GetxService {
  static VpnGatewayProxyService get instance =>
      Get.isRegistered<VpnGatewayProxyService>()
          ? Get.find<VpnGatewayProxyService>()
          : Get.put(VpnGatewayProxyService(), permanent: true);

  final RxBool isRunning = false.obs;
  final RxInt listeningPort = 8080.obs;
  final RxList<String> localIps = <String>[].obs;
  final RxInt activeConnections = 0.obs;
  final RxInt totalConnections = 0.obs;
  final RxInt totalBytesRelayed = 0.obs;
  final RxList<String> logs = <String>[].obs;
  final RxString authUser = ''.obs;
  final RxString authPass = ''.obs;

  /// Per-device traffic & accessed domains inspector
  final RxMap<String, ConnectedPeerStat> peerStats =
      <String, ConnectedPeerStat>{}.obs;

  ServerSocket? _serverSocket;
  final Set<Socket> _clientSockets = {};

  @override
  void onInit() {
    super.onInit();
    listeningPort.value = Pref.gatewayPort;
    refreshLocalIps();
  }

  Future<void> refreshLocalIps() async {
    final List<String> detected = [];
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback) {
            detected.add('${addr.address} (${iface.name})');
          }
        }
      }
    } catch (_) {}
    if (detected.isEmpty) {
      detected.add('127.0.0.1 (local)');
    }
    localIps.assignAll(detected);
  }

  String get primaryIp {
    if (localIps.isEmpty) return '192.168.43.1';
    final wifiOrHotspot = localIps.firstWhere(
      (e) =>
          e.contains('wlan') ||
          e.contains('ap') ||
          e.contains('en') ||
          e.contains('rndis') ||
          e.contains('eth'),
      orElse: () => localIps.first,
    );
    return wifiOrHotspot.split(' ').first;
  }

  void _addLog(String message) {
    final now = DateTime.now();
    final ts =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    logs.insert(0, '[$ts] $message');
    if (logs.length > 80) {
      logs.removeRange(80, logs.length);
    }
  }

  ConnectedPeerStat _getOrCreatePeer(String clientIp) {
    final existing = peerStats[clientIp];
    if (existing != null) return existing;
    final created = ConnectedPeerStat(ip: clientIp);
    peerStats[clientIp] = created;
    return created;
  }

  Future<bool> startServer({
    int? port,
    String username = '',
    String password = '',
  }) async {
    if (isRunning.value) {
      await stopServer();
    }

    final targetPort = port ?? listeningPort.value;
    authUser.value = username.trim();
    authPass.value = password.trim();

    try {
      await refreshLocalIps();
      _serverSocket = await ServerSocket.bind(
        InternetAddress.anyIPv4,
        targetPort,
        shared: true,
      );
      listeningPort.value = _serverSocket!.port;
      Pref.gatewayPort = listeningPort.value;
      isRunning.value = true;

      _addLog(
          'Roteador/Gateway iniciado em $primaryIp:${listeningPort.value} (HTTP/CONNECT + SOCKS5)');

      _serverSocket!.listen(
        _handleIncomingClient,
        onError: (e) => _addLog('Erro no socket servidor: $e'),
        onDone: () {
          isRunning.value = false;
          _addLog('Servidor Gateway encerrado.');
        },
      );
      return true;
    } catch (e) {
      _addLog('Falha ao iniciar porta $targetPort: $e');
      isRunning.value = false;
      return false;
    }
  }

  Future<void> stopServer() async {
    try {
      for (final s in _clientSockets.toList()) {
        try {
          s.destroy();
        } catch (_) {}
      }
      _clientSockets.clear();
      await _serverSocket?.close();
      _serverSocket = null;
    } catch (_) {}
    activeConnections.value = 0;
    isRunning.value = false;
    _addLog('Gateway VPN/Proxy parado pelo usuário.');
  }

  void _handleIncomingClient(Socket client) {
    _clientSockets.add(client);
    activeConnections.value = _clientSockets.length;
    totalConnections.value++;
    final clientIp = client.remoteAddress.address;
    final clientAddr = '$clientIp:${client.remotePort}';
    final peer = _getOrCreatePeer(clientIp);
    peer.activeSockets++;
    peerStats.refresh();

    Socket? upstream;
    bool handshakeCompleted = false;
    final List<int> headerBuffer = [];

    void cleanup() {
      if (_clientSockets.remove(client)) {
        activeConnections.value = _clientSockets.length;
        if (peer.activeSockets > 0) peer.activeSockets--;
        peerStats.refresh();
      }
      try {
        client.destroy();
      } catch (_) {}
      try {
        upstream?.destroy();
      } catch (_) {}
    }

    client.listen(
      (Uint8List chunk) async {
        if (handshakeCompleted) {
          if (upstream != null) {
            try {
              upstream!.add(chunk);
              totalBytesRelayed.value += chunk.length;
              peer.bytesUploaded += chunk.length;
              peer.lastActivity = DateTime.now();
              peerStats.refresh();
            } catch (_) {
              cleanup();
            }
          }
          return;
        }

        headerBuffer.addAll(chunk);
        if (headerBuffer.isEmpty) return;

        // Detect SOCKS5 protocol (starts with 0x05)
        if (headerBuffer[0] == 0x05) {
          await _handleSocks5Handshake(
            client: client,
            clientAddr: clientAddr,
            peer: peer,
            buffer: headerBuffer,
            onConnected: (Socket connectedUpstream) {
              upstream = connectedUpstream;
              handshakeCompleted = true;
            },
            onError: cleanup,
          );
          return;
        }

        // Otherwise handle HTTP / HTTPS CONNECT tunnel
        final rawStr = latin1.decode(headerBuffer, allowInvalid: true);
        final headerEndIndex = rawStr.indexOf('\r\n\r\n');
        if (headerEndIndex == -1) {
          if (headerBuffer.length > 8192) cleanup();
          return;
        }

        handshakeCompleted = true;
        final headerPart = rawStr.substring(0, headerEndIndex);
        final lines = headerPart.split('\r\n');
        if (lines.isEmpty) {
          cleanup();
          return;
        }

        // Optional Proxy-Authorization check
        if (authUser.value.isNotEmpty) {
          final expectedToken =
              base64Encode(utf8.encode('${authUser.value}:${authPass.value}'));
          final hasValidAuth = lines.any((l) =>
              l.toLowerCase().startsWith('proxy-authorization:') &&
              l.contains(expectedToken));
          if (!hasValidAuth) {
            client.write(
              'HTTP/1.1 407 Proxy Authentication Required\r\n'
              'Proxy-Authenticate: Basic realm="HideProtocolVPN"\r\n'
              'Connection: close\r\n\r\n',
            );
            _addLog('Acesso negado (407) para $clientAddr');
            cleanup();
            return;
          }
        }

        final firstLineParts = lines.first.split(' ');
        if (firstLineParts.length < 2) {
          cleanup();
          return;
        }

        final method = firstLineParts[0].toUpperCase();
        final target = firstLineParts[1];

        String host = '';
        int port = 80;

        if (method == 'CONNECT') {
          final hp = target.split(':');
          host = hp[0];
          port = hp.length > 1 ? (int.tryParse(hp[1]) ?? 443) : 443;
        } else {
          final uri = Uri.tryParse(target);
          if (uri != null && uri.host.isNotEmpty) {
            host = uri.host;
            port = uri.hasPort ? uri.port : (uri.scheme == 'https' ? 443 : 80);
          } else {
            for (final line in lines) {
              if (line.toLowerCase().startsWith('host:')) {
                final hVal = line.substring(5).trim();
                final hp = hVal.split(':');
                host = hp[0];
                port = hp.length > 1 ? (int.tryParse(hp[1]) ?? 80) : 80;
                break;
              }
            }
          }
        }

        if (host.isEmpty) {
          cleanup();
          return;
        }

        peer.recordDomain('$host:$port');
        peerStats.refresh();

        try {
          upstream = await Socket.connect(
            host,
            port,
            timeout: const Duration(seconds: 8),
          );
          _addLog('$clientIp acessando ➔ $host:$port ($method)');

          if (method == 'CONNECT') {
            client.write(
                'HTTP/1.1 200 Connection Established\r\nProxy-Agent: HideProtocol-VPN-Gateway\r\n\r\n');
            final bodyStartOffset = headerEndIndex + 4;
            if (headerBuffer.length > bodyStartOffset) {
              final remaining = headerBuffer.sublist(bodyStartOffset);
              upstream!.add(remaining);
              totalBytesRelayed.value += remaining.length;
              peer.bytesUploaded += remaining.length;
            }
          } else {
            upstream!.add(headerBuffer);
            totalBytesRelayed.value += headerBuffer.length;
            peer.bytesUploaded += headerBuffer.length;
          }
          peerStats.refresh();

          upstream!.listen(
            (Uint8List data) {
              try {
                client.add(data);
                totalBytesRelayed.value += data.length;
                peer.bytesDownloaded += data.length;
                peer.lastActivity = DateTime.now();
                peerStats.refresh();
              } catch (_) {
                cleanup();
              }
            },
            onError: (_) => cleanup(),
            onDone: cleanup,
          );
        } catch (e) {
          _addLog('Falha ao conectar destino $host:$port');
          cleanup();
        }
      },
      onError: (_) => cleanup(),
      onDone: cleanup,
    );
  }

  Future<void> _handleSocks5Handshake({
    required Socket client,
    required String clientAddr,
    required ConnectedPeerStat peer,
    required List<int> buffer,
    required void Function(Socket upstream) onConnected,
    required void Function() onError,
  }) async {
    try {
      if (buffer.length < 3) return;
      final nMethods = buffer[1];
      if (buffer.length == 2 + nMethods) {
        client.add(const [0x05, 0x00]);
        buffer.clear();
        return;
      }

      if (buffer.length >= 7 && buffer[0] == 0x05 && buffer[1] == 0x01) {
        final atyp = buffer[3];
        String host = '';
        int port = 0;

        if (atyp == 0x01 && buffer.length >= 10) {
          host = '${buffer[4]}.${buffer[5]}.${buffer[6]}.${buffer[7]}';
          port = (buffer[8] << 8) | buffer[9];
        } else if (atyp == 0x03) {
          final domainLen = buffer[4];
          if (buffer.length < 5 + domainLen + 2) return;
          host = utf8.decode(buffer.sublist(5, 5 + domainLen));
          port = (buffer[5 + domainLen] << 8) | buffer[5 + domainLen + 1];
        } else {
          onError();
          return;
        }

        peer.recordDomain('$host:$port');
        peerStats.refresh();

        final upstream = await Socket.connect(
          host,
          port,
          timeout: const Duration(seconds: 8),
        );
        _addLog('${peer.ip} acessando ➔ $host:$port (SOCKS5)');

        client.add(const [0x05, 0x00, 0x00, 0x01, 0, 0, 0, 0, 0, 0]);
        buffer.clear();
        onConnected(upstream);

        upstream.listen(
          (Uint8List data) {
            try {
              client.add(data);
              totalBytesRelayed.value += data.length;
              peer.bytesDownloaded += data.length;
              peer.lastActivity = DateTime.now();
              peerStats.refresh();
            } catch (_) {
              onError();
            }
          },
          onError: (_) => onError(),
          onDone: onError,
        );
      }
    } catch (_) {
      onError();
    }
  }

  String generateShareableOvpnProfile(Vpn activeVpn) {
    final phoneIp = primaryIp;
    final port = listeningPort.value;
    String baseConfig = activeVpn.decodedConfig;

    if (baseConfig.isEmpty) {
      baseConfig = '''
client
dev tun
proto tcp
remote 219.100.37.180 443
resolv-retry infinite
nobind
persist-key
persist-tun
cipher AES-128-CBC
auth SHA1
verb 3
''';
    }

    final header = '''
# =====================================================================
# HIDE PROTOCOL VPN - PERFIL COMPARTILHADO PELO CELULAR (GATEWAY VPN)
# Host do Celular: $phoneIp
# Porta do Gateway: $port
# =====================================================================
http-proxy $phoneIp $port
http-proxy-retry
''';
    return '$header\n$baseConfig';
  }

  String get formattedBytesRelayed {
    final b = totalBytesRelayed.value;
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
    return '${(b / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}
