import 'package:disaster_management/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DisasterDeclarationCard extends StatelessWidget {
  final String title;
  final String type;
  final String location;
  final String date;
  final String status;

  const DisasterDeclarationCard({
    super.key,
    required this.title,
    required this.type,
    required this.location,
    required this.date,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final bool isActive = status.toLowerCase() == 'active';
    final Color statusColor = isActive ? AppColors.primaryColor : Colors.grey;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    
    IconData typeIcon;
    Color typeColor;
    
    switch (type.toLowerCase()) {
      case 'flood':
        typeIcon = Icons.water_drop_rounded;
        typeColor = AppColors.primaryColor.withBlue(255);
        break;
      case 'hurricane':
        typeIcon = Icons.cyclone_rounded;
        typeColor = AppColors.primaryColor.withRed(180);
        break;
      case 'fire':
        typeIcon = Icons.local_fire_department_rounded;
        typeColor = AppColors.primaryColor.withRed(255);
        break;
      case 'tornado':
        typeIcon = Icons.tornado_rounded;
        typeColor = AppColors.primaryColor.withGreen(180);
        break;
      case 'earthquake':
        typeIcon = Icons.vibration_rounded;
        typeColor = AppColors.primaryColor;
        break;
      default:
        typeIcon = Icons.warning_rounded;
        typeColor = AppColors.primaryColor.withOpacity(0.8);
    }

    return Card(
      elevation: 1,
      shadowColor: AppColors.primaryColor.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: AppColors.primaryColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    typeIcon,
                    color: AppColors.primaryColor,
                    size: isSmallScreen ? 20 : 24,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 12 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          color: AppColors.textColor,
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      _buildStatusChip(status, statusColor, isSmallScreen),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: isSmallScreen
                  ? Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildInfoItem(Icons.location_on_rounded, location, isSmallScreen),
                            _buildInfoItem(Icons.calendar_today_rounded, date, isSmallScreen),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildTypeChip(type, typeColor, isSmallScreen),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(child: _buildInfoItem(Icons.location_on_rounded, location, isSmallScreen)),
                        Flexible(child: _buildInfoItem(Icons.calendar_today_rounded, date, isSmallScreen)),
                        _buildTypeChip(type, typeColor, isSmallScreen),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text, bool isSmallScreen) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: isSmallScreen ? 14 : 16,
          color: AppColors.primaryColor,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: GoogleFonts.inter(
              color: AppColors.textColor,
              fontSize: isSmallScreen ? 11 : 13,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status, Color color, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 6 : 8, 
        vertical: isSmallScreen ? 3 : 4
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isSmallScreen ? 5 : 6,
            height: isSmallScreen ? 5 : 6,
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: isSmallScreen ? 3 : 4),
          Text(
            status,
            style: GoogleFonts.inter(
              color: AppColors.primaryColor,
              fontSize: isSmallScreen ? 10 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String type, Color color, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 8 : 10, 
        vertical: isSmallScreen ? 3 : 4
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        type,
        style: GoogleFonts.inter(
          color: AppColors.primaryColor,
          fontSize: isSmallScreen ? 10 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}