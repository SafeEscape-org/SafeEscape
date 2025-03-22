import 'package:disaster_management/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RecentEarthquakesCard extends StatelessWidget {
  const RecentEarthquakesCard({super.key});

  @override
  Widget build(BuildContext context) {
    final earthquakes = [
      {
        'magnitude': '4.5',
        'location': 'San Francisco, CA',
        'time': '2 hours ago',
        'depth': '10 km',
      },
      {
        'magnitude': '3.2',
        'location': 'Los Angeles, CA',
        'time': '5 hours ago',
        'depth': '5 km',
      },
    ];

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
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            ...earthquakes.map((quake) => _buildEarthquakeItem(quake)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildEarthquakeItem(Map<String, String> quake) {
    final magnitude = double.tryParse(quake['magnitude'] ?? '0.0') ?? 0.0;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.08),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primaryColor.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                quake['magnitude'] ?? '0.0',
                style: GoogleFonts.inter(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quake['location'] ?? 'Unknown Location',
                  style: GoogleFonts.inter(
                    color: AppColors.textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildInfoChip(
                      Icons.access_time_rounded,
                      quake['time'] ?? 'Unknown Time',
                    ),
                    const SizedBox(width: 12),
                    _buildInfoChip(
                      Icons.vertical_align_bottom_rounded,
                      quake['depth'] ?? 'Unknown Depth',
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: AppColors.primaryColor,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.inter(
              color: AppColors.textColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}