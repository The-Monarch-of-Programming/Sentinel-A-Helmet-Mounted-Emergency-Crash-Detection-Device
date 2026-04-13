import 'package:flutter/material.dart';
import 'package:sentinel_app/login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _phoneNumber = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  String? _selectedBloodType;

  bool _isLoading = false;

  Future<void> _signUp() async {
    // Basic Validation
    if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Passwords do not match!")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create user in Firebase Authentication
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Save the Name and Email to Cloud Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'uid': userCredential.user!.uid,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phoneno': _phoneNumber.text.trim(),
        'address': _address.text.trim(),
        'dob': _dobController.text,
        'bloodType': _selectedBloodType ?? 'Unknown',
        'createdAt': DateTime.now(),
        'role': 'driver',
      });

      // Navigate to Login or Dashboard after success
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = "The email address is not valid.";

      if (e.code == 'email-already-in-use') {
        message = "This email is already registered. Try logging in!";
      } else if (e.code == 'weak-password') {
        message = "The password provided is too weak.";
      } else if (e.code == 'invalid-email') {
        message = "The email address is not valid.";
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _dobController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  //PAGE BODY
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFF3031C0),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
        height: MediaQuery.of(context).size.height - 50,
        width: double.infinity,
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              const Column(
                children: <Widget>[
                  Text(
                    "Sign up",
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Create an account to enjoy sentinel service",
                    style: TextStyle(fontSize: 15),
                  ),
                ],
              ),
              Column(
                children: <Widget>[
                  inputFile(label: "Name", controller: _nameController),
                  inputFile(label: "Email", controller: _emailController),
                  inputFile(label: "Phone Number", controller: _phoneNumber),
                  _buildCalendarField(context, "Date of Birth", _dobController),
                  _buildDropdown("Blood Type", (newValue) {
                    setState(() {
                      _selectedBloodType =
                          newValue; // Updating the state when selected
                    });
                  }),
                  inputFile(
                    label: "Address",
                    controller: _address,
                    maxLines: 3,
                  ),
                  inputFile(
                    label: "Password",
                    obscureText: true,
                    controller: _passwordController,
                  ),
                  inputFile(
                    label: "Confirm Password ",
                    obscureText: true,
                    controller: _confirmPasswordController,
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.only(top: 3, left: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  border: const Border(
                    bottom: BorderSide(color: Colors.black),
                    top: BorderSide(color: Colors.black),
                    left: BorderSide(color: Colors.black),
                    right: BorderSide(color: Colors.black),
                  ),
                ),
                child: MaterialButton(
                  minWidth: double.infinity,
                  height: 50,
                  onPressed: () {
                    _isLoading ? null : _signUp();
                  },
                  color: Colors.lightBlue,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Text(
                    "Sign up",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text("Already have an account?"),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginPage()),
                      );
                    },
                    child: const Text(
                      'Login',
                      style: TextStyle(color: Colors.lightBlue),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  //Widget textfield
  Widget inputFile({
    label,
    obscureText = false,
    int maxLines = 1,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Colors.lightBlue),
        ),
        const SizedBox(height: 5),
        TextField(
          style: const TextStyle(color: Colors.lightBlue),
          obscureText: obscureText,
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(
              vertical: maxLines > 1 ? 15 : 0,
              horizontal: 10,
            ),
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            border: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  //widget calendar popup
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
          DateTime? pickedDate = await showDatePicker(
            context: context,
            initialDate: DateTime(2000),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(
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
            // Check if the screen is still active
            if (mounted) {
              setState(() {
                controller.text =
                    "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
              });
            }
          }
        },
      ),
    );
  }

  Widget _buildDropdown(String label, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedBloodType,
        style: const TextStyle(color: Colors.black),
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
}