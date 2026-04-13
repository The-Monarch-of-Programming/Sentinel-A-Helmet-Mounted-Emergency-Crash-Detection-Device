import 'package:flutter/material.dart';
import 'profile.dart';
import 'settings.dart';
import 'map.dart';

class UserDashboard extends StatelessWidget {
  const UserDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3130C0),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF3130C0),
        leading: Image.asset('assets/logo.png', width: 10, height: 10),
        title: const Text('Dashboard'),
        centerTitle: true,
        actions: <Widget>[
          IconButton(onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MapPage()),
            );
          }, icon: const Icon(Icons.location_on), color: Colors.lightBlue,),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(height: 40),
            Container(
              height: 250,
              width: 250,
              decoration: const BoxDecoration(
                color: Colors.lightBlue,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('75%', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
                  Text('Battery Life', style: TextStyle(fontSize: 20)),
                ],
              ),
            ),
            const Spacer(),
            Container(
              height: 200,
              width: 200,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
              ),
              child: const Center(
                child: Text('Manual SOS', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        height: 60,
        backgroundColor: Colors.lightBlue,
        selectedIndex: 1,
        onDestinationSelected: (index) {
          if (index == 0) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
          } else if (index == 2) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const UserProfile()));
          } else if (index == 3) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const MapPage()));
          }
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
