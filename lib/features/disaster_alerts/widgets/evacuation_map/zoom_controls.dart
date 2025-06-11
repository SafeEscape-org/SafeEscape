import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/colors.dart';

class ZoomControls extends StatelessWidget {
  final Function() onZoomIn;
  final Function() onZoomOut;

  const ZoomControls({
    Key? key,
    required this.onZoomIn,
    required this.onZoomOut,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Zoom in
          IconButton(
            icon: const Icon(Icons.add),
            color: EvacuationColors.primaryColor,
            onPressed: () {
              HapticFeedback.selectionClick();
              onZoomIn();
            },
          ),
          
          // Zoom out
          IconButton(
            icon: const Icon(Icons.remove),
            color: EvacuationColors.primaryColor,
            onPressed: () {
              HapticFeedback.selectionClick();
              onZoomOut();
            },
          ),
        ],
      ),
    );
  }
}