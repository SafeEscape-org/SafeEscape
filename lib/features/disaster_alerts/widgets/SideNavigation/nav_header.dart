import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/colors.dart';
import '../../common/animated_background.dart';

class NavHeader extends StatefulWidget {
  final String userName;
  final String? userEmail;
  final String? userAvatar;
  final VoidCallback? onProfileTap;
  final bool isEmergencyMode;

  const NavHeader({
    Key? key,
    required this.userName,
    this.userEmail,
    this.userAvatar,
    this.onProfileTap,
    this.isEmergencyMode = false,
  }) : super(key: key);

  @override
  State<NavHeader> createState() => _NavHeaderState();
}

class _NavHeaderState extends State<NavHeader> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      child: Stack(
        children: [
          // Map-themed animated background
          AnimatedBackground(
            colors: widget.isEmergencyMode 
                ? [
                    Color(0xFF7D0000),
                    Color(0xFFAA0000),
                    Color(0xFF7D0000),
                  ]
                : [
                    EvacuationColors.primaryColor,
                    EvacuationColors.primaryColor.withBlue(EvacuationColors.primaryColor.blue + 40),
                    EvacuationColors.accentColor,
                  ],
            isEmergencyMode: widget.isEmergencyMode,
          ),
          
          // Custom map elements overlay
          Positioned.fill(
            child: CustomPaint(
              painter: NavigationLinesPainter(
                progress: _animationController.value,
                isEmergencyMode: widget.isEmergencyMode,
              ),
            ),
          ),
          
          // Content
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 20,
                bottom: 20,
                left: 20,
                right: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile section with GPS beacon effect
                  GestureDetector(
                    onTap: widget.onProfileTap,
                    onTapDown: (_) {
                      HapticFeedback.selectionClick();
                    },
                    child: Row(
                      children: [
                        // Avatar with pulsing effect
                        AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                // Outer pulse
                                Transform.scale(
                                  scale: _pulseAnimation.value,
                                  child: Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: widget.isEmergencyMode
                                          ? Colors.red.withOpacity(0.2)
                                          : Colors.cyan.withOpacity(0.2),
                                    ),
                                  ),
                                ),
                                // Middle pulse
                                Transform.scale(
                                  scale: _pulseAnimation.value * 0.9,
                                  child: Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: widget.isEmergencyMode
                                          ? Colors.red.withOpacity(0.3)
                                          : Colors.cyan.withOpacity(0.3),
                                    ),
                                  ),
                                ),
                                // Avatar
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: widget.isEmergencyMode
                                          ? Colors.red.withOpacity(0.8)
                                          : Colors.white,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: widget.isEmergencyMode
                                            ? Colors.red.withOpacity(0.5)
                                            : Colors.cyan.withOpacity(0.5),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 25,
                                    backgroundColor: Colors.white,
                                    backgroundImage: widget.userAvatar != null
                                        ? NetworkImage(widget.userAvatar!)
                                        : null,
                                    child: widget.userAvatar == null
                                        ? Text(
                                            widget.userName[0].toUpperCase(),
                                            style: GoogleFonts.poppins(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: EvacuationColors.primaryColor,
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        
                        const SizedBox(width: 16),
                        
                        // User info
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
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (widget.userEmail != null)
                                Text(
                                  widget.userEmail!,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              
                              // Location indicator
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      color: widget.isEmergencyMode
                                          ? Colors.red
                                          : Colors.cyan,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Current Location',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // View Profile button
                  InkWell(
                    onTap: widget.onProfileTap,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View Profile',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom wave decoration
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 20,
              child: ClipPath(
                clipper: WaveClipper(),
                child: Container(
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Wave clipper for the bottom decoration
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, 0);
    
    // First wave
    final firstControlPoint = Offset(size.width / 4, size.height);
    final firstEndPoint = Offset(size.width / 2.25, size.height / 2);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );
    
    // Second wave
    final secondControlPoint = Offset(size.width / 1.8, 0);
    final secondEndPoint = Offset(size.width / 1.25, size.height / 2);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );
    
    // Third wave
    final thirdControlPoint = Offset(size.width / 1.1, size.height);
    final thirdEndPoint = Offset(size.width, 0);
    path.quadraticBezierTo(
      thirdControlPoint.dx,
      thirdControlPoint.dy,
      thirdEndPoint.dx,
      thirdEndPoint.dy,
    );
    
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}