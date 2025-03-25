import 'package:flutter/material.dart';
import 'package:disaster_management/core/constants/app_colors.dart';
import 'package:disaster_management/shared/controllers/chat_assistance_controller.dart';
import 'package:disaster_management/shared/models/chat_message.dart';

class ChatAssistance extends StatefulWidget {
  const ChatAssistance({super.key});

  @override
  State<ChatAssistance> createState() => _ChatAssistanceState();
}

class _ChatAssistanceState extends State<ChatAssistance> with SingleTickerProviderStateMixin {
  late ChatAssistanceController _controller;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    // Initialize the controller
    _controller = ChatAssistanceController();
    
    // Set context for location services
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.setContext(context);
        
        // Show prediction tip after a delay
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted && !_controller.isExpandedNotifier.value) {
            _showPredictionTip();
          }
        });
      }
    });
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }
  
  // Add this method to show a tip about the prediction feature
  void _showPredictionTip() {
    _animationController.forward();
    
    // Auto-hide the tip after some time
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) {
        _animationController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive layout
    final Size screenSize = MediaQuery.of(context).size;
    final double chatWidth = screenSize.width < 600 
        ? screenSize.width * 0.85 
        : 400;
    final double chatHeight = screenSize.height < 700 
        ? screenSize.height * 0.6 
        : screenSize.height * 0.7 > 600 ? 600 : screenSize.height * 0.7;
    
    // Use SafeArea to avoid system UI overlaps
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 16, bottom: 16),
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              // Chat window - use ValueListenableBuilder to rebuild only when expanded state changes
              ValueListenableBuilder<bool>(
                valueListenable: _controller.isExpandedNotifier,
                builder: (context, isExpanded, _) {
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: isExpanded 
                      ? _buildChatWindow(chatWidth, chatHeight)
                      : const SizedBox.shrink(),
                  );
                },
              ),
              
              // Prediction tip bubble
              ValueListenableBuilder<bool>(
                valueListenable: _controller.isExpandedNotifier,
                builder: (context, isExpanded, _) {
                  if (isExpanded) return const SizedBox.shrink();
                  
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _animationController,
                      curve: Curves.elasticOut,
                    )),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 70), // Added space for the button
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: chatWidth,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.radar, color: AppColors.primaryColor),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: const Text(
                                    'Check disaster risks\nin your area!',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: () {
                                    _animationController.reverse();
                                    _controller.isExpandedNotifier.value = true;
                                    _controller.checkDisasterRisks();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryColor,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    minimumSize: Size.zero,
                                  ),
                                  child: const Text(
                                    'Check Now',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
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
    return Positioned(
      bottom: 70, // Position above the chat button
      right: 0,
      child: Material(
        elevation: 10,
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        child: Container(
          width: width,
          height: height,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            children: [
              // Chat Header
              _buildChatHeader(),
              
              // Chat Messages - use ValueListenableBuilder to rebuild only when messages change
              Expanded(
                child: ValueListenableBuilder(
                  valueListenable: _controller.messagesNotifier,
                  builder: (context, List<ChatMessage> messages, _) {
                    return _buildMessageList(width, messages);
                  },
                ),
              ),
              
              // Loading indicator - use ValueListenableBuilder to rebuild only when loading state changes
              ValueListenableBuilder<bool>(
                valueListenable: _controller.isLoadingNotifier,
                builder: (context, isLoading, _) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: isLoading ? 40 : 0,
                    child: isLoading
                      ? const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                  );
                },
              ),
              
              // Input Field
              _buildInputField(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageList(double chatWidth, List<ChatMessage> messages) {
    return ListView.builder(
      controller: _controller.scrollController,
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
          // Add AI prediction button
          IconButton(
            icon: const Icon(Icons.radar, color: Colors.white),
            tooltip: 'Predict Disasters',
            onPressed: () {
              _showDisasterPredictionDialog();
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () {
              _controller.isExpandedNotifier.value = false;
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // Add this method to show the disaster prediction dialog
  void _showDisasterPredictionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 10),
            Text('AI Disaster Prediction'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Would you like to check potential disaster risks in your current location using AI?',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This will use your current location to analyze potential risks based on historical data and environmental factors.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _controller.isExpandedNotifier.value = true;
              _controller.checkDisasterRisks();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
            ),
            child: Text('Check Risks', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
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
              controller: _controller.messageController,
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
              onSubmitted: (_) => _controller.sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(30),
            child: InkWell(
              onTap: () => _controller.sendMessage(),
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
          _controller.isExpandedNotifier.value = !_controller.isExpandedNotifier.value;
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
                    : message.isError
                        ? Colors.red.shade50
                        : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(18),
              ),
              child: SelectableText(
                message.text,
                style: TextStyle(
                  color: message.isUser 
                      ? Colors.white 
                      : message.isError
                          ? Colors.red.shade800
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