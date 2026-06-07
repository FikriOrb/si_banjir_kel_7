import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingData> _pages = [
    _OnboardingData(
      title: 'Halo! Selamat Datang',
      description:
          'SiBanjir adalah pahlawan barumu buat hindarin genangan air. Biar motor nggak mogok dan kamu tetep bisa jalan-jalan dengan tenang walau habis hujan.',
      icon: LucideIcons.waves,
      color: const Color(0xFF3B82F6),
    ),
    _OnboardingData(
      title: 'Sering Kejebak Banjir?',
      description:
          'Lagi buru-buru, eh jalanan depan malah banjir parah. Pasti bikin repot, buang waktu, dan ngerusak mood banget kan?',
      icon: LucideIcons.cloudRainWind,
      color: const Color(0xFF6366F1),
    ),
    _OnboardingData(
      title: 'Yuk, Saling Bantu!',
      description:
          'Sekarang kamu bisa pantau genangan air secara real-time, cari rute aman, dan bagi info banjir sekitarmu buat bantu warga lain. Kita hadapi bareng!',
      icon: LucideIcons.mapPin,
      color: const Color(0xFF10B981),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _onFinish();
    }
  }

  Future<void> _onFinish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const LoginPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            var begin = const Offset(0.0, 0.1); // Mulai dari agak bawah (10%)
            var end = Offset.zero;
            var curve = Curves.easeOutCubic;

            var slideAnimation = animation.drive(
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve)),
            );

            return SlideTransition(
              position: slideAnimation,
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 700),
        ),
      );
    }
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
        child: Stack(
          children: [
            // Glow effects background (Global)
            Positioned(
              top: -50,
              left: -50,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _pages[_currentPage].color.withOpacity(0.35),
                ),
              ),
            ),
            Positioned(
              bottom: 50,
              right: -50,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _pages[_currentPage].color.withOpacity(0.25),
                ),
              ),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: Colors.transparent),
              ),
            ),

            // Foreground Content
            SafeArea(
              child: Column(
                children: [
                  // Top action (Skip)
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextButton(
                        onPressed: _onFinish,
                        child: Text(
                          'Lewati',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Page View
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      itemCount: _pages.length,
                      itemBuilder: (context, index) {
                        final page = _pages[index];
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Icon Animation with Glow
                                TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  duration: const Duration(milliseconds: 600),
                                  curve: Curves.elasticOut,
                                  builder: (context, value, child) {
                                    return Transform.scale(
                                      scale: value,
                                      child: Container(
                                        padding: const EdgeInsets.all(36),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.08),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: page.color.withOpacity(0.6),
                                            width: 1.5,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: page.color.withOpacity(0.4),
                                              blurRadius: 40,
                                              spreadRadius: 5,
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          page.icon,
                                          size: 100,
                                          color: Colors.white,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 56),
                                
                                // Glassmorphic Text Card
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.1),
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        page.title,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        page.description,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: Colors.white.withOpacity(0.85),
                                          height: 1.6,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Bottom controls
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Dot indicators
                        Row(
                          children: List.generate(
                            _pages.length,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.only(right: 8),
                              height: 8,
                              width: _currentPage == index ? 24 : 8,
                              decoration: BoxDecoration(
                                color: _currentPage == index
                                    ? _pages[_currentPage].color
                                    : Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),

                        // Next / Finish button
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          child: FilledButton(
                            onPressed: _onNext,
                            style: FilledButton.styleFrom(
                              backgroundColor: _pages[_currentPage].color,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _currentPage == _pages.length - 1
                                      ? 'Mulai Sekarang'
                                      : 'Selanjutnya',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                                if (_currentPage < _pages.length - 1) ...[
                                  const SizedBox(width: 8),
                                  const Icon(LucideIcons.arrowRight, size: 20, color: Colors.white),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  _OnboardingData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
