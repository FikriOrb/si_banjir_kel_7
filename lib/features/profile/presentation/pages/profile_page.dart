import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'dart:io';
import 'package:image_picker/image_picker.dart';

import '../../../auth/presentation/pages/login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isUploadingAvatar = false;

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final fullName = user?.userMetadata?['full_name'] as String? ?? 'Warga Medan';
    final username = user?.userMetadata?['username'] as String? ?? '@warga';
    final email = user?.email ?? 'Belum ada email';
    final avatarUrl = user?.userMetadata?['avatar_url'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil & Pengaturan', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 24),
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: const Color(0xFFE9EEF5),
                  backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl == null ? const Icon(Icons.person, size: 50, color: Colors.grey) : null,
                ),
                if (_isUploadingAvatar)
                  const Positioned.fill(
                    child: CircularProgressIndicator(color: Colors.blue),
                  ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: InkWell(
                    onTap: _isUploadingAvatar ? null : _uploadAvatar,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            fullName,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(
            '$username • $email',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          _buildMenuTile(
            context,
            icon: Icons.person_outline,
            title: 'Ubah Profil',
            subtitle: 'Ganti nama dan username',
            onTap: () => _showEditProfileDialog(context, fullName, username),
          ),
          _buildMenuTile(
            context,
            icon: Icons.lock_outline,
            title: 'Ubah Kata Sandi',
            subtitle: 'Perbarui keamanan akunmu',
            onTap: () => _showChangePasswordDialog(context),
          ),
          const Divider(),
          _buildMenuTile(
            context,
            icon: Icons.help_outline,
            title: 'Pusat Bantuan',
            onTap: () => _showComingSoon(context, 'Pusat Bantuan'),
          ),
          _buildMenuTile(
            context,
            icon: Icons.info_outline,
            title: 'Tentang Aplikasi',
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'Sistem Banjir Medan',
              applicationVersion: '1.0.0',
              applicationLegalese: '© 2026 Proyek Akhir Akademik',
            ),
          ),
          const Divider(),
          _buildMenuTile(
            context,
            icon: Icons.logout,
            title: 'Keluar (Logout)',
            textColor: Colors.red,
            iconColor: Colors.red,
            onTap: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Color? textColor,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.black87),
      title: Text(title, style: TextStyle(color: textColor ?? Colors.black87, fontWeight: FontWeight.w500)),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(feature),
        content: const Text('Fitur ini sedang dalam tahap pengembangan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, String currentName, String currentUsername) {
    final nameController = TextEditingController(text: currentName);
    final userController = TextEditingController(text: currentUsername.replaceAll('@', ''));
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Ubah Profil'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Lengkap Baru',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: userController,
                    decoration: const InputDecoration(
                      labelText: 'Username Baru (tanpa @)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final newName = nameController.text.trim();
                          String newUser = userController.text.trim();
                          if (newName.isEmpty || newUser.isEmpty) {
                            return;
                          }

                          if (!newUser.startsWith('@')) {
                            newUser = '@$newUser';
                          }

                          setState(() => isLoading = true);
                          try {
                            final userId = Supabase.instance.client.auth.currentUser!.id;

                            // 1. Update metadata di auth.users
                            await Supabase.instance.client.auth.updateUser(
                              UserAttributes(data: {'full_name': newName, 'username': newUser}),
                            );

                            // 2. Update kolom di public.users agar sinkron dengan Feed!
                            await Supabase.instance.client.from('users').update({
                              'full_name': newName,
                              'username': newUser,
                            }).eq('id', userId);

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Profil berhasil diperbarui! Silakan refresh/restart aplikasi.')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Gagal mengubah profil: $e'), backgroundColor: Colors.red),
                              );
                            }
                          } finally {
                            if (context.mounted) {
                              setState(() => isLoading = false);
                            }
                          }
                        },
                  child: isLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final controller = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Ubah Kata Sandi'),
              content: TextField(
                controller: controller,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Kata Sandi Baru (Min. 6 karakter)',
                  border: OutlineInputBorder(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final newPassword = controller.text;
                          if (newPassword.length < 6) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Kata sandi harus minimal 6 karakter!'), backgroundColor: Colors.red),
                            );
                            return;
                          }

                          setState(() => isLoading = true);
                          try {
                            await Supabase.instance.client.auth.updateUser(
                              UserAttributes(password: newPassword),
                            );
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Kata sandi berhasil diperbarui!')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Gagal mengubah kata sandi: $e'), backgroundColor: Colors.red),
                              );
                            }
                          } finally {
                            if (context.mounted) {
                              setState(() => isLoading = false);
                            }
                          }
                        },
                  child: isLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Simpan'),
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
      final objectPath = 'avatars/$userId-${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Upload ke bucket report-photos (karena bucket ini dipastikan sudah ada)
      await Supabase.instance.client.storage.from('report-photos').upload(
            objectPath,
            file,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );

      final newAvatarUrl = Supabase.instance.client.storage.from('report-photos').getPublicUrl(objectPath);

      // Simpan URL ke metadata Auth dan tabel users
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {'avatar_url': newAvatarUrl}),
      );
      await Supabase.instance.client.from('users').update({
        'avatar_url': newAvatarUrl,
      }).eq('id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto profil berhasil diperbarui!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengunggah foto: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }
}
