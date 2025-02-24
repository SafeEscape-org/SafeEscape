import 'package:flutter/material.dart';
import 'package:disaster_management/features/authentication/widgets/custom_text_field.dart';
import 'package:disaster_management/features/authentication/widgets/custom_button.dart';
import 'package:disaster_management/features/disaster_alerts/pages/home_screen.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({Key? key}) : super(key: key);

  @override
  RegistrationPageState createState() => RegistrationPageState();
}

class RegistrationPageState extends State<RegistrationPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _mobileController = TextEditingController();
  final _ageController = TextEditingController();
  String _gender = 'Male';
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _mobileController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.teal.shade300, Colors.teal.shade700],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 20),
                    Lottie.network(
                      'https://assets5.lottiefiles.com/packages/lf20_jcikwtux.json',
                      height: 200,
                      controller: _animationController,
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Join Smart Alert, Stay safe!',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    _buildAnimatedTextField(
                      label: 'Name',
                      controller: _nameController,
                      validator: (value) => value!.isEmpty ? 'Please enter your name' : null,
                      delay: 0,
                    ),
                    SizedBox(height: 16),
                    _buildAnimatedTextField(
                      label: 'Address',
                      controller: _addressController,
                      validator: (value) => value!.isEmpty ? 'Please enter your address' : null,
                      delay: 200,
                    ),
                    SizedBox(height: 16),
                    _buildAnimatedTextField(
                      label: 'Mobile Number',
                      controller: _mobileController,
                      validator: (value) => value!.isEmpty || value.length != 10
                          ? 'Please enter a valid 10-digit mobile number'
                          : null,
                      keyboardType: TextInputType.phone,
                      delay: 400,
                    ),
                    SizedBox(height: 16),
                    _buildAnimatedTextField(
                      label: 'Age',
                      controller: _ageController,
                      validator: (value) => int.tryParse(value!) == null || int.parse(value) <= 0
                          ? 'Please enter a valid age'
                          : null,
                      keyboardType: TextInputType.number,
                      delay: 600,
                    ),
                    SizedBox(height: 16),
                    _buildAnimatedDropdown(delay: 800),
                    SizedBox(height: 24),
                    _buildAnimatedButton(delay: 1000),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedTextField({
    required String label,
    required TextEditingController controller,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    required int delay,
  }) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(delay / 1500, (delay + 500) / 1500, curve: Curves.easeOut),
        ),
      ),
      child: SlideTransition(
        position: Tween<Offset>(begin: Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(delay / 1500, (delay + 500) / 1500, curve: Curves.easeOut),
          ),
        ),
        child: CustomTextField(
          label: label,
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
        ),
      ),
    );
  }

  Widget _buildAnimatedDropdown({required int delay}) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(delay / 1500, (delay + 500) / 1500, curve: Curves.easeOut),
        ),
      ),
      child: SlideTransition(
        position: Tween<Offset>(begin: Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(delay / 1500, (delay + 500) / 1500, curve: Curves.easeOut),
          ),
        ),
        child: DropdownButtonFormField<String>(
          value: _gender,
          decoration: InputDecoration(
            labelText: 'Gender',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.black.withOpacity(0.8),
          ),
          items: ['Male', 'Female']
              .map((label) => DropdownMenuItem(
            child: Text(label),
            value: label,
          ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _gender = value!;
            });
          },
        ),
      ),
    );
  }

  Widget _buildAnimatedButton({required int delay}) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(delay / 1500, (delay + 500) / 1500, curve: Curves.easeOut),
        ),
      ),
      child: SlideTransition(
        position: Tween<Offset>(begin: Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(delay / 1500, (delay + 500) / 1500, curve: Curves.easeOut),
          ),
        ),
        child: CustomButton(
          text: 'Register',
          onPressed: _submitForm,
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Create user in Firebase Authentication
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: "${_mobileController.text}@smartemergency.com",
          password: _mobileController.text, // Using mobile number as password (not recommended for production)
        );

        // Save user details to Firestore
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'name': _nameController.text,
          'address': _addressController.text,
          'mobile': _mobileController.text,
          'age': int.parse(_ageController.text),
          'gender': _gender,
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registration successful!')));

        // Navigate to Home screen after successful registration
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CombinedHomeWeatherComponent()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registration failed: $e')));
      }
    }
  }
}

