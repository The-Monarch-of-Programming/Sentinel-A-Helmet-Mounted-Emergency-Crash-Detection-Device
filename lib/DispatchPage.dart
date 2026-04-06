import 'package:flutter/material.dart';
import 'dispatchprofile.dart';
import 'dispatchersettingpage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  runApp(const DispatcherApp());
}

class DispatcherApp extends StatefulWidget {
  const DispatcherApp({super.key});

  @override
  State<DispatcherApp> createState() => _DispatcherAppState();
}

class _DispatcherAppState extends State<DispatcherApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const DashboardPage(),
    );
  }
}

//  Specific Crash Details Page
class CrashDetailsPage extends StatelessWidget {
  final Map<String, String> details;

  const CrashDetailsPage({super.key, required this.details});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Details: ${details['location'] ?? details['name']}"),
        backgroundColor: const Color(0xFF1A1A72),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF3B4CCF), Color(0xFF1A1A72)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Card(
            color: Colors.white.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Icon(
                      Icons.report_problem,
                      size: 60,
                      color: Colors.orangeAccent,
                    ),
                  ),
                  const Divider(height: 40, color: Colors.white24),

                  // Dynamically list all data found in the Map
                  ...details.entries
                      .map(
                        (entry) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.key.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.cyanAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                entry.value,
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 5),
                            ],
                          ),
                        ),
                      )
                      .toList(),

                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 248, 191, 1),
                      ),
                      child: const Text(
                        "Respond to Alert",
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 0, 247, 255),
                      ),
                      child: const Text(
                        "Back to List",
                        style: TextStyle(color: Colors.black),
                      ),
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
}

//Dashboard Page
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E31B1),
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
          style: TextStyle(fontWeight: FontWeight.w300),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF5A6AF1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Column(
                children: [
                  const Text(
                    "Dispatcher",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400),
                  ),
                  const Divider(color: Colors.white24, height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: const [
                      StatBox(label: "Active Alerts", value: "12"),
                      StatBox(label: "Resolved", value: "4"),
                      StatBox(label: "In Progress", value: "8"),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            const Text("Quick Actions", style: TextStyle(fontSize: 20)),
            const SizedBox(height: 20),
            ActionTile(
              title: "View All Task",
              subtitle: "Manage Dispatch Task",
              icon: Icons.list_alt_rounded,
              color: const Color(0xFF192BB6),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AllTasksPage()),
              ),
            ),
            const SizedBox(height: 10),
            ActionTile(
              title: "Emergency Alerts",
              subtitle: "View Urgent Alerts",
              icon: Icons.notifications_active,
              color: const Color(0xFF862134),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EmergencyAlerts(),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 1),
    );
  }
}

// --- All Tasks Page ---
class AllTasksPage extends StatefulWidget {
  const AllTasksPage({super.key});

  @override
  State<AllTasksPage> createState() => _AllTasksPageState();
}

class _AllTasksPageState extends State<AllTasksPage> {
  final List<Map<String, String>> tasks = const [
    {
      "location": "Sta. Mesa",
      "time": "3:28:59 pm",
      "detail": "Multiple vehicle collision.",
    },
    {
      "location": "San Jose Del Monte",
      "time": "5:08:45 pm",
      "detail": "Overturned truck blocking lane.",
    },
    {
      "location": "Bangued",
      "time": "10:28:57 pm",
      "detail": "Engine fire reported.",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Tasks"),
        backgroundColor: const Color(0xFF3B4CCF),
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF3B4CCF), Color(0xFF1A1A72)],
          ),
        ),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                'Task List',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF5A75F9).withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    _buildHeader(),
                    ...tasks.map((task) => _buildTaskRow(task)).toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.all(15),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'Location',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text('Time', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(flex: 2, child: Text('Action', textAlign: TextAlign.center)),
        ],
      ),
    );
  }

  Widget _buildTaskRow(Map<String, String> task) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(task['location']!)),
          Expanded(flex: 3, child: Text(task['time']!)),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CrashDetailsPage(details: task),
                  ),
                );
              },
              child: const Text("View", style: TextStyle(fontSize: 10)),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Emergency Alerts ---
class EmergencyAlerts extends StatefulWidget {
  const EmergencyAlerts({super.key});

  @override
  State<EmergencyAlerts> createState() => _EmergencyAlertsState();
}

class _EmergencyAlertsState extends State<EmergencyAlerts> {
  final List<Map<String, String>> tasks = const [
    {
      "name": "Sta. Mesa",
      "contact": "0961 212 1223",
      "status": "CRITICAL",
      "detail": "Multiple vehicle collision.",
      "time": "3:28:59 pm",
    },
    {
      "name": "San Jose Del Monte",
      "contact": "0947 234 2323",
      "status": "CRITICAL",
      "detail": "Truck accident.",
      "time": "5:08:45 pm",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Emergency Alerts"),
        backgroundColor: const Color(0xFF3B4CCF),
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF3B4CCF), Color(0xFF1A1A72)],
          ),
        ),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                'Emergency List',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF5A75F9).withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(15),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              'Name',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              'Contact',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text('Action', textAlign: TextAlign.center),
                          ),
                        ],
                      ),
                    ),
                    ...tasks
                        .map(
                          (task) => Padding(
                            padding: const EdgeInsets.all(15),
                            child: Row(
                              children: [
                                Expanded(flex: 3, child: Text(task['name']!)),
                                Expanded(
                                  flex: 3,
                                  child: Text(task['contact']!),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              CrashDetailsPage(details: task),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      "View",
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 1),
    );
  }
}

// --- Custom Bottom Nav Bar ---
class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  const CustomBottomNavBar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: const Color.fromARGB(255, 0, 204, 255),
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.black54,
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      onTap: (index) {
        if (index == currentIndex) return;
        if (index == 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const Dispatchersettingpage(),
            ),
          );
        } else if (index == 1) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const DispatcherApp()),
            (route) => false,
          );
        } else if (index == 2) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const DispatchUserProfile(),
            ),
          );
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

// --- Reusable Components ---
class ActionTile extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const ActionTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
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
                      fontWeight: FontWeight.bold,
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
        ),
      ),
    );
  }
}

class StatBox extends StatelessWidget {
  final String label, value;
  const StatBox({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 10)),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
