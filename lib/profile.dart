import 'package:flutter/material.dart';
import 'home.dart';
import 'editprofile.dart';
import 'settings.dart';

class UserProfile extends StatelessWidget {
  const UserProfile({super.key});


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3130C0),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF3130C0),
        leading: Image.asset('assets/logo.png', width: 10, height: 10),
        title: const Text('Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 30),
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white,
                child: const Icon(Icons.person, size: 60, color: Colors.grey),
              ),
              const SizedBox(height: 30),

              _buildTextField(label: "NAME"),
              _buildTextField(label: "PHONE"),
              _buildTextField(label: "EMAIL"),
              _buildTextField(label: "ADDRESS"),

              const SizedBox(height: 30),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                  );
                },
                child: const Text(
                  "Edit Profile",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
       bottomNavigationBar: NavigationBar(
        height: 60,
        backgroundColor: Colors.lightBlue,
        selectedIndex: 2,
        onDestinationSelected: (index) {
          if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsPage()),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const UserDashboard()),
            );
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
          NavigationDestination(icon: Icon(Icons.home), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildTextField({required String label}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
      child: TextField(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
