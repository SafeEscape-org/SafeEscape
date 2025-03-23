class ApiConstants {
  // Google Maps API
  static const String googleApiKey = 'AIzaSyCKiAUtSDYgRhtelG0tVsAXSvcAMJoA78I';
  static const String nearbyPlacesBaseUrl =
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json';
  static const int searchRadius = 5000; // in meters
  
  // Firebase Android Options
  static const String firebaseAndroidApiKey = 'AIzaSyBbTbSGzz7z2WmLqWP7zLePR0TO_wW_PAs';
  static const String firebaseAndroidAppId = '1:841617839404:android:eb8cf767ac259f7d3c4889';
  static const String firebaseMessagingSenderId = '841617839404';
  static const String firebaseProjectId = 'disaster-management-de632';
  static const String firebaseStorageBucket = 'disaster-management-de632.firebasestorage.app';
  
  // Firebase iOS Options
  static const String firebaseIOSApiKey = 'AIzaSyBFcxhs2s06uIYioy-KKYypK5pRDqKiQts';
  static const String firebaseIOSAppId = '1:841617839404:ios:ecd856ac48e978983c4889';
  static const String firebaseIOSBundleId = 'com.example.disasterManagement';
  
  // Socket Server Configuration
  static const String socketServerIP = '192.168.0.121';
  static const int socketServerPort = 5000;
  static const int socketTimeoutMs = 20000;
  
  // Get the full socket server URL
  static String get socketServerUrl => 'http://$socketServerIP:$socketServerPort';
  
  // Weather API - Update to match the correct endpoint
  static String get weatherApiBaseUrl => 'http://$socketServerIP:$socketServerPort/api/alerts/weather';
  
  // Disaster Alerts API
  static String get disasterAlertsApiUrl => 'http://$socketServerIP:$socketServerPort/api/disasters/active';
  
  // Gemini Chat API
  static String get geminiChatApiUrl => 'http://$socketServerIP:$socketServerPort';
  
  // Get chat history endpoint
  static String getChatHistoryUrl(String sessionId) => '$geminiChatApiUrl/api/gemini/chat/$sessionId/history';
  
  // Get message endpoint
  static String getChatMessageUrl(String sessionId) => '$geminiChatApiUrl/api/gemini/chat/$sessionId/message';
}