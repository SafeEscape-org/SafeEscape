import '../models/chat_message.dart';

class ChatService {
  static Future<String> getResponse(String message) async {
    // Implement your chatbot logic here
    // This could be an API call to your backend or AI service
    return "Thank you for your message. How can I assist you?";
  }
}