import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dispatchprofile.dart';
import 'dispatchersettingpage.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const DispatcherPage());
}

class DispatcherPage extends StatelessWidget {
  const DispatcherPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dispatcher Admin',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF1A1A72),
        scaffoldBackgroundColor: const Color(0xFF2E31B1),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const DashboardPage(),
    );
  }
}

// --- MODELS ---
// Using a class instead of Map<String, String> makes data much safer
class Incident {
  final String title;
  final String subtitle;
  final String time;
  final Map<String, String> rawData;

  Incident({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.rawData,
  });
}

// --- SHARED UI COMPONENTS ---

class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3B4CCF), Color(0xFF1A1A72)],
        ),
      ),
      child: child,
    );
  }
}

class StatBox extends StatelessWidget {
  final String label, value;
  const StatBox({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.cyanAccent,
            ),
          ),
        ],
      ),
    );
  }
}

// --- PAGES ---

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('crash_records')
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: CircleAvatar(child: Icon(Icons.security, size: 20)),
        ),
        title: const Text(
          'Dashboard',
          style: TextStyle(fontWeight: FontWeight.w300),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Connection Error"));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          // Logic for status counts
          int active = 0, progress = 0, resolved = 0;
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'] ?? '';
            final dispId = data['dispatcher_id'] ?? '';

            if (status == 'responded') {
              resolved++;
            } else if (status == 'ongoing') {
              dispId.isEmpty ? active++ : progress++;
            }
          }

          return _DashboardContent(
            active: active,
            progress: progress,
            resolved: resolved,
          );
        },
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 1),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final int active, progress, resolved;
  const _DashboardContent({
    required this.active,
    required this.progress,
    required this.resolved,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderCard(),
          const SizedBox(height: 30),
          const Text(
            "Quick Actions",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _ActionTile(
            title: "View All Tasks",
            icon: Icons.list_alt,
            color: const Color(0xFF192BB6),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AllTasksPage()),
            ),
          ),
          const SizedBox(height: 12),
          _ActionTile(
            title: "Emergency Alerts",
            icon: Icons.warning_amber_rounded,
            color: const Color(0xFF862134),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EmergencyAlerts()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF5A6AF1),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        children: [
          const Text("Dispatcher Overview", style: TextStyle(fontSize: 18)),
          const Divider(height: 30, color: Colors.white24),
          Row(
            children: [
              Expanded(
                child: StatBox(label: "Active", value: "$active"),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatBox(label: "In Progress", value: "$progress"),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatBox(label: "Resolved", value: "$resolved"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CrashDetailsPage extends StatelessWidget {
  final Map<String, dynamic> details;

  const CrashDetailsPage({super.key, required this.details});

  Future<Map<String, dynamic>> _getDriverFullDetails(String? uid) async {
    if (uid == null || uid.isEmpty || uid == "null") {
      return {"name": "Unknown", "phone": "N/A", "plate": "N/A"};
    }
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final List<dynamic> contacts = userData['emergencyContacts'] ?? [];
        String emergencyPhone = "No Contact Set";
        if (contacts.isNotEmpty) {
          emergencyPhone = contacts[0]['phone'] ?? "No Number";
        }
        return {
          "name": userData['name'] ?? "Anonymous",
          "emergency_phone": emergencyPhone,
          "plate": userData['plate_number'] ?? "No Plate Found",
        };
      }
      return {
        "name": "User Not Found",
        "emergency_phone": "N/A",
        "plate": "N/A",
      };
    } catch (e) {
      return {"name": "Error", "emergency_phone": "Error", "plate": "Error"};
    }
  }

  Future<String> _getDispatcherName(String? uid) async {
    if (uid == null || uid.isEmpty || uid == "null") {
      return "Awaiting Assignment";
    }
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      return userDoc.exists ? (userDoc.get('name') ?? "Unknown") : "Not Found";
    } catch (e) {
      return "Error";
    }
  }

  Future<void> _respondToIncident(
    BuildContext context,
    String selectedHospital,
  ) async {
    try {
      final String? currentUserUid = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserUid == null) throw "You must be logged in.";

      await FirebaseFirestore.instance
          .collection('crash_records')
          .doc(details['id'])
          .update({
            'status': 'responded',
            'dispatcher_id': currentUserUid,
            'hospital': selectedHospital,
            'respondedAt': FieldValue.serverTimestamp(),
          });

      if (!context.mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Alert Resolved: Dispatched to $selectedHospital"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error updating: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showHospitalPicker(BuildContext context) {
    String tempSelection = "Quezon City General Hospital";
    List<String> hospitals = [
      "Quezon City General Hospital",
      "St. Luke's Medical Center",
      "Philippine Heart Center",
      "East Avenue Medical Center",
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A40),
        title: const Text(
          "Assign Hospital",
          style: TextStyle(color: Colors.white),
        ),
        content: StatefulBuilder(
          builder: (context, setDialogState) => DropdownButton<String>(
            value: tempSelection,
            isExpanded: true,
            dropdownColor: const Color(0xFF1A1A40),
            style: const TextStyle(color: Colors.white),
            items: hospitals
                .map((h) => DropdownMenuItem(value: h, child: Text(h)))
                .toList(),
            onChanged: (val) => setDialogState(() => tempSelection = val!),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _respondToIncident(context, tempSelection);
            },
            child: const Text("CONFIRM"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = "Date not recorded";
    if (details['date'] is Timestamp) {
      formattedDate = DateFormat(
        'MMMM d, yyyy - h:mm a',
      ).format((details['date'] as Timestamp).toDate());
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Incident Details")),
      body: AppBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Card(
            color: Colors.white.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Icon(
                      Icons.minor_crash_rounded,
                      size: 60,
                      color: Colors.orangeAccent,
                    ),
                  ),
                  const Divider(height: 40, color: Colors.white24),

                  _buildInfoTile("Date & Time", formattedDate),
                  _buildInfoTile(
                    "Location",
                    details['location']?.toString() ?? "Unknown",
                  ),

                  FutureBuilder<Map<String, dynamic>>(
                    future: _getDriverFullDetails(
                      details['driver_id']?.toString(),
                    ),
                    builder: (context, snapshot) {
                      final data = snapshot.data;
                      final bool loading =
                          snapshot.connectionState == ConnectionState.waiting;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoTile(
                            "Driver Name",
                            data?['name'] ?? "Loading...",
                            isLoading: loading,
                          ),
                          _buildInfoTile(
                            "Vehicle Plate Number",
                            data?['plate'] ?? "Loading...",
                            isLoading: loading,
                          ),
                          _buildInfoTile(
                            "Emergency Contact",
                            data?['emergency_phone'] ?? "Loading...",
                            isLoading: loading,
                            isWarning:
                                data?['emergency_phone'] == "No Contact Set",
                          ),
                        ],
                      );
                    },
                  ),

                  FutureBuilder<String>(
                    future: _getDispatcherName(
                      details['dispatcher_id']?.toString(),
                    ),
                    builder: (context, snapshot) {
                      String name = snapshot.data ?? "Loading...";
                      return _buildInfoTile(
                        "Assigned Dispatcher",
                        name,
                        isLoading:
                            snapshot.connectionState == ConnectionState.waiting,
                        isWarning:
                            name.contains("Awaiting") ||
                            name.contains("Not Found"),
                      );
                    },
                  ),

                  _buildInfoTile(
                    "Target Hospital",
                    (details['hospital'] == null || details['hospital'].isEmpty)
                        ? "Not Yet Set"
                        : details['hospital'],
                    isWarning: details['hospital'] == null,
                  ),

                  const SizedBox(height: 20),

                  if (details['status'] == 'ongoing')
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.send_rounded),
                        label: const Text(
                          "RESPOND TO INCIDENT",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () => _showHospitalPicker(context),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile(
    String label,
    String value, {
    bool isWarning = false,
    bool isLoading = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Colors.cyanAccent,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  value,
                  style: TextStyle(
                    fontSize: 17,
                    color: isWarning ? Colors.orangeAccent : Colors.white,
                    fontStyle: isWarning ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
        ],
      ),
    );
  }
}

Widget _buildInfoTile(
  String label,
  String value, {
  bool isWarning = false,
  bool isLoading = false,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Colors.cyanAccent,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        if (isLoading)
          const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              color: isWarning ? Colors.orangeAccent : Colors.white,
              fontStyle: isWarning ? FontStyle.italic : FontStyle.normal,
            ),
          ),
      ],
    ),
  );
}

// --- REUSABLE LIST VIEW ---

class IncidentListView extends StatelessWidget {
  final String title;
  final List<Map<String, String>> items;
  final bool isEmergency;

  const IncidentListView({
    super.key,
    required this.title,
    required this.items,
    this.isEmergency = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: AppBackground(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: const Color(0xFF5A75F9).withOpacity(0.5),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) =>
                      const Divider(color: Colors.white12),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      title: Text(
                        item['location'] ?? item['name'] ?? 'Unknown',
                      ),
                      subtitle: Text(item['time'] ?? ''),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isEmergency
                              ? Colors.red
                              : Colors.blue,
                        ),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CrashDetailsPage(details: item),
                          ),
                        ),
                        child: const Text("View"),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Dummy classes to represent your routes
class AllTasksPage extends StatefulWidget {
  const AllTasksPage({super.key});

  @override
  State<AllTasksPage> createState() => _AllTasksPageState();
}

class _AllTasksPageState extends State<AllTasksPage> {
  String _filter = 'All'; // Options: All, Ongoing, Responded

  @override
  Widget build(BuildContext context) {
    // We fetch everything, then filter locally for better UI responsiveness
    final Stream<QuerySnapshot> _taskStream = FirebaseFirestore.instance
        .collection('crash_records')
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Task Management"),
        backgroundColor: const Color(0xFF3B4CCF),
      ),
      body: AppBackground(
        // Using the reusable background from previous cleanup
        child: Column(
          children: [
            _buildFilterRow(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _taskStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text("Error loading tasks"));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data?.docs ?? [];

                  // Apply local filtering based on the 'status' field in Firestore
                  final filteredDocs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    if (_filter == 'All') return true;
                    return data['status'] == _filter.toLowerCase();
                  }).toList();

                  if (filteredDocs.isEmpty) {
                    return const Center(child: Text("No records found"));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 10,
                    ),
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final doc = filteredDocs[index];
                      final data = doc.data() as Map<String, dynamic>;

                      data['id'] = doc.id;

                      return _buildTaskCard(data);
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

  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: ['All', 'Ongoing', 'Responded'].map((status) {
          final isSelected = _filter == status;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(status),
              selected: isSelected,
              onSelected: (val) => setState(() => _filter = status),
              selectedColor: Colors.cyanAccent,
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> data) {
    final bool isResolved = data['status'] == 'responded';
    String displayDate = "N/A";
    var dateValue = data['date'];

    if (dateValue is Timestamp) {
      displayDate = DateFormat('MMM d, h:mm a').format(dateValue.toDate());
    } else if (dateValue != null) {
      displayDate = dateValue.toString();
    }
    // ---------------------------------

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: CircleAvatar(
          backgroundColor: isResolved
              ? Colors.green.withOpacity(0.2)
              : Colors.orange.withOpacity(0.2),
          child: Icon(
            isResolved ? Icons.check_circle : Icons.warning,
            color: isResolved ? Colors.greenAccent : Colors.orangeAccent,
          ),
        ),
        title: Text(
          data['location'] ?? 'Unknown Location',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            Text(
              "Time: $displayDate",
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
            const SizedBox(height: 2),
            Text(
              "Status: ${data['status']?.toUpperCase() ?? 'PENDING'}",
              style: TextStyle(
                color: isResolved ? Colors.greenAccent : Colors.cyanAccent,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5A75F9),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CrashDetailsPage(details: data),
              ),
            );
          },
          child: const Text(
            "VIEW",
            style: TextStyle(fontSize: 12, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class EmergencyAlerts extends StatelessWidget {
  const EmergencyAlerts({super.key});

  @override
  Widget build(BuildContext context) {
    final Stream<QuerySnapshot> _emergencyStream = FirebaseFirestore.instance
        .collection('crash_records')
        .where('status', isEqualTo: 'ongoing')
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Emergency Alerts"),
        backgroundColor: const Color(0xFF862134), // Emergency Red
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF862134), Color(0xFF1A1A72)],
          ),
        ),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                'URGENT INCIDENTS',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _emergencyStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError)
                    return const Center(child: Text("Error loading alerts"));
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        "No active emergencies. Stay alert!",
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;

                      data['id'] = doc.id;

                      return _buildEmergencyCard(context, data);
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

  Widget _buildEmergencyCard(BuildContext context, Map<String, dynamic> data) {
    String displayDate = "Time Unknown";
    if (data['date'] is Timestamp) {
      displayDate = DateFormat(
        'MMM d, h:mm a',
      ).format((data['date'] as Timestamp).toDate());
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      color: Colors.black26,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Colors.redAccent, width: 1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              backgroundColor: Colors.red,
              radius: 20,
              child: Icon(
                Icons.warning_amber_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 15),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['location'] ?? 'Unknown Location',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),

                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.cyanAccent,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        displayDate,
                        style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(data['driver_id'])
                        .get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Text(
                          "Loading contact...",
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        );
                      }

                      if (snapshot.hasData && snapshot.data!.exists) {
                        final userData =
                            snapshot.data!.data() as Map<String, dynamic>;
                        final List contacts =
                            userData['emergencyContacts'] ?? [];

                        if (contacts.isNotEmpty) {
                          final contact = contacts[0];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "EMERGENCY CONTACT:",
                                style: TextStyle(
                                  color: Colors.orangeAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "${contact['name']}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                "${contact['phone']}",
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          );
                        }
                      }
                      return const Text(
                        "No Emergency Contact Set",
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CrashDetailsPage(details: data),
                          ),
                        );
                      },
                      child: const Text("RESPOND TO INCIDENT"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
<<<<<<< HEAD
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 1),
=======
>>>>>>> 770f34e6b740327cc5fada233e0942c5f266b778
    );
  }
}

<<<<<<< HEAD
// --- CUSTOM BOTTOM NAVIGATION BAR (FIXED) ---
=======
// --- NAVIGATION & TILES ---

class _ActionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      tileColor: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      leading: Icon(icon, color: Colors.white, size: 30),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white70),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    );
  }
}

>>>>>>> 770f34e6b740327cc5fada233e0942c5f266b778
class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  const CustomBottomNavBar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: const Color(0xFF00CCFF),
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.black54,
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      onTap: (index) {
        if (index == currentIndex) return;
        // Navigation Logic
        Widget page;
        switch (index) {
          case 0:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const Dispatchersettingpage(),
              ),
            );
            break;
          case 1:
            page = const DashboardPage();
            break;
          case 2:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const DispatchUserProfile(),
              ),
            );
            break;
          default:
            page = const DashboardPage();
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        BottomNavigationBarItem(
          icon: Icon(Icons.home_filled),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_circle),
          label: 'Profile',
        ),
      ],
    );
  }
}
