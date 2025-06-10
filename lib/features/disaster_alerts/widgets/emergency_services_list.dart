import 'package:flutter/material.dart';
import 'package:disaster_management/features/disaster_alerts/constants/colors.dart';

class EmergencyServicesList extends StatefulWidget {
  const EmergencyServicesList({Key? key}) : super(key: key);

  @override
  State<EmergencyServicesList> createState() => _EmergencyServicesListState();
}

class _EmergencyServicesListState extends State<EmergencyServicesList>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;


  final List<Map<String, dynamic>> services = const [
    {
      'title': 'Police',
      'number': '100',
      'icon': Icons.local_police_outlined,
      'color': Colors.blue,
    },
    {
      'title': 'Ambulance',
      'number': '108',
      'icon': Icons.medical_services_outlined,
      'color': Colors.red,
    },
    {
      'title': 'Fire Brigade',
      'number': '101',
      'icon': Icons.fire_truck_outlined,
      'color': Colors.orange,
    },
    {
      'title': 'Women Helpline',
      'number': '1091',
      'icon': Icons.woman_outlined,
      'color': Colors.purple,
    },
    {
      'title': 'Child Helpline',
      'number': '1098',
      'icon': Icons.child_care_outlined,
      'color': Colors.green,
    },
    {
      'title': 'Disaster',
      'number': '1070',
      'icon': Icons.emergency_outlined,
      'color': Colors.brown,
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    // Start animation after build completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Emergency Services',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                itemCount: services.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final service = services[index];
                  final delay = index * 0.1; // Staggered delay
                  final itemAnimation = Tween<double>(
                    begin: 0.0,
                    end: 1.0,
                  ).animate(
                    CurvedAnimation(
                      parent: _animationController,
                      curve: Interval(
                        delay,
                        1.0,
                        curve: Curves.easeOutBack,
                      ),
                    ),
                  );

                  return Transform.scale(
                    scale: itemAnimation.value,
                    child: Opacity(
                      opacity: itemAnimation.value,
                      child: _buildServiceCard(context, service, index),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildServiceCard(
      BuildContext context, Map<String, dynamic> service, int index) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        // Add tap animation
        _handleServiceTap(index);
      },
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated icon container
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: service['color'].withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  service['icon'],
                  color: service['color'],
                  size: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                service['title'],
                style: Theme.of(context).textTheme.labelMedium,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                service['number'],
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: service['color'],
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleServiceTap(int index) {
    // Create a temporary animation controller for the tap effect
    final tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    final tapAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(
        parent: tapController,
        curve: Curves.easeInOut,
      ),
    );

    tapController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        tapController.reverse();
      }
    });

    tapController.forward();

    // Implement your call functionality here
    // You can access the service using services[index]
    debugPrint('Calling ${services[index]['title']} at ${services[index]['number']}');
  }
}