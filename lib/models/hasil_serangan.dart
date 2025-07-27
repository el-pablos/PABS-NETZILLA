/// Model untuk hasil eksekusi serangan
class HasilSerangan {
  final bool sukses;
  final String pesan;
  final String? error;
  final DateTime timestamp;
  final int? jumlahServer;
  final Duration? durasi;

  HasilSerangan({
    required this.sukses,
    required this.pesan,
    this.error,
    DateTime? timestamp,
    this.jumlahServer,
    this.durasi,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Factory constructor untuk hasil sukses
  factory HasilSerangan.sukses(String pesan, {int? jumlahServer, Duration? durasi}) {
    return HasilSerangan(
      sukses: true,
      pesan: pesan,
      jumlahServer: jumlahServer,
      durasi: durasi,
    );
  }

  /// Factory constructor untuk hasil error
  factory HasilSerangan.error(String error) {
    return HasilSerangan(
      sukses: false,
      pesan: 'Serangan gagal dieksekusi',
      error: error,
    );
  }

  /// Convert to Map for JSON serialization
  Map<String, dynamic> toMap() {
    return {
      'sukses': sukses,
      'pesan': pesan,
      'error': error,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'jumlahServer': jumlahServer,
      'durasi': durasi?.inMilliseconds,
    };
  }

  /// Create from Map for JSON deserialization
  factory HasilSerangan.fromMap(Map<String, dynamic> map) {
    return HasilSerangan(
      sukses: map['sukses'] ?? false,
      pesan: map['pesan'] ?? '',
      error: map['error'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      jumlahServer: map['jumlahServer'],
      durasi: map['durasi'] != null ? Duration(milliseconds: map['durasi']) : null,
    );
  }

  @override
  String toString() {
    return 'HasilSerangan(sukses: $sukses, pesan: $pesan, timestamp: $timestamp)';
  }
}

/// Model untuk statistik serangan
class StatistikSerangan {
  final int totalSerangan;
  final int seranganSukses;
  final int seranganGagal;
  final int totalServer;
  final double tingkatKeberhasilan;
  final Duration totalUptime;

  StatistikSerangan({
    required this.totalSerangan,
    required this.seranganSukses,
    required this.seranganGagal,
    required this.totalServer,
    required this.tingkatKeberhasilan,
    required this.totalUptime,
  });

  /// Factory constructor untuk statistik kosong
  factory StatistikSerangan.kosong() {
    return StatistikSerangan(
      totalSerangan: 0,
      seranganSukses: 0,
      seranganGagal: 0,
      totalServer: 150, // Default server count
      tingkatKeberhasilan: 0.0,
      totalUptime: Duration.zero,
    );
  }

  /// Convert to Map for JSON serialization
  Map<String, dynamic> toMap() {
    return {
      'totalSerangan': totalSerangan,
      'seranganSukses': seranganSukses,
      'seranganGagal': seranganGagal,
      'totalServer': totalServer,
      'tingkatKeberhasilan': tingkatKeberhasilan,
      'totalUptime': totalUptime.inMilliseconds,
    };
  }

  /// Create from Map for JSON deserialization
  factory StatistikSerangan.fromMap(Map<String, dynamic> map) {
    return StatistikSerangan(
      totalSerangan: map['totalSerangan'] ?? 0,
      seranganSukses: map['seranganSukses'] ?? 0,
      seranganGagal: map['seranganGagal'] ?? 0,
      totalServer: map['totalServer'] ?? 150,
      tingkatKeberhasilan: map['tingkatKeberhasilan']?.toDouble() ?? 0.0,
      totalUptime: Duration(milliseconds: map['totalUptime'] ?? 0),
    );
  }

  /// Hitung tingkat keberhasilan
  double hitungTingkatKeberhasilan() {
    if (totalSerangan == 0) return 0.0;
    return (seranganSukses / totalSerangan) * 100;
  }

  /// Copy with new values
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
    return 'StatistikSerangan(total: $totalSerangan, sukses: $seranganSukses, gagal: $seranganGagal)';
  }
}
