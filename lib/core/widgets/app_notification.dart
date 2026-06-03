import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum AppNotificationType {
  login,
  register,
  submitReport,
  deleteHistory,
  updateProfile,
  updatePassword,
  logout,
  error
}

class AppNotification {
  const AppNotification._();

  static void show(
    BuildContext context, {
    required AppNotificationType type,
    required String message,
    String? title,
  }) {
    final overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _TopNotificationWidget(
        type: type,
        message: message,
        title: title,
        onDismiss: () {
          overlayEntry.remove();
        },
      ),
    );

    overlayState.insert(overlayEntry);
  }
}

class _TopNotificationWidget extends StatefulWidget {
  final AppNotificationType type;
  final String message;
  final String? title;
  final VoidCallback onDismiss;

  const _TopNotificationWidget({
    required this.type,
    required this.message,
    this.title,
    required this.onDismiss,
  });

  @override
  State<_TopNotificationWidget> createState() => _TopNotificationWidgetState();
}

class _TopNotificationWidgetState extends State<_TopNotificationWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.5),
      end: const Offset(0.0, 0.0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    // Auto dismiss setelah 3.2 detik
    Future.delayed(const Duration(milliseconds: 3200), () {
      if (mounted && !_isDismissing) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    if (_isDismissing) return;
    setState(() {
      _isDismissing = true;
    });
    _controller.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    String displayTitle;

    switch (widget.type) {
      case AppNotificationType.login:
        icon = LucideIcons.logIn;
        color = const Color(0xFF1E40AF); // Royal Blue
        displayTitle = widget.title ?? 'Berhasil Masuk';
        break;
      case AppNotificationType.register:
        icon = LucideIcons.userPlus;
        color = const Color(0xFF10B981); // Emerald Green
        displayTitle = widget.title ?? 'Akun Terdaftar';
        break;
      case AppNotificationType.submitReport:
        icon = LucideIcons.camera;
        color = const Color(0xFF3B82F6); // Electric Blue
        displayTitle = widget.title ?? 'Laporan Dikirim';
        break;
      case AppNotificationType.deleteHistory:
        icon = LucideIcons.trash2;
        color = const Color(0xFFEF4444); // Red
        displayTitle = widget.title ?? 'Laporan Dihapus';
        break;
      case AppNotificationType.updateProfile:
        icon = LucideIcons.userCheck;
        color = const Color(0xFF8B5CF6); // Purple
        displayTitle = widget.title ?? 'Profil Diperbarui';
        break;
      case AppNotificationType.updatePassword:
        icon = LucideIcons.keyRound;
        color = const Color(0xFF059669); // Teal
        displayTitle = widget.title ?? 'Sandi Diperbarui';
        break;
      case AppNotificationType.logout:
        icon = LucideIcons.logOut;
        color = const Color(0xFF475569); // Slate Gray
        displayTitle = widget.title ?? 'Keluar Akun';
        break;
      case AppNotificationType.error:
        icon = LucideIcons.alertCircle;
        color = const Color(0xFFEF4444); // Red
        displayTitle = widget.title ?? 'Peringatan';
        break;
    }

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
          child: SlideTransition(
            position: _offsetAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 480),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Icon with background circle
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          color: color,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Text Info
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayTitle,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.message,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Close button
                      IconButton(
                        icon: const Icon(LucideIcons.x, color: Color(0xFF94A3B8), size: 18),
                        onPressed: _dismiss,
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                        splashRadius: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
