import 'package:flutter/material.dart';
import '../models/models.dart';

/// Widget kartu untuk menampilkan metode serangan
class KartuMetodeSerangan extends StatelessWidget {
  final MetodeSerangan metode;
  final VoidCallback onTap;

  const KartuMetodeSerangan({
    super.key,
    required this.metode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header dengan ikon dan nama
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(
                        metode.kategori,
                      ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      metode.ikon,
                      size: 24,
                      color: _getCategoryColor(metode.kategori),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          metode.nama,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getCategoryDisplayName(metode.kategori),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: _getCategoryColor(metode.kategori),
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Deskripsi
              Text(
                metode.deskripsi,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // Chip mode dan fitur
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (metode.mendukungPPS)
                    _buildFeatureChip(
                      context,
                      'PPS',
                      Icons.speed,
                      Colors.green,
                    ),
                  if (metode.mendukungGBPS)
                    _buildFeatureChip(
                      context,
                      'GBPS',
                      Icons.network_check,
                      Colors.blue,
                    ),
                  if (metode.membutuhkanPort)
                    _buildFeatureChip(
                      context,
                      'Port Required',
                      Icons.settings_ethernet,
                      Colors.orange,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build feature chip
  Widget _buildFeatureChip(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Get color based on category
  Color _getCategoryColor(KategoriSerangan kategori) {
    switch (kategori) {
      case KategoriSerangan.tcp:
        return Colors.blue;
      case KategoriSerangan.icmp:
        return Colors.green;
      case KategoriSerangan.kustom:
        return Colors.purple;
      case KategoriSerangan.mlKhusus:
        return Colors.red;
    }
  }

  /// Get display name for category
  String _getCategoryDisplayName(KategoriSerangan kategori) {
    switch (kategori) {
      case KategoriSerangan.tcp:
        return 'TCP Protocol';
      case KategoriSerangan.icmp:
        return 'ICMP Protocol';
      case KategoriSerangan.kustom:
        return 'Custom Method';
      case KategoriSerangan.mlKhusus:
        return 'Mobile Legends';
    }
  }
}
