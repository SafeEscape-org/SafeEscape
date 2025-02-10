import 'package:disaster_management/features/disaster_alerts/widgets/headerComponent.dart';
import 'package:flutter/material.dart';

class EvacuationScreen extends StatelessWidget {
  const EvacuationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Column(
        children: [
          const HeaderComponent(), // Your existing header
          Expanded(
            child: Column(
              children: [
                // Map Container
                Container(
                  height: 300,
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        spreadRadius: 2,
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.map_outlined,
                          color: Colors.white.withOpacity(0.2),
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'MAP VIEW',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.3),
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Routes List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: 3, // Static demo data
                    itemBuilder: (context, index) => _buildRouteCard(index),
                  ),
                ),
              ],
            ),
          ),
          // const FooterComponent(), // Your existing footer
        ],
      ),
    );
  }

  Widget _buildRouteCard(int index) {
    final routes = [
      {
        'destination': 'Delhi Emergency Shelter #1',
        'distance': '5.2 km',
        'duration': '15 mins',
        'traffic': 'Low',
      },
      {
        'destination': 'Government Hospital',
        'distance': '7.8 km',
        'duration': '22 mins',
        'traffic': 'Medium',
      },
      {
        'destination': 'Police Station HQ',
        'distance': '3.4 km',
        'duration': '10 mins',
        'traffic': 'High',
      },
    ];

    final route = routes[index];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF404040),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF00FF00).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.directions,
            color: Color(0xFF00FF00),
            size: 24,
          ),
        ),
        title: Text(
          route['destination']!,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                _buildStatusChip(
                  icon: Icons.timer,
                  text: route['duration']!,
                  color: Colors.blue,
                ),
                const SizedBox(width: 12),
                _buildStatusChip(
                  icon: Icons.directions_car,
                  text: route['distance']!,
                  color: Colors.green,
                ),
              ],
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getTrafficColor(route['traffic']!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            route['traffic']!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip({required IconData icon, required String text, required Color color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Color _getTrafficColor(String level) {
    switch (level.toLowerCase()) {
      case 'high':
        return Colors.red.withOpacity(0.4);
      case 'medium':
        return Colors.orange.withOpacity(0.4);
      default:
        return Colors.green.withOpacity(0.4);
    }
  }
}