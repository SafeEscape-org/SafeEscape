import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:disaster_management/core/constants/app_colors.dart';
import 'package:lottie/lottie.dart';

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

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
  bool _isLoading = true;
  Map<String, dynamic>? _weatherData;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchWeatherData();
  }
  
  @override
  void didUpdateWidget(CurrentWeatherCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.city != widget.city) {
      _fetchWeatherData();
    }
  }

  Future<void> _fetchWeatherData() async {
    if (widget.city.isEmpty) return;
    
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
        } else {
          setState(() {
            _errorMessage = 'Failed to load weather data';
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
        _errorMessage = 'Network error: $e';
        _isLoading = false;
      });
    }
  }

  String _getWeatherIcon(String? iconCode, String weatherMain) {
    if (iconCode == null) return 'assets/animations/general_alert.json';
    
    // Map weather conditions to animations and SVGs based on weather type
    switch (weatherMain.toLowerCase()) {
      case 'thunderstorm':
        return 'assets/animations/storm_alert.json';
      case 'rain':
      case 'drizzle':
        return 'assets/animations/flood_alert.json';
      case 'snow':
        return 'assets/animations/general_alert.json';
      default:
        // For clear, clouds, mist, etc. use general alert
        return 'assets/animations/general_alert.json';
    }
  }

  Widget _buildWeatherIcon(String iconCode, String weatherMain) {
    final bool isNight = iconCode.endsWith('n');
    final String assetPath = _getWeatherIcon(iconCode, weatherMain);
    
    return Row(
      children: [
        Lottie.asset(
          assetPath,
          width: 60,
          height: 60,
          fit: BoxFit.contain,
        ),
        if (isNight)
          const Icon(
            Icons.nightlight_round,
            color: Colors.white,
            size: 24,
          ),
      ],
    );
  }

  // In your build method, replace the Image.asset with _buildWeatherIcon
  String _formatTime(int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat('h:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingCard();
    }
    
    if (_errorMessage.isNotEmpty) {
      return _buildErrorCard();
    }
    
    if (_weatherData == null) {
      return _buildEmptyCard();
    }
    
    // Extract weather data
    final weather = _weatherData!['weather'][0];
    final main = _weatherData!['main'];
    final wind = _weatherData!['wind'];
    final sys = _weatherData!['sys'];
    
    final temp = main['temp'].toDouble();
    final feelsLike = main['feels_like'].toDouble();
    final humidity = main['humidity'];
    final windSpeed = wind['speed'].toDouble();
    final weatherMain = weather['main'];
    final weatherDesc = weather['description'];
    final iconCode = weather['icon'];
    final sunrise = sys['sunrise'];
    final sunset = sys['sunset'];
    
    return Card(
      elevation: 8,
      shadowColor: AppColors.primaryColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.35,
          minHeight: 220,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade700,
              Colors.blue.shade500,
              Colors.indigo.shade400,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // City and Weather Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.city,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        weatherDesc.toString().capitalize(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    width: 45,
                    height: 45,
                    child: _buildWeatherIcon(iconCode, weatherMain),
                  ),
                ),
              ],
            ),
            
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${temp.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 64,
                          fontWeight: FontWeight.w200,
                          height: 0.9,
                        ),
                      ),
                      const Text(
                        '°',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 64,
                          fontWeight: FontWeight.w200,
                          height: 0.9,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Bottom metrics row
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetricItem(
                      Icons.water_drop_outlined, 
                      '$humidity%', 
                      'Humidity'
                    ),
                    _buildDivider(),
                    _buildMetricItem(
                      Icons.air_outlined, 
                      '${windSpeed.toStringAsFixed(1)}', 
                      'm/s'
                    ),
                    _buildDivider(),
                    _buildMetricItem(
                      Icons.wb_sunny_outlined, 
                      _formatTime(sunrise), 
                      'Sunrise'
                    ),
                    _buildDivider(),
                    _buildMetricItem(
                      Icons.nightlight_outlined, 
                      _formatTime(sunset), 
                      'Sunset'
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMetricItem(IconData icon, String value, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white.withOpacity(0.8),
            size: 16,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 10,
              fontWeight: FontWeight.w400,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
  
  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 30,
      color: Colors.white.withOpacity(0.2),
    );
  }

  Widget _buildWeatherMetrics(int humidity, double windSpeed) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.water_drop,
                  color: Colors.blue.shade200,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$humidity%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.air,
                  color: Colors.teal.shade200,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${windSpeed.toStringAsFixed(1)} m/s',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSunriseSunset(int sunrise, int sunset) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTimeCard(Icons.wb_sunny, 'Sunrise', _formatTime(sunrise)),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.2),
          ),
          _buildTimeCard(Icons.nightlight_round, 'Sunset', _formatTime(sunset)),
        ],
      ),
    );
  }

  Widget _buildTimeCard(IconData icon, String label, String time) {
    return Column(
      children: [
        Icon(icon, color: Colors.amber, size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          time,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        height: 180,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryColor.withOpacity(0.8),
              AppColors.primaryColor.withOpacity(0.6),
            ],
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.red.withOpacity(0.8),
              Colors.red.withOpacity(0.6),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 40,
            ),
            const SizedBox(height: 8),
            Text(
              'Unable to load weather data',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _errorMessage,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _fetchWeatherData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.red,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryColor.withOpacity(0.8),
              AppColors.primaryColor.withOpacity(0.6),
            ],
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              color: Colors.white,
              size: 40,
            ),
            SizedBox(height: 8),
            Text(
              'No weather data available',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}