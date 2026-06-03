import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:typed_data';
import 'package:sistem_peringatan_banjir_berbasis_komunitas/core/theme/app_theme.dart';
import 'package:sistem_peringatan_banjir_berbasis_komunitas/features/map/data/models/flood_report.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Provider to fetch only the required data (created_at and depth_level)
final communityStatisticsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await Supabase.instance.client
      .from('flood_reports')
      .select('created_at, depth_level, address, location');
  
  return List<Map<String, dynamic>>.from(response);
});

class ReportStatisticsPage extends ConsumerWidget {
  const ReportStatisticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(communityStatisticsProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Statistik Banjir Komunitas',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: statsAsync.when(
        data: (data) {
          if (data.isEmpty) {
            return const Center(
              child: Text('Belum ada data laporan banjir.'),
            );
          }
          return _StatisticsContent(data: data);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Gagal memuat statistik:\n$error', textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

class _StatisticsContent extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const _StatisticsContent({required this.data});

  @override
  Widget build(BuildContext context) {
    // 1. Data untuk Pie Chart (Distribusi Kedalaman)
    final depthCounts = <String, int>{};
    for (var row in data) {
      final depth = row['depth_level'] as String? ?? 'unknown';
      depthCounts[depth] = (depthCounts[depth] ?? 0) + 1;
    }

    // 2. Data untuk Bar Chart (Laporan per Hari selama 7 hari terakhir)
    final now = DateTime.now();
    final weekData = List.filled(7, 0); // indeks 0 = hari ini, 1 = kemarin, ... 6 = 6 hari lalu

    for (var row in data) {
      final dateStr = row['created_at'] as String?;
      if (dateStr == null) continue;
      final date = DateTime.tryParse(dateStr)?.toLocal();
      if (date == null) continue;

      // Reset waktu ke 00:00 untuk perbandingan akurat
      final cleanNow = DateTime(now.year, now.month, now.day);
      final cleanDate = DateTime(date.year, date.month, date.day);
      
      final diffDays = cleanNow.difference(cleanDate).inDays;
      if (diffDays >= 0 && diffDays < 7) {
        weekData[6 - diffDays]++; // 6 - diffDays agar urutannya dari kiri ke kanan (Masa lalu -> Sekarang)
      }
    }

    // 3. Data untuk Top 5 Lokasi Banjir
    final locationCounts = <String, int>{};
    final locationCoords = <String, Map<String, double>>{};
    
    // Helper untuk decode lokasi dari EWKB / GeoJSON
    Map<String, double>? parseLocation(dynamic loc) {
      if (loc == null) return null;
      if (loc is String) {
        // Coba parsing EWKB (format Hex)
        if (loc.startsWith('0101000020E6100000') && loc.length == 50) {
          try {
            final lngHex = loc.substring(18, 34);
            final latHex = loc.substring(34, 50);
            
            double decodeDouble(String hex) {
              final bytes = Uint8List(8);
              for (var i = 0; i < 8; i++) {
                bytes[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
              }
              return ByteData.view(bytes.buffer).getFloat64(0, Endian.little);
            }
            return {'lat': decodeDouble(latHex), 'lng': decodeDouble(lngHex)};
          } catch (_) {}
        }
      } else if (loc is Map<String, dynamic> && loc['type'] == 'Point') {
        // Jika formatnya GeoJSON
        final coords = loc['coordinates'] as List<dynamic>?;
        if (coords != null && coords.length == 2) {
          return {
            'lat': (coords[1] as num).toDouble(),
            'lng': (coords[0] as num).toDouble(),
          };
        }
      }
      return null;
    }

    for (var row in data) {
      final addr = row['address'] as String?;
      if (addr != null && addr.isNotEmpty && addr.toLowerCase() != 'null') {
        // Ambil nama jalan/area utama (sebelum koma pertama)
        final mainArea = addr.split(',').first.trim();
        if (mainArea.isNotEmpty) {
          locationCounts[mainArea] = (locationCounts[mainArea] ?? 0) + 1;
          if (!locationCoords.containsKey(mainArea)) {
            final coords = parseLocation(row['location']);
            if (coords != null) {
              locationCoords[mainArea] = coords;
            } else {
              // Jika gagal decode, set default ke 0
              locationCoords[mainArea] = {'lat': 0.0, 'lng': 0.0};
            }
          }
        }
      }
    }
    final sortedLocations = locationCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topLocations = sortedLocations.take(5).toList();
    final maxLocationCount = topLocations.isNotEmpty ? topLocations.first.value : 1;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Total Reports Card
          _buildSummaryCard(data.length),
          const SizedBox(height: 16),
          
          // Bar Chart Card
          _buildChartCard(
            title: 'Tren Laporan 7 Hari Terakhir',
            icon: LucideIcons.barChart2,
            iconColor: Colors.blue.shade700,
            iconBg: Colors.blue.shade50,
            child: AspectRatio(
              aspectRatio: 1.5,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (weekData.reduce((a, b) => a > b ? a : b).toDouble() * 1.2).clamp(5.0, double.infinity),
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final daysAgo = 6 - value.toInt();
                          if (daysAgo < 0 || daysAgo > 6) return const SizedBox.shrink();
                          
                          final date = now.subtract(Duration(days: daysAgo));
                          final text = '${date.day}/${date.month}';
                          
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(text, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: weekData.asMap().entries.map((e) {
                    return BarChartGroupData(
                      x: e.key,
                      barRods: [
                        BarChartRodData(
                          toY: e.value.toDouble(),
                          gradient: LinearGradient(
                            colors: [AppColors.primary.withValues(alpha: 0.6), AppColors.primary],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          width: 24,
                          borderRadius: BorderRadius.circular(6),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: (weekData.reduce((a, b) => a > b ? a : b).toDouble() * 1.2).clamp(5.0, double.infinity),
                            color: Colors.blue.shade50,
                          ),
                        )
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),

          // Pie Chart Card
          _buildChartCard(
            title: 'Persentase Kedalaman Air',
            icon: LucideIcons.pieChart,
            iconColor: Colors.purple.shade700,
            iconBg: Colors.purple.shade50,
            child: AspectRatio(
              aspectRatio: 1.3,
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 4,
                        centerSpaceRadius: 50,
                        sections: WaterDepthLevel.values.map((level) {
                          final count = depthCounts[level.name] ?? 0;
                          final percentage = data.isEmpty ? 0.0 : (count / data.length * 100);
                          return PieChartSectionData(
                            color: level.color,
                            value: count.toDouble(),
                            title: count > 0 ? '${percentage.toStringAsFixed(0)}%' : '',
                            radius: count > 0 ? 45 : 40,
                            titleStyle: const TextStyle(
                              fontSize: 13, 
                              fontWeight: FontWeight.bold, 
                              color: Colors.white,
                              shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: WaterDepthLevel.values.map((level) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          children: [
                            Container(width: 14, height: 14, decoration: BoxDecoration(color: level.color, borderRadius: BorderRadius.circular(4))),
                            const SizedBox(width: 8),
                            Text(level.label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                          ],
                        ),
                      );
                    }).toList(),
                  )
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),

          // Top Locations Chart
          if (topLocations.isNotEmpty)
            _buildChartCard(
              title: '5 Lokasi Paling Rawan',
              icon: LucideIcons.mapPin,
              iconColor: Colors.red.shade700,
              iconBg: Colors.red.shade50,
              child: Column(
                children: topLocations.map((entry) {
                  final percentage = entry.value / maxLocationCount;
                  return InkWell(
                    onTap: () {
                      final coords = locationCoords[entry.key];
                      if (coords != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => _LocationMapViewer(
                              locationName: entry.key,
                              latitude: coords['lat']!,
                              longitude: coords['lng']!,
                            ),
                          ),
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            entry.key,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 4,
                          child: Stack(
                            children: [
                              Container(
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: percentage,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 800),
                                  curve: Curves.easeOutCubic,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.orange.shade400, Colors.red.shade500],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(color: Colors.red.shade200.withValues(alpha: 0.5), blurRadius: 6, offset: const Offset(0, 2))
                                    ]
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 30,
                          child: Text(
                            '${entry.value}x',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      );
  }

  Widget _buildSummaryCard(int total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.users, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Kontribusi Komunitas',
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '$total Laporan',
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildChartCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF94A3B8).withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
          )
        ],
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Decorative background blob
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconBg.withValues(alpha: 0.5),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: iconBg, 
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: iconBg, blurRadius: 8, offset: const Offset(0, 4))
                          ]
                        ),
                        child: Icon(icon, color: iconColor, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                    ],
                  ),
                  const SizedBox(height: 28),
                  child,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationMapViewer extends StatelessWidget {
  final String locationName;
  final double latitude;
  final double longitude;

  const _LocationMapViewer({
    required this.locationName,
    required this.latitude,
    required this.longitude,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(locationName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(latitude, longitude),
              zoom: 16.5,
            ),
            markers: {
              Marker(
                markerId: MarkerId(locationName),
                position: LatLng(latitude, longitude),
                infoWindow: InfoWindow(title: locationName),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              ),
            },
            myLocationButtonEnabled: false,
            myLocationEnabled: false,
            zoomControlsEnabled: false,
          ),
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.info, color: Colors.blueAccent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Peta lokasi berdasarkan titik koordinat laporan banjir pertama di $locationName.',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
