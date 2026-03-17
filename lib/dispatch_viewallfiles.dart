import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark),
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
  int _selectedIndex = 1; // Default to Dashboard

  final List<Map<String, String>> tasks = [
    {"location": "Sta. Mesa", "time": "3:28:59 pm"},
    {"location": "San Jose Del Monte", "time": "5:08:45 pm"},
    {"location": "Bangued", "time": "10:28:57 pm"},
    {"location": "Taytay", "time": "12:28:01 pm"},
    {"location": "Tondo", "time": "2:28:43 am"},
    {"location": "Pasig", "time": "1:00:59 am"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF3B4CCF), Color(0xFF1A1A72)],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom AppBar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person, color: Colors.cyanAccent),
                    ),
                    const Text(
                      'Dashboard',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(onPressed: () {}, icon: const Icon(Icons.menu)),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'All Task',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                ),
              ),
              // Task Table Container
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF5A75F9).withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      // Header
                      _buildHeader(),
                      const Divider(color: Colors.white24, height: 1),
                      // Data Rows
                      ...tasks.map((task) => _buildTaskRow(task)).toList(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        backgroundColor: Colors.cyan,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Dashboard'),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_pin),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 15, horizontal: 15),
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
          Expanded(
            flex: 2,
            child: Text(
              'Action',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskRow(Map<String, String> task) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 15),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white12, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              task['location']!,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(task['time']!, style: const TextStyle(fontSize: 14)),
          ),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 30,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7CB9FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.zero,
                ),
                onPressed: () {},
                child: const Text(
                  'View',
                  style: TextStyle(fontSize: 12, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
