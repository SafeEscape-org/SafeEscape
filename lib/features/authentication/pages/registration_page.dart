import 'package:disaster_management/features/authentication/widgets/background_pattern.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../widgets/app_branding.dart';
import '../widgets/registration_form.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Stack(
        children: [
          const BackgroundPattern(),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 30),
                    
                    // App branding component
                    const AppBranding(),
                    
                    const SizedBox(height: 40),
                    
                    // Registration form component
                    RegistrationForm(
                      animationController: _animationController,
                      onRegister: _handleRegistration,
                      isLoading: _isLoading,
                    ),
                    
                    // Privacy note
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          'Your information is secure and will only be used for emergency purposes',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            color: AppColors.textColor.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Handle registration
  Future<void> _handleRegistration({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String gender,
    required double? latitude,
    required double? longitude,
    required String? address,
  }) async {
    // Check if location is selected
    if (latitude == null || longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select your location',
            style: GoogleFonts.montserrat(),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // First, register the user with Firebase Authentication
      print('Attempting to create user with email: ${email.trim()}');
      final UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      // Update the user's display name
      await userCredential.user?.updateDisplayName(name.trim());
      
      // Print debug information
      print('User created with UID: ${userCredential.user!.uid}');
      
      // Create user data map
      final userData = {
        'name': name.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'gender': gender,
        'emergencyContacts': [],
        'location': {
          'latitude': latitude,
          'longitude': longitude,
          'address': address ?? '',
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'lastActive': FieldValue.serverTimestamp(),
      };
      
      print('Attempting to create Firestore document with data: $userData');
      
      try {
        // Now, manually create the user document in Firestore with error handling
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(userData)
            .timeout(const Duration(seconds: 15)); // Add timeout
        
        print('Firestore document created successfully');
        
        // Verify the document was created
        final docSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();
            
        if (!docSnapshot.exists) {
          print('ERROR: Document was not created in Firestore');
          throw Exception('Failed to create user document in Firestore');
        } else {
          print('Document verified in Firestore: ${docSnapshot.data()}');
          
          // Navigate to the home screen or wherever you want to go after registration
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/home');
          }
        }
      } catch (firestoreError) {
        print('Firestore error: $firestoreError');
        
        // Try an alternative approach with a different collection reference
        try {
          print('Trying alternative Firestore approach...');
          final db = FirebaseFirestore.instance;
          await db.collection('users').doc(userCredential.user!.uid).set(userData);
          
          print('Alternative Firestore approach succeeded');
          
          // Navigate to the home screen
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/home');
          }
        } catch (alternativeError) {
          print('Alternative Firestore approach failed: $alternativeError');
          throw Exception('Failed to create user document: $alternativeError');
        }
      }
    } catch (e) {
      print('Registration error: $e');
      if (mounted) {
        // Show modern error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Registration failed: ${e.toString()}',
              style: GoogleFonts.montserrat(),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Initialize animations
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuart,
    ));

    // Start animation after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}