import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:collection';
import 'dart:async';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final Queue<_NotificationItem> _notificationQueue = Queue();
  final List<OverlayEntry> _activeNotifications = [];
  final int _maxVisibleNotifications = 3;
  bool _isProcessingQueue = false;
  
  // Add a flag to track if the home screen is active
  bool _isHomeScreenActive = false;
  
  NotificationService._internal();
  
  // Method to set the active screen status
  void setActiveScreen(bool isActive) {
    _isHomeScreenActive = isActive;
    
    // If screen becomes inactive, remove all active notifications
    if (!isActive) {
      _removeAllNotifications();
    } else if (_notificationQueue.isNotEmpty) {
      // If screen becomes active and there are pending notifications, process them
      _processNotificationQueue();
    }
  }
  
  // Method to remove all active notifications
  void _removeAllNotifications() {
    for (var entry in List.from(_activeNotifications)) {
      if (entry.mounted) {
        entry.remove();
      }
    }
    _activeNotifications.clear();
  }
  
  void showNotification(String title, String message, String alertType) {
    _notificationQueue.add(_NotificationItem(
      title: title,
      message: message,
      alertType: alertType,
    ));
    
    // Only process queue if home screen is active
    if (_isHomeScreenActive && !_isProcessingQueue) {
      Future.microtask(() => _processNotificationQueue());
    }
  }
  
  void _processNotificationQueue() async {
    if (_isProcessingQueue) return;
    _isProcessingQueue = true;
    
    while (_notificationQueue.isNotEmpty && _isHomeScreenActive) {
      final item = _notificationQueue.removeFirst();
      await _displayNotification(item.title, item.message, item.alertType);
      await Future.delayed(const Duration(milliseconds: 300));
    }
    
    _isProcessingQueue = false;
  }
  
  Future<void> _displayNotification(String title, String message, String alertType) async {
    final context = navigatorKey.currentContext;
    if (context == null) return Future.value();

    final overlayState = Navigator.of(context, rootNavigator: true).overlay;
    if (overlayState == null) return Future.value();

    // Calculate position based on existing notifications
    final topPadding = MediaQuery.of(context).padding.top + 10;
    final index = _activeNotifications.length;
    final topOffset = topPadding + (index * 20);
    
    OverlayEntry? entry;
    
    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: topOffset,
        left: 16.0,
        right: 16.0,
        child: _buildNotification(context, title, message, alertType, entry),
      ),
    );

    // Add to list and insert into overlay
    _activeNotifications.add(entry);
    overlayState.insert(entry);

    // Remove oldest notification if we exceed the maximum
    if (_activeNotifications.length > _maxVisibleNotifications) {
      _removeOldestNotification();
    }

    // Auto-dismiss after delay
    return Future.delayed(const Duration(seconds: 4), () {
      _removeNotification(entry!);
    });
  }

  Widget _buildNotification(BuildContext context, String title, String message, 
      String alertType, OverlayEntry? entry) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, -50 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity != null && 
              (details.primaryVelocity! > 200 || details.primaryVelocity! < -200)) {
            _removeNotification(entry!);
          }
        },
        onTap: () => _removeNotification(entry!),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: _getAccentColor(alertType).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getAccentColor(alertType).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: _getAlertIcon(alertType),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      if (message.isNotEmpty) const SizedBox(height: 4),
                      if (message.isNotEmpty)
                        Text(
                          message,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16, color: Colors.white70),
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  onPressed: () => _removeNotification(entry!),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to get appropriate icon for alert type
  Widget _getAlertIcon(String alertType) {
    IconData iconData;
    
    switch (alertType.toLowerCase()) {
      case 'warning':
        iconData = Icons.warning_amber_rounded;
        break;
      case 'error':
      case 'danger':
        iconData = Icons.error_outline_rounded;
        break;
      case 'success':
        iconData = Icons.check_circle_outline_rounded;
        break;
      case 'info':
      default:
        iconData = Icons.info_outline_rounded;
        break;
    }
    
    return Icon(
      iconData,
      color: _getAccentColor(alertType),
      size: 20,
    );
  }
  
  // Get accent color based on alert type
  Color _getAccentColor(String alertType) {
    switch (alertType.toLowerCase()) {
      case 'warning':
        return Colors.amber;
      case 'error':
      case 'danger':
        return Colors.redAccent;
      case 'success':
        return Colors.greenAccent;
      case 'info':
      default:
        return Colors.cyanAccent;
    }
  }
  
  void _removeNotification(OverlayEntry entry) {
    // Schedule removal in a microtask to avoid UI thread blocking
    Future.microtask(() {
      if (!entry.mounted) return;
      
      try {
        entry.remove();
        _activeNotifications.remove(entry);
        _repositionNotifications();
      } catch (e) {
        debugPrint('Error removing notification: $e');
      }
    });
  }

  void _repositionNotifications() {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    
    final topPadding = MediaQuery.of(context).padding.top + 10;
    
    for (int i = 0; i < _activeNotifications.length; i++) {
      final entry = _activeNotifications[i];
      if (entry.mounted) {
        entry.markNeedsBuild();
      }
    }
  }

  void _removeOldestNotification() {
    if (_activeNotifications.isEmpty) return;
    
    final oldest = _activeNotifications.first;
    _removeNotification(oldest);
  }
}

class _NotificationItem {
  final String title;
  final String message;
  final String alertType;
  
  _NotificationItem({
    required this.title,
    required this.message,
    required this.alertType,
  });
}