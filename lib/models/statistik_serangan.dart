/// Model untuk statistik serangan
class StatistikSerangan {
  final int totalSerangan;
  final int seranganSukses;
  final int seranganGagal;
  final int totalServer;
  final double tingkatKeberhasilan;
  final Duration totalUptime;

  const StatistikSerangan({
    required this.totalSerangan,
    required this.seranganSukses,
    required this.seranganGagal,
    required this.totalServer,
    required this.tingkatKeberhasilan,
    required this.totalUptime,
  });

  /// Factory untuk membuat statistik kosong
  factory StatistikSerangan.kosong() {
    return const StatistikSerangan(
      totalSerangan: 0,
      seranganSukses: 0,
      seranganGagal: 0,
      totalServer: 0,
      tingkatKeberhasilan: 0.0,
      totalUptime: Duration.zero,
    );
  }

  /// Factory dari JSON
  factory StatistikSerangan.fromJson(Map<String, dynamic> json) {
    return StatistikSerangan(
      totalSerangan: json['total_serangan'] as int? ?? 0,
      seranganSukses: json['serangan_sukses'] as int? ?? 0,
      seranganGagal: json['serangan_gagal'] as int? ?? 0,
      totalServer: json['total_server'] as int? ?? 0,
      tingkatKeberhasilan: (json['tingkat_keberhasilan'] as num?)?.toDouble() ?? 0.0,
      totalUptime: Duration(milliseconds: json['total_uptime_ms'] as int? ?? 0),
    );
  }

  /// Convert ke JSON
  Map<String, dynamic> toJson() {
    return {
      'total_serangan': totalSerangan,
      'serangan_sukses': seranganSukses,
      'serangan_gagal': seranganGagal,
      'total_server': totalServer,
      'tingkat_keberhasilan': tingkatKeberhasilan,
      'total_uptime_ms': totalUptime.inMilliseconds,
    };
  }

  /// Copy with
  StatistikSerangan copyWith({
    int? totalSerangan,
    int? seranganSukses,
    int? seranganGagal,
    int? totalServer,
    double? tingkatKeberhasilan,
    Duration? totalUptime,
  }) {
    return StatistikSerangan(
      totalSerangan: totalSerangan ?? this.totalSerangan,
      seranganSukses: seranganSukses ?? this.seranganSukses,
      seranganGagal: seranganGagal ?? this.seranganGagal,
      totalServer: totalServer ?? this.totalServer,
      tingkatKeberhasilan: tingkatKeberhasilan ?? this.tingkatKeberhasilan,
      totalUptime: totalUptime ?? this.totalUptime,
    );
  }

  @override
  String toString() {
    return 'StatistikSerangan(totalSerangan: $totalSerangan, seranganSukses: $seranganSukses, seranganGagal: $seranganGagal, totalServer: $totalServer, tingkatKeberhasilan: $tingkatKeberhasilan, totalUptime: $totalUptime)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StatistikSerangan &&
        other.totalSerangan == totalSerangan &&
        other.seranganSukses == seranganSukses &&
        other.seranganGagal == seranganGagal &&
        other.totalServer == totalServer &&
        other.tingkatKeberhasilan == tingkatKeberhasilan &&
        other.totalUptime == totalUptime;
  }

  @override
  int get hashCode {
    return Object.hash(
      totalSerangan,
      seranganSukses,
      seranganGagal,
      totalServer,
      tingkatKeberhasilan,
      totalUptime,
    );
  }
}
