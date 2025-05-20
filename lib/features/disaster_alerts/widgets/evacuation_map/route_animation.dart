import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import '../../constants/colors.dart';

class RouteAnimator {
  List<LatLng> _animatedPoints = [];
  Set<Polyline> _animatedPolylines = {};
  Timer? _routeAnimationTimer;
  bool _isAnimatingRoute = false;
  
  // Getters
  Set<Polyline> get animatedPolylines => _animatedPolylines;
  bool get isAnimating => _isAnimatingRoute;
  
  void dispose() {
    _routeAnimationTimer?.cancel();
  }
  
  void clearRoute() {
    _animatedPolylines.clear();
    _animatedPoints.clear();
    _isAnimatingRoute = false;
    _routeAnimationTimer?.cancel();
  }
  
  void startAnimation(Set<Polyline> polylines, Function(Set<Polyline>) onUpdate, Function() onComplete) {
    // Cancel any existing animation
    _routeAnimationTimer?.cancel();
    
    if (polylines.isEmpty) return;
    
    _isAnimatingRoute = true;
    _animatedPoints = [];
    _animatedPolylines = {};
    onUpdate(_animatedPolylines);
    
    final allPoints = polylines.first.points;
    final totalPoints = allPoints.length;
    int currentPointIndex = 0;
    
    // Create a timer that adds points to the animated polyline
    _routeAnimationTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (currentPointIndex >= totalPoints) {
        timer.cancel();
        return;
      }
      
      // Add the next point to our animated points list
      _animatedPoints.add(allPoints[currentPointIndex]);
      
      // Create a new polyline with the current points
      _animatedPolylines = {
        Polyline(
          polylineId: const PolylineId('animated_route'),
          points: _animatedPoints,
          color: EvacuationColors.primaryColor,
          width: 5,
          patterns: [
            PatternItem.dash(20),
            PatternItem.gap(5),
          ],
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      };
      
      onUpdate(_animatedPolylines);
      
      currentPointIndex++;
      
      // If we've added all points, stop the animation
      if (currentPointIndex >= totalPoints) {
        _isAnimatingRoute = false;
        onComplete();
        timer.cancel();
      }
    });
  }
}