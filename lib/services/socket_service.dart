import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/material.dart';

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:disaster_management/core/constants/api_constants.dart';

class SocketService extends ChangeNotifier {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  
  late IO.Socket socket;
  bool isConnected = false;
  bool _isInitialized = false;
  bool _isAttemptingReconnect = false;
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 5;
  Timer? _reconnectTimer;
  bool _isRegistered = false;
  
  // Add a flag to control notifications
  bool _shouldNotifyListeners = true;
  
  // Use the notification service


  SocketService._internal() {
    _initializeSocket();
  }

  void _initializeSocket() {
    if (_isInitialized) return;
    
    debugPrint('📡 Attempting to connect to socket server...');
    
    // Log the actual URL being used
    debugPrint('📡 Socket server URL: ${ApiConstants.socketServerUrl}');
    
    socket = IO.io(ApiConstants.socketServerUrl, {
      'transports': ['websocket', 'polling'],
      'autoConnect': false, // Changed to false to control connection manually
      'reconnection': false, // We'll handle reconnection ourselves
      'timeout': ApiConstants.socketTimeoutMs,
      'forceNew': true,
      'query': {'clientType': 'mobile'}, // Add client type for server identification
    });

    _setupSocketListeners();
    _isInitialized = true;
    
    // Connect after a short delay to avoid immediate connection attempts during app startup
    Future.delayed(const Duration(milliseconds: 500), () {
      // Use a microtask to avoid blocking the UI thread
      Future.microtask(() => connectSocket());
    });
  }

  // Add this method to safely notify listeners without blocking UI
  void _safeNotifyListeners() {
    if (!_shouldNotifyListeners) return;
    
    // Use a microtask to avoid blocking the UI thread
    Future.microtask(() {
      try {
        notifyListeners(); // Uncomment this line - it's currently commented out
      } catch (e) {
        debugPrint('Error in notifyListeners: $e');
      }
    });
  }

  // Replace the _showNotification method with this optimized version
  void _showNotification(String title, String message, String alertType) {
    // Run notification in background to avoid UI blocking
    Future.microtask(() {
      try {
        // Uncomment this to actually show notifications
        
      } catch (e) {
        debugPrint('Error showing notification: $e');
      }
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
    // Remove any existing listeners to prevent duplicates
    socket.off('connect');
    socket.off('registered');
    socket.off('error');
    socket.off('message');
    socket.off('emergency-alert');
    socket.off('evacuation-notice');
    socket.off('disaster-warning');
    socket.off('connect_error');
    socket.off('disconnect');
    socket.off('active-disasters'); // Add this line
    
    socket.onConnect((_) {
      debugPrint('🟢 Connected to socket server with ID: ${socket.id}');
      isConnected = true;
      _reconnectAttempts = 0;
      _isAttemptingReconnect = false;
      _cancelReconnectTimer();
      
      // Use safe notify instead of direct call
      _safeNotifyListeners();
      
      // Register user with socket server after connection
      if (!_isRegistered) {
        // Run in background to avoid UI blocking
        Future.microtask(() => _registerUserWithSocket());
      }
    });

    // Add listener for registration acknowledgement
    socket.on('registered', (data) {
      try {
        final success = data['success'] as bool;
        final message = data['message'] as String;
        
        debugPrint('📝 Registration response: $success - $message');
        
        // Only update registration status if not already registered
        if (!_isRegistered && success) {
          _isRegistered = true;
          
          // Show notification for registration status
          // _showNotification(
          //   'Connection Status',
          //   message,
          //   success ? 'success' : 'error',
          // );
          
          // Use safe notify
          _safeNotifyListeners();
        }
      } catch (e) {
        debugPrint('Error handling registration response: $e');
        debugPrint('Raw registration response data: $data');
      }
    });

    // Add a listener for any errors from the server
    socket.on('error', (data) {
      debugPrint('⚠️ Socket server error: $data');
    });
    
    // Add a listener for general server messages
    socket.on('message', (data) {
      debugPrint('📩 Server message: $data');
    });

    void handleSocketEvent(String eventType, dynamic data) {
      debugPrint('📨 Received $eventType: $data');
      try {
        final parsedData = _parseSocketData(data, eventType);
        // _showNotification(
        //   parsedData['title'] as String,
        //   parsedData['message'] as String,
        //   parsedData['severity'] as String,
        // );
      } catch (e) {
        debugPrint('Error in handleSocketEvent: $e');
      }
    }

    socket.on('emergency-alert', (data) => handleSocketEvent('Emergency Alert', data));
    socket.on('evacuation-notice', (data) => handleSocketEvent('Evacuation Notice', data));
    socket.on('disaster-warning', (data) => handleSocketEvent('Disaster Warning', data));
    
    // Add handler for active disasters response
    socket.on('active-disasters', (data) {
      debugPrint('📨 Received active disasters: $data');
      try {
        if (data is List) {
          // Handle list of disasters
          for (var disaster in data) {
            final parsedData = _parseSocketData(disaster, 'Active Disaster');
            // _showNotification(
            //   parsedData['title'] as String,
            //   parsedData['message'] as String,
            //   parsedData['severity'] as String,
            // );
          }
        } else {
          // Handle single disaster or other format
          final parsedData = _parseSocketData(data, 'Active Disasters');
          // _showNotification(
          //   parsedData['title'] as String,
          //   parsedData['message'] as String,
          //   parsedData['severity'] as String,
          // );
        }
      } catch (e) {
        debugPrint('Error handling active disasters: $e');
      }
    });

    socket.onConnectError((data) {
      debugPrint('❌ Connection error: $data');
      if (!_isAttemptingReconnect) {
        isConnected = false;
        // Use safe notify
        _safeNotifyListeners();
        _scheduleReconnect();
      }
    });

    socket.onDisconnect((_) {
      debugPrint('🔴 Disconnected from server');
      if (!_isAttemptingReconnect) {
        isConnected = false;
        _isRegistered = false;
        // Use safe notify
        _safeNotifyListeners();
        _scheduleReconnect();
      }
    });
  }

  // New method to register user with socket server
  Future<void> _registerUserWithSocket() async {
    // Run in a separate isolate or at least a microtask
    return Future.microtask(() async {
      // Temporarily disable notifications during registration
      _shouldNotifyListeners = false;
      
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          debugPrint('❌ Cannot register with socket: No authenticated user');
          _shouldNotifyListeners = true;
          return;
        }
        
        // Check if socket is actually connected
        if (!socket.connected) {
          debugPrint('❌ Cannot register user: Socket not connected');
          _shouldNotifyListeners = true;
          connectSocket();
          return;
        }
        
        // Check if already registered to prevent duplicate registrations
        if (_isRegistered) {
          debugPrint('✅ User already registered with socket server');
          _shouldNotifyListeners = true;
          return;
        }
        
        // Prepare basic registration data first
        final basicData = {
          'userId': user.uid,
          'email': user.email,
          'name': user.displayName ?? 'Unknown User',
        };
        
        // Register with basic info immediately
        socket.emit('register', basicData);
        
        // Then try to get more detailed info in the background
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          
          if (userDoc.exists) {
            final userData = userDoc.data()!;
            
            // Extract location data if available
            if (userData.containsKey('location') && userData['location'] is Map) {
              final locationMap = Map<String, dynamic>.from(userData['location'] as Map);
              
              if (locationMap.containsKey('address') && 
                  locationMap.containsKey('latitude') && 
                  locationMap.containsKey('longitude')) {
                
                // Prepare detailed registration data
                final detailedData = {
                  'userId': user.uid,
                  'email': user.email,
                  'name': userData['name'] ?? user.displayName ?? 'Unknown User',
                  'location': {
                    'coordinates': [locationMap['longitude'], locationMap['latitude']],
                    'address': locationMap['address'],
                  },
                  'timestamp': DateTime.now().millisecondsSinceEpoch,
                };
                
                // Register with detailed info
                socket.emit('register', detailedData);
              }
            }
          }
        } catch (e) {
          debugPrint('Error getting detailed user data: $e');
          // We already registered with basic info, so this is not critical
        }
        
      } catch (e) {
        debugPrint('❌ Error registering user with socket: $e');
        _registerWithBasicInfo(FirebaseAuth.instance.currentUser, null);
      } finally {
        _shouldNotifyListeners = true;
      }
    });
  }
  
  // Helper method for basic registration
  void _registerWithBasicInfo(User? user, Map<String, dynamic>? userData) {
    if (user == null) return;
    
    final basicData = {
      'userId': user.uid,
      'email': user.email,
      'name': userData?['name'] ?? user.displayName ?? 'Unknown User',
    };
    
    debugPrint('📤 Registering with basic info: $basicData');
    socket.emit('register', basicData);  // Changed from 'register_user' to 'register'
  }

  // Public method to manually trigger registration
  void registerUser() {
    if (isConnected) {
      _registerUserWithSocket();
    } else {
      connectSocket();
    }
  }

  void _scheduleReconnect() {
    if (_isAttemptingReconnect || _reconnectAttempts >= _maxReconnectAttempts) return;
    
    _isAttemptingReconnect = true;
    _reconnectAttempts++;
    
    // Use exponential backoff with a maximum delay cap
    final delay = Duration(milliseconds: 1000 * (1 << _reconnectAttempts.clamp(0, 6)));
    debugPrint('📡 Scheduling reconnect attempt $_reconnectAttempts in ${delay.inSeconds}s');
    
    _cancelReconnectTimer();
    _reconnectTimer = Timer(delay, () {
      if (!isConnected) {
        debugPrint('📡 Attempting to reconnect...');
        _isAttemptingReconnect = false;
        
        // Use a separate isolate or at least a microtask to avoid UI blocking
        Future.microtask(() {
          try {
            connectSocket();
          } catch (e) {
            debugPrint('Error during reconnect: $e');
            // Reset the attempting flag if there was an error
            _isAttemptingReconnect = false;
          }
        });
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
        // Check if we're already trying to connect
        if (_isAttemptingReconnect) {
          debugPrint('Already attempting to reconnect, skipping duplicate connection attempt');
          return;
        }
        
        debugPrint('📡 Connecting to socket server...');
        socket.connect();
      } else {
        debugPrint('Socket already connected, skipping connection attempt');
      }
    } catch (e) {
      debugPrint('Error connecting socket: $e');
      _scheduleReconnect();
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
  
  // Public method to request active disasters
  void requestActiveDisasters() {
    debugPrint('🚨 REQUESTING ACTIVE DISASTERS - START 🚨');
    
    if (!isConnected) {
      debugPrint('❌ Cannot request active disasters: Socket not connected (status: ${socket.connected})');
      debugPrint('🔄 Attempting to connect socket first...');
      connectSocket();
      
      // Try again after connection
      Future.delayed(const Duration(seconds: 3), () {
        if (isConnected) {
          debugPrint('✅ Socket now connected, retrying request for active disasters');
          requestActiveDisasters();
        }
      });
      return;
    }
    
    if (!_isRegistered) {
      debugPrint('❌ Cannot request active disasters: User not registered');
      debugPrint('🔄 Attempting to register user first...');
      _registerUserWithSocket();
      
      // Schedule a retry after registration
      Future.delayed(const Duration(seconds: 3), () {
        if (_isRegistered) {
          debugPrint('✅ User now registered, retrying request for active disasters');
          requestActiveDisasters();
        } else {
          debugPrint('⚠️ User still not registered after 3 seconds, cannot request disasters');
        }
      });
      return;
    }
    
    try {
      // Use a simpler event name that matches your backend
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
      debugPrint('📤 EMITTING request-active-disasters EVENT (socket ID: ${socket.id}, user: $userId)');
      
      // Try both with and without data
      socket.emit('request-active-disasters');
      
      // Also try with a simple payload in case the server expects it
      Future.delayed(const Duration(milliseconds: 500), () {
        debugPrint('📤 Trying alternative request format...');
        socket.emit('request-active-disasters', {'userId': userId});
      });
      
      // Add a check to see if we get a response
      Future.delayed(const Duration(seconds: 5), () {
        debugPrint('⏱️ Active disasters request check after 5s: isConnected=${isConnected}, isRegistered=${_isRegistered}');
        debugPrint('⚠️ If you do not see active disasters data, check your server implementation');
      });
    } catch (e) {
      debugPrint('❌ Error requesting active disasters: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
    }
  }
  
  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}