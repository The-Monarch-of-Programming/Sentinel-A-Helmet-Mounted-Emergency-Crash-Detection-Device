import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dispatch.dart';
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

  // Hardcoded hospitals in the area
  final List<Map<String, dynamic>> _hospitals = [
    {'name': 'St. Luke\'s Medical Center Quezon City', 'location': const LatLng(14.6299, 121.0336), 'address': 'E Rodriguez Sr Ave, Quezon City'},
    {'name': 'Riverbanks Center', 'location': const LatLng(14.7280, 121.5610), 'address': 'Marikina, Metro Manila'},
    {'name': 'Makati Medical Center', 'location': const LatLng(14.5542, 121.0167), 'address': 'Makati, Metro Manila'},
    {'name': 'Philippine General Hospital', 'location': const LatLng(14.5994, 120.9842), 'address': 'Taft Ave, Manila'},
  ];

  @override
  void initState() {
    super.initState();
    _loadMarkersAndHospitals();
  }

  Future<void> _loadMarkersAndHospitals() async {
    final Set<Marker> markers = {};

    // Load crash markers
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('crashes')
          .where('status', isEqualTo: 'ongoing')
          .get();

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final LatLng location = LatLng(data['latitude'], data['longitude']);
        markers.add(Marker(
          markerId: MarkerId('crash_${doc.id}'),
          position: location,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'Crash Alert',
            snippet: 'Time: ${data['timestamp']?.toDate()?.toString() ?? 'Unknown'}',
          ),
        ));
      }
    } catch (e) {
      debugPrint('Error loading crashes: $e');
    }

    // Add hospital markers
    for (final hospital in _hospitals) {
      markers.add(Marker(
        markerId: MarkerId('hospital_${hospital['name']}'),
        position: hospital['location'],
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(
          title: hospital['name'],
          snippet: hospital['address'],
        ),
      ));
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
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(14.6537, 121.0689),
          zoom: 10,
        ),
        markers: _markers,
        onMapCreated: (controller) => _controller.complete(controller),
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
      bottomNavigationBar: NavigationBar(
        height: 60,
        backgroundColor: Colors.lightBlue,
        selectedIndex: 3,
        onDestinationSelected: (index) {
          if (index == 3) return;
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Dispatchersettingpage()),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DispatcherApp()),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DispatchUserProfile()),
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