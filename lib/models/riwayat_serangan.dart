import 'package:uuid/uuid.dart';
import 'metode_serangan.dart';

/// Model untuk riwayat serangan yang disimpan di database
class RiwayatSerangan {
  final String id;
  final String metodeId;
  final String namaMetode;
  final String targetIp;
  final int? port;
  final ModeSerangan mode;
  final int jumlahServer;
  final bool sukses;
  final DateTime timestamp;
  final Duration? durasi;
  final String? pesanError;

  RiwayatSerangan({
    String? id,
    required this.metodeId,
    required this.namaMetode,
    required this.targetIp,
    this.port,
    required this.mode,
    required this.jumlahServer,
    required this.sukses,
    DateTime? timestamp,
    this.durasi,
    this.pesanError,
  }) : id = id ?? const Uuid().v4(),
       timestamp = timestamp ?? DateTime.now();

  /// Factory constructor untuk membuat riwayat dari serangan yang sukses
  factory RiwayatSerangan.sukses({
    required MetodeSerangan metode,
    required String targetIp,
    int? port,
    required ModeSerangan mode,
    required int jumlahServer,
    Duration? durasi,
  }) {
    return RiwayatSerangan(
      metodeId: metode.id,
      namaMetode: metode.nama,
      targetIp: targetIp,
      port: port,
      mode: mode,
      jumlahServer: jumlahServer,
      sukses: true,
      durasi: durasi,
    );
  }

  /// Factory constructor untuk membuat riwayat dari serangan yang gagal
  factory RiwayatSerangan.gagal({
    required MetodeSerangan metode,
    required String targetIp,
    int? port,
    required ModeSerangan mode,
    required String pesanError,
  }) {
    return RiwayatSerangan(
      metodeId: metode.id,
      namaMetode: metode.nama,
      targetIp: targetIp,
      port: port,
      mode: mode,
      jumlahServer: 0,
      sukses: false,
      pesanError: pesanError,
    );
  }

  /// Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'metode_id': metodeId,
      'nama_metode': namaMetode,
      'target_ip': targetIp,
      'port': port,
      'mode': mode.name,
      'jumlah_server': jumlahServer,
      'sukses': sukses ? 1 : 0,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'durasi': durasi?.inMilliseconds,
      'pesan_error': pesanError,
    };
  }

  /// Create from Map for database retrieval
  factory RiwayatSerangan.fromMap(Map<String, dynamic> map) {
    return RiwayatSerangan(
      id: map['id'] ?? '',
      metodeId: map['metode_id'] ?? '',
      namaMetode: map['nama_metode'] ?? '',
      targetIp: map['target_ip'] ?? '',
      port: map['port'],
      mode: ModeSerangan.values.firstWhere(
        (e) => e.name == map['mode'],
        orElse: () => ModeSerangan.PPS,
      ),
      jumlahServer: map['jumlah_server'] ?? 0,
      sukses: (map['sukses'] ?? 0) == 1,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      durasi: map['durasi'] != null ? Duration(milliseconds: map['durasi']) : null,
      pesanError: map['pesan_error'],
    );
  }

  /// Get formatted timestamp
  String get timestampFormatted {
    return '${timestamp.day.toString().padLeft(2, '0')}/'
           '${timestamp.month.toString().padLeft(2, '0')}/'
           '${timestamp.year} '
           '${timestamp.hour.toString().padLeft(2, '0')}:'
           '${timestamp.minute.toString().padLeft(2, '0')}';
  }

  /// Get formatted duration
  String get durasiFormatted {
    if (durasi == null) return '-';
    
    final minutes = durasi!.inMinutes;
    final seconds = durasi!.inSeconds % 60;
    
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  /// Get status text
  String get statusText {
    return sukses ? 'Berhasil' : 'Gagal';
  }

  /// Get target display text
  String get targetDisplay {
    if (port != null) {
      return '$targetIp:$port';
    }
    return targetIp;
  }

  /// Get mode display text
  String get modeDisplay {
    switch (mode) {
      case ModeSerangan.PPS:
        return 'PPS';
      case ModeSerangan.GBPS:
        return 'GBPS';
    }
  }

  @override
  String toString() {
    return 'RiwayatSerangan(id: $id, metode: $namaMetode, target: $targetIp, sukses: $sukses)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RiwayatSerangan && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
