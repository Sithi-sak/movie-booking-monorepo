import 'package:flutter/material.dart';
import 'package:movie_booking_app/core/theme/app_theme.dart';
import 'package:movie_booking_app/presentation/auth/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SabayBook',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
