import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../../../core/theme/app_theme.dart';

class EvacuationCentersPage extends StatelessWidget {
  const EvacuationCentersPage({super.key});

  Future<void> _openMap(BuildContext context, String name, String query) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}';
    try {
      if (await canLaunchUrlString(url)) {
        await launchUrlString(url);
      } else {
        throw 'Perangkat tidak mendukung pembukaan peta.';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka peta untuk $name: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final centers = [
      {
        'name': 'Pusat Koordinasi BPBD Kota Medan',
        'address': 'Jl. Rotan Baru No.21, Petisah Tengah, Kec. Medan Petisah',
        'status': 'Pusat Utama',
        'statusColor': Colors.blue,
        'query': 'BPBD Kota Medan Jl. Rotan Baru No.21',
      },
      {
        'name': 'Posko Kecamatan Medan Baru',
        'address': 'Kantor Camat Medan Baru, Jl. Camat No.1, Padang Bulan',
        'status': 'Aktif',
        'statusColor': Colors.green,
        'query': 'Kantor Camat Medan Baru',
      },
      {
        'name': 'GOR Badminton PBSI Sumut',
        'address': 'Jl. Sutomo No.4, Gaharu, Kec. Medan Timur',
        'status': 'Aktif',
        'statusColor': Colors.green,
        'query': 'GOR PBSI Sumut Jl. Sutomo',
      },
      {
        'name': 'Posko Evakuasi Kelurahan Aur',
        'address': 'Kantor Lurah Aur, Jl. Brigjend Katamso, Kec. Medan Maimun',
        'status': 'Aktif (Dekat Sungai Deli)',
        'statusColor': Colors.green,
        'query': 'Kantor Lurah Aur Medan',
      },
      {
        'name': 'Gelanggang Remaja Medan',
        'address': 'Jl. Sutomo Ujung, Kec. Medan Timur',
        'status': 'Siaga',
        'statusColor': Colors.orange,
        'query': 'Gelanggang Remaja Medan',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Posko Evakuasi'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Premium Info Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade700, Colors.teal.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.2),
                      blurRadius: 16,
                      spreadRadius: 2,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.white24,
                      child: Icon(LucideIcons.home, color: Colors.white, size: 26),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lokasi Pengungsian',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Berikut adalah lokasi posko evakuasi bencana banjir resmi yang dibuka untuk warga Kota Medan.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12.5,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Titik Posko Evakuasi Terdekat',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...centers.map((center) {
                final name = center['name'] as String;
                final address = center['address'] as String;
                final status = center['status'] as String;
                final statusColor = center['statusColor'] as Color;
                final query = center['query'] as String;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(LucideIcons.mapPin, color: AppColors.safe, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      status.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w900,
                                        color: statusColor,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          address,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1, color: Color(0xFFEFF2F6)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _openMap(context, name, query),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(LucideIcons.navigation, size: 16, color: Color(0xFF475569)),
                                    SizedBox(width: 8),
                                    Text(
                                      'Petunjuk Rute Peta',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF475569),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
