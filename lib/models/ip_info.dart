import 'dart:convert';

/// Model untuk informasi IP address
class IpInfo {
  final String ip;
  final String? hostname;
  final String? city;
  final String? region;
  final String? country;
  final String? countryCode;
  final String? timezone;
  final String? isp;
  final String? org;
  final String? asn;
  final String? asnOrg;
  final double? latitude;
  final double? longitude;
  final bool? isProxy;
  final bool? isVpn;
  final bool? isTor;
  final String? threatLevel;
  final Map<String, dynamic>? additionalInfo;

  const IpInfo({
    required this.ip,
    this.hostname,
    this.city,
    this.region,
    this.country,
    this.countryCode,
    this.timezone,
    this.isp,
    this.org,
    this.asn,
    this.asnOrg,
    this.latitude,
    this.longitude,
    this.isProxy,
    this.isVpn,
    this.isTor,
    this.threatLevel,
    this.additionalInfo,
  });

  /// Factory constructor dari JSON
  factory IpInfo.fromJson(Map<String, dynamic> json) {
    return IpInfo(
      ip: json['ip'] as String? ?? json['query'] as String? ?? '',
      hostname: json['hostname'] as String?,
      city: json['city'] as String?,
      region: json['region'] as String? ?? json['regionName'] as String?,
      country: json['country'] as String? ?? json['countryName'] as String?,
      countryCode: json['countryCode'] as String? ?? json['country_code'] as String?,
      timezone: json['timezone'] as String?,
      isp: json['isp'] as String?,
      org: json['org'] as String? ?? json['organization'] as String?,
      asn: json['asn'] as String? ?? json['as']?.toString(),
      asnOrg: json['asnOrg'] as String? ?? json['asname'] as String?,
      latitude: (json['lat'] as num?)?.toDouble() ?? (json['latitude'] as num?)?.toDouble(),
      longitude: (json['lon'] as num?)?.toDouble() ?? (json['longitude'] as num?)?.toDouble(),
      isProxy: json['proxy'] as bool? ?? json['is_proxy'] as bool?,
      isVpn: json['vpn'] as bool? ?? json['is_vpn'] as bool?,
      isTor: json['tor'] as bool? ?? json['is_tor'] as bool?,
      threatLevel: json['threat_level'] as String? ?? json['threatLevel'] as String?,
      additionalInfo: json['additional_info'] as Map<String, dynamic>?,
    );
  }

  /// Convert ke JSON
  Map<String, dynamic> toJson() {
    return {
      'ip': ip,
      'hostname': hostname,
      'city': city,
      'region': region,
      'country': country,
      'country_code': countryCode,
      'timezone': timezone,
      'isp': isp,
      'org': org,
      'asn': asn,
      'asn_org': asnOrg,
      'latitude': latitude,
      'longitude': longitude,
      'is_proxy': isProxy,
      'is_vpn': isVpn,
      'is_tor': isTor,
      'threat_level': threatLevel,
      'additional_info': additionalInfo,
    };
  }

  /// Copy with method
  IpInfo copyWith({
    String? ip,
    String? hostname,
    String? city,
    String? region,
    String? country,
    String? countryCode,
    String? timezone,
    String? isp,
    String? org,
    String? asn,
    String? asnOrg,
    double? latitude,
    double? longitude,
    bool? isProxy,
    bool? isVpn,
    bool? isTor,
    String? threatLevel,
    Map<String, dynamic>? additionalInfo,
  }) {
    return IpInfo(
      ip: ip ?? this.ip,
      hostname: hostname ?? this.hostname,
      city: city ?? this.city,
      region: region ?? this.region,
      country: country ?? this.country,
      countryCode: countryCode ?? this.countryCode,
      timezone: timezone ?? this.timezone,
      isp: isp ?? this.isp,
      org: org ?? this.org,
      asn: asn ?? this.asn,
      asnOrg: asnOrg ?? this.asnOrg,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isProxy: isProxy ?? this.isProxy,
      isVpn: isVpn ?? this.isVpn,
      isTor: isTor ?? this.isTor,
      threatLevel: threatLevel ?? this.threatLevel,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }

  @override
  String toString() {
    return 'IpInfo(ip: $ip, city: $city, country: $country, isp: $isp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is IpInfo && other.ip == ip;
  }

  @override
  int get hashCode => ip.hashCode;

  /// Get location string
  String get locationString {
    final parts = <String>[];
    if (city?.isNotEmpty == true) parts.add(city!);
    if (region?.isNotEmpty == true) parts.add(region!);
    if (country?.isNotEmpty == true) parts.add(country!);
    return parts.join(', ');
  }

  /// Get full location with coordinates
  String get fullLocationString {
    final location = locationString;
    if (latitude != null && longitude != null) {
      return '$location ($latitude, $longitude)';
    }
    return location;
  }

  /// Check if IP is suspicious
  bool get isSuspicious {
    return isProxy == true || isVpn == true || isTor == true;
  }

  /// Get threat level color
  String get threatLevelColor {
    switch (threatLevel?.toLowerCase()) {
      case 'high':
        return '#FF0000';
      case 'medium':
        return '#FFA500';
      case 'low':
        return '#FFFF00';
      default:
        return '#00FF00';
    }
  }

  /// Get ISP and organization info
  String get ispOrgString {
    final parts = <String>[];
    if (isp?.isNotEmpty == true) parts.add(isp!);
    if (org?.isNotEmpty == true && org != isp) parts.add(org!);
    return parts.join(' / ');
  }

  /// Get ASN info string
  String get asnString {
    final parts = <String>[];
    if (asn?.isNotEmpty == true) parts.add('AS$asn');
    if (asnOrg?.isNotEmpty == true) parts.add(asnOrg!);
    return parts.join(' - ');
  }

  /// Check if location data is available
  bool get hasLocationData {
    return city?.isNotEmpty == true || 
           region?.isNotEmpty == true || 
           country?.isNotEmpty == true;
  }

  /// Check if coordinates are available
  bool get hasCoordinates {
    return latitude != null && longitude != null;
  }

  /// Check if ISP data is available
  bool get hasIspData {
    return isp?.isNotEmpty == true || org?.isNotEmpty == true;
  }

  /// Check if ASN data is available
  bool get hasAsnData {
    return asn?.isNotEmpty == true || asnOrg?.isNotEmpty == true;
  }

  /// Get security flags as list
  List<String> get securityFlags {
    final flags = <String>[];
    if (isProxy == true) flags.add('Proxy');
    if (isVpn == true) flags.add('VPN');
    if (isTor == true) flags.add('Tor');
    return flags;
  }

  /// Get all available information as map
  Map<String, String> get allInfo {
    final info = <String, String>{};
    
    info['IP Address'] = ip;
    if (hostname?.isNotEmpty == true) info['Hostname'] = hostname!;
    if (hasLocationData) info['Location'] = locationString;
    if (hasCoordinates) info['Coordinates'] = '$latitude, $longitude';
    if (timezone?.isNotEmpty == true) info['Timezone'] = timezone!;
    if (hasIspData) info['ISP/Org'] = ispOrgString;
    if (hasAsnData) info['ASN'] = asnString;
    if (securityFlags.isNotEmpty) info['Security Flags'] = securityFlags.join(', ');
    if (threatLevel?.isNotEmpty == true) info['Threat Level'] = threatLevel!;
    
    return info;
  }
}
