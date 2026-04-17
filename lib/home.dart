import 'package:flutter/material.dart';
import 'widgets/bottomnavbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  bool _isLocked = false;
  String? _frozenX, _frozenY, _frozenZ, _frozenSeverity;

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
              data['severity'] ?? 'unknown',
              data['hospital'] ?? '',
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> _triggerManualSos() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    bool confirm = await _showSosConfirmDialog();
    if (!confirm) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.redAccent),
      ),
    );

    void _showErrorSnackBar(String message) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.orangeAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    try {
      // Get the map data instead of just a string
      Map<String, dynamic> locationData = await _getCurrentLocation();

      if (locationData.containsKey('error')) {
        if (mounted) Navigator.pop(context);
        _showErrorSnackBar(locationData['error']);
        return;
      }

      await FirebaseFirestore.instance.collection('crash_records').add({
        'date': FieldValue.serverTimestamp(),
        'dispatcher_id': "",
        'driver_id': user.uid,
        'hospital': "",
        'location': locationData['address'],
        'latitude': locationData['latitude'],
        'longitude': locationData['longitude'],
        'respondedAt': null,
        'status': "ongoing",
        'severity': "Medium",
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("SOS Sent with precise GPS!"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      print("SOS Error: $e");
    }
  }

  Future<bool> _showSosConfirmDialog() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Colors.white10, width: 1),
            ),
            title: Row(
              children: const [
                Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                SizedBox(width: 10),
                Text(
                  "Confirm SOS?",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: const Text(
              "This will alert emergency responders to your current location. Do you wish to proceed?",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            actionsPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 10,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  "CANCEL",
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text(
                    "SEND SOS",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<Map<String, dynamic>> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return {'error': "Location services disabled"};

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied)
          return {'error': "Permission denied"};
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      String address = "Unknown Location";
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        Placemark place = placemarks[0];
        address = "${place.street}, ${place.locality}";
      } catch (_) {
        address = "${position.latitude}, ${position.longitude}";
      }

      return {
        'address': address,
        'latitude': position.latitude,
        'longitude': position.longitude,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
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
                    _buildSensorReadings(),

                    const SizedBox(height: 20),

                    InkWell(
                      onTap: () => _triggerManualSos(),
                      borderRadius: BorderRadius.circular(110),
                      child: _buildStatCircle(
                        'Manual SOS',
                        '',
                        Colors.red,
                        isSos: true,
                      ),
                    ),

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

  Widget _buildSensorReadings() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('devices')
          .doc('readings')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists)
          return const SizedBox();

        var data = snapshot.data!.data() as Map<String, dynamic>;
        String currentSeverity = data['severity'] ?? "None";
        String x = data['ax']?.toStringAsFixed(3) ?? "0.000";
        String y = data['ay']?.toStringAsFixed(3) ?? "0.000";
        String z = data['az']?.toStringAsFixed(3) ?? "0.000";

        if (!_isLocked &&
            (currentSeverity == "Medium" || currentSeverity == "High")) {
          _frozenX = x;
          _frozenY = y;
          _frozenZ = z;
          _frozenSeverity = currentSeverity;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() => _isLocked = true);
          });
        }

        if (_isLocked) {
          return _buildLockedSensorUI(
            _frozenX ?? x,
            _frozenY ?? y,
            _frozenZ ?? z,
            _frozenSeverity ?? currentSeverity,
          );
        }

        // Otherwise, show live updating UI
        return _buildSensorUI(x, y, z, currentSeverity);
      },
    );
  }

  Widget _buildSensorUI(String x, String y, String z, String severity) {
    Color severityColor;
    switch (severity.toLowerCase()) {
      case 'high':
        severityColor = Colors.redAccent;
        break;
      case 'medium':
        severityColor = Colors.orangeAccent;
        break;
      case 'low':
        severityColor = Colors.greenAccent;
        break;
      default:
        severityColor = Colors.cyanAccent;
    }

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: severityColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "LIVE SENSOR DATA",
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _severityBadge(severity, severityColor),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildAxisVal("AX", x),
              _buildAxisVal("AY", y),
              _buildAxisVal("AZ", z),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAxisVal(String label, String val) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.cyanAccent, fontSize: 10),
        ),
        Text(
          val,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLockedSensorUI(String x, String y, String z, String severity) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.redAccent, width: 2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.lock_clock, color: Colors.redAccent, size: 20),
              SizedBox(width: 8),
              Text(
                "MEDIUM OR HIGHER IMPACT SEVERITY DETECTED",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 12
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildAxisVal("AX", x),
              _buildAxisVal("AY", y),
              _buildAxisVal("AZ", z),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.refresh),
              label: const Text("RESET"),
              onPressed: () {
                setState(() {
                  _isLocked = false;
                  _frozenX = null;
                  _frozenY = null;
                  _frozenZ = null;
                  _frozenSeverity = null;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _severityBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
