import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import 'auth_choice_screen.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> onboardingData = [
    {
      "title": "Laporkan Barang Hilang",
      "description": "Buat laporan barang hilang dengan mudah menggunakan foto, deskripsi, waktu, dan lokasi terakhir barang terlihat.",
      "image": "assets/images/onboarding1.png"
    },
    {
      "title": "Temukan Barang di Sekitar",
      "description": "Lihat laporan barang hilang dan ditemukan berdasarkan lokasi terdekat melalui peta interaktif.",
      "image": "assets/images/onboarding2.png"
    },
    {
      "title": "Hubungi Penemu dengan Aman",
      "description": "Gunakan fitur chat untuk berkomunikasi tanpa perlu membagikan kontak pribadi.",
      "image": "assets/images/onboarding3.png"
    }
  ];

  void _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(Constants.hasSeenOnboardingKey, true);
    if (mounted) {
      Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => AuthChoiceScreen())
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withOpacity(0.15),
              Colors.white,
              Colors.white,
            ],
            stops: [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Logo Top
              Padding(
                padding: const EdgeInsets.only(top: 20.0, bottom: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      height: 30,
                      errorBuilder: (context, error, stackTrace) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.near_me, size: 24, color: AppColors.textPrimary),
                            SizedBox(width: 8),
                            Text(
                              'TraceIt',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              // Carousel
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (value) {
                    setState(() {
                      _currentPage = value;
                    });
                  },
                  itemCount: onboardingData.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Spacer(flex: 2),
                          // Illustration
                          Image.asset(
                            onboardingData[index]["image"]!,
                            height: 250,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 250,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Icon(Icons.image, size: 80, color: Colors.grey[400]),
                                ),
                              );
                            },
                          ),
                          Spacer(flex: 2),
                          // Title
                          Text(
                            onboardingData[index]["title"]!,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16),
                          // Description
                          Text(
                            onboardingData[index]["description"]!,
                            style: TextStyle(
                              fontSize: 14, 
                              color: AppColors.textSecondary, 
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Spacer(flex: 1),
                        ],
                      ),
                    );
                  },
                ),
              ),
              
              // Dot Indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  onboardingData.length,
                  (index) => buildDot(index, context),
                ),
              ),
              
              SizedBox(height: 30),
              
              // Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                        ),
                        onPressed: () {
                          if (_currentPage == onboardingData.length - 1) {
                            _finishOnboarding();
                          } else {
                            _pageController.nextPage(
                              duration: Duration(milliseconds: 300),
                              curve: Curves.ease,
                            );
                          }
                        },
                        child: Text(
                          _currentPage == onboardingData.length - 1 
                              ? "Mulai Sekarang" 
                              : "Lanjutkan",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    TextButton(
                      onPressed: _finishOnboarding,
                      child: Text(
                        "Lewati",
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Container buildDot(int index, BuildContext context) {
    return Container(
      height: 6,
      width: _currentPage == index ? 20 : 6,
      margin: EdgeInsets.only(right: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: _currentPage == index ? AppColors.primary : AppColors.borderColor,
      ),
    );
  }
}
