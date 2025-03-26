import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import 'animated_dropdown_field.dart';
import 'animated_button.dart';
import 'animated_input_field.dart';
import 'location_section.dart'; // We'll create this next

class RegistrationForm extends StatefulWidget {
  final AnimationController animationController;
  final Function({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String gender,
    required double? latitude,
    required double? longitude,
    required String? address,
  }) onRegister;
  final bool isLoading;

  const RegistrationForm({
    super.key,
    required this.animationController,
    required this.onRegister,
    required this.isLoading,
  });

  @override
  State<RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _obscurePassword = true;
  String _gender = 'Male';
  
  // Location data
  String? _selectedAddress;
  double? _latitude;
  double? _longitude;

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
    return Container(
      decoration: _glassCardDecoration,
      padding: const EdgeInsets.all(28),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Form header
            Text(
              'User Authentication',
              style: GoogleFonts.montserrat(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.textColor,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Please provide your information to continue',
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
            
            // Location section
            LocationSection(
              onLocationSelected: (latitude, longitude, address) {
                setState(() {
                  _latitude = latitude;
                  _longitude = longitude;
                  _selectedAddress = address;
                });
              },
              animation: widget.animationController,
            ),
            
            // Gender dropdown with animation
            AnimatedDropdownField(
              value: _gender,
              label: 'Gender',
              prefixIcon: Icons.people_outline_rounded,
              items: const ['Male', 'Female', 'Other'],
              onChanged: (value) => setState(() => _gender = value!),
              animation: widget.animationController,
              delay: 0.6,
            ),
            
            const SizedBox(height: 24),
            
            // Register button with animation
            AnimatedButton(
              onPressed: _submitForm,
              text: 'Authenticate',
              isLoading: widget.isLoading,
              animation: widget.animationController,
            ),
            
            const SizedBox(height: 24),
          ],
        ),
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
      animation: widget.animationController,
      isPassword: isPassword,
      keyboardType: keyboardType,
      maxLines: maxLines,
      obscureText: _obscurePassword,
      onTogglePassword: isPassword ? () => setState(() => _obscurePassword = !_obscurePassword) : null,
    );
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;
    
    // Validate phone number format
    String phoneNumber = _phoneController.text.trim();
    // Remove any non-digit characters from phone
    phoneNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    // Ensure we have valid location data
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
    
    widget.onRegister(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      phone: phoneNumber,
      gender: _gender,
      latitude: _latitude,
      longitude: _longitude,
      address: _selectedAddress,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}