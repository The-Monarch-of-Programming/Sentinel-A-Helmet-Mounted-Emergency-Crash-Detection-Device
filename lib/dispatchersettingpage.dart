import 'package:flutter/material.dart';
import 'package:sentinel_app/DispatchPage.dart';
import 'package:sentinel_app/dispatch.dart';
import 'login.dart';
import 'dispatcheditprofile.dart';
import 'dispatchprofile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dispatcher_map.dart';

class Dispatchersettingpage extends StatefulWidget {
  const Dispatchersettingpage({super.key});

  @override
  State<Dispatchersettingpage> createState() => _DispatchersettingpageState();
}

class _DispatchersettingpageState extends State<Dispatchersettingpage> {
  String name = "Loading...";
  String email = "Loading...";
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get(const GetOptions(source: Source.server));

        if (userData.exists) {
          Map<String, dynamic> data = userData.data() as Map<String, dynamic>;

          setState(() {
            name = data['name'] ?? 'N/A';
            email = data['email'] ?? 'N/A';
          });
        }
      } catch (e) {
        print("Error fetching data: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _isDarkMode
        ? Colors.grey[900]
        : const Color(0xFF3130C0);
    final appBarColor = _isDarkMode
        ? Colors.grey[850]
        : const Color(0xFF3130C0);
    final scaffoldColor = _isDarkMode ? Colors.grey[800] : Colors.lightBlue;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: appBarColor,
        title: const Text('Settings'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DispatcherMapPage()),
              );
            },
            icon: const Icon(Icons.location_on),
            color: Colors.lightBlue,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: Colors.grey),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(email, style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 30),
            const Text(
              "Notification Settings",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.white),
              title: const Text(
                "Edit profile",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DispatchEditProfileScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock, color: Colors.white),
              title: const Text(
                "Change password",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.language, color: Colors.white),
              title: const Text(
                "Languages",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.contacts, color: Colors.white),
              title: const Text(
                "Add emergency contact",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {},
            ),
            SwitchListTile(
              title: const Text(
                "Share location",
                style: TextStyle(color: Colors.white),
              ),
              value: true,
              onChanged: (value) {},
            ),
            const Text(
              "More",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.white),
              title: const Text(
                "About us",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip, color: Colors.white),
              title: const Text(
                "Privacy policy",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.article, color: Colors.white),
              title: const Text(
                "Terms and conditions",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {},
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false,
                  );
                }
              },
              child: const Text(
                "Log Out",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        height: 60,
        backgroundColor: scaffoldColor,
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DispatcherApp()),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DispatchUserProfile(),
              ),
            );
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DispatcherMapPage()),
            );
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
