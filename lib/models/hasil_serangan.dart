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
  factory HasilSerangan.sukses(
    String pesan, {
    int? jumlahServer,
    Duration? durasi,
  }) {
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
      durasi: map['durasi'] != null
          ? Duration(milliseconds: map['durasi'])
          : null,
    );
  }

  @override
  String toString() {
    return 'HasilSerangan(sukses: $sukses, pesan: $pesan, timestamp: $timestamp)';
  }
}
