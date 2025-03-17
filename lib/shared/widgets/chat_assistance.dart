import 'package:flutter/material.dart';
import 'package:disaster_management/core/constants/app_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class ChatAssistance extends StatefulWidget {
  const ChatAssistance({super.key});

  @override
  State<ChatAssistance> createState() => _ChatAssistanceState();
}

class _ChatAssistanceState extends State<ChatAssistance> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  
  final List<ChatMessage> _messages = [
    ChatMessage(
      text: "Hello! I'm your disaster assistance bot. How can I help you today?",
      isUser: false,
      timestamp: DateTime.now(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    
    setState(() {
      _messages.add(ChatMessage(
        text: _messageController.text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _messageController.clear();
    });
    
    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
    
    // Simulate bot response
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      
      final responses = [
        "I understand your concern. Let me help you with that.",
        "Here's what you should do in this situation...",
        "I've marked your location for emergency services.",
        "Stay calm and follow these safety instructions...",
      ];
      
      setState(() {
        _messages.add(ChatMessage(
          text: responses[DateTime.now().second % responses.length],
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
      
      // Scroll to bottom again
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive layout
    final Size screenSize = MediaQuery.of(context).size;
    final double chatWidth = screenSize.width < 400 ? screenSize.width * 0.85 : 320;
    final double chatHeight = screenSize.height < 700 ? screenSize.height * 0.6 : 450;
    
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      right: 16,
      bottom: 16,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_isExpanded)
            Material(
              elevation: 10,
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
              child: Container(
                width: chatWidth,
                height: chatHeight,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    // Chat Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 16,
                            child: Icon(
                              Icons.support_agent,
                              color: AppColors.primaryColor,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Emergency Assistant',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () {
                              setState(() => _isExpanded = false);
                              _animationController.reverse();
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                    
                    // Chat Messages
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
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
                                      backgroundColor: AppColors.primaryColor.withOpacity(0.1),
                                      radius: 16,
                                      child: Icon(
                                        Icons.support_agent,
                                        color: AppColors.primaryColor,
                                        size: 16,
                                      ),
                                    ),
                                  if (!message.isUser) const SizedBox(width: 8),
                                  
                                  Flexible(
                                    child: Container(
                                      constraints: BoxConstraints(
                                        maxWidth: chatWidth * 0.7,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: message.isUser 
                                            ? AppColors.primaryColor 
                                            : Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: Text(
                                        message.text,
                                        style: TextStyle(
                                          color: message.isUser 
                                              ? Colors.white 
                                              : Colors.black87,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ).animate()
                                      .fadeIn(duration: 300.ms)
                                      .slideX(
                                        begin: message.isUser ? 0.3 : -0.3, 
                                        end: 0,
                                        duration: 300.ms,
                                        curve: Curves.easeOutQuad,
                                      ),
                                  ),
                                    
                                  if (message.isUser) const SizedBox(width: 8),
                                  if (message.isUser)
                                    CircleAvatar(
                                      backgroundColor: Colors.blue,
                                      radius: 16,
                                      child: const Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    
                    // Input Field
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 5,
                            spreadRadius: 1,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              decoration: InputDecoration(
                                hintText: 'Type your emergency...',
                                hintStyle: TextStyle(color: Colors.grey.shade400),
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Material(
                            color: AppColors.primaryColor,
                            borderRadius: BorderRadius.circular(30),
                            child: InkWell(
                              onTap: _sendMessage,
                              borderRadius: BorderRadius.circular(30),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                child: const Icon(
                                  Icons.send,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().scale(
              begin: const Offset(0.9, 0.9),
              end: const Offset(1.0, 1.0),
              duration: 300.ms,
              curve: Curves.easeOutBack,
            ).fadeIn(duration: 200.ms),
            
          // Chat Button
          Material(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(30),
            elevation: 5,
            child: InkWell(
              onTap: () {
                setState(() => _isExpanded = !_isExpanded);
                if (_isExpanded) {
                  _animationController.forward();
                } else {
                  _animationController.reverse();
                }
              },
              borderRadius: BorderRadius.circular(30),
              child: Container(
                width: 56,  // Slightly smaller for better compatibility
                height: 56, // Slightly smaller for better compatibility
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return ScaleTransition(scale: animation, child: child);
                    },
                    child: _isExpanded
                        ? const Icon(
                            Icons.close,
                            color: Colors.white,
                            key: ValueKey('close'),
                          )
                        : const Icon(
                            Icons.support_agent,
                            color: Colors.white,
                            key: ValueKey('chat'),
                          ),
                  ),
                ),
              ),
            ),
          ).animate().shake(
            duration: 2000.ms, 
            delay: 3000.ms,
            hz: 2,
            curve: Curves.easeInOut,
          ).then().shake(
            duration: 2000.ms, 
            delay: 10000.ms,
            hz: 2,
            curve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }
}