import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DispatchEditProfileScreen extends StatefulWidget {
  const DispatchEditProfileScreen({super.key});

  @override
  State<DispatchEditProfileScreen> createState() => _DispatchEditProfileState();
}

class _DispatchEditProfileState extends State<DispatchEditProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  String? _selectedBloodType;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Load current data when the page opens
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Get the current document from Firestore
      DocumentSnapshot userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userData.exists) {
        Map<String, dynamic> data = userData.data() as Map<String, dynamic>;
        setState(() {
          // Fill the controllers with existing data
          _nameController.text = data['name'] ?? '';
          _emailController.text = data['email'] ?? '';
          _addressController.text = data['email'] ?? '';
          _phoneController.text = data['phoneno'] ?? '';
          _dobController.text = data['dob'] ?? '';
          _selectedBloodType = data['bloodType'];
        });
      }
    }
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'name': _nameController.text.trim(),
              'phoneno': _phoneController.text.trim(),
              'dob': _dobController.text.trim(),
              'bloodType': _selectedBloodType,
              // email is usually not updated here as it's linked to Auth
            });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile Updated Successfully!")),
        );
        Navigator.pop(context); // Go back to Profile Page
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to update: $e")));
      }
    }
    setState(() => _isLoading = false);
  }

  //PAGE BODY
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3130C0),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF3130C0),
        title: const Text("Edit Profile"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.person, size: 60, color: Colors.grey),
                ),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.lightBlue,
                  child: const Icon(Icons.edit, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 30),

            _buildTextField("Name", _nameController),
            _buildTextField("Email", _emailController),
            _buildTextField("Address", _addressController),
            _buildTextField("Phone Number", _phoneController),
            _buildCalendarField(context, "Birth", _dobController),
            _buildDropdown(
              "Blood Type",
              (val) => setState(() => _selectedBloodType = val),
            ),

            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: _isLoading ? null : _updateProfile,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "Save Changes",
                      style: TextStyle(color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,

          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedBloodType,
        style: const TextStyle(color: Colors.black),
        // dropdownColor: Colors.white,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        items: const [
          DropdownMenuItem(value: "Type O", child: Text("Type O")),
          DropdownMenuItem(value: "Type O-", child: Text("Type O-")),
          DropdownMenuItem(value: "Type A", child: Text("Type A")),
          DropdownMenuItem(value: "Type A-", child: Text("Type A-")),
          DropdownMenuItem(value: "Type B", child: Text("Type B")),
          DropdownMenuItem(value: "Type B-", child: Text("Type B-")),
          DropdownMenuItem(value: "Type AB", child: Text("Type AB")),
          DropdownMenuItem(value: "Unknown", child: Text("Unknown")),
        ],
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildCalendarField(
    BuildContext context,
    String label,
    TextEditingController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: controller,
        readOnly: true,
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          suffixIcon: const Icon(Icons.calendar_today, color: Colors.lightBlue),
        ),
        onTap: () async {
          DateTime initialDate = DateTime.now();
          if (controller.text.isNotEmpty) {
            try {
              List<String> parts = controller.text.split('/');
              initialDate = DateTime(
                int.parse(parts[2]),
                int.parse(parts[1]),
                int.parse(parts[0]),
              );
            } catch (e) {
              initialDate = DateTime.now();
            }
          }

          DateTime? pickedDate = await showDatePicker(
            context: context,
            initialDate: initialDate,
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: ColorScheme.light(
                    primary: Colors.lightBlue,
                    onPrimary: Colors.white,
                    onSurface: Colors.black,
                  ),
                  textButtonTheme: TextButtonThemeData(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.lightBlue,
                    ),
                  ),
                ),
                child: child!,
              );
            },
          );

          if (pickedDate != null) {
            controller.text =
                "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
          }
        },
      ),
    );
  }
}
