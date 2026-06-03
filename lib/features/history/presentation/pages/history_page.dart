import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../map/data/repositories/flood_report_repository.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyReportsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Laporan Saya', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: historyAsync.when(
        data: (reports) {
          if (reports.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_edu, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Belum ada riwayat',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Laporan yang kamu kirim akan muncul di sini.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(historyReportsProvider);
            },
            child: ListView.separated(
              itemCount: reports.length,
              separatorBuilder: (_, __) => const Divider(height: 1, thickness: 1),
              itemBuilder: (context, index) {
                final report = reports[index];
                return ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: report.depthLevel.color,
                    child: const Icon(Icons.water_drop, color: Colors.white),
                  ),
                  title: Text(
                    'Banjir ${report.depthLevel.label}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text((report.address != null && report.address!.isNotEmpty && report.address != 'null') ? report.address! : 'Dilaporkan pada ${report.createdAt.toLocal().toString().split('.')[0]}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        report.expiresAt.isAfter(DateTime.now()) ? Icons.check_circle : Icons.history,
                        color: report.expiresAt.isAfter(DateTime.now()) ? Colors.green : Colors.grey,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Hapus Laporan?'),
                              content: const Text('Apakah kamu yakin ingin menghapus laporan banjir ini?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Batal'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                                  child: const Text('Hapus'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await ref.read(floodReportRepositoryProvider).deleteReport(report.id);
                            ref.invalidate(historyReportsProvider);
                            ref.invalidate(activeFloodReportsProvider);
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
        error: (error, _) => Center(child: Text('Gagal memuat: $error')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
