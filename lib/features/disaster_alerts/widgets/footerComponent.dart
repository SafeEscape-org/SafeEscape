import 'package:flutter/material.dart';

class FooterComponent extends StatelessWidget {
  final Function(int)? onTabSelected;
  final int currentIndex;

  const FooterComponent({
    super.key,
    this.onTabSelected,
    this.currentIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.only(top: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A), // Deep black background
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 16,
              spreadRadius: 4,
              offset: const Offset(0, -6),)
          ],
        ),
        child: NavigationBar(
          elevation: 0,
          height: 76,
          backgroundColor: Colors.transparent,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
          selectedIndex: currentIndex,
          animationDuration: const Duration(milliseconds: 400),
          onDestinationSelected: onTabSelected,
          destinations: [
            _buildDestination(context, 0, Icons.home_filled, 'Home'),
            _buildDestination(context, 1, Icons.warning_rounded, 'Alerts'),
            _buildDestination(context, 2, Icons.emergency_rounded, 'Safety'),
          ],
        ),
      ),
    );
  }

  NavigationDestination _buildDestination(
    BuildContext context,
    int index,
    IconData icon,
    String label,
  ) {
    final isSelected = index == currentIndex;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return NavigationDestination(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Icon(
          icon,
          size: 26,
          color: isSelected ? const Color(0xFF00FF00) : Colors.white70,
        ),
      ),
      selectedIcon: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0.8, end: 1.0),
            duration: const Duration(milliseconds: 300),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF00FF00).withOpacity(0.3),
                        const Color(0xFF00FF00).withOpacity(0.1),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00FF00).withOpacity(0.2),
                        blurRadius: 12,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    size: 28,
                    color: const Color(0xFF00FF00),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 6),
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: const Color(0xFF00FF00),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              fontSize: 10,
            ),
          ),
        ],
      ),
      label: label,
    );
  }
}