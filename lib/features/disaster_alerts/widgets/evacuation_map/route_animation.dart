import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../constants/colors.dart';
class RouteAnimator {
  List<LatLng> _animatedPoints = [];
  Set<Polyline> _animatedPolylines = {};
  Timer? _routeAnimationTimer;
  Timer? _pulseAnimationTimer;
  bool _isAnimatingRoute = false;
  bool _isPulsing = false;
  int _pulseWidth = 5;
  final int _maxPulseWidth = 8;
  final int _minPulseWidth = 4;
  bool _pulseIncreasing = true;
  
  // Getters
  Set<Polyline> get animatedPolylines => _animatedPolylines;
  bool get isAnimating => _isAnimatingRoute;
  
  void dispose() {
    _routeAnimationTimer?.cancel();
    _pulseAnimationTimer?.cancel();
  }
  
  void clearRoute() {
    _animatedPolylines.clear();
    _animatedPoints.clear();
    _isAnimatingRoute = false;
    _isPulsing = false;
    _routeAnimationTimer?.cancel();
    _pulseAnimationTimer?.cancel();
  }
  
  void startAnimation(
    Set<Polyline> polylines, 
    Function(Set<Polyline>) onUpdate, 
    Function() onComplete,
    [Function(CameraUpdate)? onCameraUpdate]  // Optional camera update callback
  ) {
    // Cancel any existing animation
    _routeAnimationTimer?.cancel();
    _pulseAnimationTimer?.cancel();
    
    if (polylines.isEmpty) return;
    
    _isAnimatingRoute = true;
    _animatedPoints = [];
    _animatedPolylines = {};
    onUpdate(_animatedPolylines);
    
    final allPoints = polylines.first.points;
    final totalPoints = allPoints.length;
    int currentPointIndex = 0;
    
    // Create a timer that adds points to the animated polyline
    _routeAnimationTimer = Timer.periodic(const Duration(milliseconds: 40), (timer) {
      if (currentPointIndex >= totalPoints) {
        timer.cancel();
        _startPulseAnimation(onUpdate, onComplete);
        return;
      }
      
      // Add the next point to our animated points list
      _animatedPoints.add(allPoints[currentPointIndex]);
      
      // Create a new polyline with the current points
      _updateAnimatedPolyline(onUpdate);
      
      // Update camera position if callback is provided
      if (onCameraUpdate != null && _animatedPoints.isNotEmpty) {
        // Determine the camera position based on animation progress
        _updateCameraPosition(allPoints, currentPointIndex, onCameraUpdate);
      }
      
      currentPointIndex++;
      
      // If we've added all points, stop the animation
      if (currentPointIndex >= totalPoints) {
        timer.cancel();
        _startPulseAnimation(onUpdate, onComplete);
      }
    });
  }
  
  void _updateCameraPosition(List<LatLng> allPoints, int currentIndex, Function(CameraUpdate) onCameraUpdate) {
    // Calculate the appropriate camera position based on the current animation progress
    
    // For the first few points, we want to show the starting point and direction
    if (currentIndex < 5) {
      // Show the first few points with some padding
      final bounds = _calculateBounds(allPoints.sublist(0, math.min(10, allPoints.length)));
      onCameraUpdate(CameraUpdate.newLatLngBounds(bounds, 100));
      return;
    }
    
    // For the middle of the route, follow the current point with some lookahead
    int endIndex = math.min(currentIndex + 5, allPoints.length - 1);
    int startIndex = math.max(0, currentIndex - 2);
    
    // Calculate visible segment bounds
    final visibleSegment = allPoints.sublist(startIndex, endIndex + 1);
    final bounds = _calculateBounds(visibleSegment);
    
    // Update camera to show the current segment with padding
    onCameraUpdate(CameraUpdate.newLatLngBounds(bounds, 80));
  }
  
  LatLngBounds _calculateBounds(List<LatLng> points) {
    if (points.isEmpty) {
      // Default bounds if no points (shouldn't happen)
      return LatLngBounds(
        southwest: const LatLng(0, 0),
        northeast: const LatLng(0, 0)
      );
    }
    
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;
    
    for (var point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }
    
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng)
    );
  }
  
  void _startPulseAnimation(Function(Set<Polyline>) onUpdate, Function() onComplete) {
    _isPulsing = true;
    
    // Create a pulsing effect by changing the width of the polyline
    _pulseAnimationTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_pulseIncreasing) {
        _pulseWidth++;
        if (_pulseWidth >= _maxPulseWidth) {
          _pulseIncreasing = false;
        }
      } else {
        _pulseWidth--;
        if (_pulseWidth <= _minPulseWidth) {
          _pulseIncreasing = true;
        }
      }
      
      _updateAnimatedPolyline(onUpdate);
      
      // After a certain time, stop the pulsing animation
      if (!_isAnimatingRoute && timer.tick > 50) {
        _isPulsing = false;
        _isAnimatingRoute = false;
        timer.cancel();
        onComplete();
      }
    });
  }
  
  void _updateAnimatedPolyline(Function(Set<Polyline>) onUpdate) {
    if (_animatedPoints.isEmpty) return;
    
    // Create a gradient effect by using two polylines
    _animatedPolylines = {
      // Main route polyline
      Polyline(
        polylineId: const PolylineId('animated_route'),
        points: _animatedPoints,
        color: EvacuationColors.primaryColor,
        width: _pulseWidth,
        patterns: [
          PatternItem.dash(20),
          PatternItem.gap(5),
        ],
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
      
      // Glow effect polyline (slightly wider and more transparent)
      Polyline(
        polylineId: const PolylineId('glow_effect'),
        points: _animatedPoints,
        color: EvacuationColors.primaryColor.withOpacity(0.3),
        width: _pulseWidth + 3,  // Remove .toDouble()
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
      
      // Direction indicator at the end of the route
      if (_animatedPoints.length > 1)
        Polyline(
          polylineId: const PolylineId('direction_indicator'),
          points: [
            _animatedPoints.last,
            _getDirectionPoint(_animatedPoints),
          ],
          color: Colors.white,
          width: 3,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
    };
    
    onUpdate(_animatedPolylines);
  }
  
  // Helper method to create a point that indicates direction
  LatLng _getDirectionPoint(List<LatLng> points) {
    if (points.length < 2) return points.last;
    
    // Get the last two points to determine direction
    final LatLng lastPoint = points.last;
    final LatLng secondLastPoint = points[points.length - 2];
    
    // Calculate direction vector
    double dx = lastPoint.latitude - secondLastPoint.latitude;
    double dy = lastPoint.longitude - secondLastPoint.longitude;
    
    // Normalize and scale
    double length = sqrt(dx * dx + dy * dy);
    dx = dx / length * 0.0005; // Small offset for direction indicator
    dy = dy / length * 0.0005;
    
    // Return a point slightly ahead in the direction of travel
    return LatLng(lastPoint.latitude + dx, lastPoint.longitude + dy);
  }
}

// Helper method for square root calculation
double sqrt(double value) {
  return value <= 0 ? 0 : math.sqrt(value);
}