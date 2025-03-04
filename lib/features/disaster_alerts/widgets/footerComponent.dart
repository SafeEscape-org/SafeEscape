import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.only(top: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 24,
              spreadRadius: -2,
              offset: const Offset(0, -6),
            )
          ],
        ),
        child: NavigationBar(
          elevation: 0,
          height: 76,
          backgroundColor: Colors.transparent,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
          selectedIndex: currentIndex,
          animationDuration: const Duration(milliseconds: 400),
          onDestinationSelected: (index) {
            HapticFeedback.mediumImpact();
            onTabSelected?.call(index);
          },
          destinations: [
            _buildDestination(context, 0, Icons.home_rounded, 'Home'),
            _buildDestination(context, 1, Icons.notifications_rounded, 'Alerts'),
            _buildDestination(context, 2, Icons.health_and_safety_rounded, 'Safety'),
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

    return NavigationDestination(
      icon: TweenAnimationBuilder<double>(
        tween: Tween(begin: 1.0, end: isSelected ? 0.0 : 1.0),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, isSelected ? -8 * (1 - value) : 0),
            child: Transform.scale(
              scale: value,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutQuart,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF5F5F5),
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: Colors.grey[600],
                ),
              ),
            ),
          );
        },
      ),
      selectedIcon: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: isSelected ? 1.0 : 0.0),
        duration: const Duration(milliseconds: 600),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, -8 * value),
            child: Transform.scale(
              scale: value,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutQuart,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF2196F3),
                          const Color(0xFF1976D2),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2196F3).withOpacity(0.25),
                          blurRadius: 12,
                          spreadRadius: 0,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Transform.scale(
                      scale: 0.8 + (0.2 * value),
                      child: Icon(
                        icon,
                        size: 24,
                        color: Colors.white.withOpacity(value),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    opacity: value,
                    child: Text(
                      label.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF1976D2),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      label: label,
    );
  }
}