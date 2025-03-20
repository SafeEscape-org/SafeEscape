import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/material.dart';
import 'package:disaster_management/widgets/alert_notification.dart';
import 'dart:ui';
import 'dart:async';

class SocketService extends ChangeNotifier {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  
  late IO.Socket socket;
  bool isConnected = false;
  bool _isInitialized = false;
  bool _isAttemptingReconnect = false;
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 5;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  Timer? _reconnectTimer;

  SocketService._internal() {
    _initializeSocket();
  }

  void _initializeSocket() {
    if (_isInitialized) return;
    
    debugPrint('📡 Attempting to connect to socket server...');
    
    socket = IO.io('http://:5000', {
      'transports': ['websocket', 'polling'],
      'autoConnect': false, // Changed to false to control connection manually
      'reconnection': false, // We'll handle reconnection ourselves
      'timeout': 20000,
      'forceNew': true,
    });

    _setupSocketListeners();
    _isInitialized = true;
    
    // Connect after a short delay to avoid immediate connection attempts during app startup
    Future.delayed(const Duration(milliseconds: 500), () {
      connectSocket();
    });
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
      _reconnectAttempts = 0;
      _isAttemptingReconnect = false;
      _cancelReconnectTimer();
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
      if (!_isAttemptingReconnect) {
        isConnected = false;
        notifyListeners();
        _scheduleReconnect();
      }
    });

    socket.onDisconnect((_) {
      debugPrint('🔴 Disconnected from server');
      if (!_isAttemptingReconnect) {
        isConnected = false;
        notifyListeners();
        _scheduleReconnect();
      }
    });
  }

  void _scheduleReconnect() {
    if (_isAttemptingReconnect || _reconnectAttempts >= _maxReconnectAttempts) return;
    
    _isAttemptingReconnect = true;
    _reconnectAttempts++;
    
    // Use exponential backoff for reconnection attempts
    final delay = Duration(milliseconds: 1000 * (1 << _reconnectAttempts.clamp(0, 6)));
    debugPrint('📡 Scheduling reconnect attempt $_reconnectAttempts in ${delay.inSeconds}s');
    
    _cancelReconnectTimer();
    _reconnectTimer = Timer(delay, () {
      if (!isConnected) {
        debugPrint('📡 Attempting to reconnect...');
        _isAttemptingReconnect = false;
        connectSocket();
      }
    });
  }

  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  void connectSocket() {
    if (!_isInitialized) {
      _initializeSocket();
      return;
    }
    
    try {
      if (!socket.connected) {
        socket.connect();
      }
    } catch (e) {
      debugPrint('Error connecting socket: $e');
      _scheduleReconnect();
    }
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
      _cancelReconnectTimer();
      _isAttemptingReconnect = false;
      socket.disconnect();
    } catch (e) {
      debugPrint('Error disconnecting socket: $e');
    }
  }

  void reconnect() {
    _reconnectAttempts = 0;
    _isAttemptingReconnect = false;
    connectSocket();
  }
  
  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}