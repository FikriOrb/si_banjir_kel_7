import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../map/data/models/flood_report.dart';
import '../../../map/data/repositories/flood_report_repository.dart';
import '../../../report/presentation/widgets/report_bottom_sheet.dart';
import '../widgets/report_comments_sheet.dart';
import 'report_map_detail_page.dart';

class FeedPage extends ConsumerWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(activeFloodReportsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Warga', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      backgroundColor: const Color(0xFFF3F5F9),
      body: reportsAsync.when(
        data: (reports) {
          if (reports.isEmpty) {
            return const Center(
              child: Text('Belum ada laporan banjir aktif saat ini.'),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(activeFloodReportsProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final report = reports[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      // Bisa dikembangkan untuk membuka halaman detail laporan
                    },
                    splashColor: Colors.blue.withOpacity(0.1),
                    highlightColor: Colors.blue.withOpacity(0.05),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      // Header
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blueAccent,
                          backgroundImage: report.reporterAvatar != null ? NetworkImage(report.reporterAvatar!) : null,
                          child: report.reporterAvatar == null ? const Icon(Icons.person, color: Colors.white) : null,
                        ),
                        title: Text(
                          report.reporterName ?? 'Warga Anonim',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (report.reporterUsername != null)
                              Text(
                                report.reporterUsername!,
                                style: const TextStyle(fontSize: 12, color: Colors.blueAccent, fontWeight: FontWeight.w500),
                              ),
                            Text(
                              report.createdAt.toLocal().toString().split('.')[0],
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: report.depthLevel.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: report.depthLevel.color),
                          ),
                          child: Text(
                            'Tinggi: ${report.depthLevel.label}',
                            style: TextStyle(
                              color: report.depthLevel.color,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      // Gambar
                      if (report.photoUrl.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FullScreenImagePage(imageUrl: report.photoUrl),
                              ),
                            );
                          },
                          child: Hero(
                            tag: report.photoUrl,
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: Image.network(
                                report.photoUrl,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const ColoredBox(
                                  color: Color(0xFFE9EEF5),
                                  child: Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
                                ),
                              ),
                            ),
                          ),
                        ),
                      // Caption / Catatan / Lokasi
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 16, color: Colors.red),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    (report.address != null && report.address!.isNotEmpty && report.address != 'null')
                                        ? report.address!
                                        : 'Titik Lokasi (Berdasarkan GPS)',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ReportLocationMapPage(report: report),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.map, size: 16),
                                  label: const Text('Lihat Peta', style: TextStyle(fontSize: 12)),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              (report.note != null && report.note!.isNotEmpty && report.note != 'null') 
                                ? report.note! 
                                : 'Warga melaporkan genangan air setinggi ${report.depthLevel.label} di lokasi ini. Harap berhati-hati saat melintas.',
                              style: const TextStyle(fontSize: 14, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      // Tombol Validasi
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Tooltip(
                              message: 'Tahan untuk membatalkan suara',
                              child: TextButton.icon(
                                onPressed: () => _handleVote(context, ref, report, true),
                                onLongPress: () => _handleRemoveVote(context, ref, report),
                                icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                                label: Text('Masih Banjir (${report.upvoteCount})', style: const TextStyle(color: Colors.orange)),
                              ),
                            ),
                            Tooltip(
                              message: 'Tahan untuk membatalkan suara',
                              child: TextButton.icon(
                                onPressed: () => _handleVote(context, ref, report, false),
                                onLongPress: () => _handleRemoveVote(context, ref, report),
                                icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                                label: Text('Sudah Surut (${report.downvoteCount})', style: const TextStyle(color: Colors.green)),
                              ),
                            ),
                            IconButton(
                              onPressed: () => showReportCommentsSheet(context, report),
                              icon: const Icon(Icons.chat_bubble_outline, color: Colors.blue),
                              tooltip: 'Lihat Diskusi Laporan',
                            ),
                          ],
                        ),
                      ),
                      // Progress Bar Validasi
                      if (report.upvoteCount > 0 || report.downvoteCount > 0)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0).copyWith(bottom: 16.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0, end: report.upvoteCount / (report.upvoteCount + report.downvoteCount)),
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, _) {
                                return LinearProgressIndicator(
                                  value: value,
                                  backgroundColor: Colors.green.shade200,
                                  color: Colors.orange,
                                  minHeight: 6,
                                );
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                );
              },
            ),
          );
        },
        error: (error, _) => Center(child: Text('Gagal memuat: $error')),
        loading: () => ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: 3,
          itemBuilder: (context, index) => const _SkeletonCard(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showReportBottomSheet(context),
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }

  Future<void> _handleVote(BuildContext context, WidgetRef ref, FloodReport report, bool isUpvote) async {
    final voteLabel = isUpvote ? 'Masih Banjir' : 'Sudah Surut';
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Suara'),
        content: Text('Apakah kamu yakin ingin menyatakan bahwa area ini "$voteLabel"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: isUpvote ? Colors.orange : Colors.green,
            ),
            child: const Text('Ya, Kirim Suara'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(floodReportRepositoryProvider).voteReport(report.id, isUpvote);
        ref.invalidate(activeFloodReportsProvider);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal mengirim suara: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _handleRemoveVote(BuildContext context, WidgetRef ref, FloodReport report) async {
    // Cek dulu apakah user sudah vote
    final hasVoted = await ref.read(floodReportRepositoryProvider).hasUserVoted(report.id);
    if (!hasVoted) return; // Jika belum vote, tidak terjadi apa-apa saat ditekan tahan

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan Suara?'),
        content: const Text('Apakah kamu ingin menarik kembali (membatalkan) suaramu dari laporan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tidak'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.grey),
            child: const Text('Tarik Suara'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(floodReportRepositoryProvider).removeVote(report.id);
        ref.invalidate(activeFloodReportsProvider);
      } catch (e) {
        // Ignored
      }
    }
  }
}

class FullScreenImagePage extends StatelessWidget {
  final String imageUrl;

  const FullScreenImagePage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4.0,
          child: Hero(
            tag: imageUrl,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatefulWidget {
  const _SkeletonCard();

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 120, height: 14, color: Colors.grey.shade300),
                      const SizedBox(height: 8),
                      Container(width: 80, height: 10, color: Colors.grey.shade300),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(8)),
              ),
              const SizedBox(height: 16),
              Container(width: double.infinity, height: 12, color: Colors.grey.shade300),
              const SizedBox(height: 8),
              Container(width: 200, height: 12, color: Colors.grey.shade300),
            ],
          ),
        ),
      ),
    );
  }
}
