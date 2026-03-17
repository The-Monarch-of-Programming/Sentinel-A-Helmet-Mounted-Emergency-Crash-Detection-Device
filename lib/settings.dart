import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home.dart';
import 'profile.dart';

class SettingsService {
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  static const _darkModeKey = 'dark_mode';
  static const _notificationsKey = 'notifications_enabled';

  final ValueNotifier<bool> isDarkMode = ValueNotifier<bool>(false);
  final ValueNotifier<bool> notificationsEnabled = ValueNotifier<bool>(true);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    isDarkMode.value = prefs.getBool(_darkModeKey) ?? false;
    notificationsEnabled.value = prefs.getBool(_notificationsKey) ?? true;
  }

  Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, value);
    isDarkMode.value = value;
  }

  Future<void> setNotificationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, value);
    notificationsEnabled.value = value;
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3130C0),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF3130C0),
        title: const Text('Settings'),
        centerTitle: true,
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
                  children: const [
                    Text(
                      "Mike Myers",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      "User Profile",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 30),

            const Text(
              "Notification Settings",
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.white),
              title: const Text("Edit profile", style: TextStyle(color: Colors.white)),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.lock, color: Colors.white),
              title: const Text("Change password", style: TextStyle(color: Colors.white)),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.language, color: Colors.white),
              title: const Text("Languages", style: TextStyle(color: Colors.white)),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.contacts, color: Colors.white),
              title: const Text("Add emergency contact", style: TextStyle(color: Colors.white)),
              onTap: () {},
            ),
            ValueListenableBuilder<bool>(
              valueListenable: SettingsService.instance.notificationsEnabled,
              builder: (context, enabled, _) {
                return SwitchListTile(
                  title: const Text("Share location", style: TextStyle(color: Colors.white)),
                  value: enabled,
                  activeColor: Colors.white,
                  activeTrackColor: Colors.white24,
                  onChanged: (value) {
                    SettingsService.instance.setNotificationsEnabled(value);
                  },
                );
              },
            ),
            ValueListenableBuilder<bool>(
              valueListenable: SettingsService.instance.isDarkMode,
              builder: (context, isDarkMode, _) {
                return SwitchListTile(
                  title: const Text("Dark mode", style: TextStyle(color: Colors.white)),
                  value: isDarkMode,
                  activeColor: Colors.white,
                  activeTrackColor: Colors.white24,
                  onChanged: (value) {
                    SettingsService.instance.setDarkMode(value);
                  },
                );
              },
            ),

            const SizedBox(height: 20),
            const Text(
              "More",
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.white),
              title: const Text("About us", style: TextStyle(color: Colors.white)),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip, color: Colors.white),
              title: const Text("Privacy policy", style: TextStyle(color: Colors.white)),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.article, color: Colors.white),
              title: const Text("Terms and conditions", style: TextStyle(color: Colors.white)),
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
              onPressed: _logout,
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
        backgroundColor: Colors.lightBlue,
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const UserDashboard()),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const UserProfile()),
            );
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
          NavigationDestination(icon: Icon(Icons.home), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}