import 'package:flutter/material.dart';
import 'widgets/bottomnavbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  Widget _buildIncidentHistory() {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Center(
        child: Text(
          "Please log in to view history",
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('crash_records')
          .where('driver_id', isEqualTo: uid)
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text(
            "Error: ${snapshot.error}",
            style: const TextStyle(color: Colors.redAccent),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              "No incidents recorded.",
              style: TextStyle(color: Colors.white54),
            ),
          );
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;

            String dateLabel = "Unknown Date";
            if (data['date'] is Timestamp) {
              dateLabel = DateFormat(
                'MMM d, yyyy • h:mm a',
              ).format((data['date'] as Timestamp).toDate());
            }

            return _buildIncidentCard(
              data['location'] ?? 'Unknown Location',
              dateLabel,
              data['status'] ?? 'unknown',
              data['hospital'] ?? '',
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3130C0),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF3130C0),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/logo.png'),
        ),
        title: const Text('Dashboard'),
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.location_on),
            color: Colors.lightBlue,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    _buildStatCircle('75%', 'Battery Life', Colors.lightBlue),

                    const SizedBox(height: 20),

                    _buildStatCircle('Manual SOS', '', Colors.red, isSos: true),

                    const SizedBox(height: 40),

                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Incident History',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    _buildIncidentHistory(),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: CustomBottomNavBar(currentIndex: 1, role: 'driver'),
    );
  }

  Widget _buildStatCircle(
    String title,
    String subtitle,
    Color color, {
    bool isSos = false,
  }) {
    return Container(
      height: 220,
      width: 220,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isSos ? 30 : 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (subtitle.isNotEmpty)
              Text(
                subtitle,
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncidentCard(
    String location,
    String date,
    String status,
    String hospital,
  ) {
    bool isResponded = status.toLowerCase() == 'responded';
    Color statusColor = isResponded ? Colors.greenAccent : Colors.orangeAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(
            isResponded ? Icons.check_circle_outline : Icons.error_outline,
            color: statusColor,
            size: 30,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  location,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  date,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                if (hospital.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      "Hospital: $hospital",
                      style: TextStyle(
                        color: statusColor.withOpacity(0.8),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                color: statusColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
