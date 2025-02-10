import 'package:flutter/material.dart';
import 'package:disaster_management/features/disaster_alerts/widgets/footerComponent.dart';
import 'package:disaster_management/features/disaster_alerts/widgets/headerComponent.dart';

class CombinedHomeWeatherComponent extends StatelessWidget {
  final String temperature;
  final String condition;
  final String sensibleTemperature;
  final String humidity;
  final String pressure;

  CombinedHomeWeatherComponent({
    this.temperature = '23',
    this.condition = 'Moderate disaster risk',
    this.sensibleTemperature = '25°',
    this.humidity = '63%',
    this.pressure = '1009 hPa',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121212), // Dark background for professional look
      body: SafeArea(
        child: Column(
          children: [
            HeaderComponent(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Weather Info Section
                    Container(
                      margin: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16),
                      padding: EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            spreadRadius: 2,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Alert Status label
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            decoration: BoxDecoration(
                              color: Color(0xFF2A2A2A),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Current Alert Status',
                              style: TextStyle(
                                color: Color(0xFF00E676), // Alert green
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          
                          // Disaster info row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Image.asset(
                              //   'assets/images/disaster_alert.png',
                              //   width: 120,
                              //   height: 120,
                              // ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Risk Level',
                                    style: TextStyle(
                                      color: Color(0xFFBDBDBD),
                                      fontSize: 14,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    temperature,
                                    style: TextStyle(
                                      color: _getRiskColor(int.parse(temperature)),
                                      fontSize: 42,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                  Text(
                                    condition,
                                    style: TextStyle(
                                      color: Color(0xFF9E9E9E),
                                      fontSize: 14,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          
                          // Environmental details row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildWeatherDetail(sensibleTemperature, 'Heat Index', Icons.thermostat),
                              _buildWeatherDetail(humidity, 'Humidity', Icons.water_drop),
                              _buildWeatherDetail(pressure, 'Pressure', Icons.speed),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Alert Predictions Section
                    Container(
                      margin: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            spreadRadius: 2,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Critical Alerts Card
                          Container(
                            margin: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Color(0xFF2D1E1E),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Color(0xFFB71C1C).withOpacity(0.5)),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Color(0xFFB71C1C),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.warning_amber, color: Colors.white, size: 24),
                                        SizedBox(width: 8),
                                        Text(
                                          'CRITICAL',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '3 Active Emergencies',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'In your monitored regions',
                                          style: TextStyle(
                                            color: Color(0xFF9E9E9E),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Prediction Controls
                          Container(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Predictive Analysis',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildAlertCard(
                                      'Earthquake',
                                      65,
                                      Icons.landscape,
                                      Color(0xFF4A148C),
                                    ),
                                    _buildAlertCard(
                                      'Flood',
                                      89,
                                      Icons.waves,
                                      Color(0xFF0D47A1),
                                    ),
                                  ],
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
            FooterComponent(),
          ],
        ),
      ),
    );
  }

  Color _getRiskColor(int riskLevel) {
    if (riskLevel >= 75) return Color(0xFFD32F2F);
    if (riskLevel >= 50) return Color(0xFFFFA000);
    return Color(0xFF4CAF50);
  }

  Widget _buildWeatherDetail(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Color(0xFF757575), size: 28),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Color(0xFF9E9E9E),
            fontSize: 12,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }

  Widget _buildAlertCard(String title, int riskPercent, IconData icon, Color color) {
    return Container(
      width: 160,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color),
              ),
              Text(
                '$riskPercent%',
                style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          LinearProgressIndicator(
            value: riskPercent / 100,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }
}