import 'package:disaster_management/services/location_service.dart';
import 'package:flutter/material.dart';
import 'package:disaster_management/features/disaster_alerts/widgets/headerComponent.dart';

class CombinedHomeWeatherComponent extends StatefulWidget {
  // ... keep existing constructor and properties ...

  @override
  _CombinedHomeWeatherComponentState createState() =>
      _CombinedHomeWeatherComponentState();
}

class _CombinedHomeWeatherComponentState
    extends State<CombinedHomeWeatherComponent> with WidgetsBindingObserver {
  final String temperature;
  final String condition;
  final String sensibleTemperature;
  final String humidity;
  final String pressure;

  Map<String, dynamic>? _locationData;
  String _errorMessage = '';
  bool _isLoading = true;

  _CombinedHomeWeatherComponentState({
    this.temperature = '23',
    this.condition = 'Moderate disaster risk',
    this.sensibleTemperature = '25°',
    this.humidity = '63%',
    this.pressure = '1009 hPa',
  });

  @override
  void initState() {
    super.initState();
     WidgetsBinding.instance.addObserver(this);
    _fetchLocationData();
  }

    @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchLocationData();
    }
  }

  //initial location fetch on home screen
  Future<void> _fetchLocationData() async {
    print("Fetching location data...");
    try {
      final data = await LocationService.getCurrentLocation(context);
      setState(() {
        _locationData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching location: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  String _formatCoordinates() {
    if (_locationData == null) return 'Fetching coordinates...';
    final lat = _locationData!['latitude'].toStringAsFixed(4);
    final lng = _locationData!['longitude'].toStringAsFixed(4);
    return '$lat° N, $lng° E';
  }

  String _formatTimeAgo() {
    if (_locationData == null) return 'Just now';
    final lastFetched = DateTime.parse(_locationData!['lastFetched']);
    final difference = DateTime.now().difference(lastFetched);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    WidgetsApp.debugAllowBannerOverride = false; // Removes the debug banner

    return Scaffold(
      backgroundColor: Color(0xFF121212),
      body: SafeArea(
        child: Column(
          children: [
            HeaderComponent(),
            Expanded(
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height -
                        kToolbarHeight -
                        kBottomNavigationBarHeight,
                  ),
                  child: Column(
                    children: [
                      // Location and Risk Section
                      _buildLocationRiskSection(context, isSmallScreen),

                      // Immediate Threats Section
                      _buildImmediateThreatsSection(isSmallScreen),

                      // Predictive Analysis Section
                      _buildPredictiveAnalysisSection(),

                      // Safety Checklist Section
                      _buildSafetyChecklistSection(),
                    ],
                  ),
                ),
              ),
            ),
            // FooterComponent(),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRiskSection(BuildContext context, bool isSmallScreen) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
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
          Flex(
            direction: isSmallScreen ? Axis.vertical : Axis.horizontal,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: isSmallScreen
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              Flexible(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Location',
                      style: TextStyle(
                        color: Color(0xFFBDBDBD),
                        fontSize: 14,
                        fontFamily: 'Inter',
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            color: Color(0xFF00E676), size: 20),
                        SizedBox(width: 8),
                        Flexible(
                          child: _isLoading
                              ? Text('Fetching location...',
                                  style: TextStyle(color: Colors.white))
                              : Text(
                                  _locationData?['address'] ??
                                      'Unknown Location',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      _isLoading ? '...' : _formatCoordinates(),
                      style: TextStyle(
                        color: Color(0xFF9E9E9E),
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _isLoading ? 'Updating...' : 'Last updated: ${_formatTimeAgo()}',
                      style: TextStyle(
                        color: Color(0xFF6B6B6B),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isSmallScreen) SizedBox(width: 16),
              Flexible(
                flex: 1,
                child: Column(
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
                    SizedBox(height: 8),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _getRiskColor(int.parse(temperature))
                            .withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getRiskColor(int.parse(temperature)),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        '$temperature%',
                        style: TextStyle(
                          color: _getRiskColor(int.parse(temperature)),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      condition,
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
          SizedBox(height: 16),
          Divider(color: Color(0xFF373737)),
          SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.spaceEvenly,
            children: [
              _buildWeatherDetail(
                  sensibleTemperature, 'Heat Index', Icons.thermostat),
              _buildWeatherDetail(humidity, 'Humidity', Icons.water_drop),
              _buildWeatherDetail(pressure, 'Pressure', Icons.speed),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImmediateThreatsSection(bool isSmallScreen) {
    final threats = [
      _ThreatData('Tsunami Alert', 'Coastal Warning', Icons.waves, 0xFF1565C0),
      _ThreatData('Strong Winds', '50-70 km/h Expected', Icons.air, 0xFFFFB74D),
      _ThreatData('Wildfire Risk', 'High Temp Alert',
          Icons.local_fire_department, 0xFFE53935),
    ];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Immediate Threats',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(Icons.warning_amber, color: Color(0xFFD32F2F), size: 24),
              ],
            ),
          ),
          SizedBox(
            height: 140,
            child: ListView.builder(
              physics: BouncingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              itemCount: threats.length,
              padding: EdgeInsets.only(left: 16, right: 16, bottom: 16),
              itemBuilder: (context, index) {
                final threat = threats[index];
                return Container(
                  width: isSmallScreen ? 160 : 180,
                  margin: EdgeInsets.only(right: 16),
                  child: _buildThreatCard(
                    threat.title,
                    threat.subtitle,
                    threat.icon,
                    Color(threat.color),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictiveAnalysisSection() {
    final predictions = [
      _PredictionData('Earthquake', 65, Icons.landscape, 0xFF4A148C),
      _PredictionData('Flood', 89, Icons.water_damage, 0xFF0D47A1),
      _PredictionData('Tsunami', 42, Icons.waves, 0xFF1565C0),
      _PredictionData('Cyclone', 78, Icons.storm, 0xFF00695C),
    ];

    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Predictive Analysis',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - 48) / 2;
              return GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio:
                      itemWidth / 140, // Adjusted height to prevent overflow
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                ),
                itemCount: predictions.length,
                itemBuilder: (context, index) {
                  final prediction = predictions[index];
                  return _buildAlertCard(
                    prediction.title,
                    prediction.riskPercent,
                    prediction.icon,
                    Color(prediction.color),
                  );
                },
              );
            },
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSafetyChecklistSection() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Safety Checklist',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          ..._buildChecklistItems(),
        ],
      ),
    );
  }

  List<Widget> _buildChecklistItems() {
    final items = [
      _ChecklistItem('Emergency kit prepared', true),
      _ChecklistItem('Evacuation route planned', false),
      _ChecklistItem('Important documents secured', true),
      _ChecklistItem('Emergency contacts saved', false),
    ];

    return items
        .map((item) => _buildChecklistItem(item.text, item.isComplete))
        .toList();
  }

  Widget _buildThreatCard(
      String title, String subtitle, IconData icon, Color color) {
    return Container(
      width: 180,
      margin: EdgeInsets.only(left: 16, bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(String text, bool isComplete) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            isComplete ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isComplete ? Color(0xFF00E676) : Color(0xFF6B6B6B),
            size: 20,
          ),
          SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: isComplete ? Colors.white : Color(0xFF9E9E9E),
              fontSize: 14,
            ),
          ),
        ],
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

  Widget _buildAlertCard(
      String title, int riskPercent, IconData icon, Color color) {
    return Container(
      constraints: const BoxConstraints(minWidth: 160),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: IntrinsicHeight(
          // Prevents bottom overflow
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 8), // Prevents tight spacing
                  Expanded(
                    child: Text(
                      '$riskPercent%',
                      style: TextStyle(
                        color: color,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) {
                  return SizedBox(
                    width: constraints.maxWidth,
                    child: LinearProgressIndicator(
                      value: riskPercent / 100,
                      backgroundColor: color.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper classes for data organization
class _ThreatData {
  final String title;
  final String subtitle;
  final IconData icon;
  final int color;

  _ThreatData(this.title, this.subtitle, this.icon, this.color);
}

class _PredictionData {
  final String title;
  final int riskPercent;
  final IconData icon;
  final int color;

  _PredictionData(this.title, this.riskPercent, this.icon, this.color);
}

class _ChecklistItem {
  final String text;
  final bool isComplete;

  _ChecklistItem(this.text, this.isComplete);
}
