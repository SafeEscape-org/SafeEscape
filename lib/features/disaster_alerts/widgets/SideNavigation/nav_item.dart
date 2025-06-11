import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/navigation_item.dart';
import '../../constants/colors.dart';

class NavItem extends StatelessWidget {
  final NavigationItem item;
  final bool isSelected;
  final int index;
  final VoidCallback onTap;
  final bool isSmallScreen;

  const NavItem({
    Key? key,
    required this.item,
    required this.isSelected,
    required this.index,
    required this.onTap,
    this.isSmallScreen = false,
  }) : super(key: key);

  Color _getAlertColor() {
    switch (item.alertLevel) {
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
  Widget build(BuildContext context) {
    final double fontSize = isSmallScreen ? 13.0 : 14.0;
    final double iconSize = isSmallScreen ? 20.0 : 22.0;
    final double verticalPadding = isSmallScreen ? 8.0 : 10.0;
    final double horizontalPadding = isSmallScreen ? 10.0 : 12.0;
    final double iconContainerPadding = isSmallScreen ? 6.0 : 8.0;

    final alertColor = _getAlertColor();
    final hasAlert = item.hasAlert;

    return Padding(
      padding: EdgeInsets.only(bottom: isSmallScreen ? 4 : 6),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          splashColor: EvacuationColors.primaryColor.withOpacity(0.1),
          highlightColor: EvacuationColors.primaryColor.withOpacity(0.05),
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding, vertical: verticalPadding),
            decoration: BoxDecoration(
              color: isSelected
                  ? (hasAlert
                      ? alertColor.withOpacity(0.1)
                      : EvacuationColors.primaryColor.withOpacity(0.1))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? (hasAlert ? alertColor : EvacuationColors.primaryColor)
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                // Item icon with container
                Container(
                  padding: EdgeInsets.all(iconContainerPadding),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (hasAlert
                            ? alertColor.withOpacity(0.2)
                            : EvacuationColors.primaryColor.withOpacity(0.2))
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    item.icon,
                    color: isSelected
                        ? (hasAlert
                            ? alertColor
                            : EvacuationColors.primaryColor)
                        : Colors.grey.shade700,
                    size: iconSize,
                  ),
                ),

                SizedBox(width: isSmallScreen ? 8 : 10),

                // Item title
                Expanded(
                  child: Text(
                    item.title,
                    style: GoogleFonts.poppins(
                      fontSize: fontSize,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? (hasAlert
                              ? alertColor
                              : EvacuationColors.primaryColor)
                          : Colors.grey.shade800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Badge or notification count if available
                if (item.badge != null)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 5 : 6,
                      vertical: isSmallScreen ? 1 : 2,
                    ),
                    margin: EdgeInsets.only(left: isSmallScreen ? 4 : 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? EvacuationColors.primaryColor
                          : Colors.grey.shade600,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item.badge!,
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 10 : 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),

                // Alert indicator
                if (hasAlert && item.badge == null)
                  Container(
                    width: isSmallScreen ? 6 : 8,
                    height: isSmallScreen ? 6 : 8,
                    margin: EdgeInsets.only(left: isSmallScreen ? 4 : 6),
                    decoration: BoxDecoration(
                      color: alertColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: alertColor.withOpacity(0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
