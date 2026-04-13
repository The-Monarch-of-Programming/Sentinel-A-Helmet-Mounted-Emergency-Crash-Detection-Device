import 'package:flutter/material.dart';
import 'package:sentinel_app/DispatchPage.dart';
import '../login.dart';
import '../dispatcheditprofile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dispatcher_map.dart';

class DispatchUserProfile extends StatefulWidget {
  const DispatchUserProfile({super.key});

  @override
  State<DispatchUserProfile> createState() => _DispatchUserProfileState();
}

class _DispatchUserProfileState extends State<DispatchUserProfile> {
  String name = "Loading...";
  String phone = "Not provided";
  String email = "Loading...";
  String address = "Loading...";
  String dob = "Loading...";
  String bloodType = "Loading...";

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // Fetch data from Firestore
  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get(const GetOptions(source: Source.server));

        if (userData.exists) {
          // Convert to Map to avoid "Field does not exist" crashes
          Map<String, dynamic> data = userData.data() as Map<String, dynamic>;

          setState(() {
            name = data['name'] ?? 'N/A';
            email = data['email'] ?? 'N/A';
            address = data['address'] ?? 'No address set';
            phone = data['phoneno'] ?? 'Not provided';
            dob = data['dob'] ?? 'Not set';
            bloodType = data['bloodType'] ?? 'Unknown';
          });
        }
      } catch (e) {
        print("Error fetching data: $e");
      }
    }
  }

  //PAGE BODY
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
        title: const Text('Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DispatcherMapPage()),
            ),
            icon: const Icon(Icons.location_on),
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

              _buildTextField(label: "NAME", value: name),
              _buildTextField(label: "PHONE", value: phone),
              _buildTextField(label: "EMAIL", value: email),
              _buildTextField(label: "DATE OF BIRTH", value: dob),
              _buildTextField(label: "BLOOD TYPE", value: bloodType),
              _buildTextField(label: "ADDRESS", value: address),

              const SizedBox(height: 30),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlueAccent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DispatchEditProfileScreen(),
                    ),
                  );

                  _fetchUserData();
                },
                child: const Text(
                  "Edit Profile",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();

                  if (mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                      (route) => false,
                    );
                  }
                },
                child: const Text(
                  "Logout",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF00CCFF),
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        currentIndex: 1,
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
            default:
              page = const DashboardPage();
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
        ],
      ),
    );
  }

  Widget _buildTextField({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
      child: TextField(
        readOnly: true,
        controller: TextEditingController(text: value),
        enableInteractiveSelection: false,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          filled: true,
          fillColor: Colors.lightBlue,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}