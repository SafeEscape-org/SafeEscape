import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/navigation_item.dart';
import '../../constants/colors.dart';

class NavItem extends StatefulWidget {
  final NavigationItem item;
  final bool isSelected;
  final int index;
  final VoidCallback onTap;

  const NavItem({
    Key? key,
    required this.item,
    required this.isSelected,
    required this.index,
    required this.onTap,
  }) : super(key: key);

  @override
  State<NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<NavItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _iconScaleAnimation;
  late Animation<double> _alertPulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _iconScaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _alertPulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.2),
        weight: 1.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0),
        weight: 1.0,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.item.hasAlert) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(NavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _controller.forward(from: 0).then((_) => _controller.reverse());
      }
    }

    if (widget.item.hasAlert != oldWidget.item.hasAlert) {
      if (widget.item.hasAlert) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
      }
    }
  }

  Color _getAlertColor() {
    switch (widget.item.alertLevel) {
      case AlertLevel.high:
        return Colors.red;
      case AlertLevel.medium:
        return Colors.orange;
      case AlertLevel.low:
        return Colors.yellow;
      default:
        return Colors.transparent;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (widget.index * 100)),
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
        padding: const EdgeInsets.only(bottom: 8),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            widget.onTap();
          },
          onTapDown: (_) => _controller.forward(),
          onTapUp: (_) => _controller.reverse(),
          onTapCancel: () => _controller.reverse(),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              );
            },
            child: Stack(
              children: [
                _buildNavItemContent(),
                if (widget.item.hasAlert)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: AnimatedBuilder(
                      animation: _alertPulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _alertPulseAnimation.value,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _getAlertColor(),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _getAlertColor().withOpacity(0.5),
                                  blurRadius: 6,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItemContent() {
    final alertColor = _getAlertColor();
    final hasAlert = widget.item.hasAlert;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: widget.isSelected
            ? (hasAlert ? alertColor.withOpacity(0.1) : EvacuationColors.primaryColor.withOpacity(0.1))
            : Colors.grey.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isSelected
              ? (hasAlert ? alertColor : EvacuationColors.primaryColor)
              : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: widget.isSelected
            ? [
                BoxShadow(
                  color: (hasAlert ? alertColor : EvacuationColors.primaryColor).withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Icon container with map-themed animation
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Animated background for selected items
                  if (widget.isSelected)
                    Transform.scale(
                      scale: _iconScaleAnimation.value * 0.9,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (hasAlert ? alertColor : EvacuationColors.primaryColor).withOpacity(0.2),
                        ),
                      ),
                    ),
                  
                  // Icon container
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: widget.isSelected
                          ? (hasAlert ? alertColor : EvacuationColors.primaryColor)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: widget.isSelected
                              ? (hasAlert ? alertColor : EvacuationColors.primaryColor).withOpacity(0.3)
                              : Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.item.icon,
                      color: widget.isSelected
                          ? Colors.white
                          : (hasAlert ? alertColor : widget.item.iconColor ?? EvacuationColors.primaryColor),
                      size: 24,
                    ),
                  ),
                  
                  // Ripple effect for selected items
                  if (widget.isSelected)
                    ...List.generate(2, (index) {
                      final delay = index * 0.4;
                      final progress = (_controller.value - delay) % 1.0;
                      
                      // Only show if within the visible range
                      if (progress < 0) return const SizedBox();
                      
                      return Transform.scale(
                        scale: 0.5 + (progress * 0.8),
                        child: Opacity(
                          opacity: (1.0 - progress) * 0.4,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: hasAlert ? alertColor : EvacuationColors.primaryColor,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              );
            },
          ),
          
          const SizedBox(width: 16),
          
          // Title with animated underline for selected items
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.item.title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: widget.isSelected
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: widget.isSelected
                        ? (hasAlert ? alertColor : EvacuationColors.primaryColor)
                        : EvacuationColors.textColor,
                  ),
                ),
                
                // Animated underline for selected items
                if (widget.isSelected)
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Container(
                        margin: const EdgeInsets.only(top: 4),
                        height: 2,
                        width: 20 + (30 * _controller.value),
                        decoration: BoxDecoration(
                          color: hasAlert ? alertColor : EvacuationColors.primaryColor,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          
          // Badge or distance indicator
          if (widget.item.badge != null)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: widget.item.badgeColor ?? EvacuationColors.primaryColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: (widget.item.badgeColor ?? EvacuationColors.primaryColor)
                        .withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                widget.item.badge!,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}