import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../feed/presentation/pages/feed_page.dart';
import '../../../history/presentation/pages/history_page.dart';
import '../../../map/data/models/flood_report.dart';
import '../../../map/domain/services/geofencing_service.dart';
import '../../../map/presentation/pages/main_map_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../map/data/repositories/flood_report_repository.dart';
import '../../../report/presentation/widgets/report_bottom_sheet.dart';

class HomeShellPage extends ConsumerStatefulWidget {
  const HomeShellPage({super.key});

  @override
  ConsumerState<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends ConsumerState<HomeShellPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const FeedPage(),
    const MainMapPage(),
    const HistoryPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        ref.read(geofencingServiceProvider).start(radiusMeters: 500);
      } catch (e) {
        // Abaikan jika user menolak permission di awal, agar tidak crash
      }
    });
  }

  @override
  void dispose() {
    try {
      ref.read(geofencingServiceProvider).stop();
    } catch (_) {}
    super.dispose();
  }

  void _showElegantAlert(BuildContext context, FloodReport report) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, anim1, anim2) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        final curveValue = Curves.easeInOutBack.transform(anim1.value);
        return Transform.scale(
          scale: curveValue,
          child: Opacity(
            opacity: anim1.value,
            child: AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 16,
              contentPadding: EdgeInsets.zero,
              content: Container(
                width: 320,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    colors: [Colors.white, Color(0xFFF8FAFC)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 12,
                      decoration: const BoxDecoration(
                        color: AppColors.medium,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.medium.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.alertOctagon,
                        color: AppColors.medium,
                        size: 44,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Banjir Dekat Anda!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Terdeteksi titik banjir di sekitar lokasi Anda. Harap berhati-hati.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: const Color(0xFF475569),
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(LucideIcons.mapPin, color: Colors.redAccent, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  report.address ?? 'Lokasi tidak diketahui',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(LucideIcons.droplets, color: report.depthLevel.color, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'Ketinggian: ${report.depthLevel.label}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: report.depthLevel.color,
                                ),
                              ),
                            ],
                          ),
                          if (report.distanceMeters != null) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(LucideIcons.navigation, color: Colors.blueAccent, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'Jarak: ~${report.distanceMeters!.round()} meter',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueAccent,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text(
                                'Tutup',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () {
                                Navigator.pop(context);
                                setState(() {
                                  _currentIndex = 1;
                                });
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text(
                                'Lihat Peta',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<FloodReport?>(activeGeofenceAlertProvider, (previous, next) {
      if (next != null) {
        _showElegantAlert(context, next);
        ref.read(activeGeofenceAlertProvider.notifier).state = null;
      }
    });

    final width = MediaQuery.sizeOf(context).width;
    final isTablet = width >= 600;
    
    final reportsAsync = ref.watch(activeFloodReportsProvider);
    final activeCount = reportsAsync.maybeWhen(
      data: (reports) => reports.length,
      orElse: () => 0,
    );

    return Scaffold(
      body: Row(
        children: [
          if (isTablet)
            NavigationRail(
              selectedIndex: _currentIndex,
              elevation: 1,
              backgroundColor: Colors.white,
              onDestinationSelected: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              labelType: NavigationRailLabelType.all,
              selectedIconTheme: const IconThemeData(color: Color(0xFF1E40AF)), // AppColors.primary
              selectedLabelTextStyle: const TextStyle(
                color: Color(0xFF1E40AF), // AppColors.primary
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              unselectedIconTheme: const IconThemeData(color: Color(0xFF64748B)),
              unselectedLabelTextStyle: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
              ),
              destinations: [
                const NavigationRailDestination(
                  icon: Icon(LucideIcons.home),
                  selectedIcon: Icon(LucideIcons.home),
                  label: Text('Beranda'),
                ),
                NavigationRailDestination(
                  icon: Badge(
                    label: Text('$activeCount'),
                    isLabelVisible: activeCount > 0,
                    backgroundColor: AppColors.medium,
                    child: const Icon(LucideIcons.map),
                  ),
                  selectedIcon: Badge(
                    label: Text('$activeCount'),
                    isLabelVisible: activeCount > 0,
                    backgroundColor: AppColors.medium,
                    child: const Icon(LucideIcons.map),
                  ),
                  label: const Text('Peta'),
                ),
                const NavigationRailDestination(
                  icon: Icon(LucideIcons.history),
                  selectedIcon: Icon(LucideIcons.history),
                  label: Text('Riwayat'),
                ),
                const NavigationRailDestination(
                  icon: Icon(LucideIcons.user),
                  selectedIcon: Icon(LucideIcons.user),
                  label: Text('Profil'),
                ),
              ],
            ),
          if (isTablet)
            const VerticalDivider(thickness: 1, width: 1, color: Color(0xFFE2E8F0)),
          Expanded(
            child: _FadeIndexedStack(
              index: _currentIndex,
              children: _pages,
            ),
          ),
        ],
      ),
      bottomNavigationBar: isTablet
          ? null
          : Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: NavigationBar(
                elevation: 0,
                selectedIndex: _currentIndex,
                onDestinationSelected: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                destinations: [
                  const NavigationDestination(
                    icon: Icon(LucideIcons.home),
                    selectedIcon: Icon(LucideIcons.home),
                    label: 'Beranda',
                  ),
                  NavigationDestination(
                    icon: Badge(
                      label: Text('$activeCount'),
                      isLabelVisible: activeCount > 0,
                      backgroundColor: AppColors.medium,
                      child: const Icon(LucideIcons.map),
                    ),
                    selectedIcon: Badge(
                      label: Text('$activeCount'),
                      isLabelVisible: activeCount > 0,
                      backgroundColor: AppColors.medium,
                      child: const Icon(LucideIcons.map),
                    ),
                    label: 'Peta',
                  ),
                  const NavigationDestination(
                    icon: Icon(LucideIcons.history),
                    selectedIcon: Icon(LucideIcons.history),
                    label: 'Riwayat',
                  ),
                  const NavigationDestination(
                    icon: Icon(LucideIcons.user),
                    selectedIcon: Icon(LucideIcons.user),
                    label: 'Profil',
                  ),
                ],
              ),
            ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryLight],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          onPressed: () => showReportBottomSheet(context),
          icon: const Icon(LucideIcons.camera),
          label: const Text('Kirim Laporan'),
        ),
      ),
    );
  }
}

class _FadeIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;

  const _FadeIndexedStack({required this.index, required this.children});

  @override
  State<_FadeIndexedStack> createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<_FadeIndexedStack> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _controller.forward();
    super.initState();
  }

  @override
  void didUpdateWidget(_FadeIndexedStack oldWidget) {
    if (widget.index != oldWidget.index) {
      _controller.forward(from: 0.0);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: IndexedStack(
        index: widget.index,
        children: widget.children,
      ),
    );
  }
}
