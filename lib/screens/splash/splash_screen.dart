import 'package:fauna_pulse/screens/onboarding/onboarding_screen.dart';
import 'package:flutter/material.dart';

/// SplashScreen widget
/// This widget displays a splash screen with a logo and a background image.
/// After a delay of 3 seconds, it navigates to the OnboardingScreen.
/// It is the first screen that users see when they open the app.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _imagesLoaded = false;

  @override
  void initState() {
    super.initState();
    // Navigate to onboarding after 3 seconds
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Safe place to precache images after context is available
    if (!_imagesLoaded) {
      precacheImage(const AssetImage('lib/assets/images/soil_background.jpg'), context)
        .then((_) {
          if (mounted) setState(() => _imagesLoaded = true);
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/assets/images/soil_background.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.white30, 
              BlendMode.lighten
            ),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo with hexagon and circuit lines
                      Image.asset(
                        'lib/assets/images/poultry_app_logo.png',
                        width: 150,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'PoultryApp',
                        style: TextStyle(
                          fontFamily: 'Lexend',
                          fontSize: 28,
                          fontWeight: FontWeight.w800, // Extra bold for stronger emphasis
                          color: Color(0xFF5E4935),
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 30.0),
                child: Column(
                  children: [
                    Text(
                      'BY',
                      style: TextStyle(
                        fontFamily: 'Lexend',
                        fontSize: 8,
                        fontWeight: FontWeight.w300,
                        color: Color(0xFF5E4935),
                      ),
                    ),
                    Text(
                      'BABALOLA',
                      style: TextStyle(
                        fontFamily: 'Lexend',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5E4935),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}