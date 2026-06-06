import 'package:sistem_peringatan_banjir_berbasis_komunitas/core/utils/error_handler.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../../../core/theme/app_theme.dart';

class EmergencyContactsPage extends StatelessWidget {
  const EmergencyContactsPage({super.key});

  Future<void> _makeCall(BuildContext context, String name, String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    final url = 'tel:$cleanNumber';
    try {
      if (await canLaunchUrlString(url)) {
        await launchUrlString(url);
      } else {
        throw 'Perangkat tidak mendukung panggilan telepon.';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghubungi $name: ${AppError.toMessage(e)}'),
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
    final contacts = [
      {
        'name': 'BPBD Kota Medan',
        'desc': 'Badan Penanggulangan Bencana Daerah',
        'number': '(061) 4556488',
        'icon': LucideIcons.shieldAlert,
        'color': Colors.red,
      },
      {
        'name': 'BASARNAS (Tim SAR) Medan',
        'desc': 'Pencarian dan Penyelamatan Korban',
        'number': '(061) 8222922',
        'icon': LucideIcons.search,
        'color': Colors.orange,
      },
      {
        'name': 'Panggilan Darurat Medis / Ambulans',
        'desc': 'Layanan Ambulans & Medis Gawat Darurat',
        'number': '119',
        'icon': LucideIcons.heartPulse,
        'color': Colors.pink,
      },
      {
        'name': 'Palang Merah Indonesia (PMI) Medan',
        'desc': 'Bantuan Kemanusiaan & Donor Darah',
        'number': '(061) 4567400',
        'icon': LucideIcons.droplet,
        'color': Colors.redAccent,
      },
      {
        'name': 'Pemadam Kebakaran Medan',
        'desc': 'Penyelamatan & Pemadam Kebakaran',
        'number': '(061) 4515350',
        'icon': LucideIcons.flame,
        'color': Colors.deepOrange,
      },
      {
        'name': 'Polrestabes Medan',
        'desc': 'Layanan Keamanan & Ketertiban',
        'number': '110',
        'icon': LucideIcons.phoneCall,
        'color': Colors.blue,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kontak Darurat'),
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
                    colors: [Colors.red.shade700, Colors.orange.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.2),
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
                      child: Icon(LucideIcons.phoneCall, color: Colors.white, size: 26),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Panggilan Darurat',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Hubungi instansi penyelamat di bawah ini jika Anda memerlukan evakuasi atau bantuan medis segera.',
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
                  'Instansi Penyelamat Kota Medan',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...contacts.map((contact) {
                final name = contact['name'] as String;
                final desc = contact['desc'] as String;
                final number = contact['number'] as String;
                final icon = contact['icon'] as IconData;
                final color = contact['color'] as Color;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: InkWell(
                    onTap: () => _makeCall(context, name, number),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: color, size: 24),
                          ),
                          const SizedBox(width: 16),
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
                                Text(
                                  desc,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  number,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.primary.withOpacity(0.06),
                            child: const Icon(
                              LucideIcons.chevronRight,
                              color: AppColors.primary,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
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
