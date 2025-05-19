import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import 'nav_header.dart';
import 'nav_item.dart';
import 'nav_footer.dart';
import '../../common/animated_background.dart';
import '../../models/navigation_item.dart';
import '../../constants/colors.dart';

class SideNavigation extends StatefulWidget {
  final String userName;
  final String? userEmail;
  final String? userAvatar;
  final VoidCallback? onClose;
  final int initialSelectedIndex;
  final Function(int index)? onItemSelected;

  const SideNavigation({
    Key? key,
    required this.userName,
    this.userEmail,
    this.userAvatar,
    this.onClose,
    this.initialSelectedIndex = 0,
    this.onItemSelected,
  }) : super(key: key);

  @override
  State<SideNavigation> createState() => _SideNavigationState();
}

class _SideNavigationState extends State<SideNavigation>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late int _selectedIndex;
  final ScrollController _scrollController = ScrollController();
  final List<NavigationItem> _navItems = [];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialSelectedIndex;

    // Animation controller for entrance and exit animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animationController.forward();

    // Initialize navigation items
    _initNavigationItems();
  }

  void _initNavigationItems() {
    _navItems.addAll([
      NavigationItem(
        icon: Icons.home_rounded,
        title: 'Home',
        route: '/home',
      ),
      NavigationItem(
        icon: Icons.notifications_rounded,
        title: 'Notifications',
        badge: '3',
        route: '/notifications',
      ),
      NavigationItem(
        icon: Icons.shield_rounded,
        title: 'Emergency Contacts',
        route: '/emergency_contacts',
      ),
      NavigationItem(
        icon: Icons.directions_run,
        title: 'Evacuation',
        route: '/evacuation',
      ),
      NavigationItem(
        icon: Icons.history_rounded,
        title: 'History',
        route: '/history',
      ),
      NavigationItem(
        icon: Icons.settings_rounded,
        title: 'Settings',
        route: '/settings',
      ),
    ]);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleItemTap(int index) {
    if (_selectedIndex == index) return;

    HapticFeedback.selectionClick();
    setState(() {
      _selectedIndex = index;
    });

    if (widget.onItemSelected != null) {
      widget.onItemSelected!(index);
    }

    // Navigate to the selected route
    final route = _navItems[index].route;
    if (route != null) {
      Navigator.pop(context);
      Navigator.pushReplacementNamed(context, route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: EvacuationColors.backgroundColor,
      elevation: 0,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(-0.2, 0),
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
            // Header with user profile
            NavHeader(
              userName: widget.userName,
              userEmail: widget.userEmail,
              userAvatar: widget.userAvatar,
              onProfileTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/profile');
              },
            ),

            // Navigation items
            Expanded(
              child: Theme(
                data: Theme.of(context).copyWith(
                  scrollbarTheme: ScrollbarThemeData(
                    thumbColor: MaterialStateProperty.all(
                      EvacuationColors.primaryColor.withOpacity(0.5),
                    ),
                    radius: const Radius.circular(10),
                    thickness: MaterialStateProperty.all(5),
                  ),
                ),
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 12,
                    ),
                    child: Column(
                      children: List.generate(
                        _navItems.length,
                        (index) => NavItem(
                          item: _navItems[index],
                          isSelected: _selectedIndex == index,
                          index: index,
                          onTap: () => _handleItemTap(index),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Footer with logout button
            NavFooter(
              onLogoutTap: () {
                HapticFeedback.mediumImpact();
                // Show confirmation dialog
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (context) => _buildLogoutConfirmation(context),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutConfirmation(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.25,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Logout',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Are you sure you want to logout?',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: EvacuationColors.primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: EvacuationColors.primaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Handle logout
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Logout',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
