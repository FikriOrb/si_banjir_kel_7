import 'package:sistem_peringatan_banjir_berbasis_komunitas/core/utils/error_handler.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/config/env.dart';
import '../../../../core/widgets/app_notification.dart';
import '../../../home/presentation/pages/home_shell_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      AppNotification.show(
        context,
        type: AppNotificationType.error,
        message: 'Email dan Password tidak boleh kosong!',
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (mounted) {
        AppNotification.show(
          context,
          type: AppNotificationType.login,
          message: 'Selamat datang kembali di Peringatan Banjir Medan.',
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeShellPage()),
        );
      }
    } catch (e) {
      if (mounted) {
        AppNotification.show(
          context,
          type: AppNotificationType.error,
          message: 'Login Gagal: ${AppError.toMessage(e)}',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final webClientId = Env.googleWebClientId;
      final iosClientId = Env.googleIosClientId;

      await GoogleSignIn.instance.initialize(
        clientId: iosClientId.isEmpty ? null : iosClientId,
        serverClientId: webClientId.isEmpty ? null : webClientId,
      );
      
      final googleUser = await GoogleSignIn.instance.authenticate();
      if (googleUser == null) {
        if (mounted) setState(() => _isLoading = false);
        return; // User canceled
      }
      
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        if (webClientId.isEmpty) {
          throw 'Google Web Client ID belum dikonfigurasi di .env';
        }
        throw 'ID Token tidak ditemukan.';
      }

      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );

      // Sinkronisasi foto profil agar tidak tertimpa oleh foto Google
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        try {
          final userData = await Supabase.instance.client
              .from('users')
              .select('avatar_url')
              .eq('id', user.id)
              .maybeSingle();

          final dbAvatarUrl = userData?['avatar_url'] as String?;
          final metaAvatarUrl = user.userMetadata?['avatar_url'] as String?;

          if (dbAvatarUrl != null && dbAvatarUrl.contains('report-photos')) {
            // Jika sudah punya foto custom di database, paksa auth metadata pakai foto custom
            if (metaAvatarUrl != dbAvatarUrl) {
              await Supabase.instance.client.auth.updateUser(
                UserAttributes(data: {'avatar_url': dbAvatarUrl}),
              );
            }
          } else if (metaAvatarUrl != null && metaAvatarUrl != dbAvatarUrl) {
            // Jika belum punya foto custom, tapi login google bawa foto, simpan ke database
            await Supabase.instance.client.from('users').update({
              'avatar_url': metaAvatarUrl,
            }).eq('id', user.id);
          }
        } catch (_) {
          // Abaikan jika terjadi error saat sinkronisasi (misal RLS)
        }
      }

      if (mounted) {
        AppNotification.show(
          context,
          type: AppNotificationType.login,
          message: 'Berhasil masuk dengan Google.',
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeShellPage()),
        );
      }
    } catch (e) {
      if (mounted) {
        AppNotification.show(
          context,
          type: AppNotificationType.error,
          message: 'Login Google Gagal: ${AppError.toMessage(e)}',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F172A), // Slate 900
              Color(0xFF1E3A8A), // Blue 900
              Color(0xFF1E40AF), // Blue 800
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo Container with Pulse shadow
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.25),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/icon/app_icon.webp',
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Peringatan Banjir Medan',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Portal pemantau genangan air berbasis komunitas',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Form Card
                  Card(
                    color: Colors.white,
                    elevation: 12,
                    shadowColor: Colors.black.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(28.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Selamat Datang',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Masuk dengan akun Anda untuk melihat atau melaporkan banjir',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12.5,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Email Field
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(LucideIcons.mail),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Password Field
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _login(),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(LucideIcons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                                  color: const Color(0xFF64748B),
                                  size: 20,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          if (_isLoading)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 12.0),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else ...[
                            FilledButton(
                              onPressed: _login,
                              child: const Text('Masuk'),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton(
                              onPressed: _loginWithGoogle,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: const BorderSide(color: Color(0xFFE2E8F0)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.g_mobiledata, size: 28, color: Color(0xFF64748B)),
                                  SizedBox(width: 8),
                                  Text(
                                    'Masuk dengan Google',
                                    style: TextStyle(color: Color(0xFF475569)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const RegisterPage()),
                                );
                              },
                              child: const Text('Belum punya akun? Daftar di sini'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ))),
            ),
          ),
        ),
      ),
    );
  }
}
