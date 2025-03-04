import 'package:disaster_management/main.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:disaster_management/features/authentication/services/auth_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
// ignore: depend_on_referenced_packages
import 'package:flutter_svg/flutter_svg.dart';

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

  // Updated modern design constants
  final _borderRadius = 20.0;
  final _primaryColor = const Color(0xFF007AFF); // iOS blue
  final _accentColor = const Color(0xFF5AC8FA); // iOS light blue
  final _backgroundColor = const Color(0xFFF2F6FC); // Light blue-tinted background
  final _textColor = const Color(0xFF333333);
  final _shadowColor = const Color(0x1A000000); // Semi-transparent shadow
  
  // Updated gradient for a more iOS feel
  LinearGradient get _primaryGradient => LinearGradient(
    colors: [_primaryColor, _accentColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Light glass effect for cards
  BoxDecoration get _glassCardDecoration => BoxDecoration(
    color: Colors.white.withOpacity(0.9),
    borderRadius: BorderRadius.circular(_borderRadius),
    boxShadow: [
      BoxShadow(
        color: _shadowColor,
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

  // Glass-like background elements
  List<Widget> generateBackgroundPattern() {
    return [
      Positioned(
        top: -100,
        right: -50,
        child: Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_primaryColor.withOpacity(0.15), _accentColor.withOpacity(0.1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
        ),
      ),
      Positioned(
        bottom: -120,
        left: -80,
        child: Container(
          width: 280,
          height: 280,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_accentColor.withOpacity(0.15), _primaryColor.withOpacity(0.1)],
              begin: Alignment.bottomRight,
              end: Alignment.topLeft,
            ),
            shape: BoxShape.circle,
          ),
        ),
      ),
      Positioned(
        top: MediaQuery.of(context).size.height * 0.4,
        left: MediaQuery.of(context).size.width * 0.5,
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.withOpacity(0.1), _accentColor.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Stack(
        children: [
          // Modern background pattern
          ...generateBackgroundPattern(),
          
          // Main content
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
                              gradient: _primaryGradient,
                              borderRadius: BorderRadius.circular(_borderRadius),
                              boxShadow: [
                                BoxShadow(
                                  color: _primaryColor.withOpacity(0.3),
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
                            shaderCallback: (bounds) => _primaryGradient.createShader(bounds),
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
                              color: _textColor.withOpacity(0.7),
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
                                color: _textColor,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Please fill in the details to get started',
                              style: GoogleFonts.montserrat(
                                fontSize: 15,
                                color: _textColor.withOpacity(0.6),
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
                            _buildAnimatedInputField(
                              controller: _addressController,
                              label: 'Address',
                              icon: Icons.location_on_outlined,
                              delay: 0.6,
                              maxLines: 2,
                            ),
                            
                            // Gender dropdown with animation
                            AnimatedBuilder(
                              animation: _animationController,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(0, 40 * (1 - _animationController.value)),
                                  child: Opacity(
                                    opacity: _animationController.value,
                                    child: Container(
                                      margin: const EdgeInsets.only(top: 16, bottom: 16),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: Colors.grey.shade200),
                                        color: Colors.grey[50],
                                        boxShadow: [
                                          BoxShadow(
                                            color: _shadowColor.withOpacity(0.05),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: DropdownButtonFormField<String>(
                                        value: _gender,
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                          labelText: 'Gender',
                                          labelStyle: GoogleFonts.montserrat(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          prefixIcon: Icon(
                                            Icons.people_outline_rounded,
                                            color: _primaryColor.withOpacity(0.7),
                                          ),
                                        ),
                                        style: GoogleFonts.montserrat(
                                          fontSize: 16,
                                          color: _textColor,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        dropdownColor: Colors.white,
                                        items: ['Male', 'Female', 'Other']
                                            .map((label) => DropdownMenuItem(
                                                  value: label,
                                                  child: Text(
                                                    label,
                                                    style: GoogleFonts.montserrat(),
                                                  ),
                                                ))
                                            .toList(),
                                        onChanged: (value) {
                                          setState(() => _gender = value!);
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Register button with animation
                            AnimatedBuilder(
                              animation: _animationController,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: 0.9 + (0.1 * _animationController.value),
                                  child: Opacity(
                                    opacity: _animationController.value,
                                    child: SizedBox(
                                      width: double.infinity,
                                      height: 58,
                                      child: ElevatedButton(
                                        onPressed: _isLoading ? null : _handleRegistration,
                                        style: ElevatedButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          backgroundColor: _primaryColor,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(18),
                                          ),
                                          elevation: 4,
                                          shadowColor: _primaryColor.withOpacity(0.4),
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                        ),
                                        child: _isLoading
                                            ? SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2.5,
                                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                ),
                                              )
                                            : Text(
                                                'Create Account',
                                                style: GoogleFonts.montserrat(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
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
                              color: _textColor.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              foregroundColor: _primaryColor,
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
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final double progress = Curves.easeOutCubic.transform(
          ((_animationController.value - delay).clamp(0, 1 - delay)) / (1 - delay),
        );

        return Transform.translate(
          offset: Offset(0, 40 * (1 - progress)),
          child: Opacity(
            opacity: progress,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 300),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 0.98 + (0.02 * value),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: _shadowColor.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextFormField(
                        controller: controller,
                        obscureText: isPassword && _obscurePassword,
                        keyboardType: keyboardType,
                        maxLines: maxLines,
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          color: _textColor,
                        ),
                        decoration: InputDecoration(
                          labelText: label,
                          labelStyle: GoogleFonts.montserrat(
                            color: Colors.grey[600],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          floatingLabelStyle: GoogleFonts.montserrat(
                            color: _primaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          prefixIcon: Icon(icon, color: _primaryColor.withOpacity(0.7), size: 22),
                          suffixIcon: isPassword
                              ? IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                                    color: Colors.grey[500],
                                    size: 22,
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscurePassword = !_obscurePassword),
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey[200]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey[200]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: _primaryColor, width: 1.5),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'This field is required';
                          }
                          return null;
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // Handle registration
  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authService.registerUser(
        context: context,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phone: _phoneController.text.trim(),
        emergencyContacts: [],
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
}