enum HostProxyMode { none, customSocks }

class HostProxySettings {
  const HostProxySettings({
    this.mode = HostProxyMode.none,
    this.host,
    this.port,
    this.username,
    this.password,
  });

  final HostProxyMode mode;
  final String? host;
  final int? port;
  final String? username;
  final String? password;

  HostProxySettings copyWith({
    HostProxyMode? mode,
    String? host,
    int? port,
    String? username,
    String? password,
  }) {
    return HostProxySettings(
      mode: mode ?? this.mode,
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      password: password ?? this.password,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mode': mode.name,
      'host': host,
      'port': port,
      'username': username,
      'password': password,
    };
  }

  factory HostProxySettings.fromJson(Map<String, dynamic> json) {
    final modeName = json['mode'] as String?;
    final modeValue = HostProxyMode.values.firstWhere(
      (mode) => mode.name == modeName,
      orElse: () => HostProxyMode.none,
    );
    return HostProxySettings(
      mode: modeValue,
      host: json['host'] as String?,
      port: (json['port'] as num?)?.toInt(),
      username: json['username'] as String?,
      password: json['password'] as String?,
    );
  }
}
