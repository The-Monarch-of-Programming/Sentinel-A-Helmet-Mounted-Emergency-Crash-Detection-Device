import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sentinel_app/DispatchPage.dart';

void main() {
  runApp(const DispatcherApp());
}

class DispatcherApp extends StatelessWidget {
  const DispatcherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final Set<String> _knownOngoingIds = {};
  bool _hasSeenMapSnapshot = false;
  StreamSubscription<QuerySnapshot>? _crashSubscription;

  @override
  void initState() {
    super.initState();
    _crashSubscription = FirebaseFirestore.instance
        .collection('crash_records')
        .where('status', isEqualTo: 'ongoing')
        .snapshots()
        .listen(
          _onOngoingCrashRecordsUpdate,
          onError: (error) {
            debugPrint('Dispatcher crash notification stream error: $error');
          },
        );
  }

  @override
  void dispose() {
    _crashSubscription?.cancel();
    super.dispose();
  }

  void _onOngoingCrashRecordsUpdate(QuerySnapshot snapshot) {
    final ids = snapshot.docs.map((doc) => doc.id).toSet();
    if (!_hasSeenMapSnapshot) {
      _knownOngoingIds.addAll(ids);
      _hasSeenMapSnapshot = true;
      return;
    }

    final newIds = ids.difference(_knownOngoingIds);
    if (newIds.isEmpty) return;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'A rider has sent an SOS',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'See Location',
            textColor: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EmergencyAlerts()),
              );
            },
          ),
        ),
      );
    }

    _knownOngoingIds.addAll(newIds);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E31B1), // Main background color
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Color(0xFF5A62F1),
            child: Icon(
              Icons.directions_run,
              size: 20,
              color: Colors.cyanAccent,
            ),
          ),
        ),
        title: const Text(
          'Dashboard',
          style: TextStyle(fontWeight: FontWeight.w300, letterSpacing: 1.2),
        ),
        centerTitle: true,
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.menu))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dispatcher Stats Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF5A6AF1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Column(
                children: [
                  Text(
                    "Dispatcher",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400),
                  ),
                  Divider(color: Colors.white24, height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      StatBox(label: "Active Alerts", value: "12"),
                      StatBox(label: "Resolved", value: "4"),
                    ],
                  ),
                  SizedBox(height: 20),
                  StatBox(label: "In Progress", value: "4"),
                ],
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              "Quick Actions",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
            ),
            const SizedBox(height: 20),
            // Action Buttons
            const ActionTile(
              title: "View All Task",
              subtitle: "Manage Dispatch Task",
              icon: Icons.list_alt_rounded,
              color: Color(0xFF192BB6),
            ),
            const SizedBox(height: 15),
            const ActionTile(
              title: "Emergency Alerts",
              subtitle: "View Urgent Alerts",
              icon: Icons.notifications_active,
              color: Color(0xFF862134),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color.fromARGB(255, 0, 204, 255),
        selectedItemColor: Colors.black87,
        unselectedItemColor: Colors.grey,
        currentIndex: 1,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class StatBox extends StatelessWidget {
  final String label;
  final String value;

  const StatBox({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF3B48B1).withOpacity(0.5),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class ActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const ActionTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 40, color: Colors.white),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.white60),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
