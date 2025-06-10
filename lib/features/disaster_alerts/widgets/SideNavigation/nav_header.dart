import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/colors.dart';
import 'dart:math' as math;

class NavHeader extends StatelessWidget {
  final String userName;
  final String? userEmail;
  final String? userAvatar;
  final VoidCallback? onProfileTap;
  final bool isEmergencyMode;
  final bool isSmallScreen;

  const NavHeader({
    Key? key,
    required this.userName,
    this.userEmail,
    this.userAvatar,
    this.onProfileTap,
    this.isEmergencyMode = false,
    this.isSmallScreen = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate responsive sizes based on screen size
    final size = MediaQuery.of(context).size;
    final headerHeight = isSmallScreen
        ? math.min(150.0, size.height * 0.25)
        : math.min(180.0, size.height * 0.3);
    final avatarSize = isSmallScreen ? 40.0 : 50.0;
    final double horizontalPadding = isSmallScreen ? 12.0 : 16.0;
    final double verticalPadding = isSmallScreen ? 8.0 : 12.0;

    return Container(
      height: headerHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isEmergencyMode
              ? [
                  Color(0xFF7D0000),
                  Color(0xFFAA0000),
                ]
              : [
                  EvacuationColors.primaryColor,
                  EvacuationColors.primaryColor.withBlue(
                      (EvacuationColors.primaryColor.blue + 40).clamp(0, 255)),
                ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile section with avatar and user info
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar
                    GestureDetector(
                      onTap: onProfileTap,
                      onTapDown: (_) {
                        HapticFeedback.selectionClick();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: avatarSize / 2 - 2,
                          backgroundColor: Colors.white,
                          backgroundImage: userAvatar != null
                              ? NetworkImage(userAvatar!)
                              : null,
                          child: userAvatar == null
                              ? Text(
                                  userName.isNotEmpty
                                      ? userName[0].toUpperCase()
                                      : "U",
                                  style: GoogleFonts.poppins(
                                    fontSize: isSmallScreen ? 16 : 18,
                                    fontWeight: FontWeight.bold,
                                    color: EvacuationColors.primaryColor,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),

                    SizedBox(width: horizontalPadding),

                    // User info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            userName,
                            style: GoogleFonts.poppins(
                              fontSize: isSmallScreen ? 16 : 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (userEmail != null)
                            Text(
                              userEmail!,
                              style: GoogleFonts.poppins(
                                fontSize: isSmallScreen ? 11 : 12,
                                color: Colors.white.withOpacity(0.8),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Spacer
              Spacer(flex: 1),

              // Status card
              Container(
                constraints: BoxConstraints(
                  maxHeight: isSmallScreen ? 60 : 70,
                ),
                padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding / 1.5,
                    vertical: verticalPadding / 1.5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                      decoration: BoxDecoration(
                        color: isEmergencyMode
                            ? Colors.red.withOpacity(0.3)
                            : Colors.white.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isEmergencyMode
                            ? Icons.warning_rounded
                            : Icons.shield_rounded,
                        color: Colors.white,
                        size: isSmallScreen ? 14 : 16,
                      ),
                    ),
                    SizedBox(width: horizontalPadding / 2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isEmergencyMode
                                ? 'Emergency Mode Active'
                                : 'Status: Safe',
                            style: GoogleFonts.poppins(
                              fontSize: isSmallScreen ? 12 : 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            isEmergencyMode
                                ? 'Emergency services notified'
                                : 'No active alerts in your area',
                            style: GoogleFonts.poppins(
                              fontSize: isSmallScreen ? 10 : 11,
                              color: Colors.white.withOpacity(0.8),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Small bottom space
              SizedBox(height: verticalPadding / 2),
            ],
          ),
        ),
      ),
    );
  }
}
