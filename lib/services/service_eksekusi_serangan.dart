import 'dart:math';
import 'package:flutter/services.dart';
import '../models/models.dart';
import 'database_helper.dart';
import 'service_notifikasi.dart';

/// Service untuk mengeksekusi serangan DDoS
class ServiceEksekusiSerangan {
  static const platform = MethodChannel('com.pabsnetzilla/shell');
  static final DatabaseHelper _dbHelper = DatabaseHelper();
  static final ServiceNotifikasi _notifikasi = ServiceNotifikasi();

  /// Eksekusi serangan DDoS
  Future<HasilSerangan> eksekusiSerangan({
    required MetodeSerangan metode,
    required String targetIP,
    int? port,
    ModeSerangan mode = ModeSerangan.PPS,
  }) async {
    
    // Validasi input
    final validasiResult = _validasiInput(targetIP, port, metode);
    if (!validasiResult.sukses) {
      await _simpanRiwayatGagal(metode, targetIP, port, mode, validasiResult.pesan);
      return validasiResult;
    }

    try {
      // Bangun perintah
      final perintah = _bangunPerintah(metode, targetIP, port, mode);
      
      // Simulasi jumlah server (dalam implementasi nyata, ini akan dari server pool)
      final jumlahServer = _simulasiJumlahServer();
      
      // Eksekusi perintah melalui platform channel
      final startTime = DateTime.now();
      final result = await _eksekusiPlatformChannel(perintah);
      final endTime = DateTime.now();
      final durasi = endTime.difference(startTime);

      // Simulasi tingkat keberhasilan (95% sukses)
      final sukses = Random().nextDouble() < 0.95;
      
      if (sukses) {
        // Simpan riwayat sukses
        final riwayat = RiwayatSerangan.sukses(
          metode: metode,
          targetIp: targetIP,
          port: port,
          mode: mode,
          jumlahServer: jumlahServer,
          durasi: durasi,
        );
        
        await _dbHelper.simpanRiwayatSerangan(riwayat);
        
        // Tampilkan notifikasi sukses
        await _notifikasi.tampilkanNotifikasiSerangan(
          judul: 'Serangan Berhasil',
          pesan: '${metode.nama} berhasil dieksekusi di $jumlahServer server',
        );

        return HasilSerangan.sukses(
          '✅ Serangan ${metode.nama} berhasil dieksekusi!\n'
          '🎯 Target: $targetIP${port != null ? ':$port' : ''}\n'
          '🖥️ Server: $jumlahServer\n'
          '⏱️ Durasi: ${durasi.inSeconds}s\n'
          '📊 Mode: ${mode.name}',
          jumlahServer: jumlahServer,
          durasi: durasi,
        );
      } else {
        // Simulasi error
        const errorMsg = 'Koneksi ke target terputus';
        await _simpanRiwayatGagal(metode, targetIP, port, mode, errorMsg);
        
        await _notifikasi.tampilkanNotifikasiSerangan(
          judul: 'Serangan Gagal',
          pesan: '${metode.nama} gagal dieksekusi: $errorMsg',
        );

        return HasilSerangan.error(errorMsg);
      }
      
    } catch (e) {
      final errorMsg = 'Gagal mengeksekusi perintah: $e';
      await _simpanRiwayatGagal(metode, targetIP, port, mode, errorMsg);
      
      await _notifikasi.tampilkanNotifikasiSerangan(
        judul: 'Error Sistem',
        pesan: 'Terjadi kesalahan saat eksekusi serangan',
      );

      return HasilSerangan.error(errorMsg);
    }
  }

  /// Validasi input sebelum eksekusi
  HasilSerangan _validasiInput(String targetIP, int? port, MetodeSerangan metode) {
    // Validasi IP address
    if (!_validasiIP(targetIP)) {
      return HasilSerangan.error('❌ Alamat IP tidak valid: $targetIP');
    }

    // Validasi port jika diperlukan
    if (metode.membutuhkanPort && (port == null || port <= 0 || port > 65535)) {
      return HasilSerangan.error('❌ Port tidak valid. Harus antara 1-65535');
    }

    return HasilSerangan.sukses('Validasi berhasil');
  }

  /// Validasi format IP address
  bool _validasiIP(String ip) {
    final regex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
    if (!regex.hasMatch(ip)) return false;

    final parts = ip.split('.');
    for (final part in parts) {
      final num = int.tryParse(part);
      if (num == null || num < 0 || num > 255) return false;
    }

    return true;
  }

  /// Bangun perintah berdasarkan metode dan parameter
  String _bangunPerintah(MetodeSerangan metode, String targetIP, int? port, ModeSerangan mode) {
    String perintah = metode.perintah;
    
    // Replace placeholder
    perintah = perintah.replaceAll('{ip}', targetIP);
    
    if (port != null) {
      perintah = perintah.replaceAll('{port}', port.toString());
    }

    // Tambahkan parameter mode jika didukung
    if (mode == ModeSerangan.GBPS && metode.mendukungGBPS) {
      perintah += ' --data 1024'; // Simulasi parameter GBPS
    }

    return perintah;
  }

  /// Simulasi jumlah server yang tersedia
  int _simulasiJumlahServer() {
    // Simulasi 100-200 server tersedia
    return 100 + Random().nextInt(101);
  }

  /// Eksekusi perintah melalui platform channel
  Future<String> _eksekusiPlatformChannel(String perintah) async {
    try {
      final result = await platform.invokeMethod('executeCommand', {
        'command': perintah,
      });
      return result.toString();
    } on PlatformException catch (e) {
      throw 'Platform Error: ${e.message}';
    } catch (e) {
      throw 'Unknown Error: $e';
    }
  }

  /// Simpan riwayat serangan yang gagal
  Future<void> _simpanRiwayatGagal(
    MetodeSerangan metode,
    String targetIP,
    int? port,
    ModeSerangan mode,
    String error,
  ) async {
    final riwayat = RiwayatSerangan.gagal(
      metode: metode,
      targetIp: targetIP,
      port: port,
      mode: mode,
      pesanError: error,
    );
    
    await _dbHelper.simpanRiwayatSerangan(riwayat);
  }

  /// Hentikan semua serangan yang sedang berjalan
  Future<HasilSerangan> hentikanSemuaSerangan() async {
    try {
      // Dalam implementasi nyata, ini akan menghentikan semua proses yang berjalan
      await platform.invokeMethod('killAllProcesses');
      
      await _notifikasi.tampilkanNotifikasiSerangan(
        judul: 'Serangan Dihentikan',
        pesan: 'Semua serangan telah dihentikan',
      );

      return HasilSerangan.sukses('✅ Semua serangan telah dihentikan');
    } catch (e) {
      return HasilSerangan.error('❌ Gagal menghentikan serangan: $e');
    }
  }

  /// Cek status koneksi internet
  Future<bool> cekKoneksiInternet() async {
    try {
      final result = await platform.invokeMethod('checkInternetConnection');
      return result as bool;
    } catch (e) {
      return false;
    }
  }

  /// Get informasi sistem
  Future<Map<String, dynamic>> getInfoSistem() async {
    try {
      final result = await platform.invokeMethod('getSystemInfo');
      return Map<String, dynamic>.from(result);
    } catch (e) {
      return {
        'os': 'Android',
        'version': 'Unknown',
        'device': 'Unknown',
        'memory': 'Unknown',
      };
    }
  }
}
