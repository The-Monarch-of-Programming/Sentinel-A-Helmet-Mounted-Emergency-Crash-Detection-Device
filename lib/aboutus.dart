import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AboutUsPage extends StatefulWidget {
  const AboutUsPage({super.key});

  @override
  State<AboutUsPage> createState() => _AboutUsPageState();
}

class _AboutUsPageState extends State<AboutUsPage> {
  String name = "Loading...";
  String email = "Loading...";
  String role = "";
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
            role = data['role'] ?? "Not Set";
          });
        }
      } catch (e) {
        debugPrint("Error fetching data: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _isDarkMode
        ? Colors.grey[900]!
        : const Color(0xFF3130C0);
    final cardColor = _isDarkMode ? Colors.grey[850]! : Colors.white;
    final primaryTextColor = _isDarkMode ? Colors.white : Colors.black87;
    final secondaryTextColor = _isDarkMode ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'About Us',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // --- Header Section ---
              const SizedBox(height: 24),
              const Text(
                "Team Sentinel",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "A Helmet-Mounted Emergency Crash Detection Device",
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 32),

              // Mission Card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                color: cardColor,
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Text(
                        "Our Mission",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _isDarkMode
                              ? Colors.lightBlueAccent
                              : const Color(0xFF3130C0),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "The primary objective of this project is to develop a smart helmet equipped with crash detection and SOS features that enhance rider safety and enable faster emergency response. The system aims to automatically detect accidents using integrated sensors and immediately transmit the rider’s location and alert notifications to emergency responders and designated contacts.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: primaryTextColor,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // --- Core Values Section ---
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Core Values",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildValueTile(
                Icons.shield,
                "Increased Safety",
                "The system will help to reduce the risk of injury or fatality by enabling fast emergency responses and reducing response time to incidents.",
              ),
              _buildValueTile(
                Icons.bolt,
                "Improved Compliance",
                "Compliance with safety standards and regulations for motorcycle safety on the road will help in case a motor accident occurs.",
              ),
              _buildValueTile(
                Icons.timeline,
                "Time Savings",
                "With faster response times, riders are less likely to suffer from prolonged injuries, reducing healthcare and insurance costs for organizations.",
              ),
              _buildValueTile(
                Icons.scale_sharp,
                "Scalability",
                "The technology can be adapted to various sectors, including military, oil and gas, and emergency services, increasing potential for growth and profitability.",
              ),
              const SizedBox(height: 40),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Core Benefits",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildValueTile(
                Icons.motorcycle,
                "Motorcycle Riders",
                "Provides immediate crash detection and emergency alerts, helping reduce injury severity and increasing chances of survival.",
              ),
              _buildValueTile(
                Icons.favorite,
                "Families of Riders",
                "Receives real-time notifications and location updates, allowing faster response during emergencies.",
              ),
              _buildValueTile(
                Icons.warning,
                "Emergency Responders",
                "Gains accurate and timely accident data, improving coordination and reducing response time.",
              ),
              _buildValueTile(
                Icons.health_and_safety_rounded,
                "Healthcare System",
                "Benefits from quicker medical intervention, potentially lowering long-term treatment costs and complications.",
              ),
              _buildValueTile(
                Icons.search,
                "Researchers and Developers",
                "Contributes to advancements in motorcycle safety technology and helps address issues like false alarms and inaccurate tracking.",
              ),
              _buildValueTile(
                Icons.safety_check,
                "Government and Road Safety Agencies",
                "Supports initiatives to reduce road accident fatalities and improve overall traffic safety.",
              ),
              _buildValueTile(
                Icons.group,
                "Society",
                "Promotes safer riding practices and enhances public awareness of road safety.",
              ),
              const SizedBox(height: 40),
              // --- Footer Info ---
              const Divider(color: Colors.white24),
              const SizedBox(height: 10),
              const Text(
                "Sentinel App @ 2026 All rights reserved.",
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildValueTile(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.lightBlueAccent, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
