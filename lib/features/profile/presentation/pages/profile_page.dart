import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'dart:io';
import 'package:image_picker/image_picker.dart';

import '../../../auth/presentation/pages/login_page.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_notification.dart';
import 'emergency_contacts_page.dart';
import 'flood_guide_page.dart';
import 'evacuation_centers_page.dart';
import 'report_statistics_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isUploadingAvatar = false;
  int _violationCount = 0;
  bool _isBanned = false;
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final data = await Supabase.instance.client
          .from('users')
          .select('violation_count, is_banned')
          .eq('id', user.id)
          .maybeSingle();

      if (data != null && mounted) {
        setState(() {
          _violationCount = data['violation_count'] as int? ?? 0;
          _isBanned = data['is_banned'] as bool? ?? false;
          _isLoadingData = false;
        });
      } else {
        if (mounted) setState(() => _isLoadingData = false);
      }
    } catch (e) {
      // Ignore if columns don't exist yet (SQL migration not run)
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final fullName =
        user?.userMetadata?['full_name'] as String? ?? 'Warga Medan';
    final username = user?.userMetadata?['username'] as String? ?? '@warga';
    final email = user?.email ?? 'Belum ada email';
    final avatarUrl = user?.userMetadata?['avatar_url'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil & Pengaturan'),
      ),
      body: Center(
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  const SizedBox(height: 16),

                  // Violation Warning Banner
                  if (!_isLoadingData && (_violationCount > 0 || _isBanned))
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _isBanned
                              ? Colors.red.shade900
                              : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _isBanned
                                ? Colors.red.shade900
                                : Colors.orange.shade300,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (_isBanned
                                      ? Colors.red.shade900
                                      : Colors.orange.shade500)
                                  .withValues(alpha: 0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              LucideIcons.alertTriangle,
                              color: _isBanned
                                  ? Colors.white
                                  : Colors.orange.shade700,
                              size: 28,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isBanned
                                        ? 'AKUN DIBEKUKAN PERMANEN'
                                        : 'Peringatan Pelanggaran ($_violationCount/3)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15,
                                      color: _isBanned
                                          ? Colors.white
                                          : Colors.orange.shade900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _isBanned
                                        ? 'Akun Anda telah diblokir karena membuat laporan palsu berulang kali. Anda tidak dapat lagi menggunakan fitur lapor.'
                                        : 'Sebagian laporan Anda dinilai tidak valid oleh komunitas (downvote tinggi). Jika mencapai 3 kali pelanggaran, akun Anda akan diblokir.',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: _isBanned
                                          ? Colors.red.shade100
                                          : Colors.orange.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Profile Card Header
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 16,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor: const Color(0xFFF1F5F9),
                                backgroundImage: avatarUrl != null
                                    ? NetworkImage(avatarUrl)
                                    : null,
                                child: avatarUrl == null
                                    ? const Icon(LucideIcons.user,
                                        size: 50, color: Color(0xFF64748B))
                                    : null,
                              ),
                            ),
                            if (_isUploadingAvatar)
                              const Positioned.fill(
                                child: CircularProgressIndicator(
                                    color: AppColors.primary),
                              ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: InkWell(
                                onTap:
                                    _isUploadingAvatar ? null : _uploadAvatar,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 4,
                                          spreadRadius: 1),
                                    ],
                                  ),
                                  child: const Icon(LucideIcons.camera,
                                      color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                            if (!_isLoadingData &&
                                (_violationCount > 0 || _isBanned))
                              Positioned(
                                top: 0,
                                left: 75,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _isBanned ? Colors.red.shade50 : Colors.amber.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: _isBanned ? Colors.red.shade400 : Colors.amber.shade400,
                                        width: 1.5),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                          _isBanned ? LucideIcons.ban : LucideIcons.alertTriangle,
                                          size: 12,
                                          color: _isBanned ? Colors.red.shade800 : Colors.amber.shade800),
                                      const SizedBox(width: 4),
                                      Text(
                                        _isBanned
                                            ? 'Akun Diblokir Permanen'
                                            : 'Akun ini telah melanggar peraturan',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: _isBanned ? Colors.red.shade900 : Colors.amber.shade900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          fullName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$username • $email',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 13,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Account Settings Card Group
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Card(
                      child: Column(
                        children: [
                          _buildMenuTile(
                            context,
                            icon: LucideIcons.user,
                            iconBgColor: Colors.blue.shade50,
                            iconColor: Colors.blue.shade700,
                            title: 'Ubah Profil',
                            subtitle: 'Ganti nama dan username',
                            onTap: () => _showEditProfileDialog(
                                context, fullName, username),
                          ),
                          const Divider(
                              height: 1,
                              indent: 56,
                              endIndent: 16,
                              color: Color(0xFFE2E8F0)),
                          _buildMenuTile(
                            context,
                            icon: LucideIcons.lock,
                            iconBgColor: Colors.purple.shade50,
                            iconColor: Colors.purple.shade700,
                            title: 'Ubah Kata Sandi',
                            subtitle: 'Perbarui keamanan akunmu',
                            onTap: () => _showChangePasswordDialog(context),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Safety & Information Card Group
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Card(
                      child: Column(
                        children: [
                          _buildMenuTile(
                            context,
                            icon: LucideIcons.phoneCall,
                            iconBgColor: Colors.red.shade50,
                            iconColor: Colors.red.shade700,
                            title: 'Kontak Darurat',
                            subtitle: 'Hubungi BPBD & Tim SAR Medan',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const EmergencyContactsPage()),
                            ),
                          ),
                          const Divider(
                              height: 1,
                              indent: 56,
                              endIndent: 16,
                              color: Color(0xFFE2E8F0)),
                          _buildMenuTile(
                            context,
                            icon: LucideIcons.bookOpen,
                            iconBgColor: Colors.amber.shade50,
                            iconColor: Colors.amber.shade700,
                            title: 'Panduan Siaga Banjir',
                            subtitle: 'Edukasi & pencegahan bencana',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const FloodGuidePage()),
                            ),
                          ),
                          const Divider(
                              height: 1,
                              indent: 56,
                              endIndent: 16,
                              color: Color(0xFFE2E8F0)),
                          _buildMenuTile(
                            context,
                            icon: LucideIcons.home,
                            iconBgColor: Colors.green.shade50,
                            iconColor: Colors.green.shade700,
                            title: 'Posko Evakuasi',
                            subtitle: 'Lokasi pengungsian terdekat',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const EvacuationCentersPage()),
                            ),
                          ),
                          const Divider(
                              height: 1,
                              indent: 56,
                              endIndent: 16,
                              color: Color(0xFFE2E8F0)),
                          _buildMenuTile(
                            context,
                            icon: LucideIcons.barChart2,
                            iconBgColor: Colors.blue.shade50,
                            iconColor: Colors.blue.shade700,
                            title: 'Statistik Komunitas',
                            subtitle: 'Tren banjir & laporan warga',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ReportStatisticsPage()),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Support & App Info Card Group
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Card(
                      child: Column(
                        children: [
                          _buildMenuTile(
                            context,
                            icon: LucideIcons.helpCircle,
                            iconBgColor: Colors.teal.shade50,
                            iconColor: Colors.teal.shade700,
                            title: 'Pusat Bantuan',
                            onTap: () =>
                                _showComingSoon(context, 'Pusat Bantuan'),
                          ),
                          const Divider(
                              height: 1,
                              indent: 56,
                              endIndent: 16,
                              color: Color(0xFFE2E8F0)),
                          _buildMenuTile(
                            context,
                            icon: LucideIcons.info,
                            iconBgColor: Colors.grey.shade100,
                            iconColor: Colors.grey.shade700,
                            title: 'Tentang Aplikasi',
                            onTap: () => _showAboutAppDialog(context),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Logout Card Group
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Card(
                      child: _buildMenuTile(
                        context,
                        icon: LucideIcons.logOut,
                        iconBgColor: Colors.red.shade50,
                        iconColor: Colors.red.shade700,
                        title: 'Keluar (Logout)',
                        textColor: Colors.red.shade700,
                        onTap: () => _showLogoutConfirmationDialog(context),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ))),
    );
  }

  Widget _buildMenuTile(
    BuildContext context, {
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    String? subtitle,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconBgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? const Color(0xFF1E293B),
          fontWeight: FontWeight.w700,
          fontSize: 14.5,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            )
          : null,
      trailing: const Icon(LucideIcons.chevronRight, color: Color(0xFF94A3B8)),
      onTap: onTap,
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => _CustomDialog(
        icon: LucideIcons.helpCircle,
        iconColor: AppColors.primary,
        title: feature,
        subtitle: 'Layanan Bantuan & Dukungan',
        content: const Text(
          'Fitur ini sedang dalam tahap pengembangan oleh tim akademis kami. Harap nantikan di pembaruan selanjutnya!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.5),
        ),
        actions: [
          Expanded(
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Tutup',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutAppDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _CustomDialog(
        icon: LucideIcons.droplets,
        iconColor: AppColors.primary,
        title: 'Tentang Aplikasi',
        subtitle: 'Versi 1.0.0',
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Aplikasi ini merupakan Sistem Peringatan Dini Banjir Berbasis Komunitas untuk wilayah Kota Medan. Warga dapat saling berbagi informasi titik banjir, memvalidasi laporan, dan menerima notifikasi bahaya secara real-time.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13.5, color: Color(0xFF475569), height: 1.55),
            ),
            SizedBox(height: 20),
            Divider(color: Color(0xFFE2E8F0)),
            SizedBox(height: 12),
            Text(
              '© 2026 Proyek Akhir Akademik\nDikembangkan secara kolaboratif untuk keselamatan warga Medan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11, color: Color(0xFF94A3B8), height: 1.4),
            ),
          ],
        ),
        actions: [
          Expanded(
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Tutup',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _CustomDialog(
        icon: LucideIcons.logOut,
        iconColor: Colors.red,
        title: 'Konfirmasi Keluar',
        subtitle: 'Apakah kamu yakin ingin keluar dari akun ini?',
        content: const Text(
          'Setelah keluar, Anda harus masuk kembali untuk membuat laporan banjir baru atau menerima notifikasi real-time.',
          textAlign: TextAlign.center,
          style:
              TextStyle(fontSize: 13.5, color: Color(0xFF64748B), height: 1.45),
        ),
        actions: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Batal',
                  style: TextStyle(
                      color: Color(0xFF475569), fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: () async {
                Navigator.pop(context);
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) {
                  AppNotification.show(
                    context,
                    type: AppNotificationType.logout,
                    message: 'Anda telah berhasil keluar dari akun Anda.',
                  );
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Keluar',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(
      BuildContext context, String currentName, String currentUsername) {
    final nameController = TextEditingController(text: currentName);
    final userController =
        TextEditingController(text: currentUsername.replaceAll('@', ''));
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return _CustomDialog(
              icon: LucideIcons.user,
              iconColor: AppColors.primary,
              title: 'Ubah Profil',
              subtitle:
                  'Perbarui nama lengkap dan username akun Anda di bawah ini.',
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Lengkap Baru',
                      prefixIcon: Icon(LucideIcons.user, size: 20),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: userController,
                    decoration: const InputDecoration(
                      labelText: 'Username Baru',
                      prefixIcon: Icon(LucideIcons.atSign, size: 20),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                  ),
                ],
              ),
              actions: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isLoading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Batal',
                        style: TextStyle(
                            color: Color(0xFF475569),
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: isLoading
                        ? null
                        : () async {
                            final newName = nameController.text.trim();
                            String newUser = userController.text.trim();
                            if (newName.isEmpty || newUser.isEmpty) {
                              AppNotification.show(
                                context,
                                type: AppNotificationType.error,
                                message: 'Semua kolom harus diisi!',
                              );
                              return;
                            }

                            if (!newUser.startsWith('@')) {
                              newUser = '@$newUser';
                            }

                            setState(() => isLoading = true);
                            try {
                              final userId =
                                  Supabase.instance.client.auth.currentUser!.id;

                              // 1. Update metadata di auth.users
                              await Supabase.instance.client.auth.updateUser(
                                UserAttributes(data: {
                                  'full_name': newName,
                                  'username': newUser
                                }),
                              );

                              // 2. Update kolom di public.users agar sinkron dengan Feed!
                              await Supabase.instance.client
                                  .from('users')
                                  .update({
                                'full_name': newName,
                                'username': newUser,
                              }).eq('id', userId);

                              if (context.mounted) {
                                Navigator.pop(context);
                                AppNotification.show(
                                  context,
                                  type: AppNotificationType.updateProfile,
                                  message: 'Profil Anda berhasil diperbarui.',
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                AppNotification.show(
                                  context,
                                  type: AppNotificationType.error,
                                  message: 'Gagal mengubah profil: $e',
                                );
                              }
                            } finally {
                              if (context.mounted) {
                                setState(() => isLoading = false);
                              }
                            }
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Simpan',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isLoading = false;
    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return _CustomDialog(
              icon: LucideIcons.lock,
              iconColor: AppColors.primary,
              title: 'Ubah Kata Sandi',
              subtitle:
                  'Masukkan kata sandi lama Anda beserta kata sandi baru yang ingin digunakan.',
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: oldPasswordController,
                    obscureText: obscureOld,
                    decoration: InputDecoration(
                      labelText: 'Kata Sandi Lama',
                      prefixIcon: const Icon(LucideIcons.lock, size: 20),
                      border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12))),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureOld ? LucideIcons.eyeOff : LucideIcons.eye,
                          color: const Color(0xFF64748B),
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => obscureOld = !obscureOld),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: newPasswordController,
                    obscureText: obscureNew,
                    decoration: InputDecoration(
                      labelText: 'Kata Sandi Baru (Min. 6 karakter)',
                      prefixIcon: const Icon(LucideIcons.lock, size: 20),
                      border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12))),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureNew ? LucideIcons.eyeOff : LucideIcons.eye,
                          color: const Color(0xFF64748B),
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => obscureNew = !obscureNew),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'Konfirmasi Kata Sandi Baru',
                      prefixIcon: const Icon(LucideIcons.lock, size: 20),
                      border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12))),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureConfirm ? LucideIcons.eyeOff : LucideIcons.eye,
                          color: const Color(0xFF64748B),
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => obscureConfirm = !obscureConfirm),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isLoading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Batal',
                        style: TextStyle(
                            color: Color(0xFF475569),
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: isLoading
                        ? null
                        : () async {
                            final oldPassword = oldPasswordController.text;
                            final newPassword = newPasswordController.text;
                            final confirmPassword =
                                confirmPasswordController.text;

                            if (oldPassword.isEmpty ||
                                newPassword.isEmpty ||
                                confirmPassword.isEmpty) {
                              AppNotification.show(
                                context,
                                type: AppNotificationType.error,
                                message: 'Semua kolom harus diisi!',
                              );
                              return;
                            }

                            if (newPassword.length < 6) {
                              AppNotification.show(
                                context,
                                type: AppNotificationType.error,
                                message:
                                    'Kata sandi baru harus minimal 6 karakter!',
                              );
                              return;
                            }

                            if (newPassword != confirmPassword) {
                              AppNotification.show(
                                context,
                                type: AppNotificationType.error,
                                message:
                                    'Konfirmasi kata sandi baru tidak cocok!',
                              );
                              return;
                            }

                            setState(() => isLoading = true);
                            try {
                              final email = Supabase
                                  .instance.client.auth.currentUser?.email;
                              if (email == null) {
                                throw Exception(
                                    'Email pengguna tidak ditemukan.');
                              }

                              // 1. Re-autentikasi kata sandi lama untuk keamanan
                              await Supabase.instance.client.auth
                                  .signInWithPassword(
                                email: email,
                                password: oldPassword,
                              );

                              // 2. Perbarui kata sandi baru
                              await Supabase.instance.client.auth.updateUser(
                                UserAttributes(password: newPassword),
                              );

                              if (context.mounted) {
                                Navigator.pop(context);
                                AppNotification.show(
                                  context,
                                  type: AppNotificationType.updatePassword,
                                  message:
                                      'Kata sandi akun Anda berhasil diperbarui.',
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                AppNotification.show(
                                  context,
                                  type: AppNotificationType.error,
                                  message:
                                      'Gagal mengubah kata sandi. Pastikan kata sandi lama benar.',
                                );
                              }
                            } finally {
                              if (context.mounted) {
                                setState(() => isLoading = false);
                              }
                            }
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Simpan',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _uploadAvatar() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
      maxWidth: 800,
    );

    if (pickedFile == null) return;

    setState(() => _isUploadingAvatar = true);
    try {
      final file = File(pickedFile.path);
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final objectPath =
          'avatars/$userId-${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Upload ke bucket report-photos (karena bucket ini dipastikan sudah ada)
      await Supabase.instance.client.storage.from('report-photos').upload(
            objectPath,
            file,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );

      final newAvatarUrl = Supabase.instance.client.storage
          .from('report-photos')
          .getPublicUrl(objectPath);

      // Simpan URL ke metadata Auth dan tabel users
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {'avatar_url': newAvatarUrl}),
      );
      await Supabase.instance.client.from('users').update({
        'avatar_url': newAvatarUrl,
      }).eq('id', userId);

      if (mounted) {
        AppNotification.show(
          context,
          type: AppNotificationType.updateProfile,
          message: 'Foto profil Anda berhasil diperbarui.',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal mengunggah foto: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }
}

class _CustomDialog extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget content;
  final List<Widget> actions;

  const _CustomDialog({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.content,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      backgroundColor: Colors.white,
      child: Container(
        width: MediaQuery.of(context).size.width > 420
            ? 400
            : MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Centered Header Section
            Container(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
              color: Colors.white,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 28),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      subtitle!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        height: 1.45,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Scrollable Content Section
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: content,
              ),
            ),

            // Actions Section
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              color: Colors.white,
              child: Row(
                children: actions,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
