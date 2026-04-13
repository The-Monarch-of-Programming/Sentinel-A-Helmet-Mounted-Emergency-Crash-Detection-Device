import 'package:flutter/material.dart';
import '../home.dart';
import '../profile.dart';
import '../settings.dart';
import '../DispatchPage.dart';
import '../map.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final String role;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(color: Colors.black, fontSize: 12),
        ),
        iconTheme: WidgetStateProperty.all(
          const IconThemeData(color: Colors.black),
        ),
        indicatorColor: Colors.black.withOpacity(0.1),
      ),
      child: NavigationBar(
        height: 60,
        backgroundColor: Colors.lightBlue,
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          if (index == currentIndex) return;

          Widget nextScreen;

          switch (index) {
            case 0:
              nextScreen = const SettingsPage();
              break;
            case 1:
              nextScreen = (role == 'dispatcher')
                  ? const DashboardPage()
                  : const UserDashboard();
              break;
            case 2:
              nextScreen = const UserProfile();
              break;
            case 3:
              nextScreen = const MapPage();
            default:
              return;
          }

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => nextScreen),
          );
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
          NavigationDestination(icon: Icon(Icons.home), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
          NavigationDestination(icon: Icon(Icons.map), label: 'Map'),
        ],
      ),
    );
  }
}
