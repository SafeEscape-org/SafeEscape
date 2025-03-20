import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class CurrentWeatherCard extends StatefulWidget {
  final String city;

  const CurrentWeatherCard({
    Key? key,
    required this.city,
  }) : super(key: key);

  @override
  State<CurrentWeatherCard> createState() => _CurrentWeatherCardState();
}

class _CurrentWeatherCardState extends State<CurrentWeatherCard> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _weatherData;
  bool _isLoading = true;
  String _errorMessage = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _fetchWeatherData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchWeatherData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse('http://:5000/api/alerts/weather/${widget.city}'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true && jsonData['data'] != null) {
          setState(() {
            _weatherData = jsonData['data'];
            _isLoading = false;
          });
          _animationController.forward();
        } else {
          setState(() {
            _errorMessage = jsonData['message'] ?? 'Failed to load weather data';
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

  String _getWeatherAnimation(String condition) {
    condition = condition.toLowerCase();
    if (condition.contains('rain') || condition.contains('drizzle')) {
      return 'assets/animations/flood_alert.json';
    } else if (condition.contains('thunder') || condition.contains('storm')) {
      return 'assets/animations/earthquake_alert.json';
    } else if (condition.contains('snow')) {
      return 'assets/animations/general_alert.json';
    } else if (condition.contains('clear')) {
      return 'assets/animations/fire_alert.json';
    } else if (condition.contains('cloud')) {
      return 'assets/animations/general_alert.json';
    } else if (condition.contains('fog') || condition.contains('mist')) {
      return 'assets/animations/general_alert.json';
    } else {
      return 'assets/animations/general_alert.json';
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: _isLoading
          ? _buildLoadingState()
          : _errorMessage.isNotEmpty
              ? _buildErrorState()
              : _buildWeatherCard(isSmallScreen),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF42A5F5),
            const Color(0xFF64B5F6),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.blue[800],
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
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

  Widget _buildWeatherCard(bool isSmallScreen) {
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
    final dateFormat = DateFormat('EEEE, MMM d');
    final timeFormat = DateFormat('h:mm a');
    final formattedDate = dateFormat.format(now);
    final formattedTime = timeFormat.format(now);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getBackgroundColor(condition),
              _getBackgroundColor(condition).withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Background pattern - use a subtle pattern or remove if not available
              Positioned.fill(
                child: Opacity(
                  opacity: 0.05,
                  child: Container(
                    color: Colors.white,
                  ),
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Location and date
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '$cityName, $country',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: isSmallScreen ? 16 : 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formattedDate,
                                style: GoogleFonts.poppins(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: isSmallScreen ? 12 : 14,
                                ),
                              ),
                              Text(
                                formattedTime,
                                style: GoogleFonts.poppins(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: isSmallScreen ? 12 : 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Weather animation
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: Image.asset(
                            'assets/icons/weather/${condition.toLowerCase()}.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.cloud,
                                color: Colors.white,
                                size: 50,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Temperature and description
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
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
                                    fontSize: isSmallScreen ? 40 : 48,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '°C',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: isSmallScreen ? 20 : 24,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Feels like ${feelsLike.round()}°C',
                              style: GoogleFonts.poppins(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: isSmallScreen ? 12 : 14,
                              ),
                            ),
                          ],
                        ),
                        
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              condition,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: isSmallScreen ? 18 : 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              description,
                              style: GoogleFonts.poppins(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: isSmallScreen ? 12 : 14,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Additional info
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildWeatherInfoItem(
                            icon: Icons.water_drop_outlined,
                            value: '$humidity%',
                            label: 'Humidity',
                            isSmallScreen: isSmallScreen,
                          ),
                          _buildWeatherInfoItem(
                            icon: Icons.air,
                            value: '${windSpeed.toStringAsFixed(1)} m/s',
                            label: 'Wind',
                            isSmallScreen: isSmallScreen,
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
      ),
    );
  }

  Widget _buildWeatherInfoItem({
    required IconData icon,
    required String value,
    required String label,
    required bool isSmallScreen,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: isSmallScreen ? 18 : 22,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: isSmallScreen ? 14 : 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.9),
            fontSize: isSmallScreen ? 12 : 14,
          ),
        ),
      ],
    );
  }
}