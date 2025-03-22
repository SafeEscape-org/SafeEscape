import 'package:flutter/material.dart';
import 'package:disaster_management/core/constants/app_colors.dart';
import 'package:disaster_management/shared/models/chat_message.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final double maxWidth;

  const MessageBubble({
    required this.message,
    required this.maxWidth,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) 
            CircleAvatar(
              backgroundColor: message.isError 
                  ? Colors.red.withOpacity(0.1)
                  : AppColors.primaryColor.withOpacity(0.1),
              radius: 16,
              child: Icon(
                message.isError ? Icons.error_outline : Icons.support_agent,
                color: message.isError ? Colors.red : AppColors.primaryColor,
                size: 16,
              ),
            ),
          if (!message.isUser) const SizedBox(width: 8),
          
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: maxWidth,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: message.isUser 
                    ? AppColors.primaryColor 
                    : (message.isError ? Colors.red.shade50 : Colors.grey.shade200),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser 
                      ? Colors.white 
                      : (message.isError ? Colors.red.shade800 : Colors.black87),
                  fontSize: 14,
                ),
              ),
            ),
          ),
              
          if (message.isUser) const SizedBox(width: 8),
          if (message.isUser)
            const CircleAvatar(
              backgroundColor: Colors.blue,
              radius: 16,
              child: Icon(
                Icons.person,
                color: Colors.white,
                size: 16,
              ),
            ),
        ],
      ),
    );
  }
}