class ProxyConfig {
  final String id;
  final String name;
  final String host;
  final int port;
  final String protocol; // 'HTTP' or 'SOCKS5'
  final String username;
  final String password;
  int? lastPingMs;

  ProxyConfig({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    this.protocol = 'HTTP',
    this.username = '',
    this.password = '',
    this.lastPingMs,
  });

  factory ProxyConfig.fromJson(Map<String, dynamic> json) {
    return ProxyConfig(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Proxy').toString(),
      host: (json['host'] ?? '').toString(),
      port: int.tryParse((json['port'] ?? '8080').toString()) ?? 8080,
      protocol: (json['protocol'] ?? 'HTTP').toString().toUpperCase(),
      username: (json['username'] ?? '').toString(),
      password: (json['password'] ?? '').toString(),
      lastPingMs: json['lastPingMs'] != null
          ? int.tryParse(json['lastPingMs'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'host': host,
        'port': port,
        'protocol': protocol,
        'username': username,
        'password': password,
        'lastPingMs': lastPingMs,
      };

  String get endpoint => '$host:$port';
  String get displayTitle => name.trim().isEmpty ? '$protocol $host:$port' : name;
  String get type => protocol;
  bool get hasAuth => username.trim().isNotEmpty;
}
