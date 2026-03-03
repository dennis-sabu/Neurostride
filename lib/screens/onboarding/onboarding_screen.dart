import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

/// Background colour that the hero image "melts" into.
const _kBgColor = Color(0xFFF2F5F9);

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  static const _pages = [
    _OnboardingData(
      image: 'assets/images/onboarding_1.png',
      headline: 'Wherever You Are,',
      highlight: 'Recovery',
      headlineSuffix: 'Starts Here',
      subtitle:
          'Your personalised knee rehabilitation journey begins with a single movement.',
    ),
    _OnboardingData(
      image: 'assets/images/onboarding_2.png',
      headline: 'Smart Sensing,',
      highlight: 'Real Results',
      headlineSuffix: '',
      subtitle:
          'Our NuroStride sensor streams live angle data directly to your phone at 100 Hz.',
    ),
    _OnboardingData(
      image: 'assets/images/onboarding_3.png',
      headline: 'Move Better,',
      highlight: 'Feel Stronger',
      headlineSuffix: 'Every Day',
      subtitle:
          'Guided exercises with intelligent coaching keep you on track and pain-free.',
    ),
    _OnboardingData(
      image: 'assets/images/onboarding_4.png',
      headline: 'Track Progress,',
      highlight: 'Share Insights',
      headlineSuffix: '',
      subtitle:
          'Review your mobility scores and share session reports with your therapist.',
    ),
  ];

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _goToDashboard();
    }
  }

  void _goToDashboard() {
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: _kBgColor,
      body: Stack(
        children: [
          // ── Swipeable pages ──
          PageView.builder(
            controller: _controller,
            itemCount: _pages.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) =>
                _OnboardingPage(data: _pages[index]),
          ),

          // ── Bottom controls (overlay) ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              // Soft upward spray from BG colour so it never looks like a hard line
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    _kBgColor,
                    _kBgColor,
                    Color(0x00F2F5F9), // fully transparent
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(28, 60, 28, 44),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Page dots ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) {
                      final isActive = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.sereneSage
                              : AppColors.greyLight,
                          borderRadius: BorderRadius.circular(100),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),

                  // ── CTA: show Get Started on last page ──
                  if (isLast) ...[
                    // Last page: only Get Started, no skip
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF2D5D62), // Deep Teal
                              Color(0xFF3A7D83),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF2D5D62,
                              ).withValues(alpha: 0.35),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _goToDashboard,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32),
                            ),
                          ),
                          child: Text(
                            'Get Started',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    // Pages 1–3: compact row with Skip + circular arrow
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Skip — subtle text
                        GestureDetector(
                          onTap: _goToDashboard,
                          child: Text(
                            'Skip',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              color: AppColors.greyText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        // Next — circular fab-style button
                        GestureDetector(
                          onTap: _next,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2D5D62), Color(0xFF3A7D83)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF2D5D62,
                                  ).withValues(alpha: 0.35),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Single page ───────────────────────────────────────────────────────────────
class _OnboardingPage extends StatelessWidget {
  final _OnboardingData data;
  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;

    return Container(
      color: _kBgColor,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Hero image with ShaderMask "fog" ─────────────────────────
          // The ShaderMask fades the image to transparent at the bottom,
          // which reveals the _kBgColor container underneath — no sharp edge.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: h * 0.62,
            child: ShaderMask(
              shaderCallback: (Rect bounds) {
                return const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black, Colors.black, Colors.transparent],
                  stops: [0.0, 0.5, 0.95],
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: Image.asset(
                data.image,
                fit: BoxFit.cover,
                errorBuilder: (_, __, _) => Container(
                  color: AppColors.sereneSage.withValues(alpha: 0.12),
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      size: 64,
                      color: AppColors.greyText,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Glassmorphic text card floating over the fog ─────────────
          Positioned(
            left: 24,
            right: 24,
            bottom: 190,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 28,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${data.headline}\n',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: AppColors.heroTitle,
                                height: 1.25,
                              ),
                            ),
                            TextSpan(
                              text: data.highlight,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: AppColors.deepTeal,
                                height: 1.25,
                              ),
                            ),
                            if (data.headlineSuffix.isNotEmpty)
                              TextSpan(
                                text: ' ${data.headlineSuffix}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.heroTitle,
                                  height: 1.25,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        data.subtitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: AppColors.greyText,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data model ────────────────────────────────────────────────────────────────
class _OnboardingData {
  final String image;
  final String headline;
  final String highlight;
  final String headlineSuffix;
  final String subtitle;

  const _OnboardingData({
    required this.image,
    required this.headline,
    required this.highlight,
    required this.headlineSuffix,
    required this.subtitle,
  });
}
