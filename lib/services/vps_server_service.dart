import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/vps_server.dart';
import 'supabase_service.dart';

/// Service untuk mengelola VPS servers
class VpsServerService extends ChangeNotifier {
  static final VpsServerService _instance = VpsServerService._internal();
  factory VpsServerService() => _instance;
  VpsServerService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final List<VpsServer> _servers = [];
  final Map<String, VpsConnectionInfo> _connections = {};
  final Uuid _uuid = const Uuid();

  List<VpsServer> get servers => List.unmodifiable(_servers);
  Map<String, VpsConnectionInfo> get connections =>
      Map.unmodifiable(_connections);

  /// Initialize service
  Future<void> initialize() async {
    await _loadServersFromLocal();
    await _syncWithSupabase();
  }

  /// Load servers dari file lokal server.json
  Future<void> _loadServersFromLocal() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/server.json');

      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> jsonList = json.decode(content);

        _servers.clear();
        for (final item in jsonList) {
          try {
            final server = VpsServer.fromJson(item as Map<String, dynamic>);
            _servers.add(server);
          } catch (e) {
            debugPrint('Error parsing server: $e');
          }
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading servers from local: $e');
    }
  }

  /// Save servers ke file lokal server.json
  Future<void> _saveServersToLocal() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/server.json');

      final jsonList = _servers.map((server) => server.toJson()).toList();
      await file.writeAsString(json.encode(jsonList));
    } catch (e) {
      debugPrint('Error saving servers to local: $e');
    }
  }

  /// Sync dengan Supabase database using SupabaseService
  Future<void> _syncWithSupabase() async {
    try {
      final supabaseService = SupabaseService();

      // Upload local servers ke Supabase
      for (final server in _servers) {
        await supabaseService.saveVpsServer(server);
      }

      // Download servers dari Supabase
      final supabaseServers = await supabaseService.getVpsServers();

      // Merge dengan local servers
      final Set<String> localIds = _servers.map((s) => s.id).toSet();
      for (final server in supabaseServers) {
        if (!localIds.contains(server.id)) {
          _servers.add(server);
        }
      }

      await _saveServersToLocal();
      notifyListeners();
    } catch (e) {
      debugPrint('Error syncing with Supabase: $e');
    }
  }

  /// Add server baru
  Future<bool> addServer({
    required String name,
    required String host,
    required int port,
    required String username,
    required String password,
    String? privateKey,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final server = VpsServer(
        id: _uuid.v4(),
        name: name,
        host: host,
        port: port,
        username: username,
        password: password,
        privateKey: privateKey,
        createdAt: DateTime.now(),
        metadata: metadata,
      );

      if (!server.isValid) {
        throw Exception('Invalid server configuration');
      }

      _servers.add(server);
      await _saveServersToLocal();

      // Upload ke Supabase
      await _supabase.from('vps_servers').insert(server.toJson());

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding server: $e');
      return false;
    }
  }

  /// Update server
  Future<bool> updateServer(
    String id, {
    String? name,
    String? host,
    int? port,
    String? username,
    String? password,
    String? privateKey,
    bool? isActive,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final index = _servers.indexWhere((s) => s.id == id);
      if (index == -1) return false;

      final updatedServer = _servers[index].copyWith(
        name: name,
        host: host,
        port: port,
        username: username,
        password: password,
        privateKey: privateKey,
        isActive: isActive,
        metadata: metadata,
      );

      _servers[index] = updatedServer;
      await _saveServersToLocal();

      // Update di Supabase
      await _supabase
          .from('vps_servers')
          .update(updatedServer.toJson())
          .eq('id', id);

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating server: $e');
      return false;
    }
  }

  /// Delete server
  Future<bool> deleteServer(String id) async {
    try {
      _servers.removeWhere((s) => s.id == id);
      _connections.remove(id);

      await _saveServersToLocal();

      // Delete dari Supabase
      await _supabase.from('vps_servers').delete().eq('id', id);

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting server: $e');
      return false;
    }
  }

  /// Get server by ID
  VpsServer? getServer(String id) {
    try {
      return _servers.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Test koneksi ke server
  Future<VpsConnectionInfo> testConnection(String serverId) async {
    final server = getServer(serverId);
    if (server == null) {
      return VpsConnectionInfo(
        server: server!,
        status: VpsConnectionStatus.error,
        errorMessage: 'Server not found',
      );
    }

    _connections[serverId] = VpsConnectionInfo(
      server: server,
      status: VpsConnectionStatus.connecting,
    );
    notifyListeners();

    try {
      // Simulate connection test (replace with actual SSH connection)
      await Future.delayed(const Duration(seconds: 2));

      // For now, randomly succeed or fail
      final success = DateTime.now().millisecond % 2 == 0;

      final connectionInfo = VpsConnectionInfo(
        server: server,
        status: success
            ? VpsConnectionStatus.connected
            : VpsConnectionStatus.error,
        errorMessage: success ? null : 'Connection failed',
        connectedAt: success ? DateTime.now() : null,
        systemInfo: success
            ? {
                'os': 'Ubuntu 20.04',
                'cpu': '2 cores',
                'memory': '4GB',
                'disk': '80GB',
              }
            : null,
      );

      _connections[serverId] = connectionInfo;

      // Update last connected time
      if (success) {
        await updateServer(
          serverId,
          metadata: {
            ...?server.metadata,
            'last_connected': DateTime.now().toIso8601String(),
          },
        );
      }

      notifyListeners();
      return connectionInfo;
    } catch (e) {
      final errorInfo = VpsConnectionInfo(
        server: server,
        status: VpsConnectionStatus.error,
        errorMessage: e.toString(),
      );

      _connections[serverId] = errorInfo;
      notifyListeners();
      return errorInfo;
    }
  }

  /// Get connection info
  VpsConnectionInfo? getConnectionInfo(String serverId) {
    return _connections[serverId];
  }

  /// Load VPS dari file dan auto setup CNC
  Future<bool> loadVpsAndSetupCnc() async {
    try {
      await _loadServersFromLocal();

      // Auto connect ke semua active servers
      final activeServers = _servers.where((s) => s.isActive).toList();

      for (final server in activeServers) {
        await testConnection(server.id);
      }

      return true;
    } catch (e) {
      debugPrint('Error loading VPS and setup CNC: $e');
      return false;
    }
  }

  /// Get active servers count
  int get activeServersCount => _servers.where((s) => s.isActive).length;

  /// Get connected servers count
  int get connectedServersCount => _connections.values
      .where((c) => c.status == VpsConnectionStatus.connected)
      .length;
}
