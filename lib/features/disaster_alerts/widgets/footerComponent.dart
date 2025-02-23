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
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1A1A1A).withOpacity(0.95),
              const Color(0xFF1A1A1A),
            ],
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, -4),
            )
          ],
        ),
        child: NavigationBar(
          elevation: 0,
          height: 72,
          backgroundColor: Colors.transparent,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
          selectedIndex: currentIndex,
          animationDuration: const Duration(milliseconds: 400),
          onDestinationSelected: (index) {
            HapticFeedback.lightImpact();
            onTabSelected?.call(index);
          },
          destinations: [
            _buildDestination(context, 0, Icons.home_max_rounded, 'Home'),
            _buildDestination(context, 1, Icons.warning_amber_rounded, 'Alerts'),
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
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1.5,
                ),
              ),
              child: Icon(
                icon,
                size: 24,
                color: Colors.white70,
              ),
            ),
          );
        },
      ),
      selectedIcon: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: isSelected ? 1.0 : 0.0),
        duration: const Duration(milliseconds: 400),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF4CAF50),
                        const Color(0xFF2E7D32),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4CAF50).withOpacity(0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [Colors.white, Colors.white.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: Icon(
                      icon,
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: value,
                  child: Text(
                    label.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF4CAF50),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      label: label,
    );
  }
}