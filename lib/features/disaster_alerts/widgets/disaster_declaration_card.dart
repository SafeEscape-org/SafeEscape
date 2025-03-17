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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    typeIcon,
                    color: AppColors.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          color: AppColors.textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      _buildStatusChip(status, statusColor),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInfoItem(Icons.location_on_rounded, location),
                  _buildInfoItem(Icons.calendar_today_rounded, date),
                  _buildTypeChip(type, typeColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.primaryColor,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: GoogleFonts.inter(
            color: AppColors.textColor,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            status,
            style: GoogleFonts.inter(
              color: AppColors.primaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String type, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        type,
        style: GoogleFonts.inter(
          color: AppColors.primaryColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}