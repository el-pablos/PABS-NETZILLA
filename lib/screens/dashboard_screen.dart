import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/services.dart';
import 'serangan_screen.dart';
import 'riwayat_screen.dart';

/// Dashboard utama aplikasi PABS-NETZILLA
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  StatistikSerangan _statistik = StatistikSerangan.kosong();
  bool _isLoading = true;

  final List<Widget> _screens = [
    const _DashboardContent(),
    const SeranganScreen(),
    const RiwayatScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadStatistik();
  }

  /// Load statistik dari database
  Future<void> _loadStatistik() async {
    try {
      final dbHelper = DatabaseHelper();
      final statistik = await dbHelper.ambilStatistik();

      if (mounted) {
        setState(() {
          _statistik = statistik;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
          _DashboardContent(statistik: _statistik, isLoading: _isLoading),
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

  const _DashboardContent({this.statistik, this.isLoading = false});

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
              childAspectRatio: 1.2,
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
                      // TODO: Quick attack
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
                    leading: const Icon(Icons.analytics),
                    title: const Text('Lihat Laporan'),
                    subtitle: const Text('Analisis performa serangan'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // TODO: Show reports
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
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
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
