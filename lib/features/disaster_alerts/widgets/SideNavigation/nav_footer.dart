import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/colors.dart';

class NavFooter extends StatelessWidget {
  final VoidCallback? onLogoutTap;
  final bool isSmallScreen;

  const NavFooter({
    Key? key,
    this.onLogoutTap,
    this.isSmallScreen = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double padding = isSmallScreen ? 12.0 : 16.0;

    return Container(
      padding: EdgeInsets.only(
        left: padding,
        right: padding,
        bottom:
            MediaQuery.of(context).padding.bottom + (isSmallScreen ? 8 : 12),
        top: isSmallScreen ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: EvacuationColors.cardBackground,
        boxShadow: [
          BoxShadow(
            color: EvacuationColors.shadowColor.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, -1),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildAppVersion(),
          SizedBox(height: isSmallScreen ? 10 : 12),
          _buildLogoutButton(),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    final double iconSize = isSmallScreen ? 16.0 : 20.0;
    final double fontSize = isSmallScreen ? 13.0 : 14.0;
    final double buttonPadding = isSmallScreen ? 8.0 : 10.0;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (onLogoutTap != null) {
            HapticFeedback.mediumImpact();
            onLogoutTap!();
          }
        },
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.red.withOpacity(0.1),
        highlightColor: Colors.red.withOpacity(0.05),
        child: Container(
          padding: EdgeInsets.symmetric(
              vertical: buttonPadding, horizontal: buttonPadding),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.red.withOpacity(0.2),
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: Colors.red,
                  size: iconSize,
                ),
              ),
              SizedBox(width: isSmallScreen ? 8 : 12),
              Text(
                'Logout',
                style: GoogleFonts.poppins(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.red,
                size: isSmallScreen ? 12 : 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppVersion() {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 8 : 10, vertical: isSmallScreen ? 3 : 4),
      decoration: BoxDecoration(
        color: EvacuationColors.borderColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'App Version 1.0.0',
        style: GoogleFonts.poppins(
          color: EvacuationColors.subtitleColor,
          fontSize: isSmallScreen ? 9 : 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
