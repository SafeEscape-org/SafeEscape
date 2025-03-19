import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/material.dart';
import 'package:disaster_management/widgets/alert_notification.dart';
import 'dart:ui';

class SocketService extends ChangeNotifier {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  
  late IO.Socket socket;
  bool isConnected = false;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  SocketService._internal() {
    _initializeSocket();
  }

  void _initializeSocket() {
    debugPrint('📡 Attempting to connect to socket server...');
    
    socket = IO.io('http://:5000', {
      'transports': ['websocket', 'polling'],
      'autoConnect': true,
      'reconnection': true,
      'reconnectionDelay': 1000,
      'reconnectionAttempts': 5,
      'timeout': 20000,
      'forceNew': true,
    });

    _setupSocketListeners();
  }

  Map<String, dynamic> _parseSocketData(dynamic data, String defaultTitle) {
    try {
      if (data == null) {
        return {
          'title': defaultTitle,
          'message': 'No data received',
          'severity': 'info'
        };
      }

      if (data is String) {
        return {
          'title': defaultTitle,
          'message': data,
          'severity': 'info'
        };
      }

      if (data is Map) {
        var parsedData = Map<String, dynamic>.from(data);
        return {
          'title': parsedData['title']?.toString() ?? defaultTitle,
          'message': parsedData['message']?.toString() ?? 
                    parsedData['test']?.toString() ?? 
                    parsedData.toString(),
          'severity': parsedData['severity']?.toString() ?? 'info'
        };
      }

      return {
        'title': defaultTitle,
        'message': data.toString(),
        'severity': 'info'
      };
    } catch (e) {
      debugPrint('Error parsing socket data: $e');
      return {
        'title': defaultTitle,
        'message': 'Error processing message',
        'severity': 'error'
      };
    }
  }

  void _setupSocketListeners() {
    socket.onConnect((_) {
      debugPrint('🟢 Connected to socket server with ID: ${socket.id}');
      isConnected = true;
      notifyListeners();
    });

    void handleSocketEvent(String eventType, dynamic data) {
      debugPrint('📨 Received $eventType: $data');
      try {
        final parsedData = _parseSocketData(data, eventType);
        _showNotification(
          parsedData['title'] as String,
          parsedData['message'] as String,
          parsedData['severity'] as String,
        );
      } catch (e) {
        debugPrint('Error in handleSocketEvent: $e');
      }
    }

    socket.on('emergency-alert', (data) => handleSocketEvent('Emergency Alert', data));
    socket.on('evacuation-notice', (data) => handleSocketEvent('Evacuation Notice', data));
    socket.on('disaster-warning', (data) => handleSocketEvent('Disaster Warning', data));

    socket.onConnectError((data) {
      debugPrint('❌ Connection error: $data');
      isConnected = false;
      notifyListeners();
    });

    socket.onDisconnect((_) {
      debugPrint('🔴 Disconnected from server');
      isConnected = false;
      notifyListeners();
    });
  }

  void _showNotification(String title, String message, String alertType) {
      try {
        final context = navigatorKey.currentContext;
        if (context == null) return;
  
        final overlayState = Navigator.of(context, rootNavigator: true).overlay;
        if (overlayState == null) return;
  
        late final OverlayEntry overlayEntry;
        
        overlayEntry = OverlayEntry(
          builder: (context) => SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  offset: const Offset(0, 0),
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 500),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: AlertNotification(
                            title: title,
                            message: message,
                            alertType: alertType,
                            onTap: () {
                              if (overlayEntry.mounted) overlayEntry.remove();
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
  
        overlayState.insert(overlayEntry);
  
        // Animate out and remove after 5 seconds
        Future.delayed(const Duration(seconds: 5), () {
          if (overlayEntry.mounted) overlayEntry.remove();
        });
      } catch (e) {
        debugPrint('Error showing notification: $e');
      }
    }

  void disconnect() {
    try {
      socket.disconnect();
    } catch (e) {
      debugPrint('Error disconnecting socket: $e');
    }
  }

  void reconnect() {
    try {
      socket.connect();
    } catch (e) {
      debugPrint('Error reconnecting socket: $e');
    }
  }
}