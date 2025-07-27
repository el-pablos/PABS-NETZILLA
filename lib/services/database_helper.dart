import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/models.dart';

/// Helper class untuk mengelola database SQLite
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  /// Getter untuk database instance
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Inisialisasi database
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'pabs_netzilla.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Membuat tabel saat database pertama kali dibuat
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE riwayat_serangan (
        id TEXT PRIMARY KEY,
        metode_id TEXT NOT NULL,
        nama_metode TEXT NOT NULL,
        target_ip TEXT NOT NULL,
        port INTEGER,
        mode TEXT NOT NULL,
        jumlah_server INTEGER NOT NULL,
        sukses INTEGER NOT NULL,
        timestamp INTEGER NOT NULL,
        durasi INTEGER,
        pesan_error TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE statistik (
        id INTEGER PRIMARY KEY,
        total_serangan INTEGER NOT NULL DEFAULT 0,
        serangan_sukses INTEGER NOT NULL DEFAULT 0,
        serangan_gagal INTEGER NOT NULL DEFAULT 0,
        total_server INTEGER NOT NULL DEFAULT 150,
        tingkat_keberhasilan REAL NOT NULL DEFAULT 0.0,
        total_uptime INTEGER NOT NULL DEFAULT 0,
        last_updated INTEGER NOT NULL
      )
    ''');

    // Insert default statistik
    await db.insert('statistik', {
      'id': 1,
      'total_serangan': 0,
      'serangan_sukses': 0,
      'serangan_gagal': 0,
      'total_server': 150,
      'tingkat_keberhasilan': 0.0,
      'total_uptime': 0,
      'last_updated': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Upgrade database jika diperlukan
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
    if (oldVersion < 2) {
      // Add new columns or tables for version 2
    }
  }

  /// Simpan riwayat serangan ke database
  Future<void> simpanRiwayatSerangan(RiwayatSerangan riwayat) async {
    final db = await database;
    
    await db.transaction((txn) async {
      // Insert riwayat serangan
      await txn.insert(
        'riwayat_serangan',
        riwayat.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Update statistik
      await _updateStatistik(txn, riwayat.sukses);
    });
  }

  /// Update statistik setelah serangan
  Future<void> _updateStatistik(Transaction txn, bool sukses) async {
    final statistik = await txn.query('statistik', where: 'id = ?', whereArgs: [1]);
    
    if (statistik.isNotEmpty) {
      final current = statistik.first;
      final totalSerangan = (current['total_serangan'] as int) + 1;
      final seranganSukses = (current['serangan_sukses'] as int) + (sukses ? 1 : 0);
      final seranganGagal = (current['serangan_gagal'] as int) + (sukses ? 0 : 1);
      final tingkatKeberhasilan = totalSerangan > 0 ? (seranganSukses / totalSerangan) * 100 : 0.0;

      await txn.update(
        'statistik',
        {
          'total_serangan': totalSerangan,
          'serangan_sukses': seranganSukses,
          'serangan_gagal': seranganGagal,
          'tingkat_keberhasilan': tingkatKeberhasilan,
          'last_updated': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [1],
      );
    }
  }

  /// Ambil semua riwayat serangan
  Future<List<RiwayatSerangan>> ambilSemuaRiwayat() async {
    final db = await database;
    final maps = await db.query(
      'riwayat_serangan',
      orderBy: 'timestamp DESC',
    );
    
    return List.generate(maps.length, (i) => RiwayatSerangan.fromMap(maps[i]));
  }

  /// Ambil riwayat serangan dengan limit
  Future<List<RiwayatSerangan>> ambilRiwayatDenganLimit(int limit) async {
    final db = await database;
    final maps = await db.query(
      'riwayat_serangan',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    
    return List.generate(maps.length, (i) => RiwayatSerangan.fromMap(maps[i]));
  }

  /// Ambil riwayat berdasarkan metode
  Future<List<RiwayatSerangan>> ambilRiwayatBerdasarkanMetode(String metodeId) async {
    final db = await database;
    final maps = await db.query(
      'riwayat_serangan',
      where: 'metode_id = ?',
      whereArgs: [metodeId],
      orderBy: 'timestamp DESC',
    );
    
    return List.generate(maps.length, (i) => RiwayatSerangan.fromMap(maps[i]));
  }

  /// Ambil statistik serangan
  Future<StatistikSerangan> ambilStatistik() async {
    final db = await database;
    final maps = await db.query('statistik', where: 'id = ?', whereArgs: [1]);
    
    if (maps.isNotEmpty) {
      final map = maps.first;
      return StatistikSerangan(
        totalSerangan: map['total_serangan'] as int,
        seranganSukses: map['serangan_sukses'] as int,
        seranganGagal: map['serangan_gagal'] as int,
        totalServer: map['total_server'] as int,
        tingkatKeberhasilan: map['tingkat_keberhasilan'] as double,
        totalUptime: Duration(milliseconds: map['total_uptime'] as int),
      );
    }
    
    return StatistikSerangan.kosong();
  }

  /// Hapus riwayat serangan berdasarkan ID
  Future<void> hapusRiwayat(String id) async {
    final db = await database;
    await db.delete(
      'riwayat_serangan',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Hapus semua riwayat serangan
  Future<void> hapusSemuaRiwayat() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('riwayat_serangan');
      
      // Reset statistik
      await txn.update(
        'statistik',
        {
          'total_serangan': 0,
          'serangan_sukses': 0,
          'serangan_gagal': 0,
          'tingkat_keberhasilan': 0.0,
          'last_updated': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [1],
      );
    });
  }

  /// Tutup database
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
