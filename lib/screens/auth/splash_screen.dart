import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../main/main_screen.dart';
import 'onboarding_screen.dart';
import 'auth_choice_screen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkNavigation();
  }

  Future<void> _checkNavigation() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    // Load auth state from local storage first
    await auth.checkAuth();
    
    // Wait for at least 2 seconds total for the splash screen
    await Future.delayed(Duration(seconds: 2));

    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool(Constants.hasSeenOnboardingKey) ?? false;

    if (auth.isAuthenticated) {
      Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => MainScreen())
      );
    } else {
      // For testing/development: always show Onboarding if not logged in.
      // If you want to show it only once, check hasSeenOnboarding again.
      Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => OnboardingScreen())
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Image.asset(
          'assets/images/logo.png',
          width: 200,
          errorBuilder: (context, error, stackTrace) {
            // Fallback if logo.png is not yet uploaded
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.near_me, size: 40, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'TraceIt',
                  style: TextStyle(
                    fontSize: 32, 
                    fontWeight: FontWeight.bold, 
                    color: Colors.white,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
