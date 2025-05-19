import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedBackground extends StatefulWidget {
  final List<Color> colors;
  final Duration duration;
  final bool isEmergencyMode;
  final AnimationStyle style;

  const AnimatedBackground({
    Key? key,
    required this.colors,
    this.duration = const Duration(seconds: 6), // Faster animation (was 10)
    this.isEmergencyMode = false,
    this.style = AnimationStyle.topographicMap,
  }) : super(key: key);

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

enum AnimationStyle {
  topographicMap,
  satelliteView,
  navigationLines,
  gridMap,
}

class _AnimatedBackgroundState extends State<AnimatedBackground> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();

    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.2),
        weight: 1.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0),
        weight: 1.0,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.colors,
                stops: const [0.0, 0.5, 1.0],
                begin: Alignment(
                  math.cos(_controller.value * 2 * math.pi) * 0.5 + 0.5,
                  math.sin(_controller.value * 2 * math.pi) * 0.5 + 0.5,
                ),
                end: Alignment(
                  math.cos((_controller.value + 0.5) * 2 * math.pi) * 0.5 + 0.5,
                  math.sin((_controller.value + 0.5) * 2 * math.pi) * 0.5 + 0.5,
                ),
                tileMode: TileMode.mirror,
              ),
            ),
            child: Stack(
              children: [
                // Advanced map background - INCREASED OPACITY for more visibility
                Positioned.fill(
                  child: Opacity(
                    opacity: widget.isEmergencyMode ? 0.4 : 0.3, // Increased from 0.25/0.15
                    child: CustomPaint(
                      painter: _getBackgroundPainter(),
                    ),
                  ),
                ),
                
                // Emergency pulse effect
                if (widget.isEmergencyMode)
                  Positioned.fill(
                    child: ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              Colors.red.withOpacity(0.3),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 1.0],
                            center: Alignment.center,
                            radius: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                
                // Overlay gradient
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.1),
                          Colors.black.withOpacity(0.2),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  CustomPainter _getBackgroundPainter() {
    switch (widget.style) {
      case AnimationStyle.topographicMap:
        return TopographicMapPainter(
          progress: _controller.value,
          isEmergencyMode: widget.isEmergencyMode,
        );
      case AnimationStyle.satelliteView:
        return SatelliteViewPainter(
          progress: _controller.value,
          isEmergencyMode: widget.isEmergencyMode,
        );
      case AnimationStyle.navigationLines:
        return NavigationLinesPainter(
          progress: _controller.value,
          isEmergencyMode: widget.isEmergencyMode,
        );
      case AnimationStyle.gridMap:
        return GridMapPainter(
          progress: _controller.value,
          isEmergencyMode: widget.isEmergencyMode,
        );
      default:
        return TopographicMapPainter(
          progress: _controller.value,
          isEmergencyMode: widget.isEmergencyMode,
        );
    }
  }
}

class TopographicMapPainter extends CustomPainter {
  final double progress;
  final bool isEmergencyMode;
  
  TopographicMapPainter({
    required this.progress,
    this.isEmergencyMode = false,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final baseColor = isEmergencyMode ? Colors.red : Colors.cyan;
    
    // Draw topographic contour lines
    for (int i = 0; i < 8; i++) {
      final contourPaint = Paint()
        ..color = baseColor.withOpacity(0.1 + (i * 0.02))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round;
      
      final scale = 1.0 + (i * 0.15);
      final offset = progress * 20.0;
      
      final path = Path();
      
      // Create organic, flowing contour lines
      for (int j = 0; j < 5; j++) {
        final startX = -size.width * 0.2 + (j * size.width * 0.3) + offset;
        final startY = size.height * (0.3 + (i * 0.1)) + 
            (math.sin(progress * math.pi * 2 + (j * 0.5)) * 20.0);
        
        if (j == 0) {
          path.moveTo(startX, startY);
        } else {
          final controlPoint1X = startX - (size.width * 0.1) + 
              (math.sin(progress * math.pi + j) * 10.0);
          final controlPoint1Y = startY - (size.height * 0.05) + 
              (math.cos(progress * math.pi + j) * 10.0);
          
          final controlPoint2X = startX - (size.width * 0.05) + 
              (math.cos(progress * math.pi + j) * 10.0);
          final controlPoint2Y = startY + (size.height * 0.05) + 
              (math.sin(progress * math.pi + j) * 10.0);
          
          path.cubicTo(
            controlPoint1X, controlPoint1Y,
            controlPoint2X, controlPoint2Y,
            startX, startY
          );
        }
      }
      
      // Complete the path with a smooth curve back to start
      path.quadraticBezierTo(
        size.width * 1.2, 
        size.height * (0.3 + (i * 0.1)) + (math.sin(progress * math.pi) * 30.0),
        size.width * 1.5, 
        size.height * (0.5 + (i * 0.05))
      );
      
      canvas.drawPath(path, contourPaint);
    }
    
    // Draw location markers
    final markerPositions = [
      Offset(size.width * 0.2, size.height * 0.3),
      Offset(size.width * 0.5, size.height * 0.6),
      Offset(size.width * 0.8, size.height * 0.4),
      Offset(size.width * 0.3, size.height * 0.7),
    ];
    
    for (var position in markerPositions) {
      _drawLocationMarker(canvas, position, baseColor);
    }
  }
  
  void _drawLocationMarker(Canvas canvas, Offset position, Color color) {
    // Pulsing effect based on progress
    final scale = 1.0 + math.sin(progress * math.pi * 2) * 0.3;
    
    // Draw outer glow
    for (int i = 5; i > 0; i--) {
      final glowPaint = Paint()
        ..color = color.withOpacity(0.03 * i)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        position, 
        (6.0 + (i * 1.5)) * scale, 
        glowPaint
      );
    }
    
    // Draw marker
    final markerPaint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      position, 
      4.0 * scale, 
      markerPaint
    );
    
    // Draw inner highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(position.dx - 1.0, position.dy - 1.0), 
      1.5 * scale, 
      highlightPaint
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class SatelliteViewPainter extends CustomPainter {
  final double progress;
  final bool isEmergencyMode;
  
  SatelliteViewPainter({
    required this.progress,
    this.isEmergencyMode = false,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final baseColor = isEmergencyMode ? Colors.red : Colors.cyan;
    
    // Draw satellite grid pattern
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    
    final gridSize = 30.0;
    final offset = progress * gridSize * 0.5;
    
    // Draw horizontal grid lines with wave effect
    for (double i = -gridSize; i <= size.height + gridSize; i += gridSize) {
      final path = Path();
      path.moveTo(0, i + offset);
      
      for (double x = 0; x <= size.width; x += 10) {
        final waveHeight = math.sin((x / size.width) * math.pi * 4 + (progress * math.pi * 2)) * 5.0;
        path.lineTo(x, i + offset + waveHeight);
      }
      
      canvas.drawPath(path, gridPaint);
    }
    
    // Draw vertical grid lines with wave effect
    for (double i = -gridSize; i <= size.width + gridSize; i += gridSize) {
      final path = Path();
      path.moveTo(i + offset, 0);
      
      for (double y = 0; y <= size.height; y += 10) {
        final waveWidth = math.sin((y / size.height) * math.pi * 4 + (progress * math.pi * 2)) * 5.0;
        path.lineTo(i + offset + waveWidth, y);
      }
      
      canvas.drawPath(path, gridPaint);
    }
    
    // Draw satellite scan line
    final scanPaint = Paint()
      ..color = baseColor.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    final scanY = size.height * progress;
    canvas.drawLine(
      Offset(0, scanY),
      Offset(size.width, scanY),
      scanPaint
    );
    
    // Draw scan glow
    final scanGlowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          baseColor.withOpacity(0.2),
          baseColor.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, scanY - 20, size.width, 40));
    
    canvas.drawRect(
      Rect.fromLTWH(0, scanY - 20, size.width, 40),
      scanGlowPaint
    );
    
    // Draw regions
    final regions = [
      Rect.fromLTWH(size.width * 0.1, size.height * 0.2, size.width * 0.3, size.height * 0.2),
      Rect.fromLTWH(size.width * 0.5, size.height * 0.3, size.width * 0.3, size.height * 0.3),
      Rect.fromLTWH(size.width * 0.2, size.height * 0.6, size.width * 0.2, size.height * 0.2),
    ];
    
    for (var region in regions) {
      final regionPaint = Paint()
        ..color = baseColor.withOpacity(0.1)
        ..style = PaintingStyle.fill;
      
      final borderPaint = Paint()
        ..color = baseColor.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      
      canvas.drawRect(region, regionPaint);
      canvas.drawRect(region, borderPaint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class NavigationLinesPainter extends CustomPainter {
  final double progress;
  final bool isEmergencyMode;
  
  NavigationLinesPainter({
    required this.progress,
    this.isEmergencyMode = false,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final baseColor = isEmergencyMode ? Colors.red : Colors.cyan;
    
    // Draw animated navigation lines
    final linePaint = Paint()
      ..color = baseColor.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    
    // Create multiple paths
    final paths = [
      _createNavigationPath(size, 0.0),
      _createNavigationPath(size, 0.33),
      _createNavigationPath(size, 0.66),
    ];
    
    for (var path in paths) {
      // Draw glowing effect with INCREASED OPACITY
      for (int i = 5; i > 0; i--) {
        final glowPaint = Paint()
          ..color = baseColor.withOpacity(0.05 * i) // Increased from 0.02
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0 + (i * 2.0) // Slightly wider glow
          ..strokeCap = StrokeCap.round;
        
        canvas.drawPath(path, glowPaint);
      }
      
      // Draw the main path with INCREASED OPACITY
      final linePaint = Paint()
        ..color = baseColor.withOpacity(0.7) // Increased from 0.4
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 // Slightly thicker
        ..strokeCap = StrokeCap.round;
      
      canvas.drawPath(path, linePaint);
      
      // Draw animated dots along the path
      _drawAnimatedDotsAlongPath(canvas, path, baseColor);
    }
    
    // Draw intersection points
    final intersections = [
      Offset(size.width * 0.3, size.height * 0.3),
      Offset(size.width * 0.6, size.height * 0.5),
      Offset(size.width * 0.4, size.height * 0.7),
    ];
    
    for (var point in intersections) {
      _drawIntersectionPoint(canvas, point, baseColor);
    }
  }
  
  Path _createNavigationPath(Size size, double offset) {
    final adjustedProgress = (progress + offset) % 1.0;
    
    final path = Path();
    path.moveTo(0, size.height * (0.3 + offset * 0.4));
    
    path.cubicTo(
      size.width * 0.3, 
      size.height * (0.2 + math.sin(adjustedProgress * math.pi * 2) * 0.1), 
      size.width * 0.6, 
      size.height * (0.7 + math.cos(adjustedProgress * math.pi * 2) * 0.1),
      size.width, 
      size.height * (0.5 + offset * 0.2)
    );
    
    return path;
  }
  
  void _drawAnimatedDotsAlongPath(Canvas canvas, Path path, Color color) {
    final pathMetrics = path.computeMetrics().first;
    final pathLength = pathMetrics.length;
    
    // Draw 5 dots along the path
    for (int i = 0; i < 5; i++) {
      final dotProgress = (progress + (i / 5)) % 1.0;
      final dotPosition = pathMetrics.getTangentForOffset(pathLength * dotProgress);
      
      if (dotPosition != null) {
        // Draw glow around dot
        final glowPaint = Paint()
          ..color = color.withOpacity(0.4) // Increased opacity
          ..style = PaintingStyle.fill;
        
        canvas.drawCircle(
          dotPosition.position, 
          6.0, // Larger glow
          glowPaint
        );
        
        // Draw dot
        final dotPaint = Paint()
          ..color = color.withOpacity(0.9) // More visible
          ..style = PaintingStyle.fill;
        
        canvas.drawCircle(
          dotPosition.position, 
          4.0, // Larger dot (was 3.0)
          dotPaint
        );
        
        // Draw trail
        final trailPaint = Paint()
          ..color = color.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        
        final trailPath = Path();
        trailPath.moveTo(dotPosition.position.dx, dotPosition.position.dy);
        trailPath.lineTo(
          dotPosition.position.dx - (dotPosition.vector.dx * 15),
          dotPosition.position.dy - (dotPosition.vector.dy * 15)
        );
        
        canvas.drawPath(trailPath, trailPaint);
      }
    }
  }
  
  void _drawIntersectionPoint(Canvas canvas, Offset position, Color color) {
    // Pulsing effect
    final scale = 1.0 + math.sin(progress * math.pi * 2) * 0.3;
    
    // Draw outer circle
    final outerPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    canvas.drawCircle(
      position, 
      10.0 * scale, 
      outerPaint
    );
    
    // Draw inner circle
    final innerPaint = Paint()
      ..color = color.withOpacity(0.7)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      position, 
      4.0 * scale, 
      innerPaint
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class GridMapPainter extends CustomPainter {
  final double progress;
  final bool isEmergencyMode;
  
  GridMapPainter({
    required this.progress,
    this.isEmergencyMode = false,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final baseColor = isEmergencyMode ? Colors.red : Colors.cyan;
    
    // Draw base grid
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    
    final gridSize = 40.0;
    
    // Draw horizontal grid lines
    for (double i = 0; i <= size.height; i += gridSize) {
      canvas.drawLine(
        Offset(0, i), 
        Offset(size.width, i), 
        gridPaint
      );
    }
    
    // Draw vertical grid lines
    for (double i = 0; i <= size.width; i += gridSize) {
      canvas.drawLine(
        Offset(i, 0), 
        Offset(i, size.height), 
        gridPaint
      );
    }
    
    // Draw animated "roads" or paths
    final roadPaint = Paint()
      ..color = baseColor.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    
    // Main diagonal path
    final path = Path();
    path.moveTo(0, size.height * 0.8);
    path.quadraticBezierTo(
      size.width * 0.3, 
      size.height * (0.2 + progress * 0.1), 
      size.width * 0.7, 
      size.height * (0.5 - progress * 0.1)
    );
    path.quadraticBezierTo(
      size.width * 0.9, 
      size.height * (0.7 + progress * 0.1), 
      size.width, 
      size.height * 0.2
    );
    
    // Secondary path
    final path2 = Path();
    path2.moveTo(0, size.height * 0.3);
    path2.quadraticBezierTo(
      size.width * 0.4, 
      size.height * (0.5 - progress * 0.1), 
      size.width * 0.6, 
      size.height * (0.2 + progress * 0.1)
    );
    path2.quadraticBezierTo(
      size.width * 0.8, 
      size.height * (0.4 - progress * 0.1), 
      size.width, 
      size.height * 0.7
    );
    
    // Draw glowing effect for both paths
    for (int i = 5; i > 0; i--) {
      final glowPaint = Paint()
        ..color = baseColor.withOpacity(0.03 * i)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0 + (6 - i) * 2.0;
      
      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path2, glowPaint);
    }
    
    // Draw the main paths
    canvas.drawPath(path, roadPaint);
    canvas.drawPath(path2, roadPaint);
    
    // Draw animated dots along the paths
    _drawAnimatedDotsAlongPath(canvas, path, baseColor);
    _drawAnimatedDotsAlongPath(canvas, path2, baseColor);
    
    // Draw location markers
    final markerPositions = [
      Offset(size.width * 0.2, size.height * 0.3),
      Offset(size.width * 0.5, size.height * 0.6),
      Offset(size.width * 0.8, size.height * 0.4),
    ];
    
    for (var position in markerPositions) {
      _drawLocationMarker(canvas, position, baseColor);
    }
    
    // Draw city/location blocks
    final locations = [
      Rect.fromLTWH(size.width * 0.1, size.height * 0.2, gridSize, gridSize),
      Rect.fromLTWH(size.width * 0.6, size.height * 0.3, gridSize * 1.5, gridSize),
      Rect.fromLTWH(size.width * 0.3, size.height * 0.6, gridSize, gridSize * 1.5),
    ];
    
    for (var location in locations) {
      final locationPaint = Paint()
        ..color = baseColor.withOpacity(0.2)
        ..style = PaintingStyle.fill;
      
      canvas.drawRect(location, locationPaint);
      
      final borderPaint = Paint()
        ..color = baseColor.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      
      canvas.drawRect(location, borderPaint);
    }
  }
  
  void _drawAnimatedDotsAlongPath(Canvas canvas, Path path, Color color) {
    try {
      final pathMetrics = path.computeMetrics().first;
      final pathLength = pathMetrics.length;
      
      // Draw 3 dots along the path
      for (int i = 0; i < 3; i++) {
        final dotProgress = (progress + (i / 3)) % 1.0;
        final dotPosition = pathMetrics.getTangentForOffset(pathLength * dotProgress);
        
        if (dotPosition != null) {
          final dotPaint = Paint()
            ..color = color
            ..style = PaintingStyle.fill;
          
          canvas.drawCircle(
            dotPosition.position, 
            4.0, 
            dotPaint
          );
          
          // Draw glow
          final glowPaint = Paint()
            ..color = color.withOpacity(0.3)
            ..style = PaintingStyle.fill;
          
          canvas.drawCircle(
            dotPosition.position, 
            8.0, 
            glowPaint
          );
        }
      }
    } catch (e) {
      // Handle empty path metrics
    }
  }
  
  void _drawLocationMarker(Canvas canvas, Offset position, Color color) {
    // Pulsing effect based on progress
    final scale = 1.0 + math.sin(progress * math.pi * 2) * 0.3;
    
    // Draw marker
    final markerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      position, 
      4.0 * scale, 
      markerPaint
    );
    
    // Draw ripple effect
    final ripplePaint = Paint()
      ..color = color.withOpacity(0.2 - (0.2 * scale))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    canvas.drawCircle(
      position, 
      10.0 * scale, 
      ripplePaint
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}