import 'package:flutter/material.dart';
import 'package:disaster_management/core/constants/app_colors.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  // Modified constructor to allow for const with DateTime
  const ChatMessage({
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
  // Replace boolean with ValueNotifier to avoid full rebuilds
  final ValueNotifier<bool> _isExpandedNotifier = ValueNotifier<bool>(false);
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  // Also use ValueNotifier for loading state
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier<bool>(false);
  
  // Fixed: Use a non-const list since we need a real DateTime
  final List<ChatMessage> _messages = [
    ChatMessage(
      text: "Hello! I'm your disaster assistance bot. How can I help you today?",
      isUser: false,
      timestamp: DateTime.now(),
    ),
  ];

  // Use a separate list for mutable messages
  late List<ChatMessage> _mutableMessages;
  // Add a ValueNotifier for messages to rebuild only the message list
  late ValueNotifier<List<ChatMessage>> _messagesNotifier;

  // Predefined responses for common emergency queries
  final Map<String, String> _predefinedResponses = const {
    'flood': 'In case of flooding, move to higher ground immediately. Avoid walking or driving through flood waters.',
    'earthquake': 'During an earthquake, drop to the ground, take cover under sturdy furniture, and hold on until the shaking stops.',
    'fire': 'If there\'s a fire, evacuate immediately. Crawl low under smoke. Call emergency services once you\'re safe.',
    'hurricane': 'For hurricanes, follow evacuation orders. If sheltering in place, stay in a small interior room away from windows.',
    'tornado': 'During a tornado, seek shelter in a basement or interior room on the lowest floor. Stay away from windows.',
    'help': 'Emergency services have been notified of your location. Stay calm and wait for assistance.',
    'emergency': 'Please specify the type of emergency you\'re facing so I can provide appropriate guidance.',
  };

  @override
  void initState() {
    super.initState();
    // Initialize mutable messages from initial messages
    _mutableMessages = List.from(_messages);
    _messagesNotifier = ValueNotifier<List<ChatMessage>>(_mutableMessages);
    
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
    _isExpandedNotifier.dispose();
    _isLoadingNotifier.dispose();
    _messagesNotifier.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || !mounted) return;
    
    // Add user message to chat
    _mutableMessages.add(ChatMessage(
      text: messageText,
      isUser: true,
      timestamp: DateTime.now(),
    ));
    _messagesNotifier.value = List.from(_mutableMessages);
    _messageController.clear();
    _isLoadingNotifier.value = true;
    
    // Scroll to bottom
    _scrollToBottom();
    
    // Use a microtask to reduce frame drops
    Future.microtask(() async {
      // Add a small delay to show loading indicator
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (!mounted) return;
      
      // Generate a response based on the message content
      String botResponse = _generateResponse(messageText);
      
      _mutableMessages.add(ChatMessage(
        text: botResponse,
        isUser: false,
        timestamp: DateTime.now(),
      ));
      _messagesNotifier.value = List.from(_mutableMessages);
      _isLoadingNotifier.value = false;
      
      _scrollToBottom();
    });
  }
  
  // Generate a simple response based on keywords in the user's message
  String _generateResponse(String message) {
    // Existing code remains unchanged
    final lowerMessage = message.toLowerCase();
    
    // Check for keywords in predefined responses
    for (final entry in _predefinedResponses.entries) {
      if (lowerMessage.contains(entry.key)) {
        return entry.value;
      }
    }
    
    // Default responses if no keywords match
    if (lowerMessage.contains('thank')) {
      return "You're welcome. Stay safe!";
    } else if (lowerMessage.contains('hello') || lowerMessage.contains('hi')) {
      return "Hello! How can I assist you with emergency information?";
    } else if (lowerMessage.contains('evacuat')) {
      return "If you need to evacuate, follow local authority instructions. Take emergency supplies and important documents with you.";
    } else if (lowerMessage.contains('shelter')) {
      return "To find the nearest shelter, check the evacuation map in the app or contact local emergency services.";
    } else {
      return "I'm here to help with emergency information. Could you provide more details about your situation?";
    }
  }

  void _scrollToBottom() {
    if (!mounted) return;
    
    // Use microtask to avoid frame drops
    Future.microtask(() {
      if (_scrollController.hasClients && mounted) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive layout
    final Size screenSize = MediaQuery.of(context).size;
    final double chatWidth = screenSize.width < 400 ? screenSize.width * 0.85 : 320;
    final double chatHeight = screenSize.height < 700 ? screenSize.height * 0.6 : 450;
    
    // Wrap the entire widget in RepaintBoundary to isolate its painting
    return RepaintBoundary(
      child: Positioned(
        right: 16,
        bottom: 16,
        // Use a separate StatefulBuilder to isolate state changes
        child: Material(
          // Use transparent material to avoid affecting parent
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min, // Add this to minimize layout impact
            children: [
              // Chat window - use ValueListenableBuilder to rebuild only when expanded state changes
              ValueListenableBuilder<bool>(
                valueListenable: _isExpandedNotifier,
                builder: (context, isExpanded, _) {
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: isExpanded 
                      ? _buildChatWindow(chatWidth, chatHeight)
                      : const SizedBox.shrink(),
                  );
                },
              ),
                
              // Chat Button - extract to reduce rebuilds
              _buildChatButton(),
            ],
          ),
        ),
      ),
    );
  }

  // Extract chat window to a separate method to reduce rebuilds
  Widget _buildChatWindow(double width, double height) {
    return Material(
      elevation: 10,
      borderRadius: BorderRadius.circular(20),
      color: Colors.white,
      child: SizedBox(
        width: width,
        height: height,
        child: Column(
          children: [
            // Chat Header
            _buildChatHeader(),
            
            // Chat Messages - use ValueListenableBuilder to rebuild only when messages change
            Expanded(
              child: ValueListenableBuilder<List<ChatMessage>>(
                valueListenable: _messagesNotifier,
                builder: (context, messages, _) {
                  return RepaintBoundary(
                    child: _buildMessageList(width, messages),
                  );
                },
              ),
            ),
            
            // Loading indicator - use ValueListenableBuilder to rebuild only when loading state changes
            ValueListenableBuilder<bool>(
              valueListenable: _isLoadingNotifier,
              builder: (context, isLoading, _) {
                return isLoading
                  ? const SizedBox(
                      height: 40,
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink();
              },
            ),
            
            // Input Field
            _buildInputField(),
          ],
        ),
      ),
    );
  }

  Widget _buildChatHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.white,
            radius: 16,
            child: Icon(
              Icons.support_agent,
              color: Colors.blue, // Use direct color to avoid AppColors lookup
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
              _isExpandedNotifier.value = false;
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(double chatWidth, List<ChatMessage> messages) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return _MessageBubble(
          message: message,
          maxWidth: chatWidth * 0.7,
          key: ValueKey('message_$index'),
        );
      },
    );
  }

  Widget _buildInputField() {
    return Container(
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
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(
                  Icons.send,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatButton() {
    return Material(
      color: AppColors.primaryColor,
      borderRadius: BorderRadius.circular(30),
      elevation: 5,
      child: InkWell(
        onTap: () {
          _isExpandedNotifier.value = !_isExpandedNotifier.value;
        },
        child: const SizedBox(
          width: 56,
          height: 56,
          child: Center(
            child: Icon(
              Icons.support_agent,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

// Extract message bubble to a separate stateless widget to reduce rebuilds
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final double maxWidth;

  const _MessageBubble({
    required this.message,
    required this.maxWidth,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Existing code remains unchanged
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
                maxWidth: maxWidth,
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