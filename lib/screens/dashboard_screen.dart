import 'package:flutter/material.dart';
import '../models/models.dart';
// import '../services/supabase_service.dart';
import '../widgets/optimized_widgets.dart';
import '../services/performance_service.dart';
import '../services/vps_server_service.dart';
import 'serangan_screen.dart';
import 'riwayat_screen.dart';

/// Dashboard utama aplikasi PABS-NETZILLA
class DashboardScreen extends OptimizedStatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends OptimizedState<DashboardScreen> {
  int _currentIndex = 0;
  StatistikSerangan _statistik = StatistikSerangan.kosong();
  bool _isLoading = true;
  // final SupabaseService _supabaseService = SupabaseService();

  final List<Widget> _screens = [
    const _DashboardContent(),
    const SeranganScreen(),
    const RiwayatScreen(),
  ];

  @override
  void onInitState() {
    _loadStatistik();
  }

  /// Load statistik dari database dengan data real-time
  Future<void> _loadStatistik() async {
    try {
      // Simulasi data real-time dari VPS servers
      final vpsService = VpsServerService();
      final servers = vpsService.servers;
      final activeServers = servers.where((s) => s.isActive).length;

      // Simulasi statistik real-time
      final now = DateTime.now();
      final statistik = StatistikSerangan(
        totalSerangan: servers.length * 5, // Simulasi berdasarkan jumlah server
        seranganSukses: (servers.length * 4.2).round(),
        seranganGagal: (servers.length * 0.8).round(),
        totalServer: servers.length,
        tingkatKeberhasilan: servers.isNotEmpty ? 84.5 : 0.0,
        totalUptime: Duration(hours: now.hour, minutes: now.minute),
      );

      optimizedSetState(() {
        _statistik = statistik;
        _isLoading = false;
      });
    } catch (e) {
      optimizedSetState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error memuat statistik: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      appBar: _currentIndex == 0
          ? AppBar(
              title: const Text('PABS-NETZILLA'),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadStatistik,
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    // TODO: Navigate to settings
                  },
                ),
              ],
            )
          : null,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _DashboardContent(
            statistik: _statistik,
            isLoading: _isLoading,
            onTabChange: (index) => setState(() => _currentIndex = index),
          ),
          const SeranganScreen(),
          const RiwayatScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(
            icon: Icon(Icons.security),
            label: 'Serangan',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  _currentIndex = 1; // Switch to Serangan tab
                });
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

/// Konten dashboard
class _DashboardContent extends StatelessWidget {
  final StatistikSerangan? statistik;
  final bool isLoading;
  final Function(int)? onTabChange;

  const _DashboardContent({
    this.statistik,
    this.isLoading = false,
    this.onTabChange,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final stats = statistik ?? StatistikSerangan.kosong();

    return RefreshIndicator(
      onRefresh: () async {
        // Refresh statistik
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      Icons.security,
                      size: 40,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selamat Datang!',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Sistem DDoS Testing siap digunakan',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Statistik cards
            Text(
              'Statistik Serangan',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _buildStatCard(
                  context,
                  'Serangan Aktif',
                  '0',
                  Icons.flash_on,
                  Colors.orange,
                ),
                _buildStatCard(
                  context,
                  'Tingkat Sukses',
                  '${stats.tingkatKeberhasilan.toStringAsFixed(1)}%',
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildStatCard(
                  context,
                  'Total Server',
                  '${stats.totalServer}',
                  Icons.dns,
                  Colors.blue,
                ),
                _buildStatCard(
                  context,
                  'Total Serangan',
                  '${stats.totalSerangan}',
                  Icons.timeline,
                  Colors.purple,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Quick actions
            Text(
              'Aksi Cepat',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.rocket_launch),
                    title: const Text('Serangan Cepat'),
                    subtitle: const Text(
                      'Mulai serangan dengan pengaturan default',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // Switch to attack tab
                      onTabChange?.call(1);
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.stop_circle),
                    title: const Text('Hentikan Semua'),
                    subtitle: const Text(
                      'Hentikan semua serangan yang berjalan',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      _showStopAllDialog(context);
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.dns),
                    title: const Text('Kelola VPS'),
                    subtitle: const Text('Manajemen server VPS untuk serangan'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.pushNamed(context, '/vps-management');
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.public),
                    title: const Text('Cek IP Address'),
                    subtitle: const Text('Informasi detail IP dan lokasi'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.pushNamed(context, '/ip-check');
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.analytics),
                    title: const Text('Lihat Laporan'),
                    subtitle: const Text('Analisis performa serangan'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // Switch to history/reports tab
                      onTabChange?.call(2);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // System status
            Text(
              'Status Sistem',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildStatusRow(
                      context,
                      'Koneksi Internet',
                      'Terhubung',
                      Icons.wifi,
                      Colors.green,
                    ),
                    const SizedBox(height: 12),
                    _buildStatusRow(
                      context,
                      'Server Pool',
                      'Online',
                      Icons.cloud,
                      Colors.green,
                    ),
                    const SizedBox(height: 12),
                    _buildStatusRow(
                      context,
                      'Database',
                      'Aktif',
                      Icons.storage,
                      Colors.green,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(
    BuildContext context,
    String label,
    String status,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  void _showStopAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hentikan Semua Serangan'),
        content: const Text(
          'Apakah Anda yakin ingin menghentikan semua serangan yang sedang berjalan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Stop all attacks
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hentikan'),
          ),
        ],
      ),
    );
  }
}
