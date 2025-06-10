import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math' as math;
import '../models/evacuation_place.dart';
import '../constants/colors.dart';
import 'evacuation_map.dart';

class ExpandedMapPreview extends StatefulWidget {
  final EvacuationPlace place;
  final LatLng currentPosition;
  final Set<Polyline> polylines;
  final Function(GoogleMapController) onMapCreated;

  const ExpandedMapPreview({
    super.key,
    required this.place,
    required this.currentPosition,
    required this.polylines,
    required this.onMapCreated,
  });

  @override
  State<ExpandedMapPreview> createState() => _ExpandedMapPreviewState();
}

class _ExpandedMapPreviewState extends State<ExpandedMapPreview>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  bool _showAIOverlay = true;

  // AI analysis factors
  final List<String> _aiFactors = [
    'Traffic density',
    'Road conditions',
    'Weather impact',
    'Emergency services',
    'Evacuation flows',
    'Hazard proximity'
  ];

  // AI routes being compared (for animation purposes)
  final List<int> _routeScores = [78, 85, 64, 92];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _pulseAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Auto-hide AI overlay after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showAIOverlay = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced header with AI badge
          Row(
            children: [
              Icon(
                Icons.route_rounded,
                color: EvacuationColors.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
          Text(
                'AI Route Analysis',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: EvacuationColors.textColor,
            ),
          ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      EvacuationColors.primaryColor,
                      EvacuationColors.accentColor,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'AI Powered',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Toggle AI overlay button
              IconButton(
                icon: Icon(
                  _showAIOverlay ? Icons.visibility : Icons.visibility_off,
                  color: EvacuationColors.primaryColor,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _showAIOverlay = !_showAIOverlay;
                  });
                },
              ),
            ],
          ),

          // Map container with AI overlay
          const SizedBox(height: 12),
          Stack(
            children: [
              // Map container with animated shadow
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Container(
                    height: 250, // Increased height
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: EvacuationColors.primaryColor
                              .withOpacity(0.1 + 0.1 * _pulseAnimation.value),
                          blurRadius: 16 + 8 * _pulseAnimation.value,
                          offset: const Offset(0, 4),
                          spreadRadius: 1 + _pulseAnimation.value,
                        ),
                      ],
                    ),
                    child: child,
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: EvacuationMap(
                    currentPosition: widget.currentPosition,
                    places: [widget.place],
                    polylines: widget.polylines,
                    onMapCreated: widget.onMapCreated,
                  ),
                ),
              ),

              // AI overlay elements (only shown when _showAIOverlay is true)
              if (_showAIOverlay)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      children: [
                        // Route analysis grid
                        Positioned(
                          right: 0,
                          top: 0,
                          bottom: 0,
                          width: 120,
                          child: Container(
                            color: Colors.black.withOpacity(0.7),
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ANALYSIS',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white.withOpacity(0.7),
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: _buildFactorsList(),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Route comparison overlay
                        Positioned(
                          left: 0,
                          bottom: 0,
                          right: 120, // Avoid overlapping with analysis panel
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withOpacity(0.8),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.looks_one_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            'Optimal Route',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.green,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '92%',
                                              style: GoogleFonts.inter(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'AI selected for safest evacuation',
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          color: Colors.white.withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Animated scanning effect
                        AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return Positioned(
                              left: 0,
                              right: 0,
                              top: _animationController.value * 250,
                              height: 2,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      EvacuationColors.primaryColor
                                          .withOpacity(0.8),
                                      Colors.transparent,
                                    ],
                                    stops: const [0.0, 0.5, 1.0],
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
            ],
          ),

          // Route info section
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI-Optimized for Your Safety',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: EvacuationColors.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Our AI has analyzed multiple route options and selected the safest path considering traffic conditions, road closures, and hazard proximity.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: EvacuationColors.subtitleColor,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildInfoItem(Icons.speed_rounded, 'Fastest', 'route'),
                    const SizedBox(width: 8),
                    _buildInfoItem(Icons.shield_rounded, 'Safest', 'option'),
                    const SizedBox(width: 8),
                    _buildInfoItem(Icons.route_rounded, 'Optimal', 'path'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFactorsList() {
    return ListView.builder(
      itemCount: _aiFactors.length,
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getAnalysisColor(index),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _aiFactors[index],
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: Duration(milliseconds: 1500 + (index * 300)),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Container(
                          height: 3,
                          width: 70 * value,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            gradient: LinearGradient(
                              colors: [
                                _getAnalysisColor(index),
                                _getAnalysisColor(index).withOpacity(0.5),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getAnalysisColor(int index) {
    final colors = [
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.amber,
    ];
    return colors[index % colors.length];
  }

  Widget _buildInfoItem(IconData icon, String title, String subtitle) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: EvacuationColors.primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: EvacuationColors.primaryColor,
              size: 16,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: EvacuationColors.textColor,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: EvacuationColors.subtitleColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
