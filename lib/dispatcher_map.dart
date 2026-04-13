import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:sentinel_app/DispatchPage.dart';
import 'dispatch.dart' hide DashboardPage;
import 'dispatchprofile.dart';
import 'dispatchersettingpage.dart';

class DispatcherMapPage extends StatefulWidget {
  const DispatcherMapPage({super.key});

  @override
  State<DispatcherMapPage> createState() => _DispatcherMapPageState();
}

class _DispatcherMapPageState extends State<DispatcherMapPage> {
  final Completer<GoogleMapController> _controller = Completer();
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _loadMarkersAndHospitals();
  }

  Future<void> _loadMarkersAndHospitals() async {
    final Set<Marker> markers = {};

    // Load crash markers from the dispatcher feed
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('crash_records')
          .where('status', isEqualTo: 'ongoing')
          .get();

      for (final doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final LatLng location = LatLng(data['latitude'], data['longitude']);
        markers.add(Marker(
          markerId: MarkerId('crash_${doc.id}'),
          position: location,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: data['location'] ?? 'Crash Alert',
            snippet: 'Status: ${data['status'] ?? 'Unknown'}',
          ),
        ));
      }
    } catch (e) {
      debugPrint('Error loading crash records: $e');
    }


    if (mounted) setState(() => _markers = markers);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dispatcher Map'),
        backgroundColor: Colors.red,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(14.6537, 121.0689),
              zoom: 10,
            ),
            markers: _markers,
            onMapCreated: (controller) => _controller.complete(controller),
          ),
          Positioned(
            left: 10,
            right: 10,
            bottom: 80,
            child: _buildIncidentPanel(),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'refresh',
            backgroundColor: Colors.blueAccent,
            onPressed: _loadMarkersAndHospitals,
            child: const Icon(Icons.refresh),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'legend',
            backgroundColor: Colors.grey,
            onPressed: () => _showLegend(context),
            child: const Icon(Icons.info),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF00CCFF),
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        currentIndex: 2,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 1) return;
          // Navigation Logic
          Widget page;
          switch (index) {
            // case 0:
            //   Navigator.pushReplacement(
            //     context,
            //     MaterialPageRoute(
            //       builder: (context) => const Dispatchersettingpage(),
            //     ),
            //   );
            //   break;
                  case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const DispatcherPage(),
                ),
              );
              break;
            case 1:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const DispatchUserProfile(),
                ),
              );
              break;
            case 2:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const DispatcherMapPage(),
                ),
              );
              break;
            default:
              break;
          }
        },
        items: const [
          // BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentPanel() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 220,
        color: Colors.white.withOpacity(0.95),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              color: Colors.redAccent,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: const Text(
                'Ongoing Incidents & Emergency Alerts',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('crash_records')
                    .where('status', isEqualTo: 'ongoing')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Could not load incidents'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return const Center(
                      child: Text('No active incidents', style: TextStyle(color: Colors.black54)),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final bool isEmergency = (data['severity'] ?? '').toString().toLowerCase() == 'high';
                      final String location = data['location'] ?? 'Unknown location';
                      final String time = data['date'] is Timestamp
                          ? DateFormat('MMM d, h:mm a').format((data['date'] as Timestamp).toDate())
                          : 'Unknown time';
                      return ListTile(
                        dense: true,
                        minVerticalPadding: 4,
                        leading: CircleAvatar(
                          backgroundColor: isEmergency ? Colors.red : Colors.orange,
                          child: Icon(isEmergency ? Icons.warning : Icons.local_hospital, color: Colors.white, size: 18),
                        ),
                        title: Text(location, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        subtitle: Text('$time • ${data['status']?.toString().toUpperCase() ?? 'ONGOING'}'),
                        trailing: Text(
                          isEmergency ? 'EMERGENCY' : 'ONGOING',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isEmergency ? Colors.red : Colors.orange,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLegend(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Map Legend'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                const Text('Crash Alert'),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                const Text('Hospital'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}