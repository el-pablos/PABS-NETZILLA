# 📱 PABS-NETZILLA - Aplikasi Android DDoS Testing Tool

![PABS-NETZILLA Logo](https://img.shields.io/badge/PABS--NETZILLA-v1.0.0-green?style=for-the-badge&logo=android)

## 🎯 Deskripsi Proyek

**PABS-NETZILLA** adalah aplikasi Android native yang dibangun menggunakan Flutter untuk melakukan testing keamanan DDoS (Distributed Denial of Service). Aplikasi ini menggantikan bot WhatsApp dengan interface mobile yang user-friendly dan responsif.

## ✨ Fitur Utama

### 🏠 Dashboard
- **Splash Screen** dengan animasi loading Flutter
- **Statistik Real-time** (Serangan aktif, Tingkat keberhasilan, Total server)
- **Quick Actions** untuk serangan cepat
- **Status Sistem** monitoring

### ⚔️ Metode Serangan
- **ML Stresser** - Khusus untuk server Mobile Legends
- **TCP SYN Flood** - Serangan TCP SYN flood
- **TCP ACK Flood** - Bypass firewall dengan ACK flood
- **ICMP Flood** - Ping flood untuk menghabiskan bandwidth
- **UDP Flood** - Serangan UDP flood
- **Slowloris** - Slow HTTP attack
- **HTTP GET Flood** - Web server flooding
- **DNS Amplification** - DNS amplification attack

### 📊 Riwayat & Analytics
- **Database SQLite** untuk menyimpan riwayat serangan
- **Filter berdasarkan status** (Berhasil/Gagal)
- **Statistik detail** dengan grafik performa
- **Export/Import** data riwayat

### 🔔 Notifikasi
- **Real-time notifications** untuk status serangan
- **Background service** monitoring
- **Custom notification channels**

## 🛠️ Teknologi yang Digunakan

### Frontend (Flutter)
```yaml
dependencies:
  flutter: sdk: flutter
  cupertino_icons: ^1.0.8
  http: ^1.1.0
  connectivity_plus: ^5.0.2
  sqflite: ^2.3.0
  path: ^1.8.3
  provider: ^6.1.1
  shared_preferences: ^2.2.2
  permission_handler: ^11.2.0
  uuid: ^4.2.1
  intl: ^0.19.0
```

### Backend (Android Native)
- **Kotlin** untuk platform channel
- **Android SDK** untuk system integration
- **SQLite** untuk local database

## 📱 Struktur Aplikasi

```
lib/
├── main.dart                 # Entry point aplikasi
├── models/                   # Data models
│   ├── metode_serangan.dart
│   ├── hasil_serangan.dart
│   └── riwayat_serangan.dart
├── services/                 # Business logic
│   ├── database_helper.dart
│   ├── service_eksekusi_serangan.dart
│   └── service_notifikasi.dart
├── screens/                  # UI Screens
│   ├── splash_screen.dart
│   ├── dashboard_screen.dart
│   ├── serangan_screen.dart
│   ├── detail_serangan_screen.dart
│   └── riwayat_screen.dart
└── widgets/                  # Reusable widgets
    └── kartu_metode_serangan.dart
```

## 🚀 Instalasi & Setup

### Prerequisites
- Flutter SDK (>=3.0.0)
- Android Studio / VS Code
- Android SDK (API level 21+)
- Device Android atau Emulator

### Langkah Instalasi

1. **Clone Repository**
```bash
git clone https://github.com/your-repo/pabs-netzilla.git
cd pabs-netzilla
```

2. **Install Dependencies**
```bash
flutter pub get
```

3. **Setup Android Permissions**
Pastikan permissions berikut ada di `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

4. **Build & Run**
```bash
# Debug mode
flutter run

# Release mode
flutter build apk --release
```

## 🎮 Cara Penggunaan

### 1. Splash Screen
- Aplikasi akan menampilkan logo PABS-NETZILLA
- Loading animation selama 3 detik
- Auto-initialization services

### 2. Dashboard
- Lihat statistik serangan real-time
- Akses quick actions
- Monitor status sistem

### 3. Pilih Metode Serangan
- Browse daftar metode yang tersedia
- Filter berdasarkan kategori (TCP, ICMP, Custom, ML Khusus)
- Search metode tertentu

### 4. Konfigurasi Serangan
- Input target IP address
- Set port (jika diperlukan)
- Pilih mode (PPS/GBPS)
- Launch attack

### 5. Monitor Hasil
- Real-time status updates
- Notifikasi hasil serangan
- Simpan ke riwayat otomatis

## 🔧 Platform Channel (Android)

### Method Channels
```kotlin
// MainActivity.kt
private val CHANNEL = "com.pabsnetzilla/shell"

// Available methods:
- executeCommand(command: String)
- checkInternetConnection()
- getSystemInfo()
- killAllProcesses()
```

### Simulasi Eksekusi
Untuk keamanan, aplikasi menggunakan simulasi eksekusi command:
- **hping3** commands → Simulated packet flooding
- **ping** commands → Simulated connectivity test
- **curl** commands → Simulated HTTP requests
- **dig** commands → Simulated DNS queries

## 📊 Database Schema

### Tabel `riwayat_serangan`
```sql
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
);
```

### Tabel `statistik`
```sql
CREATE TABLE statistik (
  id INTEGER PRIMARY KEY,
  total_serangan INTEGER NOT NULL DEFAULT 0,
  serangan_sukses INTEGER NOT NULL DEFAULT 0,
  serangan_gagal INTEGER NOT NULL DEFAULT 0,
  total_server INTEGER NOT NULL DEFAULT 150,
  tingkat_keberhasilan REAL NOT NULL DEFAULT 0.0,
  total_uptime INTEGER NOT NULL DEFAULT 0,
  last_updated INTEGER NOT NULL
);
```

## 🎨 Design System

### Material Design 3
- **Dark Theme** dengan green accent
- **Card-based UI** untuk better organization
- **Consistent spacing** dan typography
- **Responsive layout** untuk berbagai screen size

### Color Scheme
- **Primary**: Green (#4CAF50)
- **Secondary**: Blue (#2196F3)
- **Error**: Red (#F44336)
- **Warning**: Orange (#FF9800)

## ⚠️ Disclaimer & Legal

**PENTING**: Aplikasi ini dibuat khusus untuk:
- ✅ **Testing keamanan** pada sistem yang Anda miliki
- ✅ **Penetration testing** dengan izin eksplisit
- ✅ **Educational purposes** dan research
- ❌ **TIDAK untuk serangan ilegal** atau merusak sistem orang lain

### Tanggung Jawab Pengguna
- Gunakan hanya pada sistem yang Anda miliki atau dengan izin tertulis
- Patuhi hukum dan regulasi setempat
- Developer tidak bertanggung jawab atas penyalahgunaan aplikasi

## 🤝 Contributing

1. Fork repository
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

## 👨‍💻 Developer

**PABS-NETZILLA Team**
- 📧 Email: contact@pabs-netzilla.com
- 🌐 Website: https://pabs-netzilla.com
- 📱 Version: 1.0.0

---

**Made with ❤️ for cybersecurity testing and education**
