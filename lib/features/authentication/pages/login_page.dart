import 'package:flutter/material.dart';
import 'package:disaster_management/features/authentication/widgets/custom_text_field.dart';
import 'package:disaster_management/features/authentication/widgets/custom_button.dart';
import 'package:disaster_management/features/disaster_alerts/pages/home_screen.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isOtpSent = false;
  String _verificationId = '';
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
    _mobileController.dispose();
    _otpController.dispose();
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
                      'Welcome Back, Stay safe',
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
                      label: 'Mobile Number',
                      controller: _mobileController,
                      validator: (value) => value!.isEmpty || value.length != 10
                          ? 'Please enter a valid 10-digit mobile number'
                          : null,
                      keyboardType: TextInputType.phone,
                      delay: 200,
                    ),
                    SizedBox(height: 16),
                    if (_isOtpSent)
                      _buildAnimatedTextField(
                        label: 'OTP',
                        controller: _otpController,
                        validator: (value) => value!.isEmpty || value.length != 6
                            ? 'Please enter a valid 6-digit OTP'
                            : null,
                        keyboardType: TextInputType.number,
                        delay: 400,
                      ),
                    SizedBox(height: 24),
                    _buildAnimatedButton(delay: 600),
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
          text: _isOtpSent ? 'Verify OTP' : 'Send OTP',
          onPressed: _isOtpSent ? _verifyOtp : _sendOtp,
        ),
      ),
    );
  }

  Future<void> _sendOtp() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: '+91${_mobileController.text}', // Assuming Indian mobile numbers
          verificationCompleted: (PhoneAuthCredential credential) async {
            await FirebaseAuth.instance.signInWithCredential(credential);
            _navigateToHome();
          },
          verificationFailed: (FirebaseAuthException e) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Verification failed: ${e.message}')));
          },
          codeSent: (String verificationId, int? resendToken) {
            setState(() {
              _isOtpSent = true;
              _verificationId = verificationId;
            });
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            _verificationId = verificationId;
          },
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send OTP: $e')));
      }
    }
  }

  Future<void> _verifyOtp() async {
    if (_formKey.currentState!.validate()) {
      try {
        PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: _verificationId,
          smsCode: _otpController.text,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
        _navigateToHome();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid OTP')));
      }
    }
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => CombinedHomeWeatherComponent()),
    );
  }
}

