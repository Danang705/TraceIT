import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/auth_provider.dart';
import 'providers/post_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main/main_screen.dart';
import 'screens/auth/splash_screen.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PostProvider()),
      ],
      child: const TraceITApp(),
    ),
  );
}

class TraceITApp extends StatelessWidget {
  const TraceITApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TraceIT',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: SplashScreen(),
    );
  }
}

