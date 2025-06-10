import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../models/place_type.dart';
import 'dart:ui';

class PlaceTypeSelector extends StatefulWidget {
  final PlaceType selectedPlaceType;
  final Function(PlaceType) onTypeSelected;

  const PlaceTypeSelector({
    Key? key,
    required this.selectedPlaceType,
    required this.onTypeSelected,
  }) : super(key: key);

  @override
  State<PlaceTypeSelector> createState() => _PlaceTypeSelectorState();
}

class _PlaceTypeSelectorState extends State<PlaceTypeSelector>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _selectionAnimationController;
  late Animation<double> _selectionAnimation;

  // Track item positions for spring physics
  List<GlobalKey> _itemKeys = [];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Initialize selection animation
    _selectionAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _selectionAnimation = CurvedAnimation(
      parent: _selectionAnimationController,
      curve: Curves.easeOutCubic,
    );

    // Create keys for all place types
    _itemKeys = List.generate(
      PlaceType.values.length,
      (index) => GlobalKey(),
    );

    // Trigger initial animation
    _selectionAnimationController.forward();
  }

  @override
  void didUpdateWidget(PlaceTypeSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedPlaceType != widget.selectedPlaceType) {
      // Reset and play animation when selection changes
      _selectionAnimationController.reset();
      _selectionAnimationController.forward();

      // Scroll to selected item
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToSelectedItem();
      });
    }
  }

  void _scrollToSelectedItem() {
    final index = PlaceType.values.indexOf(widget.selectedPlaceType);
    if (_scrollController.hasClients &&
        index >= 0 &&
        index < _itemKeys.length) {
      // Get the context and RenderBox of the selected item
      final itemContext = _itemKeys[index].currentContext;
      if (itemContext != null) {
        final RenderBox box = itemContext.findRenderObject() as RenderBox;
        final position = box.localToGlobal(Offset.zero);

        // Calculate the center of the screen
        final screenWidth = MediaQuery.of(context).size.width;
        final screenCenter = screenWidth / 2;

        // Calculate how much to scroll to center the item
        final itemCenter = position.dx + (box.size.width / 2);
        final scrollAmount =
            _scrollController.offset + (itemCenter - screenCenter);

        // Animate to the position
        if (_scrollController.position.maxScrollExtent >= 0) {
          _scrollController.animateTo(
            scrollAmount.clamp(0.0, _scrollController.position.maxScrollExtent),
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutQuart,
          );
        }
      }
    }
  }

  String _getAnimationAsset(PlaceType type) {
    switch (type) {
      case PlaceType.hospital:
        return 'assets/animations/hospital_ambulance.json';
      case PlaceType.police:
        return 'assets/animations/police_bike.json';
      case PlaceType.fire:
        return 'assets/animations/fire_station.json';
      case PlaceType.shelter:
        return 'assets/animations/shelter.json';
      default:
        return 'assets/animations/general_alert.json';
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _selectionAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: AnimatedBuilder(
        animation: _selectionAnimation,
        builder: (context, _) {
          final animationValue = _selectionAnimation.value;

          return Stack(
            children: [
              // Main content with cards
              ShaderMask(
                shaderCallback: (Rect rect) {
                  return LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withOpacity(0),
                      Colors.black,
                      Colors.black,
                      Colors.black.withOpacity(0),
                    ],
                    stops: const [0.0, 0.05, 0.95, 1.0],
                  ).createShader(rect);
                },
                blendMode: BlendMode.dstIn,
                child: ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: PlaceType.values.length,
                  itemBuilder: (context, index) {
                    final type = PlaceType.values[index];
                    final isSelected = type == widget.selectedPlaceType;

                    return SizedBox(
                      key: _itemKeys[index],
                      width: 150,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: _buildTypeCard(
                          type,
                          isSelected,
                          animationValue,
                          index ==
                              PlaceType.values
                                  .indexOf(widget.selectedPlaceType),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Edge gradients for smooth scrolling indication
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 20,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Theme.of(context).scaffoldBackgroundColor,
                        Theme.of(context)
                            .scaffoldBackgroundColor
                            .withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 20,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: [
                        Theme.of(context).scaffoldBackgroundColor,
                        Theme.of(context)
                            .scaffoldBackgroundColor
                            .withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTypeCard(
      PlaceType type, bool isSelected, double animValue, bool isAnimating) {
    // iOS-style design colors
    final Color iosBlue = const Color(0xFF007AFF);
    final Color iosBackground = Colors.white;
    final Color iosShadow = const Color(0x1A000000);

    // Apply spring animation for currently animating item
    final scale = isAnimating
        ? Curves.easeOutBack.transform(animValue) * 0.05 + 0.95
        : 1.0;

    return GestureDetector(
      onTap: () => widget.onTypeSelected(type),
      child: Transform.scale(
        scale: scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: iosBackground,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: iosShadow,
                blurRadius: isSelected ? 8 : 4,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Background for selected state
              if (isSelected)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          iosBlue,
                          iosBlue.withBlue(255),
                        ],
                      ),
                    ),
                  ),
                ),

              // Frosted glass effect for iOS feel
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: isSelected
                        ? ImageFilter.blur(sigmaX: 0, sigmaY: 0)
                        : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected
                              ? Colors.white.withOpacity(0.2)
                              : Colors.grey.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animation container with iOS-style glass background
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withOpacity(0.25)
                            : const Color(0xFFF0F7FF),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: isSelected
                            ? null
                            : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                  spreadRadius: 0,
                                ),
                              ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Lottie.asset(
                          _getAnimationAsset(type),
                          fit: BoxFit.contain,
                          animate: isSelected,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Type label with SF Pro-like styling
                    Text(
                      type.label,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color:
                            isSelected ? Colors.white : const Color(0xFF333333),
                        letterSpacing: -0.3,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Selection indicator for iOS feel
              if (isSelected && isAnimating)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutQuart,
                    builder: (context, value, child) {
                      return Container(
                        height: 4,
                        width: double.infinity,
                        color: Colors.white,
                        margin:
                            EdgeInsets.symmetric(horizontal: 20 * (1 - value)),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
