import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _onboardingData = [
    {
      "title": "Nurostride",
      "subtitle": "Walk with Intelligence.",
      "placeholderSize": const Size(300, 400),
    },
    {
      "title": "Connect your sensors",
      "subtitle": "Place ESP32 on Hip and Knee.",
      "placeholderSize": const Size(300, 300),
    },
    {
      "title": "Clinical Precision",
      "subtitle": "Advanced Symmetry and Mobility Analysis.",
      "placeholderSize": const Size(300, 300),
    },
    {
      "title": "Ready",
      "subtitle": "All set to begin your session.",
      "placeholderSize": const Size(300, 300),
      "isLast": true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _onboardingData.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final data = _onboardingData[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: data['placeholderSize'].width,
                          height: data['placeholderSize'].height,
                          decoration: BoxDecoration(
                            color: AppColors.greyLight,
                            borderRadius: BorderRadius.circular(24.0),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.image,
                              size: 50,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 60),
                        Text(
                          data['title'],
                          style: Theme.of(context).textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          data['subtitle'],
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: AppColors.greyText),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(40.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(
                      _onboardingData.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppColors.success
                              : AppColors.greyLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  _currentPage == _onboardingData.length - 1
                      ? ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(
                              context,
                              '/dashboard',
                            );
                          },
                          child: const Text("Get Started"),
                        )
                      : TextButton(
                          onPressed: () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: const Text(
                            "Next",
                            style: TextStyle(color: AppColors.primary),
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
