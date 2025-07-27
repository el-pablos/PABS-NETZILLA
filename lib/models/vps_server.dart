// import 'dart:convert'; // Unused import

/// Model untuk VPS Server
class VpsServer {
  final String id;
  final String name;
  final String host;
  final int port;
  final String username;
  final String password;
  final String? privateKey;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastConnected;
  final Map<String, dynamic>? metadata;

  const VpsServer({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    required this.username,
    required this.password,
    this.privateKey,
    this.isActive = true,
    required this.createdAt,
    this.lastConnected,
    this.metadata,
  });

  /// Factory constructor dari JSON
  factory VpsServer.fromJson(Map<String, dynamic> json) {
    return VpsServer(
      id: json['id'] as String,
      name: json['name'] as String,
      host: json['host'] as String,
      port: json['port'] as int,
      username: json['username'] as String,
      password: json['password'] as String,
      privateKey: json['private_key'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastConnected: json['last_connected'] != null
          ? DateTime.parse(json['last_connected'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert ke JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'host': host,
      'port': port,
      'username': username,
      'password': password,
      'private_key': privateKey,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'last_connected': lastConnected?.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Copy with method
  VpsServer copyWith({
    String? id,
    String? name,
    String? host,
    int? port,
    String? username,
    String? password,
    String? privateKey,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastConnected,
    Map<String, dynamic>? metadata,
  }) {
    return VpsServer(
      id: id ?? this.id,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      password: password ?? this.password,
      privateKey: privateKey ?? this.privateKey,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastConnected: lastConnected ?? this.lastConnected,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'VpsServer(id: $id, name: $name, host: $host:$port, username: $username, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VpsServer && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  /// Get connection string untuk display
  String get connectionString => '$username@$host:$port';

  /// Check apakah server valid
  bool get isValid {
    return name.isNotEmpty &&
        host.isNotEmpty &&
        port > 0 &&
        port <= 65535 &&
        username.isNotEmpty &&
        password.isNotEmpty;
  }
}

/// Status koneksi VPS
enum VpsConnectionStatus { disconnected, connecting, connected, error }

/// Model untuk status koneksi VPS
class VpsConnectionInfo {
  final VpsServer server;
  final VpsConnectionStatus status;
  final String? errorMessage;
  final DateTime? connectedAt;
  final Map<String, dynamic>? systemInfo;

  const VpsConnectionInfo({
    required this.server,
    required this.status,
    this.errorMessage,
    this.connectedAt,
    this.systemInfo,
  });

  /// Factory constructor dari JSON
  factory VpsConnectionInfo.fromJson(Map<String, dynamic> json) {
    return VpsConnectionInfo(
      server: VpsServer.fromJson(json['server'] as Map<String, dynamic>),
      status: VpsConnectionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => VpsConnectionStatus.disconnected,
      ),
      errorMessage: json['error_message'] as String?,
      connectedAt: json['connected_at'] != null
          ? DateTime.parse(json['connected_at'] as String)
          : null,
      systemInfo: json['system_info'] as Map<String, dynamic>?,
    );
  }

  /// Convert ke JSON
  Map<String, dynamic> toJson() {
    return {
      'server': server.toJson(),
      'status': status.name,
      'error_message': errorMessage,
      'connected_at': connectedAt?.toIso8601String(),
      'system_info': systemInfo,
    };
  }

  /// Copy with method
  VpsConnectionInfo copyWith({
    VpsServer? server,
    VpsConnectionStatus? status,
    String? errorMessage,
    DateTime? connectedAt,
    Map<String, dynamic>? systemInfo,
  }) {
    return VpsConnectionInfo(
      server: server ?? this.server,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      connectedAt: connectedAt ?? this.connectedAt,
      systemInfo: systemInfo ?? this.systemInfo,
    );
  }

  /// Check apakah sedang terhubung
  bool get isConnected => status == VpsConnectionStatus.connected;

  /// Check apakah sedang connecting
  bool get isConnecting => status == VpsConnectionStatus.connecting;

  /// Check apakah ada error
  bool get hasError => status == VpsConnectionStatus.error;
}
