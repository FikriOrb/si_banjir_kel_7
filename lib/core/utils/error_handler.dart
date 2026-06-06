import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppError {
  static String toMessage(Object error) {
    final errorStr = error.toString().toLowerCase();

    // Check for offline / network errors
    if (error is SocketException ||
        errorStr.contains('socketexception') ||
        errorStr.contains('failed host lookup') ||
        errorStr.contains('network is unreachable') ||
        errorStr.contains('handshake error') ||
        errorStr.contains('connection closed') ||
        errorStr.contains('connection timed out') ||
        errorStr.contains('connection reset by peer') ||
        errorStr.contains('software caused connection abort') ||
        errorStr.contains('xmlhttprequest') ||
        errorStr.contains('fetch_error') ||
        errorStr.contains('offline') ||
        errorStr.contains('clientexception')) {
      return 'Anda sedang offline. Periksa koneksi internet Anda.';
    }

    if (error is PostgrestException) {
      if (error.code == '23505') {
        return 'Data sudah ada (duplikat).';
      }
      return 'Terjadi kesalahan pada database (Code: ${error.code}).';
    }

    if (error is AuthException) {
      return error.message; // Supabase auth error usually has readable message
    }

    // Default formatting if it's just a general Exception containing our own thrown message
    if (error is Exception) {
      final msg = error.toString();
      if (msg.startsWith('Exception: ')) {
        return msg.substring(11);
      }
      return msg;
    }

    // Return the raw error if not recognized, or generic fallback
    return error.toString();
  }
}