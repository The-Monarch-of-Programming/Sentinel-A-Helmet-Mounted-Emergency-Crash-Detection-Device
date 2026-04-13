import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TermsAndConditionsPage extends StatefulWidget {
  const TermsAndConditionsPage({super.key});

  @override
  State<TermsAndConditionsPage> createState() => _TermsAndConditionsPageState();
}

class _TermsAndConditionsPageState extends State<TermsAndConditionsPage> {
  String role = "";
  bool _isDarkMode = false;

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

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text('Terms & Conditions'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Welcome to our Application",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "By using this app, you agree to the following terms. Please read them carefully.",
                style: TextStyle(color: Colors.white70, fontSize: 15),
              ),
              const SizedBox(height: 25),

              _buildTermSection(
                "1. Acceptance of Terms",
                "By accessing or using this service, you agree to be bound by these Terms and Conditions and all applicable laws and regulations.",
              ),
              _buildTermSection(
                "2. User Accounts",
                "You are responsible for maintaining the confidentiality of your account and password. You agree to accept responsibility for all activities that occur under your account.",
              ),
              _buildTermSection(
                "3. Prohibited Use",
                "You may not use this service for any illegal or unauthorized purpose. You must not transmit any worms, viruses, or any code of a destructive nature.",
              ),
              _buildTermSection(
                "4. Intellectual Property",
                "The app and its original content, features, and functionality are owned by the developers and are protected by international copyright and trademark laws.",
              ),
              _buildTermSection(
                "5. Termination",
                "We may terminate or suspend your account immediately, without prior notice or liability, for any reason, including breach of Terms.",
              ),
              _buildTermSection(
                "6. Limitation of Liability",
                "In no event shall the application owners be liable for any indirect, incidental, or consequential damages arising out of your use of the service.",
              ),

              const SizedBox(height: 30),
              const Divider(color: Colors.white24),
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  "Sentinel App @ 2026 All rights reserved.",
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTermSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.lightBlueAccent,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
