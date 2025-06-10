import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'nav_header.dart';
import 'nav_item.dart';
import 'nav_footer.dart';
import '../../models/navigation_item.dart';
import '../../constants/colors.dart';
import 'dart:math' as math;

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

class _SideNavigationState extends State<SideNavigation> {
  late int _selectedIndex;
  final ScrollController _scrollController = ScrollController();
  final List<NavigationItem> _navItems = [];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialSelectedIndex;

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
    final Size screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen =
        screenSize.width < 360 || screenSize.height < 600;
    final double drawerWidth = math.min(
        isSmallScreen ? screenSize.width * 0.85 : 300,
        screenSize.width - 40 // Maximum width constraint
        );

    return SizedBox(
      width: drawerWidth,
      child: Drawer(
        width: drawerWidth,
        backgroundColor: EvacuationColors.backgroundColor,
        elevation: 0,
        child: SafeArea(
          child: LayoutBuilder(builder: (context, constraints) {
            return Column(
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
                  isSmallScreen: isSmallScreen,
                ),

                // Navigation items - wrap in Flexible to avoid overflow
                Flexible(
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
                      child: ListView(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.symmetric(
                          vertical: isSmallScreen ? 8 : 16,
                          horizontal: isSmallScreen ? 8 : 12,
                        ),
                        children: List.generate(
                          _navItems.length,
                          (index) => NavItem(
                            item: _navItems[index],
                            isSelected: _selectedIndex == index,
                            index: index,
                            onTap: () => _handleItemTap(index),
                            isSmallScreen: isSmallScreen,
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
                      builder: (context) =>
                          _buildLogoutConfirmation(context, isSmallScreen),
                    );
                  },
                  isSmallScreen: isSmallScreen,
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildLogoutConfirmation(BuildContext context, bool isSmallScreen) {
    final double modalHeight = math.min(
        MediaQuery.of(context).size.height * (isSmallScreen ? 0.2 : 0.25),
        isSmallScreen ? 180.0 : 220.0 // Maximum height constraint
        );

    return Container(
      height: modalHeight,
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
          const SizedBox(height: 16),
          Text(
            'Logout',
            style: GoogleFonts.poppins(
              fontSize: isSmallScreen ? 18 : 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
          Text(
            'Are you sure you want to logout?',
            style: GoogleFonts.poppins(
              fontSize: isSmallScreen ? 14 : 16,
              color: Colors.black87,
            ),
          ),
          Spacer(),
          Padding(
            padding: EdgeInsets.only(bottom: isSmallScreen ? 16 : 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 16 : 24,
                      vertical: isSmallScreen ? 8 : 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    side: BorderSide(color: EvacuationColors.primaryColor),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.w500,
                      color: EvacuationColors.primaryColor,
                    ),
                  ),
                ),
                SizedBox(width: isSmallScreen ? 12 : 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Handle logout action
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 16 : 24,
                      vertical: isSmallScreen ? 8 : 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    'Logout',
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
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
