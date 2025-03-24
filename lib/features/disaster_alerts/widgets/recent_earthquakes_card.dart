import 'package:disaster_management/core/constants/app_colors.dart';
import 'package:disaster_management/core/constants/api_constants.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class RecentEarthquakesCard extends StatefulWidget {
  const RecentEarthquakesCard({super.key});

  @override
  State<RecentEarthquakesCard> createState() => _RecentEarthquakesCardState();
}

class _RecentEarthquakesCardState extends State<RecentEarthquakesCard> {
  bool _isLoading = true;
  bool _isLoadingMore = false;
  List<Map<String, dynamic>> _earthquakes = [];
  int _page = 1;
  final int _limit = 5;
  bool _hasMoreData = true;

  @override
  void initState() {
    super.initState();
    _fetchEarthquakes();
  }

  Future<void> _fetchEarthquakes({bool loadMore = false}) async {
    if (loadMore) {
      if (!mounted) return;
      setState(() {
        _isLoadingMore = true;
      });
    } else {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
      });
    }
    
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.socketServerUrl}/api/alerts/earthquakes?page=$_page&limit=$_limit'),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        // Parse the USGS format earthquake data
        final List<dynamic> earthquakeFeatures = json.decode(response.body);
        
        if (earthquakeFeatures.isNotEmpty) {
          final List<Map<String, dynamic>> newEarthquakes = earthquakeFeatures.map((feature) {
            final properties = feature['properties'] as Map<String, dynamic>;
            final geometry = feature['geometry'] as Map<String, dynamic>;
            final coordinates = geometry['coordinates'] as List<dynamic>;
            
            return {
              'magnitude': properties['mag']?.toString() ?? '0.0',
              'location': properties['place'] ?? 'Unknown Location',
              'timestamp': DateTime.fromMillisecondsSinceEpoch(
                  properties['time'] as int).toIso8601String(),
              'depth': coordinates[2]?.toString() ?? '0',
              'id': feature['id'],
              'url': properties['url'],
            };
          }).toList();
          
          if (!mounted) return;
          setState(() {
            if (loadMore) {
              _earthquakes.addAll(newEarthquakes);
            } else {
              _earthquakes = newEarthquakes;
            }
            
            _hasMoreData = newEarthquakes.length >= _limit;
            _page++;
            _isLoading = false;
            _isLoadingMore = false;
          });
        } else {
          if (!mounted) return;
          setState(() {
            if (!loadMore) {
              _earthquakes = [];
            }
            _hasMoreData = false;
            _isLoading = false;
            _isLoadingMore = false;
          });
        }
      } else {
        if (!mounted) return;
        setState(() {
          if (!loadMore) {
            _earthquakes = [];
          }
          _hasMoreData = false;
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching earthquakes: $e');
      if (!mounted) return;
      setState(() {
        if (!loadMore) {
          _earthquakes = [];
        }
        _hasMoreData = false;
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingCard();
    }

    if (_earthquakes.isEmpty) {
      return _buildEmptyCard();
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _earthquakes.length > 5 ? 5 : _earthquakes.length,
              itemBuilder: (context, index) {
                return _buildEarthquakeItem(_earthquakes[index]);
              },
            ),
            if (_hasMoreData) _buildLoadMoreButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildEarthquakeItem(Map<String, dynamic> quake) {
    final magnitude = quake['magnitude']?.toString() ?? '0.0';
    final location = quake['location'] ?? 'Unknown Location';
    final time = _formatTimeAgo(quake['timestamp']);
    final depth = '${quake['depth']?.toString() ?? '0'} km';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getMagnitudeColor(magnitude).withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: _getMagnitudeColor(magnitude).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                magnitude.length > 4 ? magnitude.substring(0, 4) : magnitude,
                style: GoogleFonts.inter(
                  color: _getMagnitudeColor(magnitude),
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  location,
                  style: GoogleFonts.inter(
                    color: AppColors.textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _buildInfoChip(
                      Icons.access_time_rounded,
                      time,
                    ),
                    _buildInfoChip(
                      Icons.vertical_align_bottom_rounded,
                      depth,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: AppColors.primaryColor,
          ),
          const SizedBox(width: 2),
          Text(
            text,
            style: GoogleFonts.inter(
              color: AppColors.textColor,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
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
        height: 200,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCard() {
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.public_off_rounded,
                size: 48,
                color: AppColors.primaryColor.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No recent earthquakes',
                style: GoogleFonts.inter(
                  color: AppColors.textColor.withOpacity(0.7),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _fetchEarthquakes(),
                child: Text(
                  'Refresh',
                  style: GoogleFonts.inter(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: InkWell(
        onTap: _isLoadingMore ? null : () => _fetchEarthquakes(loadMore: true),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primaryColor.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Center(
            child: _isLoadingMore
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                    ),
                  )
                : Text(
                    'Update',
                    style: GoogleFonts.inter(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Color _getMagnitudeColor(String magnitudeStr) {
    final magnitude = double.tryParse(magnitudeStr) ?? 0.0;
    
    if (magnitude >= 7.0) {
      return Colors.red;
    } else if (magnitude >= 5.0) {
      return Colors.orange;
    } else if (magnitude >= 3.0) {
      return Colors.amber;
    } else {
      return AppColors.primaryColor;
    }
  }

  String _formatTimeAgo(String? timestamp) {
    if (timestamp == null) return 'Unknown';
    
    try {
      final DateTime now = DateTime.now();
      final DateTime date = DateTime.parse(timestamp);
      final Duration difference = now.difference(date);
      
      if (difference.inDays > 0) {
        return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}