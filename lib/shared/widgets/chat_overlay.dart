import 'package:flutter/material.dart';
import 'package:disaster_management/shared/widgets/chat_assistance.dart';

class ChatOverlay extends StatelessWidget {
  const ChatOverlay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Stack(
      children: [
        ChatAssistance(),
      ],
    );
  }
}