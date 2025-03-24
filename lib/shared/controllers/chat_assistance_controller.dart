import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:disaster_management/shared/models/chat_message.dart';
import 'package:disaster_management/core/constants/api_constants.dart';
import 'package:disaster_management/services/location_service.dart';

class ChatAssistanceController {
  final ValueNotifier<bool> isExpandedNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<List<ChatMessage>> messagesNotifier;
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  
  final List<ChatMessage> _mutableMessages;
  
  // Use API constants for the base URL
  String? _sessionId;
  BuildContext? _context;
  
  ChatAssistanceController() : 
    _mutableMessages = [],
    messagesNotifier = ValueNotifier<List<ChatMessage>>([]) {
    // Initialize the chat session
    _initChatSession();
  }
  
  // Set context for location services
  void setContext(BuildContext context) {
    _context = context;
  }
  
  Future<void> _initChatSession() async {
    isLoadingNotifier.value = true;
    
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.geminiChatApiUrl}/api/gemini/chat'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _sessionId = data['sessionId'];
        
        // Add welcome message
        _mutableMessages.add(ChatMessage(
          text: "Hello! I'm your disaster assistance bot. How can I help you today?",
          isUser: false,
          timestamp: DateTime.now(),
        ));
        messagesNotifier.value = List.from(_mutableMessages);
      } else {
        // Handle error
        _addErrorMessage("Couldn't connect to assistant. Please try again later.");
      }
    } catch (e) {
      _addErrorMessage("Network error. Please check your connection.");
    } finally {
      isLoadingNotifier.value = false;
    }
  }
  
  void _addErrorMessage(String message) {
    _mutableMessages.add(ChatMessage(
      text: message,
      isUser: false,
      timestamp: DateTime.now(),
      isError: true,
    ));
    messagesNotifier.value = List.from(_mutableMessages);
  }
  
  void dispose() {
    isExpandedNotifier.dispose();
    isLoadingNotifier.dispose();
    messagesNotifier.dispose();
    messageController.dispose();
    scrollController.dispose();
  }
  
  // Keep only one sendMessage method
  Future<void> sendMessage() async {
    final messageText = messageController.text.trim();
    if (messageText.isEmpty || _sessionId == null) return;
    
    // Add user message to chat
    _mutableMessages.add(ChatMessage(
      text: messageText,
      isUser: true,
      timestamp: DateTime.now(),
    ));
    messagesNotifier.value = List.from(_mutableMessages);
    messageController.clear();
    isLoadingNotifier.value = true;
    
    scrollToBottom();
    
    try {
      // Check if the message is asking about disaster prediction
      if (_isDisasterPredictionQuery(messageText) && _context != null) {
        await _handleDisasterPrediction();
      } else {
        // Regular chat message handling
        await _sendRegularChatMessage(messageText);
      }
    } catch (e) {
      _addErrorMessage("An error occurred. Please try again.");
      debugPrint("Error in sendMessage: $e");
    } finally {
      isLoadingNotifier.value = false;
      scrollToBottom();
    }
  }
  
  // Keep only one _sendRegularChatMessage method
  Future<void> _sendRegularChatMessage(String messageText) async {
    try {
      // Use the API constants to construct the URL
      final response = await http.post(
        Uri.parse(ApiConstants.getChatMessageUrl(_sessionId!)),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': messageText}),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final botResponse = data['response'];
        
        _mutableMessages.add(ChatMessage(
          text: botResponse,
          isUser: false,
          timestamp: DateTime.now(),
        ));
      } else {
        _addErrorMessage("Sorry, I couldn't process your request. Please try again.");
      }
    } catch (e) {
      _addErrorMessage("Network error. Please check your connection.");
    } finally {
      messagesNotifier.value = List.from(_mutableMessages);
    }
  }
  
  void scrollToBottom() {
    // Use microtask to avoid frame drops
    Future.microtask(() {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  // Add a method to directly trigger disaster prediction
  Future<void> checkDisasterRisks() async {
    if (_context == null) {
      isExpandedNotifier.value = true;
      _addErrorMessage("Please provide location access to check disaster risks.");
      return;
    }
    
    isExpandedNotifier.value = true;
    isLoadingNotifier.value = true;
    
    try {
      await _handleDisasterPrediction();
    } finally {
      isLoadingNotifier.value = false;
      scrollToBottom();
    }
  }
  
  // Add the missing method for handling disaster prediction
  Future<void> _handleDisasterPrediction() async {
    if (_context == null) {
      _addErrorMessage("Cannot access location services. Please try again later.");
      return;
    }
    
    // Add a message indicating we're checking location
    _mutableMessages.add(ChatMessage(
      text: "I'll check the disaster risks for your current location. Please wait a moment...",
      isUser: false,
      timestamp: DateTime.now(),
    ));
    messagesNotifier.value = List.from(_mutableMessages);
    
    // Get current location
    final locationData = await LocationService.getCurrentLocation(_context!);
    
    if (locationData == null) {
      _addErrorMessage("I couldn't access your location. Please check your location permissions and try again.");
      return;
    }
    
    // Predict disasters for the location
    final prediction = await LocationService.predictDisasterForLocation(locationData);
    
    if (prediction == null) {
      _addErrorMessage("I couldn't get disaster predictions for your area. Please try again later.");
      return;
    }
    
    // Format and display the prediction results
    final formattedResponse = _formatPredictionResponse(prediction, locationData);
    
    _mutableMessages.add(ChatMessage(
      text: formattedResponse,
      isUser: false,
      timestamp: DateTime.now(),
    ));
    messagesNotifier.value = List.from(_mutableMessages);
  }
  
  // Add method to format prediction response
  String _formatPredictionResponse(Map<String, dynamic> prediction, Map<String, dynamic> location) {
    final address = location["address"] ?? "your location";
    final StringBuilder = StringBuffer();
    
    StringBuilder.writeln("📍 **Disaster Risk Assessment for $address**\n");
    
    if (prediction.containsKey("predictions")) {
      final predictions = prediction["predictions"];
      
      if (predictions is List && predictions.isNotEmpty) {
        StringBuilder.writeln("Based on historical data and current conditions, here are the potential risks:");
        
        for (var i = 0; i < predictions.length; i++) {
          final disaster = predictions[i];
          final type = disaster["type"] ?? "Unknown";
          final risk = disaster["risk"] ?? "Unknown";
          final probability = disaster["probability"] ?? 0.0;
          
          // Format probability as percentage
          final probabilityStr = "${(probability * 100).toStringAsFixed(1)}%";
          
          // Use emoji based on risk level
          String riskEmoji;
          switch (risk.toString().toLowerCase()) {
            case "high":
              riskEmoji = "🔴";
              break;
            case "medium":
              riskEmoji = "🟠";
              break;
            case "low":
              riskEmoji = "🟢";
              break;
            default:
              riskEmoji = "⚪";
          }
          
          StringBuilder.writeln("\n$riskEmoji **$type**");
          StringBuilder.writeln("   Risk Level: $risk");
          StringBuilder.writeln("   Probability: $probabilityStr");
        }
      } else {
        StringBuilder.writeln("Good news! No significant disaster risks were identified for your area at this time.");
      }
    } else {
      StringBuilder.writeln("I couldn't analyze specific risks for your area, but it's always good to stay prepared.");
    }
    
    StringBuilder.writeln("\n💡 **Safety Tips**");
    StringBuilder.writeln("• Keep emergency contacts handy");
    StringBuilder.writeln("• Have an evacuation plan ready");
    StringBuilder.writeln("• Maintain an emergency kit with essentials");
    
    StringBuilder.writeln("\nWould you like specific safety information for any of these potential disasters?");
    
    return StringBuilder.toString();
  }
  
  // Check if message contains keywords related to disaster prediction
  bool _isDisasterPredictionQuery(String message) {
    final predictionKeywords = [
      'predict', 'forecast', 'risk', 'danger', 'hazard', 'warning',
      'disaster', 'flood', 'earthquake', 'hurricane', 'cyclone', 'tsunami',
      'tornado', 'wildfire', 'landslide', 'drought', 'my area', 'my location',
      'near me', 'around me', 'current risk', 'potential disaster'
    ];
    
    message = message.toLowerCase();
    return predictionKeywords.any((keyword) => message.contains(keyword));
  }
  
  // Update sendMessage to handle disaster prediction queries
 
  
  // Extract regular chat message handling to a separate method
}