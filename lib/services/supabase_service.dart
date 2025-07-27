import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/metode_serangan.dart';
import '../models/hasil_serangan.dart';
import '../models/riwayat_serangan.dart';
import '../models/statistik_serangan.dart';
import '../models/vps_server.dart';
import '../models/ip_info.dart';

/// Comprehensive Supabase service for real-time data operations
class SupabaseService extends ChangeNotifier {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  // Real-time subscriptions
  RealtimeChannel? _attackHistoryChannel;
  RealtimeChannel? _vpsServersChannel;
  RealtimeChannel? _ipChecksChannel;

  /// Initialize real-time subscriptions
  Future<void> initializeRealtimeSubscriptions() async {
    try {
      // Subscribe to attack history changes
      _attackHistoryChannel = _client
          .channel('attack_history_changes')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'attack_history',
            callback: (payload) {
              debugPrint('Attack history changed: ${payload.toString()}');
              notifyListeners();
            },
          )
          .subscribe();

      // Subscribe to VPS servers changes
      _vpsServersChannel = _client
          .channel('vps_servers_changes')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'vps_servers',
            callback: (payload) {
              debugPrint('VPS servers changed: ${payload.toString()}');
              notifyListeners();
            },
          )
          .subscribe();

      // Subscribe to IP checks changes
      _ipChecksChannel = _client
          .channel('ip_checks_changes')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'ip_checks',
            callback: (payload) {
              debugPrint('IP checks changed: ${payload.toString()}');
              notifyListeners();
            },
          )
          .subscribe();

      debugPrint('Real-time subscriptions initialized successfully');
    } catch (e) {
      debugPrint('Error initializing real-time subscriptions: $e');
    }
  }

  /// Dispose real-time subscriptions
  void disposeRealtimeSubscriptions() {
    _attackHistoryChannel?.unsubscribe();
    _vpsServersChannel?.unsubscribe();
    _ipChecksChannel?.unsubscribe();
  }

  // ==================== ATTACK HISTORY OPERATIONS ====================

  /// Save attack result to database
  Future<bool> saveAttackResult(HasilSerangan hasil) async {
    try {
      await _client.from('attack_history').insert({
        'id': hasil.id,
        'metode_id': hasil.metodeId,
        'metode_nama': hasil.metodeNama,
        'target_ip': hasil.targetIp,
        'port': hasil.port,
        'mode': hasil.mode ?? 'unknown',
        'sukses': hasil.sukses,
        'pesan': hasil.pesan,
        'durasi_ms': hasil.durasi?.inMilliseconds ?? 0,
        'timestamp': hasil.timestamp.toIso8601String(),
        'jumlah_server': hasil.jumlahServer,
        'created_at': DateTime.now().toIso8601String(),
      });

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error saving attack result: $e');
      return false;
    }
  }

  /// Get attack history from database
  Future<List<RiwayatSerangan>> getAttackHistory({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _client
          .from('attack_history')
          .select()
          .order('timestamp', ascending: false)
          .range(offset, offset + limit - 1);

      final List<RiwayatSerangan> history = [];
      for (final item in response) {
        try {
          final riwayat = RiwayatSerangan(
            id: item['id'] as String,
            metodeId: item['metode_id'] as String,
            namaMetode: item['metode_nama'] as String,
            targetIp: item['target_ip'] as String,
            port: item['port'] as int?,
            mode: ModeSerangan.values.firstWhere(
              (e) => e.name == item['mode'],
              orElse: () => ModeSerangan.pps,
            ),
            jumlahServer: item['jumlah_server'] as int? ?? 0,
            sukses: item['sukses'] as bool? ?? false,
            timestamp: DateTime.parse(item['timestamp'] as String),
            durasi: Duration(milliseconds: item['durasi_ms'] as int? ?? 0),
            pesanError: item['pesan'] as String? ?? '',
          );
          history.add(riwayat);
        } catch (e) {
          debugPrint('Error parsing attack history item: $e');
        }
      }

      return history;
    } catch (e) {
      debugPrint('Error getting attack history: $e');
      return [];
    }
  }

  /// Get attack statistics
  Future<StatistikSerangan> getAttackStatistics() async {
    try {
      // Get total attacks
      final totalResponse = await _client.from('attack_history').select('id');

      final totalSerangan = totalResponse.length;

      // Get successful attacks
      final successResponse = await _client
          .from('attack_history')
          .select('id')
          .eq('sukses', true);

      final seranganBerhasil = successResponse.length;

      // Get recent attacks (last 24 hours)
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final recentResponse = await _client
          .from('attack_history')
          .select('id')
          .gte('timestamp', yesterday.toIso8601String());

      final seranganHariIni = recentResponse.length;

      // Get active servers count from VPS servers
      final vpsResponse = await _client
          .from('vps_servers')
          .select('id')
          .eq('is_active', true);

      final totalServer = vpsResponse.length;

      // Calculate success rate
      final tingkatKeberhasilan = totalSerangan > 0
          ? (seranganBerhasil / totalSerangan) * 100
          : 0.0;

      return StatistikSerangan(
        totalSerangan: totalSerangan,
        seranganSukses: seranganBerhasil,
        seranganGagal: totalSerangan - seranganBerhasil,
        totalServer: totalServer,
        tingkatKeberhasilan: tingkatKeberhasilan,
        totalUptime: const Duration(hours: 24), // Default uptime
      );
    } catch (e) {
      debugPrint('Error getting attack statistics: $e');
      return StatistikSerangan.kosong();
    }
  }

  // ==================== VPS SERVERS OPERATIONS ====================

  /// Get all VPS servers
  Future<List<VpsServer>> getVpsServers() async {
    try {
      final response = await _client
          .from('vps_servers')
          .select()
          .order('created_at', ascending: false);

      final List<VpsServer> servers = [];
      for (final item in response) {
        try {
          final server = VpsServer.fromJson(item);
          servers.add(server);
        } catch (e) {
          debugPrint('Error parsing VPS server: $e');
        }
      }

      return servers;
    } catch (e) {
      debugPrint('Error getting VPS servers: $e');
      return [];
    }
  }

  /// Save VPS server
  Future<bool> saveVpsServer(VpsServer server) async {
    try {
      await _client.from('vps_servers').upsert(server.toJson());
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error saving VPS server: $e');
      return false;
    }
  }

  /// Delete VPS server
  Future<bool> deleteVpsServer(String serverId) async {
    try {
      await _client.from('vps_servers').delete().eq('id', serverId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting VPS server: $e');
      return false;
    }
  }

  // ==================== IP CHECKS OPERATIONS ====================

  /// Save IP check result
  Future<bool> saveIpCheck(IpInfo ipInfo) async {
    try {
      await _client.from('ip_checks').upsert({
        'ip_address': ipInfo.ip,
        'hostname': ipInfo.hostname,
        'city': ipInfo.city,
        'region': ipInfo.region,
        'country': ipInfo.country,
        'country_code': ipInfo.countryCode,
        'timezone': ipInfo.timezone,
        'isp': ipInfo.isp,
        'org': ipInfo.org,
        'asn': ipInfo.asn,
        'asn_org': ipInfo.asnOrg,
        'latitude': ipInfo.latitude,
        'longitude': ipInfo.longitude,
        'is_proxy': ipInfo.isProxy,
        'is_vpn': ipInfo.isVpn,
        'is_tor': ipInfo.isTor,
        'threat_level': ipInfo.threatLevel,
        'additional_info': ipInfo.additionalInfo,
        'checked_at': DateTime.now().toIso8601String(),
      });

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error saving IP check: $e');
      return false;
    }
  }

  /// Get IP check history
  Future<List<IpInfo>> getIpCheckHistory({int limit = 50}) async {
    try {
      final response = await _client
          .from('ip_checks')
          .select()
          .order('checked_at', ascending: false)
          .limit(limit);

      final List<IpInfo> history = [];
      for (final item in response) {
        try {
          final ipInfo = IpInfo.fromJson(item);
          history.add(ipInfo);
        } catch (e) {
          debugPrint('Error parsing IP check history: $e');
        }
      }

      return history;
    } catch (e) {
      debugPrint('Error getting IP check history: $e');
      return [];
    }
  }

  // ==================== UTILITY METHODS ====================

  /// Check if database connection is healthy
  Future<bool> checkDatabaseHealth() async {
    try {
      await _client.from('attack_history').select('id').limit(1);
      return true;
    } catch (e) {
      debugPrint('Database health check failed: $e');
      return false;
    }
  }

  /// Get current user session
  Session? get currentSession => _client.auth.currentSession;

  /// Check if user is authenticated
  bool get isAuthenticated => currentSession != null;

  @override
  void dispose() {
    disposeRealtimeSubscriptions();
    super.dispose();
  }
}
