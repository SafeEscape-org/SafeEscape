import 'package:disaster_management/features/authentication/widgets/background_pattern.dart';
import 'package:disaster_management/features/authentication/widgets/location_search_dialog.dart'; // Add this import
import 'package:disaster_management/main.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:disaster_management/features/authentication/services/auth_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
// ignore: depend_on_referenced_packages
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/app_colors.dart';
import '../widgets/animated_dropdown_field.dart';
import '../widgets/animated_button.dart';
import '../widgets/animated_input_field.dart';
import 'package:disaster_management/services/location_service.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _gender = 'Male';  
  // Light glass effect for cards
  BoxDecoration get _glassCardDecoration => BoxDecoration(
    color: Colors.white.withOpacity(0.9),
    borderRadius: BorderRadius.circular(AppColors.borderRadius),
    boxShadow: [
      BoxShadow(
        color: AppColors.shadowColor,
        blurRadius: 16,
        offset: const Offset(0, 4),
        spreadRadius: 0,
      ),
    ],
    border: Border.all(
      color: Colors.white.withOpacity(0.2),
      width: 1.5,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Stack(
        children: [
          const BackgroundPattern(), // Replace generateBackgroundPattern()
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 30),
                    
                    // Modern app branding
                    Center(
                      child: Column(
                        children: [
                          // App logo with glass effect
                          Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(AppColors.borderRadius),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryColor.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                  spreadRadius: -5,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.health_and_safety_outlined,
                              size: 48,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // App name with gradient text
                          ShaderMask(
                            shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
                            child: Text(
                              'SafeEscape',
                              style: GoogleFonts.montserrat(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Your safety companion',
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textColor.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Modern glass form container
                    Container(
                      decoration: _glassCardDecoration,
                      padding: const EdgeInsets.all(28),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Form header
                            Text(
                              'Create Account',
                              style: GoogleFonts.montserrat(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textColor,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Please fill in the details to get started',
                              style: GoogleFonts.montserrat(
                                fontSize: 15,
                                color: AppColors.textColor.withOpacity(0.6),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 32),
                            
                            // Form fields with subtle animations
                            _buildAnimatedInputField(
                              controller: _nameController,
                              label: 'Full Name',
                              icon: Icons.person_outline_rounded,
                              delay: 0.2,
                            ),
                            _buildAnimatedInputField(
                              controller: _emailController,
                              label: 'Email',
                              icon: Icons.email_outlined,
                              delay: 0.3,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            _buildAnimatedInputField(
                              controller: _passwordController,
                              label: 'Password',
                              icon: Icons.lock_outline_rounded,
                              isPassword: true,
                              delay: 0.4,
                            ),
                            _buildAnimatedInputField(
                              controller: _phoneController,
                              label: 'Phone Number',
                              icon: Icons.phone_iphone,
                              delay: 0.5,
                              keyboardType: TextInputType.phone,
                            ),
                            _buildLocationSection(), // Add this line
                            // Gender dropdown with animation
                            AnimatedDropdownField(
                              value: _gender,
                              label: 'Gender',
                              prefixIcon: Icons.people_outline_rounded,
                              items: const ['Male', 'Female', 'Other'],
                              onChanged: (value) => setState(() => _gender = value!),
                              animation: _animationController,
                              delay: 0.6,
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Register button with animation
                            AnimatedButton(
                              onPressed: _handleRegistration,
                              text: 'Create Account',
                              isLoading: _isLoading,
                              animation: _animationController,
                            ),
                            
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                    
                    // Already have account section
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: GoogleFonts.montserrat(
                              color: AppColors.textColor.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              foregroundColor: AppColors.primaryColor,
                            ),
                            child: Text(
                              'Sign In',
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
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

  // Modernized input field with subtle animations
  Widget _buildAnimatedInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required double delay,
    bool isPassword = false,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return AnimatedInputField(
      controller: controller,
      label: label,
      icon: icon,
      delay: delay,
      animation: _animationController,
      isPassword: isPassword,
      keyboardType: keyboardType,
      maxLines: maxLines,
      obscureText: _obscurePassword,
      onTogglePassword: isPassword ? () => setState(() => _obscurePassword = !_obscurePassword) : null,
    );
  }

  // Handle registration
  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Check if location is selected
    if (_latitude == null || _longitude == null) {
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
      await _authService.registerUser(
        context: context,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phone: _phoneController.text.trim(),
        emergencyContacts: [],
        latitude: _latitude!,
        longitude: _longitude!,
        address: _selectedAddress ?? '',
      );
    } catch (e) {
      if (mounted) {
        // Show modern error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString(),
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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }
  
  // Add these variables
  String? _selectedAddress;
  double? _latitude;
  double? _longitude;
  bool _isLoadingLocation = false;

  // Add this method to handle current location selection
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      final locationData = await LocationService.getCurrentLocation(context);
      if (locationData != null) {
        setState(() {
          _latitude = locationData['latitude'];
          _longitude = locationData['longitude'];
          _selectedAddress = locationData['address'];
          _addressController.text = locationData['address'] ?? '';
        });
      }
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  // Add this widget before the gender dropdown in the form
  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Location',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textColor,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: AnimatedInputField(
                controller: _addressController,
                label: 'Address',
                icon: Icons.location_on_outlined,
                delay: 0.6,
                animation: _animationController,
                maxLines: 2,
                // Use readOnly instead of enabled if AnimatedInputField supports it
                // readOnly: true,
              ),
            ),
            const SizedBox(width: 8),
            // Custom location search button
            Container(
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: _openLocationSearch,
                icon: const Icon(Icons.search_rounded, color: Colors.white),
                tooltip: 'Search location',
              ),
            ),
            const SizedBox(width: 8),
            // Current location button
            Container(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                icon: _isLoadingLocation
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.my_location, color: Colors.white),
                tooltip: 'Use current location',
              ),
            ),
          ],
        ),
        if (_selectedAddress != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Selected: $_selectedAddress',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: AppColors.primaryColor,
              ),
            ),
          ),
      ],
    );
  }
  
  // Add this method to open location search dialog
  Future<void> _openLocationSearch() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const LocationSearchDialog(), // Add const here
    );
    
    if (result != null) {
      setState(() {
        _latitude = result['latitude'];
        _longitude = result['longitude'];
        _selectedAddress = result['address'];
        _addressController.text = result['address'] ?? '';
      });
    }
  } // End of _buildLocationSection
} // End of _RegistrationPageState
