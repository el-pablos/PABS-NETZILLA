import 'package:flutter/material.dart';
import '../models/models.dart';
import '../widgets/kartu_metode_serangan.dart';
import 'detail_serangan_screen.dart';

/// Halaman daftar metode serangan
class SeranganScreen extends StatefulWidget {
  const SeranganScreen({super.key});

  @override
  State<SeranganScreen> createState() => _SeranganScreenState();
}

class _SeranganScreenState extends State<SeranganScreen> {
  String _searchQuery = '';
  KategoriSerangan? _selectedCategory;
  List<MetodeSerangan> _filteredMethods = [];

  @override
  void initState() {
    super.initState();
    _filteredMethods = daftarMetodeSerangan;
  }

  /// Filter metode berdasarkan pencarian dan kategori
  void _filterMethods() {
    setState(() {
      _filteredMethods = daftarMetodeSerangan.where((metode) {
        final matchesSearch = _searchQuery.isEmpty ||
            metode.nama.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            metode.deskripsi.toLowerCase().contains(_searchQuery.toLowerCase());

        final matchesCategory = _selectedCategory == null ||
            metode.kategori == _selectedCategory;

        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  /// Handle pencarian
  void _onSearchChanged(String query) {
    _searchQuery = query;
    _filterMethods();
  }

  /// Handle filter kategori
  void _onCategoryChanged(KategoriSerangan? category) {
    _selectedCategory = category;
    _filterMethods();
  }

  /// Navigate ke detail serangan
  void _navigateToDetail(MetodeSerangan metode) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DetailSeranganScreen(metode: metode),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Metode Serangan'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Cari metode serangan...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceVariant,
              ),
            ),
          ),

          // Filter chips
          SizedBox(
            height: 60,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip('Semua', null),
                const SizedBox(width: 8),
                _buildFilterChip('TCP', KategoriSerangan.TCP),
                const SizedBox(width: 8),
                _buildFilterChip('ICMP', KategoriSerangan.ICMP),
                const SizedBox(width: 8),
                _buildFilterChip('Kustom', KategoriSerangan.KUSTOM),
                const SizedBox(width: 8),
                _buildFilterChip('ML Khusus', KategoriSerangan.ML_KHUSUS),
              ],
            ),
          ),

          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${_filteredMethods.length} metode ditemukan',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                if (_searchQuery.isNotEmpty || _selectedCategory != null)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _selectedCategory = null;
                        _filteredMethods = daftarMetodeSerangan;
                      });
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text('Reset'),
                  ),
              ],
            ),
          ),

          // Methods list
          Expanded(
            child: _filteredMethods.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: () async {
                      // Refresh methods if needed
                      await Future.delayed(const Duration(milliseconds: 500));
                      _filterMethods();
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: _filteredMethods.length,
                      itemBuilder: (context, index) {
                        final metode = _filteredMethods[index];
                        return KartuMetodeSerangan(
                          metode: metode,
                          onTap: () => _navigateToDetail(metode),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// Build filter chip
  Widget _buildFilterChip(String label, KategoriSerangan? category) {
    final isSelected = _selectedCategory == category;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        _onCategoryChanged(selected ? category : null);
      },
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada metode ditemukan',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coba ubah kata kunci pencarian atau filter',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _selectedCategory = null;
                _filteredMethods = daftarMetodeSerangan;
              });
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reset Filter'),
          ),
        ],
      ),
    );
  }

  /// Show info dialog
  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Informasi Metode Serangan'),
        content: const Text(
          'Pilih metode serangan yang sesuai dengan target Anda. '
          'Setiap metode memiliki karakteristik dan efektivitas yang berbeda.\n\n'
          '• TCP: Untuk serangan pada protokol TCP\n'
          '• ICMP: Untuk serangan ping flood\n'
          '• Kustom: Metode serangan khusus\n'
          '• ML Khusus: Optimized untuk server Mobile Legends',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }
}
