import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:movie_booking_app/presentation/screens/about/about_screen.dart';
import 'package:movie_booking_app/presentation/screens/home/home_screen.dart';
import 'package:movie_booking_app/presentation/screens/profile/profile_screen.dart';
import 'package:movie_booking_app/presentation/screens/profile/ticket_history_screen.dart';
import 'package:movie_booking_app/presentation/widgets/navbar.dart';

class ScreenController extends StatefulWidget {
  const ScreenController({super.key});

  @override
  State<ScreenController> createState() => _ScreenControllerState();
}

class _ScreenControllerState extends State<ScreenController> {
  int currentScreen = 0;
  void switchScreen(int selectedScreen) {
    setState(() {
      currentScreen = selectedScreen;
    });
  }

  List<Widget> screens = [
    HomeScreen(),
    TicketHistory(),
    AboutUsScreen(),
    ProfileScreen(),
  ];

  List<String> screenTitles = [
    "SabayBook",
    "Ticket History",
    "About Us",
    "Profile",
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight + 10),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF212121).withValues(alpha: 0.3),
                    blurRadius: 3,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: AppBar(
                  title: Text(
                    screenTitles[currentScreen],
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      shadows: [
                        Shadow(
                          color: const Color(0xFF212121).withValues(alpha: 0.5),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  centerTitle: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  surfaceTintColor: Colors.transparent,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
      body: screens[currentScreen],
      bottomNavigationBar: CustomNavBar(
        currentIndex: currentScreen,
        onTap: (index) => setState(() => currentScreen = index),
      ),
    );
  }
}
