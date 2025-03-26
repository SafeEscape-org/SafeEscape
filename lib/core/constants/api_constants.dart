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
  // If running on emulator, use 10.0.2.2 to connect to host machine
  // If running on physical device, use the actual server IP
  static const String socketServerIP = '172.16.18.240'; // Your server IP
  static const int socketServerPort = 5000;
  static const int socketTimeoutMs = 20000;
  
  // Get the full socket server URL
  static String get socketServerUrl => 'http://$socketServerIP:$socketServerPort';
  
  // Base URL for all API calls
  static String get baseUrl => socketServerUrl;
  
  // Weather API - Update to match the correct endpoint
  static String get weatherApiBaseUrl => '$baseUrl/api/alerts/weather';
  
  // Disaster Alerts API
  static String get disasterAlertsApiUrl => '$baseUrl/api/disasters/active';
  
  // Gemini Chat API
  static String get geminiChatApiUrl => baseUrl;
  
  // Get chat history endpoint
  static String getChatHistoryUrl(String sessionId) => '$geminiChatApiUrl/api/gemini/chat/$sessionId/history';
  
  // Get message endpoint
  static String getChatMessageUrl(String sessionId) => '$geminiChatApiUrl/api/gemini/chat/$sessionId/message';
  
  // Disaster prediction endpoint
  static String get disasterPredictionUrl => '$baseUrl/api/ai/predict';
}