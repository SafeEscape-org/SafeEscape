import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import 'animated_input_field.dart';
import 'location_search_dialog.dart';
import '../../../services/location_service.dart';

class LocationSection extends StatefulWidget {
  final Function(double latitude, double longitude, String address) onLocationSelected;
  final AnimationController animation;

  const LocationSection({
    super.key,
    required this.onLocationSelected,
    required this.animation,
  });

  @override
  State<LocationSection> createState() => _LocationSectionState();
}

class _LocationSectionState extends State<LocationSection> {
  final _addressController = TextEditingController();
  String? _selectedAddress;
  double? _latitude;
  double? _longitude;
  bool _isLoadingLocation = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Location',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textColor,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: AnimatedInputField(
                controller: _addressController,
                label: 'Address',
                icon: Icons.location_on_outlined,
                delay: 0.6,
                animation: widget.animation,
                maxLines: 2,
              ),
            ),
            const SizedBox(width: 8),
            // Custom location search button
            Container(
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: _openLocationSearch,
                icon: const Icon(Icons.search_rounded, color: Colors.white),
                tooltip: 'Search location',
              ),
            ),
            const SizedBox(width: 8),
            // Current location button
            Container(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                icon: _isLoadingLocation
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.my_location, color: Colors.white),
                tooltip: 'Use current location',
              ),
            ),
          ],
        ),
        if (_selectedAddress != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Selected: $_selectedAddress',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: AppColors.primaryColor,
              ),
            ),
          ),
      ],
    );
  }

  // Get current location
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      final locationData = await LocationService.getCurrentLocation(context);
      if (locationData != null) {
        setState(() {
          _latitude = locationData['latitude'];
          _longitude = locationData['longitude'];
          _selectedAddress = locationData['address'];
          _addressController.text = locationData['address'] ?? '';
        });
        
        // Notify parent
        widget.onLocationSelected(
          _latitude!,
          _longitude!,
          _selectedAddress!,
        );
      }
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  // Open location search dialog
  Future<void> _openLocationSearch() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const LocationSearchDialog(),
    );
    
    if (result != null) {
      setState(() {
        _latitude = result['latitude'];
        _longitude = result['longitude'];
        _selectedAddress = result['address'];
        _addressController.text = result['address'] ?? '';
      });
      
      // Notify parent
      widget.onLocationSelected(
        _latitude!,
        _longitude!,
        _selectedAddress!,
      );
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }
}