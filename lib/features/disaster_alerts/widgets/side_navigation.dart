import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class SideNavigation extends StatefulWidget {
  final String userName;
  final VoidCallback? onClose;

  const SideNavigation({
    Key? key,
    required this.userName,
    this.onClose,
  }) : super(key: key);

  @override
  State<SideNavigation> createState() => _SideNavigationState();
}

class _SideNavigationState extends State<SideNavigation> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  int _selectedIndex = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      elevation: 0,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(-0.3, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeOutCubic,
            )),
            child: FadeTransition(
              opacity: _animationController,
              child: child,
            ),
          );
        },
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              // Removing the ShaderMask that might be causing visibility issues
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: _buildNavigationItems(context),
              ),
            ),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        bottom: 20,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2196F3),
            const Color(0xFF1976D2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Hero(
                tag: 'profile_avatar',
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Text(
                      widget.userName[0].toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1976D2),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.userName,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        // Navigate to profile
                      },
                      child: Row(
                        children: [
                          Text(
                            'View Profile',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 12,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationItems(BuildContext context) {
    return Column(
      children: [
        _buildNavItem(
          icon: Icons.home_rounded,
          title: 'Home',
          index: 0,
          onTap: () {
            Navigator.pop(context);
            Navigator.pushReplacementNamed(context, '/home');
          },
        ),
        _buildNavItem(
          icon: Icons.notifications_rounded,
          title: 'Notifications',
          badge: '3',
          index: 1,
          onTap: () {
            // Navigate to notifications
            Navigator.pop(context);
          },
        ),
        _buildNavItem(
          icon: Icons.shield_rounded,
          title: 'Emergency Contacts',
          index: 2,
          onTap: () {
            Navigator.pop(context);
            Navigator.pushReplacementNamed(context, '/emergency_contacts');
          },
        ),
        _buildNavItem(
          icon: Icons.directions_run,
          title: 'Evacuation',
          index: 3,
          onTap: () {
            Navigator.pop(context);
            Navigator.pushReplacementNamed(context, '/evacuation');
          },
        ),
        _buildNavItem(
          icon: Icons.history_rounded,
          title: 'History',
          index: 4,
          onTap: () {
            // Navigate to history
            Navigator.pop(context);
          },
        ),
      ],
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String title,
    String? badge,
    required int index,
    VoidCallback? onTap,
  }) {
    final isSelected = _selectedIndex == index;
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeOutQuint,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(30 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              _selectedIndex = index;
            });
            
            // Execute the provided onTap callback
            if (onTap != null) {
              onTap();
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF1976D2).withOpacity(0.2) : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? const Color(0xFF1976D2) : Colors.grey.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF1976D2) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected 
                            ? const Color(0xFF1976D2).withOpacity(0.3) 
                            : Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? Colors.white : const Color(0xFF1976D2),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? const Color(0xFF1976D2) : Colors.black,
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1976D2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badge,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20, 
        right: 20,
        bottom: MediaQuery.of(context).padding.bottom + 20,
        top: 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Divider(height: 1),
          const SizedBox(height: 20),
          InkWell(
            onTap: () {
              HapticFeedback.mediumImpact();
              // Handle logout
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: Colors.red,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Logout',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}