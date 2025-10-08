// Create a separate widget file: lib/widgets/bottom_navigation.dart

import 'package:flutter/material.dart';
import 'package:poultry_app/screens/dashboard/dashboard_screen.dart';
import 'package:poultry_app/screens/history/history_screen.dart';

class BottomNavigation extends StatelessWidget {
  final int currentIndex;

  const BottomNavigation({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFF5E4935),
      unselectedItemColor: Colors.grey,
      selectedFontSize: 10, // Smaller font size
      unselectedFontSize: 10, // Smaller font size
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
      ],
      onTap: (index) {
        if (index == currentIndex) return;

        switch (index) {
          case 0:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
            );
            break;
          case 1:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HistoryScreen()),
            );
            break;
        }
      },
    );
  }
}
