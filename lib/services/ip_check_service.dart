import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ip_info.dart';
import 'supabase_service.dart';

/// Service untuk checking IP address information
class IpCheckService extends ChangeNotifier {
  static final IpCheckService _instance = IpCheckService._internal();
  factory IpCheckService() => _instance;
  IpCheckService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final Map<String, IpInfo> _cache = {};
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  Map<String, IpInfo> get cache => Map.unmodifiable(_cache);

  /// Get current public IP
  Future<String?> getCurrentPublicIp() async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await http
          .get(
            Uri.parse('https://api.ipify.org?format=json'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['ip'] as String?;
      }
    } catch (e) {
      debugPrint('Error getting current IP: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return null;
  }

  /// Check IP information using multiple APIs
  Future<IpInfo?> checkIpInfo(String ipAddress) async {
    if (ipAddress.isEmpty) return null;

    // Check cache first
    if (_cache.containsKey(ipAddress)) {
      return _cache[ipAddress];
    }

    try {
      _isLoading = true;
      notifyListeners();

      IpInfo? ipInfo;

      // Try multiple IP info APIs
      ipInfo ??= await _checkWithIpApi(ipAddress);
      ipInfo ??= await _checkWithIpInfo(ipAddress);
      ipInfo ??= await _checkWithIpStack(ipAddress);
      ipInfo ??= await _checkWithFreeGeoIp(ipAddress);

      if (ipInfo != null) {
        _cache[ipAddress] = ipInfo;

        // Save to Supabase for history
        await _saveToSupabase(ipInfo);

        notifyListeners();
        return ipInfo;
      }
    } catch (e) {
      debugPrint('Error checking IP info: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    return null;
  }

  /// Check IP using ip-api.com (free, no key required)
  Future<IpInfo?> _checkWithIpApi(String ipAddress) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              'http://ip-api.com/json/$ipAddress?fields=status,message,country,countryCode,region,regionName,city,zip,lat,lon,timezone,isp,org,as,asname,query',
            ),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return IpInfo.fromJson(data);
        }
      }
    } catch (e) {
      debugPrint('Error with ip-api.com: $e');
    }
    return null;
  }

  /// Check IP using ipinfo.io (free tier available)
  Future<IpInfo?> _checkWithIpInfo(String ipAddress) async {
    try {
      final response = await http
          .get(
            Uri.parse('https://ipinfo.io/$ipAddress/json'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Parse location coordinates
        final loc = data['loc'] as String?;
        double? latitude, longitude;
        if (loc != null && loc.contains(',')) {
          final coords = loc.split(',');
          latitude = double.tryParse(coords[0]);
          longitude = double.tryParse(coords[1]);
        }

        return IpInfo(
          ip: data['ip'] as String? ?? ipAddress,
          hostname: data['hostname'] as String?,
          city: data['city'] as String?,
          region: data['region'] as String?,
          country: data['country'] as String?,
          timezone: data['timezone'] as String?,
          org: data['org'] as String?,
          latitude: latitude,
          longitude: longitude,
          additionalInfo: data,
        );
      }
    } catch (e) {
      debugPrint('Error with ipinfo.io: $e');
    }
    return null;
  }

  /// Check IP using ipstack.com (requires API key, but has free tier)
  Future<IpInfo?> _checkWithIpStack(String ipAddress) async {
    try {
      // Note: You would need to add your ipstack API key here
      // For demo purposes, we'll skip this if no key is available
      const apiKey = ''; // Add your ipstack API key here

      if (apiKey.isEmpty) return null;

      final response = await http
          .get(
            Uri.parse('http://api.ipstack.com/$ipAddress?access_key=$apiKey'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] != false) {
          return IpInfo.fromJson(data);
        }
      }
    } catch (e) {
      debugPrint('Error with ipstack.com: $e');
    }
    return null;
  }

  /// Check IP using freegeoip.app (free, no key required)
  Future<IpInfo?> _checkWithFreeGeoIp(String ipAddress) async {
    try {
      final response = await http
          .get(
            Uri.parse('https://freegeoip.app/json/$ipAddress'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return IpInfo(
          ip: data['ip'] as String? ?? ipAddress,
          city: data['city'] as String?,
          region: data['region_name'] as String?,
          country: data['country_name'] as String?,
          countryCode: data['country_code'] as String?,
          timezone: data['time_zone'] as String?,
          latitude: (data['latitude'] as num?)?.toDouble(),
          longitude: (data['longitude'] as num?)?.toDouble(),
          additionalInfo: data,
        );
      }
    } catch (e) {
      debugPrint('Error with freegeoip.app: $e');
    }
    return null;
  }

  /// Save IP info to Supabase for history using SupabaseService
  Future<void> _saveToSupabase(IpInfo ipInfo) async {
    try {
      final supabaseService = SupabaseService();
      await supabaseService.saveIpCheck(ipInfo);
    } catch (e) {
      debugPrint('Error saving to Supabase: $e');
    }
  }

  /// Get IP check history from Supabase using SupabaseService
  Future<List<IpInfo>> getIpCheckHistory({int limit = 50}) async {
    try {
      final supabaseService = SupabaseService();
      return await supabaseService.getIpCheckHistory(limit: limit);
    } catch (e) {
      debugPrint('Error getting IP check history: $e');
      return [];
    }
  }

  /// Validate IP address format
  bool isValidIpAddress(String ip) {
    if (ip.isEmpty) return false;

    // IPv4 validation
    final ipv4Regex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
    if (ipv4Regex.hasMatch(ip)) {
      final parts = ip.split('.');
      return parts.every((part) {
        final num = int.tryParse(part);
        return num != null && num >= 0 && num <= 255;
      });
    }

    // IPv6 validation (basic)
    final ipv6Regex = RegExp(r'^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$');
    if (ipv6Regex.hasMatch(ip)) {
      return true;
    }

    // Compressed IPv6 validation
    final ipv6CompressedRegex = RegExp(
      r'^([0-9a-fA-F]{1,4}:)*::([0-9a-fA-F]{1,4}:)*[0-9a-fA-F]{1,4}$',
    );
    if (ipv6CompressedRegex.hasMatch(ip)) {
      return true;
    }

    return false;
  }

  /// Check if IP is private/local
  bool isPrivateIp(String ip) {
    if (!isValidIpAddress(ip)) return false;

    final parts = ip.split('.');
    if (parts.length != 4) return false;

    final first = int.tryParse(parts[0]) ?? 0;
    final second = int.tryParse(parts[1]) ?? 0;

    // Private IP ranges
    // 10.0.0.0 - 10.255.255.255
    if (first == 10) return true;

    // 172.16.0.0 - 172.31.255.255
    if (first == 172 && second >= 16 && second <= 31) return true;

    // 192.168.0.0 - 192.168.255.255
    if (first == 192 && second == 168) return true;

    // Loopback
    if (first == 127) return true;

    return false;
  }

  /// Clear cache
  void clearCache() {
    _cache.clear();
    notifyListeners();
  }

  /// Get cached IP info
  IpInfo? getCachedIpInfo(String ipAddress) {
    return _cache[ipAddress];
  }

  /// Check multiple IPs at once
  Future<Map<String, IpInfo?>> checkMultipleIps(
    List<String> ipAddresses,
  ) async {
    final results = <String, IpInfo?>{};

    for (final ip in ipAddresses) {
      if (isValidIpAddress(ip)) {
        results[ip] = await checkIpInfo(ip);
      } else {
        results[ip] = null;
      }
    }

    return results;
  }

  /// Get network information
  Future<Map<String, dynamic>> getNetworkInfo() async {
    try {
      final interfaces = await NetworkInterface.list();
      final networkInfo = <String, dynamic>{};

      for (final interface in interfaces) {
        final addresses = interface.addresses
            .map((addr) => addr.address)
            .toList();

        networkInfo[interface.name] = {
          'addresses': addresses,
          'type': 'network_interface',
        };
      }

      return networkInfo;
    } catch (e) {
      debugPrint('Error getting network info: $e');
      return {};
    }
  }

  /// Perform traceroute to IP (simplified version)
  Future<List<String>> performTraceroute(String ipAddress) async {
    try {
      // This is a simplified version - in a real implementation,
      // you would use platform-specific code to perform actual traceroute
      final result = <String>[];

      // Simulate traceroute hops
      for (int i = 1; i <= 10; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        result.add('$i. 192.168.1.$i (${i * 10}ms)');
      }

      result.add('${result.length + 1}. $ipAddress (destination reached)');
      return result;
    } catch (e) {
      debugPrint('Error performing traceroute: $e');
      return [];
    }
  }

  /// Ping IP address
  Future<Map<String, dynamic>> pingIpAddress(
    String ipAddress, {
    int count = 4,
  }) async {
    try {
      final results = <double>[];
      int packetsLost = 0;

      for (int i = 0; i < count; i++) {
        final stopwatch = Stopwatch()..start();

        try {
          // Simulate ping by making HTTP request with timeout
          await http
              .head(Uri.parse('http://$ipAddress'))
              .timeout(const Duration(seconds: 1));

          stopwatch.stop();
          results.add(stopwatch.elapsedMilliseconds.toDouble());
        } catch (e) {
          stopwatch.stop();
          packetsLost++;
        }

        await Future.delayed(const Duration(milliseconds: 500));
      }

      final avgTime = results.isNotEmpty
          ? results.reduce((a, b) => a + b) / results.length
          : 0.0;

      return {
        'packets_sent': count,
        'packets_received': count - packetsLost,
        'packets_lost': packetsLost,
        'packet_loss_percent': (packetsLost / count * 100).round(),
        'average_time_ms': avgTime.round(),
        'min_time_ms': results.isNotEmpty
            ? results.reduce((a, b) => a < b ? a : b).round()
            : 0,
        'max_time_ms': results.isNotEmpty
            ? results.reduce((a, b) => a > b ? a : b).round()
            : 0,
        'times': results.map((t) => t.round()).toList(),
      };
    } catch (e) {
      debugPrint('Error pinging IP: $e');
      return {
        'packets_sent': count,
        'packets_received': 0,
        'packets_lost': count,
        'packet_loss_percent': 100,
        'average_time_ms': 0,
        'error': e.toString(),
      };
    }
  }
}
