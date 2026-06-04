import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider untuk mengontrol tab aktif di HomeShellPage
final homeTabIndexProvider = StateProvider<int>((ref) => 0);

/// Provider untuk menyimpan ID laporan yang harus di-scroll dan di-highlight di FeedPage
final targetReportIdProvider = StateProvider<String?>((ref) => null);
