import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:disaster_management/core/constants/api_constants.dart';

class CurrentWeatherCard extends StatefulWidget {
  final String city;

  const CurrentWeatherCard({
    Key? key,
    required this.city,
  }) : super(key: key);

  @override
  State<CurrentWeatherCard> createState() => _CurrentWeatherCardState();
}

class _CurrentWeatherCardState extends State<CurrentWeatherCard> {
  Map<String, dynamic>? _weatherData;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchWeatherData();
  }

  Future<void> _fetchWeatherData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final cityLowerCase = widget.city.toLowerCase().trim();
      final url = '${ApiConstants.weatherApiBaseUrl}/$cityLowerCase';
      
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        
        // Handle direct weather data or wrapped data
        if (jsonData.containsKey('weather') && jsonData.containsKey('main')) {
          setState(() {
            _weatherData = jsonData;
            _isLoading = false;
          });
        } else if (jsonData['success'] == true && jsonData['data'] != null) {
          setState(() {
            _weatherData = jsonData['data'];
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = jsonData['message'] ?? 'Failed to parse weather data';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Server error: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Color _getBackgroundColor(String condition) {
    condition = condition.toLowerCase();
    if (condition.contains('rain') || condition.contains('drizzle')) {
      return const Color(0xFF1A73E8);
    } else if (condition.contains('thunder') || condition.contains('storm')) {
      return const Color(0xFF3C5A99);
    } else if (condition.contains('snow')) {
      return const Color(0xFF4285F4);
    } else if (condition.contains('clear')) {
      return const Color(0xFF2196F3);
    } else if (condition.contains('cloud')) {
      return const Color(0xFF64B5F6);
    } else {
      return const Color(0xFF42A5F5);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: _isLoading
          ? _buildLoadingState()
          : _errorMessage.isNotEmpty
              ? _buildErrorState()
              : _buildWeatherCard(),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 250, // Match the height of the weather card
      decoration: BoxDecoration(
        color: Colors.blue[300],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      height: 250, // Match the height of the weather card
      decoration: BoxDecoration(
        color: Colors.blue[800],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 40,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _fetchWeatherData,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: Text(
                'Retry',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherCard() {
    final condition = _weatherData?['weather']?[0]?['main'] ?? 'Unknown';
    final description = _weatherData?['weather']?[0]?['description'] ?? 'Unknown weather';
    final temp = (_weatherData?['main']?['temp'] ?? 0).toDouble();
    final feelsLike = (_weatherData?['main']?['feels_like'] ?? 0).toDouble();
    final humidity = _weatherData?['main']?['humidity'] ?? 0;
    final windSpeed = _weatherData?['wind']?['speed'] ?? 0;
    final cityName = _weatherData?['name'] ?? widget.city;
    final country = _weatherData?['sys']?['country'] ?? '';
    
    // Format date
    final now = DateTime.now();
    final formattedDate = DateFormat('EEEE, MMM d').format(now);
    final formattedTime = DateFormat('h:mm a').format(now);

    return Container(
      // Increase height by 10 pixels to fix overflow
      height: 250,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getBackgroundColor(condition),
            _getBackgroundColor(condition).withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Location and date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '$cityName, $country',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '$formattedDate • $formattedTime',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Weather icon
                Icon(
                  _getWeatherIcon(condition),
                  color: Colors.white,
                  size: 40,
                ),
              ],
            ),
            
            const SizedBox(height: 12), // Reduced spacing
            
            // Temperature and description
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${temp.round()}',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '°C',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Feels like ${feelsLike.round()}°C',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        condition,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        description,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12), // Reduced spacing
            
            // Additional info
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(child: _buildInfoItem(Icons.water_drop_outlined, '$humidity%', 'Humidity')),
                  Expanded(child: _buildInfoItem(Icons.air, '${windSpeed.toStringAsFixed(1)} m/s', 'Wind')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min, // Use minimum vertical space
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 18, // Slightly smaller icon
        ),
        const SizedBox(height: 2), // Reduced spacing
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.9),
            fontSize: 11, // Slightly smaller font
          ),
        ),
      ],
    );
  }

  IconData _getWeatherIcon(String condition) {
    condition = condition.toLowerCase();
    if (condition.contains('rain') || condition.contains('drizzle')) {
      return Icons.water_drop;
    } else if (condition.contains('thunder') || condition.contains('storm')) {
      return Icons.flash_on;
    } else if (condition.contains('snow')) {
      return Icons.ac_unit;
    } else if (condition.contains('clear')) {
      return Icons.wb_sunny;
    } else if (condition.contains('cloud')) {
      return Icons.cloud;
    } else if (condition.contains('fog') || condition.contains('mist')) {
      return Icons.cloud;
    } else {
      return Icons.cloud;
    }
  }
}