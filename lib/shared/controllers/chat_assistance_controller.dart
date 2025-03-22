import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:disaster_management/shared/models/chat_message.dart';
import 'package:disaster_management/core/constants/api_constants.dart';

class ChatAssistanceController {
  final ValueNotifier<bool> isExpandedNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<List<ChatMessage>> messagesNotifier;
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  
  final List<ChatMessage> _mutableMessages;
  
  // Use API constants for the base URL
  String? _sessionId;
  
  ChatAssistanceController() : 
    _mutableMessages = [],
    messagesNotifier = ValueNotifier<List<ChatMessage>>([]) {
    // Initialize the chat session
    _initChatSession();
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
      isLoadingNotifier.value = false;
      scrollToBottom();
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
}