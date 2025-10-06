
import 'package:fauna_pulse/screens/auth/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

/// OnboardingScreen widget
/// This widget displays an onboarding screen with three pages.
/// Each page contains an icon, a title, and a description.
/// The user can navigate through the pages using a PageView.
/// The last page has a "Get Started" button that navigates to the LoginScreen.

 class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final controller = PageController();
  bool isLastPage = false;
  bool _imagesLoaded = false;
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Safely preload images here instead of initState
    if (!_imagesLoaded) {
      _imagesLoaded = true; // Set to true first to prevent multiple calls
      
      // Use Future.wait to load multiple images
      Future.wait([
        precacheImage(const AssetImage('lib/assets/images/soil_background.jpg'), context),
        precacheImage(const AssetImage('lib/assets/images/hexagon_pattern.png'), context),
      ]);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
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
          ),
          
          // Skip button at top
          Positioned(
            top: 40,
            left: 20,
            child: !isLastPage 
              ? TextButton(
                  onPressed: () => controller.jumpToPage(2),
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      fontFamily: 'Urbanist',
                      color: Color(0xFF5E4935),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
          ),
          
          // Hexagon at top right
          Positioned(
            top: -20,
            right: -30,
            child: Image.asset(
              'lib/assets/images/hexagon_pattern.png',
              width: 150,
            ),
          ),
          
          // Hexagon at bottom left
          Positioned(
            bottom: -20,
            left: -30,
            child: Image.asset(
              'lib/assets/images/hexagon_pattern.png',
              width: 150,
            ),
          ),
          
          // Page content
          PageView(
            controller: controller,
            onPageChanged: (index) {
              setState(() => isLastPage = index == 2);
            },
            children: [
              buildOnboardingPage(
                icon: 'lib/assets/icons/book_icon.png',
                title: 'Understand your soil\nlike never before!',
                description: '',
              ),
              buildOnboardingPage(
                icon: 'lib/assets/icons/sensor_icon.png',
                title: 'With smart sensors and AI, monitor soil health, nutrients, and environmental conditions anytime, from anywhere',
                description: ' ',
                highlightText: 'anywhere',
              ),
              buildOnboardingPage(
                icon: 'lib/assets/icons/info_icon.png',
                title: 'Let\'s get started by gathering a little information...',
                description: '',
              ),
            ],
          ),
          
          // Bottom navigation (dot indicators and next button)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Empty space where skip button used to be
                  const SizedBox(width: 80),
                  
                  // Dot indicators
                  Center(
                    child: SmoothPageIndicator(
                      controller: controller,
                      count: 3,
                      effect: const WormEffect(
                        dotColor: Colors.black26,
                        activeDotColor: Color(0xFF5E4935),
                        dotHeight: 10,
                        dotWidth: 10,
                      ),
                    ),
                  ),
                  
                  // Next button - now square with rounded corners
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF5E4935),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      onPressed: () {
                        if (isLastPage) {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (context) => const SignupScreen()),
                          );
                        } else {
                          controller.nextPage(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      icon: const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                      ),
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildOnboardingPage({
  required String icon,
  required String title,
  required String description,
  String? highlightText,
}) {
  // Split the title if it contains highlighted text at the end
  Widget titleWidget;
  
  if (highlightText != null && title.endsWith(highlightText)) {
    // Remove the highlight text from the end of the title
    final mainTitleText = title.substring(0, title.length - highlightText.length);
    
    titleWidget = RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        children: [
          TextSpan(
            text: mainTitleText,
            style: const TextStyle(
              fontFamily: 'Urbanist',
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3A3A3A),
            ),
          ),
          TextSpan(
            text: highlightText,
            style: const TextStyle(
              fontFamily: 'Urbanist',
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3FA34D), // Green highlight color
            ),
          ),
        ],
      ),
    );
  } else {
    titleWidget = Text(
      title,
      style: const TextStyle(
        fontFamily: 'Urbanist',
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Color(0xFF3A3A3A),
      ),
      textAlign: TextAlign.center,
    );
  }

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 100.0),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Custom icon
        Image.asset(
          icon,
          width: 60,
          height: 60,
          color: const Color(0xFF5E4935),
        ),
        const SizedBox(height: 20),
        
        // Title with potential highlight
        titleWidget,
        
        // Gradient bar below title
        Container(
          width: 200,
          height: 5,
          margin: const EdgeInsets.only(top: 16, bottom: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF5E4935),
                Color.fromARGB(255, 248, 230, 204),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        
        const SizedBox(height: 10),
        
        // Description with highlight if provided
        if (description.isNotEmpty)
          Text(
            description,
            style: const TextStyle(
              fontFamily: 'Urbanist',
              fontSize: 16,
              color: Color(0xFF5A5A5A),
            ),
            textAlign: TextAlign.center,
          ),
      ],
    ),
  );
}

 
}
