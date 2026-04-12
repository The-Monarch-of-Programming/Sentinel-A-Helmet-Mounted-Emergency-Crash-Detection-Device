import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  String role = "";
  bool _isDarkMode =
      false; // You can toggle this based on your app's theme state

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userData.exists) {
          setState(() {
            role = userData['role'] ?? "Not Set";
          });
        }
      } catch (e) {
        debugPrint("Error fetching role: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _isDarkMode
        ? Colors.grey[900]!
        : const Color(0xFF3130C0);
    final cardColor = _isDarkMode
        ? Colors.grey[850]!
        : Colors.white.withOpacity(0.1);
    final textColor = Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text('Privacy Policy'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Last Updated: April 2026",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 20),
              Text(
                "Your privacy is important to us. This policy explains how we collect, use, and protect your personal data.",
                style: TextStyle(color: textColor, fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 30),

              _buildPolicySection(
                "1. Data Collection",
                "We collect information you provide directly to us, such as your name, email address, and profile details when you register for an account.",
                Icons.data_usage,
              ),
              _buildPolicySection(
                "2. How We Use Data",
                "Your data is used to personalize your experience, provide customer support, and improve our application's performance and security.",
                Icons.visibility,
              ),
              _buildPolicySection(
                "3. Firebase & Security",
                "We use Google Firebase for authentication and database management. Your data is encrypted and stored securely following industry standards.",
                Icons.lock_outline,
              ),
              _buildPolicySection(
                "4. Third-Party Services",
                "We do not sell your personal information. We only share data with third-party services (like Firebase) necessary for the app's core functionality.",
                Icons.share_outlined,
              ),
              _buildPolicySection(
                "5. Your Rights",
                "You have the right to access, update, or delete your personal information at any time through the settings menu in this application.",
                Icons.person_search,
              ),

              const SizedBox(height: 40),
              Center(
                child: Text(
                  "Contact us for further information or any questions.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPolicySection(String title, String content, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(icon, color: Colors.lightBlueAccent),
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 70, right: 20, bottom: 20),
              child: Text(
                content,
                style: const TextStyle(color: Colors.white70, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
