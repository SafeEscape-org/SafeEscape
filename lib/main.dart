import 'dart:async';
import 'dart:io';
import 'package:flutter/scheduler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart'; // Add this import

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:disaster_management/config/fcm_config.dart';
import 'package:disaster_management/config/firebase_config.dart';
import 'package:disaster_management/core/constants/app_colors.dart';
import 'package:disaster_management/features/disaster_alerts/pages/assistance_help_screen.dart';
import 'package:disaster_management/features/disaster_alerts/pages/home_screen.dart';
import 'package:disaster_management/features/disaster_alerts/pages/evacuation_screen.dart';
import 'package:disaster_management/features/disaster_alerts/widgets/footerComponent.dart';
import 'package:disaster_management/features/authentication/pages/registration_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:disaster_management/features/authentication/services/auth_service.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'package:disaster_management/services/socket_service.dart';
import 'package:disaster_management/services/notification_service.dart';

// Add this function to run heavy tasks in the background
Future<T> runHeavyTask<T>(Future<T> Function() task) {
  return compute<Future<T> Function(), T>(
    (callback) => callback(),
    task,
  );
}

void main() async {
  // Initialize Flutter binding first
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  
  // Preserve splash screen while initializing
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  
  // Optimize rendering performance
  // Disable frame reporting to reduce "updateAcquireFence" errors
  debugPrintBeginFrameBanner = false;
  debugPrintEndFrameBanner = false;
  
  // Initialize Firebase first before creating socket service
  try {
    await FirebaseConfig.initializeFirebase();
    debugPrint('✅ Firebase initialized successfully');
  } catch (e) {
    debugPrint('⚠️ Firebase initialization error: $e');
  }
  
  // Create service instance once to avoid multiple instances
  final socketService = SocketService();
  
  // Start the app immediately
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
          value: socketService,
        ),
      ],
      child: const MyApp(),
    ),
  );
  
  // Run remaining initialization tasks in parallel after app has started
  Future.microtask(() async {
    try {
      // Initialize FCM after Firebase is ready
      await FCMConfig.initializeFCM();
      debugPrint('✅ FCM initialized successfully');
    } catch (e) {
      debugPrint('⚠️ FCM initialization error: $e');
    } finally {
      // Remove splash screen after initialization completes
      // Add a longer delay to ensure UI is fully ready
      await Future.delayed(const Duration(milliseconds: 800));
      FlutterNativeSplash.remove();
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Use the notification service's navigator key
      navigatorKey: NotificationService().navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: AppColors.primaryColor,
        scaffoldBackgroundColor: Colors.white,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      initialRoute: '/auth',
      routes: {
        '/auth': (context) => Consumer<SocketService>(
          builder: (context, socketService, child) {
            return StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasData) {
                  return const MainScreen();
                }

                return const RegistrationPage();
              },
            );
          },
        ),
        '/home': (context) => const MainScreen(),
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  final AuthService _authService = AuthService();
  Timer? _locationUpdateTimer;
  bool _isInitialized = false;
  bool _isInForeground = true;
  
  // Track if screens are initialized to prevent duplicate initialization
  final Map<int, bool> _initializedScreens = {0: false, 1: false, 2: false};
  
  // Keep references to screen controllers to properly manage their lifecycle
  final List<GlobalKey> _screenKeys = [
    GlobalKey(), GlobalKey(), GlobalKey()
  ];

  @override
  void initState() {
    super.initState();
    
    // Register for app lifecycle events
    WidgetsBinding.instance.addObserver(this);
    
    // Defer heavy initialization to after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _deferredInitialization();
    });
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Track app state to reduce background processing
    _isInForeground = state == AppLifecycleState.resumed;
    
    if (_isInForeground) {
      // App came to foreground, schedule a frame
      SchedulerBinding.instance.scheduleFrame();
      
      // Reconnect socket if needed
      _checkAndReconnectSocket();
    }
  }
  
  void _checkAndReconnectSocket() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    final socketService = Provider.of<SocketService>(context, listen: false);
    if (!socketService.isConnected) {
      _runInBackground(() async {
        socketService.connectSocket();
        return;
      });
    }
  }
  
  Future<void> _deferredInitialization() async {
    if (_isInitialized) return;
    
    // Don't set state until all initialization is complete
    // Run initialization in microtask to avoid blocking main thread
    await Future.microtask(() async {
      try {
        // Perform all initialization before updating state
        await _setupUserUpdates();
        
        // Don't initialize socket here since it's handled in home screen
        // This prevents duplicate initialization and UI flickers
        // _initializeSocket();
        
        // Only update state once at the end of all initialization
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      } catch (e) {
        debugPrint('⚠️ Deferred initialization error: $e');
        // Still mark as initialized even if there's an error
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      }
    });
  }

  void _initializeSocket() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('⚠️ Cannot initialize socket: No authenticated user');
      return;
    }
    
    // Store reference to avoid context issues during async operations
    final socketService = Provider.of<SocketService>(context, listen: false);
    
    // Run socket initialization in a separate isolate or compute
    Future.microtask(() {
      try {
        if (!socketService.isConnected) {
          // Add listener for connection event before connecting
          socketService.socket.on('connect', (_) {
            debugPrint('🟢 Socket connected, registering user: ${user.uid}');
            socketService.registerUser();
          });
          
          // Add error handling for socket connection
          socketService.socket.on('connect_error', (error) {
            debugPrint('⚠️ Socket connection error: $error');
          });
          
          // Add reconnection logic
          socketService.socket.on('reconnect', (_) {
            debugPrint('🔄 Socket reconnected');
            socketService.registerUser();
          });
          
          socketService.connectSocket();
        } else {
          // If already connected, just register
          socketService.registerUser();
        }
      } catch (e) {
        debugPrint('❌ Socket initialization error: $e');
      }
    });
  }

  // Add this helper method for background processing
  Future<void> _runInBackground(Future<void> Function() task) async {
    if (!mounted) return;
    
    try {
      // For simple tasks, microtask is sufficient
      await Future.microtask(() async {
        if (mounted) {
          await task();
        }
      });
    } catch (e) {
      debugPrint('Background task error: $e');
    }
  }
  
  // For CPU-intensive tasks, use compute with better error handling
  Future<T?> _computeIntensive<T>(Future<T> Function() computation) async {
    try {
      return await compute<Future<T> Function(), T>(
        (func) => func(),
        computation,
      );
    } catch (e) {
      debugPrint('Compute error: $e');
      return null;
    }
  }

  Future<void> _setupUserUpdates() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Run location update in background with lower priority
      Future.delayed(const Duration(seconds: 2), () {
        _runInBackground(() async {
          try {
            // Initial location update
            await _authService.updateUserLocation(user.uid, context);
          } catch (e) {
            debugPrint('❌ Location update error: $e');
          }
        });
      });

      // Check and update FCM token if needed - with delay to reduce startup load
      Future.delayed(const Duration(seconds: 5), () {
        _runInBackground(() async {
          try {
            bool tokenUpdated = await _authService.checkAndUpdateFCMToken(user.uid);
            
            // Show alert if token was updated
            if (tokenUpdated && mounted && _isInForeground) {
              // Use a microtask to update UI safely
              Future.microtask(() {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notification settings updated'),
                      duration: Duration(seconds: 3),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              });
            }
          } catch (e) {
            debugPrint('❌ FCM token update error: $e');
          }
        });
      });
    
      // Update location less frequently and only when app is in foreground
      _locationUpdateTimer = Timer.periodic(
        const Duration(minutes: 45),
        (_) {
          // Skip updates when app is in background
          if (!_isInForeground) return;
          
          _runInBackground(() async {
            await _authService.updateUserLocation(user.uid, context);
          });
        },
      );
    }
  }

  @override
  void dispose() {
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    
    _locationUpdateTimer?.cancel();
    // Only disconnect if connected
    final socketService = Provider.of<SocketService>(context, listen: false);
    if (socketService.isConnected) {
      socketService.socket.disconnect();
    }
    super.dispose();
  }

  int currentIndex = 0;
  void onTabSelected(int index) {
    if (currentIndex == index) return;
    
    // Use microtask to ensure state update happens after the current frame
    Future.microtask(() {
      if (mounted) {
        setState(() {
          currentIndex = index;
          
          // Initialize the screen if it hasn't been initialized yet
          if (!_initializedScreens[index]!) {
            _initializedScreens[index] = true;
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use a more efficient approach to prevent unnecessary rebuilds
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildCurrentScreen(),
      ),
      // Wrap the bottom navigation bar in RepaintBoundary
      bottomNavigationBar: RepaintBoundary(
        child: FooterComponent(
          currentIndex: currentIndex,
          onTabSelected: onTabSelected,
        ),
      ),
    );
  }
  
  // Extract screen building to a separate method
  Widget _buildCurrentScreen() {
    // Use keys to help Flutter identify which widgets have changed
    return KeyedSubtree(
      key: ValueKey('main_screen_$currentIndex'),
      child: RepaintBoundary(
        child: IndexedStack(
          index: 0, // Always show the current screen only
          children: [
            if (currentIndex == 0)
              KeepAliveWrapper(
                key: _screenKeys[0],
                child: CombinedHomeWeatherComponent(),
              )
            else if (currentIndex == 1)
              KeepAliveWrapper(
                key: _screenKeys[1],
                child: EmergencyScreen(),
              )
            else
              KeepAliveWrapper(
                key: _screenKeys[2],
                child: EvacuationScreen(),
              ),
          ],
        ),
      ),
    );
  }
}

// Add this wrapper to prevent rebuilds and maintain state
class KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  
  const KeepAliveWrapper({Key? key, required this.child}) : super(key: key);
  
  @override
  _KeepAliveWrapperState createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper> 
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  
  @override
  Widget build(BuildContext context) {
    // Must call super.build for AutomaticKeepAliveClientMixin to work
    super.build(context);
    return widget.child;
  }
}
