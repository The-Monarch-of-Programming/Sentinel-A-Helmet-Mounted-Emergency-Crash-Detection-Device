import 'dart:async';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'home.dart';
import 'profile.dart';
import 'settings.dart';
import 'widgets/bottomnavbar.dart';

class MapPage extends StatefulWidget {
  final bool isDispatcher;

  const MapPage({super.key, this.isDispatcher = false});
  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final Completer<GoogleMapController> _controller = Completer();
  static const LatLng sourceLocation = LatLng(14.6537, 121.0689);

  Set<Marker> _markers = {};
  String _currentUserName = 'You';
  String _currentUserPhone = '';
  String _currentUserEmail = '';

  final List<Map<String, dynamic>> _friends = [
    {'name': 'Denzil', 'location': const LatLng(14.6760, 121.0450), 'color': const Color(0xFF2196F3), 'avatarAsset': 'assets/friends/denzil.png', 'phone': '+63 912 345 6789'},
    {'name': 'Hanz', 'location': const LatLng(14.6350, 121.0900), 'color': const Color(0xFF9C27B0), 'avatarAsset': 'assets/friends/hanz.png', 'phone': '+63 923 456 7890'},
    {'name': 'Jerome', 'location': const LatLng(14.6700, 121.0800), 'color': const Color(0xFFFF9800), 'avatarAsset': 'assets/friends/jerome.png', 'phone': '+63 934 567 8901'},
    {'name': 'Ian', 'location': const LatLng(14.6200, 121.0550), 'color': const Color(0xFF00BCD4), 'avatarAsset': 'assets/friends/ian.png', 'phone': '+63 945 678 9012'},
    {'name': 'David', 'location': const LatLng(14.6450, 121.1050), 'color': const Color(0xFF4CAF50), 'avatarAsset': 'assets/friends/david.png', 'phone': '+63 956 789 0123'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserAndMarkers();
  }

  Future<void> _loadUserAndMarkers() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && mounted) {
          setState(() {
            _currentUserName = doc.data()?['name'] ?? user.displayName ?? 'You';
            _currentUserPhone = doc.data()?['phoneno'] ?? doc.data()?['phone'] ?? 'No number';
            _currentUserEmail = doc.data()?['email'] ?? user.email ?? '';
          });
        }
      } catch (_) {}
    }
    await _loadMarkers();
  }

  Widget _buildAvatarCircle(String? avatarAsset, String name, Color color) {
    if (avatarAsset == null) {
      return CircleAvatar(
        radius: 40,
        backgroundColor: color,
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
        ),
      );
    }

    return CircleAvatar(
      radius: 40,
      backgroundColor: color,
      child: ClipOval(
        child: Image.asset(
          avatarAsset,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showMarkerBottomSheet({
    required String id,
    required String name,
    required String phone,
    required String snippet,
    required Color color,
    String? avatarAsset,
  }) {
    final displayName = name.isNotEmpty
        ? name
        : id == 'you'
            ? _currentUserName
            : 'Friend';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SizedBox(
        height: id == 'you' ? 160 : 200,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatarCircle(avatarAsset, displayName, color),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      snippet,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            phone.isNotEmpty ? phone : 'No number',
                            style: const TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                    if (id != 'you') ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onPressed: () {},
                          icon: const Icon(Icons.call, color: Colors.white, size: 18),
                          label: const Text('Call', style: TextStyle(color: Colors.white, fontSize: 15)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<BitmapDescriptor> _createMarkerIcon(String name, Color color, String? avatarAsset, {bool isCurrentUser = false}) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    const double size = 120;
    final double radius = isCurrentUser ? 50 : 45;
    const double cx = size / 2;
    const double cy = size / 2 - 8;

    if (isCurrentUser) {
      canvas.drawCircle(const Offset(cx, cy), radius + 10, Paint()..color = Colors.white.withOpacity(0.4)..style = PaintingStyle.fill);
      canvas.drawCircle(const Offset(cx, cy), radius + 10, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 3);
    }

    canvas.drawCircle(const Offset(cx + 2, cy + 2), radius, Paint()..color = Colors.black26..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    canvas.drawCircle(const Offset(cx, cy), radius, Paint()..color = color);
    canvas.drawCircle(const Offset(cx, cy), radius, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = isCurrentUser ? 7 : 5);

    if (avatarAsset != null) {
      try {
        final data = await rootBundle.load(avatarAsset);
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        final frame = await codec.getNextFrame();
        final img = frame.image;
        final clipPath = Path()..addOval(Rect.fromCircle(center: const Offset(cx, cy), radius: radius - 4));
        canvas.save();
        canvas.clipPath(clipPath);
        canvas.drawImageRect(img, Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()), Rect.fromCircle(center: const Offset(cx, cy), radius: radius - 4), Paint());
        canvas.restore();
      } catch (_) {
        _drawInitials(canvas, name, cx, cy);
      }
    } else {
      _drawInitials(canvas, name, cx, cy);
    }

    final pinPath = Path()..moveTo(cx - 10, cy + radius - 4)..lineTo(cx + 10, cy + radius - 4)..lineTo(cx, cy + radius + 20)..close();
    canvas.drawPath(pinPath, Paint()..color = color);
    canvas.drawPath(pinPath, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2);

    final img = await recorder.endRecording().toImage(size.toInt(), (size + 10).toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  void _drawInitials(Canvas canvas, String name, double cx, double cy) {
    final textPainter = TextPainter(
      text: TextSpan(text: name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(cx - textPainter.width / 2, cy - textPainter.height / 2));
  }

  Future<void> _loadMarkers() async {
    final youIcon = await _createMarkerIcon(_currentUserName, const Color(0xFFE53935), null, isCurrentUser: true);
    final Set<Marker> markers = {
      Marker(
        markerId: const MarkerId("you"),
        position: sourceLocation,
        icon: youIcon,
        zIndex: 1,
        onTap: () => _showMarkerBottomSheet(
          id: 'you',
          name: _currentUserName,
          phone: _currentUserPhone,
          snippet: 'You are here',
          color: const Color(0xFFE53935),
        ),
      ),
    };

    for (final friend in _friends) {
      final icon = await _createMarkerIcon(friend['name'], friend['color'], friend['avatarAsset']);
      markers.add(Marker(
        markerId: MarkerId(friend['name']),
        position: friend['location'],
        icon: icon,
        onTap: () => _showMarkerBottomSheet(
          id: friend['name'],
          name: friend['name'],
          phone: friend['phone'],
          snippet: 'Friend',
          color: friend['color'],
          avatarAsset: friend['avatarAsset'],
        ),
      ));
    }
    if (mounted) setState(() => _markers = markers);
  }

  Widget _legendRow({required Color color, required String initial, required String label, bool isCurrentUser = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            decoration: isCurrentUser ? BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 2)) : null,
            child: CircleAvatar(
              radius: 10,
              backgroundColor: color,
              child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3130C0),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF3130C0),
        leading: Image.asset('assets/logo.png', width: 10, height: 10),
        title: const Text('Map'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(target: sourceLocation, zoom: 12.5),
            markers: _markers,
            onMapCreated: (controller) => _controller.complete(controller),
          ),
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              width: 200,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _legendRow(
                    color: const Color(0xFFE53935),
                    initial: _currentUserName.isNotEmpty ? _currentUserName[0].toUpperCase() : 'Y',
                    label: '$_currentUserName (You)',
                    isCurrentUser: true,
                  ),
                  const Divider(height: 8),
                  const Text('Friends nearby', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const Divider(height: 8),
                  ..._friends.map((f) => _legendRow(color: f['color'], initial: (f['name'] as String)[0], label: f['name'])),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(currentIndex: 3, role: 'driver'),
    );
  }
}