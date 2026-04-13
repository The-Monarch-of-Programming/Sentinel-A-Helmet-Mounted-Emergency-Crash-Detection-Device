import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sentinel_app/login.dart';
import 'widgets/bottomnavbar.dart';
import 'home.dart';
import 'editprofile.dart';
import 'settings.dart';
import 'map.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({super.key});

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  String name = "Loading...";
  String phone = "Not provided";
  String email = "Loading...";
  String address = "Loading...";
  String dob = "Loading...";
  String bloodType = "Loading...";
  String role = "";
  List<Map<String, dynamic>> _emergencyContacts = [];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        DocumentSnapshot userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userData.exists) {
          Map<String, dynamic> data = userData.data() as Map<String, dynamic>;

          setState(() {
            name = data['name'] ?? 'N/A';
            email = data['email'] ?? 'N/A';
            address = data['address'] ?? 'No address set';
            phone = data['phoneno'] ?? 'Not provided';
            dob = data['dob'] ?? 'Not set';
            bloodType = data['bloodType'] ?? 'Unknown';
            role = data['role'] ?? 'Not Set';

            _emergencyContacts = List<Map<String, dynamic>>.from(
              data['emergencyContacts'] ?? [],
            );
          });
        }
      } catch (e) {
        print("Error fetching data: $e");
      }
    }
  }

  void _showEmergencyContacts() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF3130C0),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Emergency Contacts",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      // Call your existing add logic
                      await _addNewContact();
                      // Force the bottom sheet list to refresh
                      setSheetState(() {});
                    },
                    icon: const Icon(
                      Icons.add_circle,
                      color: Colors.lightBlueAccent,
                      size: 30,
                    ),
                  ),
                  const Divider(color: Colors.white24),

                  if (_emergencyContacts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        "No contacts added.",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),

                  ..._emergencyContacts
                      .map(
                        (contact) => ListTile(
                          title: Text(
                            contact['name'] ?? 'N/A',
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            "${contact['relationship']} • ${contact['phone']}",
                            style: const TextStyle(color: Colors.white70),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.white70,
                                ),
                                onPressed: () async {
                                  await _editContact(contact);
                                  setSheetState(() {});
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () async {
                                  await _confirmDelete(contact);
                                  setSheetState(() {});
                                },
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> contact) async {
    bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF3130C0),
        title: const Text(
          "Delete Contact?",
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          "Remove ${contact['name']}?",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'emergencyContacts': FieldValue.arrayRemove([contact]),
            });

        await _fetchUserData();
      }
    }
  }

  Future<void> _editContact(Map<String, dynamic> oldContact) async {
    final nameController = TextEditingController(text: oldContact['name']);
    final phoneController = TextEditingController(text: oldContact['phone']);
    final relationController = TextEditingController(
      text: oldContact['relationship'],
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF3130C0),
        title: const Text(
          "Edit Contact",
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogTextField(nameController, "Name", Icons.person),
            const SizedBox(height: 10),
            _buildDialogTextField(phoneController, "Phone", Icons.phone),
            const SizedBox(height: 10),
            _buildDialogTextField(
              relationController,
              "Relation",
              Icons.family_restroom,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                final newContact = {
                  'name': nameController.text.trim(),
                  'phone': phoneController.text.trim(),
                  'relationship': relationController.text.trim(),
                  'addedAt': oldContact['addedAt'],
                };

                final userRef = FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid);

                setState(() {
                  int index = _emergencyContacts.indexOf(oldContact);
                  if (index != -1) {
                    _emergencyContacts[index] = newContact;
                  }
                });

                Navigator.pop(context);

                try {
                  await userRef.update({
                    'emergencyContacts': FieldValue.arrayRemove([oldContact]),
                  });
                  await userRef.update({
                    'emergencyContacts': FieldValue.arrayUnion([newContact]),
                  });

                  _fetchUserData();
                } catch (e) {
                  print("Firestore Error: $e");
                }
              }
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  Future<void> _addNewContact() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final relationController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF3130C0),
        title: const Text("Add Contact", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogTextField(nameController, "Name", Icons.person),
            const SizedBox(height: 10),
            _buildDialogTextField(
              phoneController,
              "Phone",
              Icons.phone,
              inputType: TextInputType.phone,
            ),
            const SizedBox(height: 10),
            _buildDialogTextField(
              relationController,
              "Relation",
              Icons.family_restroom,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty || phoneController.text.isEmpty)
                return;

              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                final newContact = {
                  'name': nameController.text.trim(),
                  'phone': phoneController.text.trim(),
                  'relationship': relationController.text.trim(),
                  'addedAt': DateTime.now().toIso8601String(),
                };

                // Update UI instantly
                setState(() {
                  _emergencyContacts.add(newContact);
                });

                Navigator.pop(context);

                // Update Firestore
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .update({
                      'emergencyContacts': FieldValue.arrayUnion([newContact]),
                    });

                _fetchUserData(); // Sync with DB
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
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
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 30),
              const CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 60, color: Colors.grey),
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
                onPressed: _showEmergencyContacts,
                child: const Text(
                  "Emergency Contacts",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 15),
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
                      builder: (context) => const EditProfileScreen(),
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
      bottomNavigationBar: role == ""
          ? const SizedBox()
          : CustomBottomNavBar(currentIndex: 2, role: role),
    );
  }

  Widget _buildTextField({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
      child: TextFormField(
        key: Key(value),
        readOnly: true,
        initialValue: value,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          filled: true,
          fillColor: Colors.lightBlue,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _buildDialogTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType inputType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white70),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white24),
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.lightBlueAccent),
          borderRadius: BorderRadius.circular(10),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
      ),
    );
  }
}
