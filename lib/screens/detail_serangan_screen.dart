import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../services/services.dart';

/// Halaman detail dan konfigurasi serangan
class DetailSeranganScreen extends StatefulWidget {
  final MetodeSerangan metode;

  const DetailSeranganScreen({
    super.key,
    required this.metode,
  });

  @override
  State<DetailSeranganScreen> createState() => _DetailSeranganScreenState();
}

class _DetailSeranganScreenState extends State<DetailSeranganScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ipController = TextEditingController();
  final _portController = TextEditingController();
  
  ModeSerangan _selectedMode = ModeSerangan.PPS;
  bool _isLoading = false;

  final ServiceEksekusiSerangan _seranganService = ServiceEksekusiSerangan();

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  /// Validasi IP address
  String? _validateIP(String? value) {
    if (value == null || value.isEmpty) {
      return 'IP address tidak boleh kosong';
    }

    final regex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
    if (!regex.hasMatch(value)) {
      return 'Format IP address tidak valid';
    }

    final parts = value.split('.');
    for (final part in parts) {
      final num = int.tryParse(part);
      if (num == null || num < 0 || num > 255) {
        return 'IP address tidak valid (0-255)';
      }
    }

    return null;
  }

  /// Validasi port
  String? _validatePort(String? value) {
    if (!widget.metode.membutuhkanPort) return null;
    
    if (value == null || value.isEmpty) {
      return 'Port tidak boleh kosong';
    }

    final port = int.tryParse(value);
    if (port == null || port <= 0 || port > 65535) {
      return 'Port harus antara 1-65535';
    }

    return null;
  }

  /// Eksekusi serangan
  Future<void> _eksekusiSerangan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final targetIP = _ipController.text.trim();
      final port = widget.metode.membutuhkanPort 
          ? int.tryParse(_portController.text.trim())
          : null;

      final hasil = await _seranganService.eksekusiSerangan(
        metode: widget.metode,
        targetIP: targetIP,
        port: port,
        mode: _selectedMode,
      );

      if (mounted) {
        _showResultDialog(hasil);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Show result dialog
  void _showResultDialog(HasilSerangan hasil) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              hasil.sukses ? Icons.check_circle : Icons.error,
              color: hasil.sukses ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(hasil.sukses ? 'Berhasil' : 'Gagal'),
          ],
        ),
        content: Text(hasil.pesan),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (hasil.sukses) {
                Navigator.of(context).pop(); // Back to serangan screen
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.metode.nama),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            widget.metode.ikon,
                            size: 32,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.metode.nama,
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.metode.deskripsi,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Configuration section
              Text(
                'Konfigurasi Serangan',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // IP Address input
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Target IP Address',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _ipController,
                        validator: _validateIP,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                        decoration: InputDecoration(
                          hintText: 'Contoh: 192.168.1.1',
                          prefixIcon: const Icon(Icons.language),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Port input (if required)
              if (widget.metode.membutuhkanPort)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Port Target',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _portController,
                          validator: _validatePort,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            hintText: 'Contoh: 80, 443, 8080',
                            prefixIcon: const Icon(Icons.settings_ethernet),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (widget.metode.membutuhkanPort) const SizedBox(height: 12),

              // Mode selection
              if (widget.metode.mendukungPPS || widget.metode.mendukungGBPS)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mode Serangan',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (widget.metode.mendukungPPS)
                          RadioListTile<ModeSerangan>(
                            title: const Text('PPS (Packets Per Second)'),
                            subtitle: const Text('Fokus pada jumlah paket per detik'),
                            value: ModeSerangan.PPS,
                            groupValue: _selectedMode,
                            onChanged: (value) {
                              setState(() {
                                _selectedMode = value!;
                              });
                            },
                          ),
                        if (widget.metode.mendukungGBPS)
                          RadioListTile<ModeSerangan>(
                            title: const Text('GBPS (Gigabits Per Second)'),
                            subtitle: const Text('Fokus pada bandwidth maksimal'),
                            value: ModeSerangan.GBPS,
                            groupValue: _selectedMode,
                            onChanged: (value) {
                              setState(() {
                                _selectedMode = value!;
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Launch button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _eksekusiSerangan,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.rocket_launch),
                  label: Text(_isLoading ? 'Meluncurkan...' : 'Luncurkan Serangan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Warning card
              Card(
                color: Colors.orange.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Gunakan tool ini hanya untuk testing keamanan pada sistem yang Anda miliki atau dengan izin eksplisit.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
