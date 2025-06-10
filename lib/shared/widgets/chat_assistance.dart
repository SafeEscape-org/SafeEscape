import 'package:flutter/material.dart';
import 'package:disaster_management/core/constants/app_colors.dart';
import 'package:disaster_management/shared/controllers/chat_assistance_controller.dart';
import 'package:disaster_management/shared/models/chat_message.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class ChatAssistance extends StatefulWidget {
  const ChatAssistance({super.key});

  @override
  State<ChatAssistance> createState() => _ChatAssistanceState();
}

class _ChatAssistanceState extends State<ChatAssistance>
    with SingleTickerProviderStateMixin {
  late ChatAssistanceController _controller;
  late AnimationController _animationController;
  bool _isSpeaking = false;
  bool _isMicActive = false;

  // Audio feedback
  Future<void> _playSound(String soundType) async {
    try {
      await SystemSound.play(soundType == 'success'
          ? SystemSoundType.click
          : SystemSoundType.alert);
    } catch (e) {
      // Silently handle errors for devices that don't support sound
    }
  }

  void _toggleMic() {
    setState(() {
      _isMicActive = !_isMicActive;
    });

    // Play sound feedback
    _playSound('success');

    if (_isMicActive) {
      // Here you would implement actual voice recognition
      // For now, we'll simulate it with a timer
      Timer(const Duration(seconds: 3), () {
        if (mounted && _isMicActive) {
          setState(() {
            _isMicActive = false;
          });

          // Simulate sending a voice message
          _controller.messageController.text =
              "Help me find evacuation routes nearby";
          _controller.sendMessage();
        }
      });
    }
  }

  void _toggleSpeaker() {
    setState(() {
      _isSpeaking = !_isSpeaking;
    });

    // Play sound feedback
    _playSound('success');

    // Here you would implement TTS for the last message
    // This is just a placeholder for the actual implementation
  }

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
    final bool isSmallScreen = screenSize.width < 360;

    // Adaptive sizing based on screen size
    final double chatWidth = screenSize.width < 600 
        ? isSmallScreen
            ? screenSize.width * 0.95
            : screenSize.width * 0.85
        : 400;
    final double chatHeight = screenSize.height < 500
        ? screenSize.height * 0.7
        : screenSize.height < 700
        ? screenSize.height * 0.6 
            : screenSize.height * 0.7 > 600
                ? 600
                : screenSize.height * 0.7;

    // Adjust padding for small screens
    final double horizontalPadding = isSmallScreen ? 8.0 : 16.0;
    final double verticalPadding = isSmallScreen ? 8.0 : 16.0;
    
    // Use SafeArea to avoid system UI overlaps
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: EdgeInsets.only(
              right: horizontalPadding, bottom: verticalPadding),
          child: Stack(
            clipBehavior: Clip.none, // Allow widgets to overflow
            alignment: Alignment.bottomRight,
            children: [
              // Chat window - use ValueListenableBuilder to rebuild only when expanded state changes
              ValueListenableBuilder<bool>(
                valueListenable: _controller.isExpandedNotifier,
                builder: (context, isExpanded, _) {
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: isExpanded 
                      ? Container(
                          margin: const EdgeInsets.only(bottom: 70),
                          width: chatWidth,
                          height: chatHeight,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Chat Header
                              _buildChatHeader(),
                              
                              // Chat Messages
                              Expanded(
                                child: ValueListenableBuilder(
                                    valueListenable:
                                        _controller.messagesNotifier,
                                    builder: (context,
                                        List<ChatMessage> messages, _) {
                                      return _buildMessageList(
                                          chatWidth, messages, isSmallScreen);
                                  },
                                ),
                              ),
                              
                              // Loading indicator
                              ValueListenableBuilder<bool>(
                                  valueListenable:
                                      _controller.isLoadingNotifier,
                                builder: (context, isLoading, _) {
                                  return AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                    height: isLoading ? 40 : 0,
                                    child: isLoading
                                      ? const Center(
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                              strokeWidth: 2,
                                                  color: AppColors.primaryColor,
                                            ),
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                  );
                                },
                              ),
                              
                              // Input Field
                                _buildInputField(isSmallScreen),
                            ],
                          ),
                        )
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
                      padding: const EdgeInsets.only(
                          bottom: 70), // Added space for the button
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isSmallScreen
                              ? screenSize.width * 0.85
                              : chatWidth,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 12 : 16,
                                vertical: isSmallScreen ? 8 : 12),
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
                            child: isSmallScreen
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.radar,
                                              color: AppColors.primaryColor,
                                              size: 16),
                                          const SizedBox(width: 6),
                                          const Expanded(
                                            child: Text(
                                              'Check disaster risks in your area!',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            _animationController.reverse();
                                            _controller.isExpandedNotifier
                                                .value = true;
                                            _controller.checkDisasterRisks();
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                AppColors.primaryColor,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 8),
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
                                      ),
                                    ],
                                  )
                                : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                      Icon(Icons.radar,
                                          color: AppColors.primaryColor),
                                const SizedBox(width: 8),
                                      const Flexible(
                                        child: Text(
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
                                          _controller.isExpandedNotifier.value =
                                              true;
                                    _controller.checkDisasterRisks();
                                  },
                                  style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppColors.primaryColor,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
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
                
              // Chat Button with pulse effect
              Material(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(30),
                elevation: 5,
                child: ValueListenableBuilder<bool>(
                  valueListenable: _controller.isExpandedNotifier,
                  builder: (context, isExpanded, _) {
                    return InkWell(
                      onTap: () {
                        _controller.isExpandedNotifier.value =
                            !_controller.isExpandedNotifier.value;
                        _playSound('success');
                      },
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primaryColor,
                              AppColors.primaryColor.withBlue(
                                  (AppColors.primaryColor.blue + 40)
                                      .clamp(0, 255)),
                            ],
                          ),
                        ),
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                          child: Icon(
                            isExpanded ? Icons.close : Icons.support_agent,
                              key: ValueKey<bool>(isExpanded),
                            color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Header icon
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.support_agent,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),

          // Header text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Disaster Assistant',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Ask me about safety information',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Audio button
          IconButton(
            icon: Icon(
              _isSpeaking ? Icons.volume_up : Icons.volume_off,
              color: Colors.white,
              size: 20,
            ),
            onPressed: _toggleSpeaker,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 36,
              minHeight: 36,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(
      double chatWidth, List<ChatMessage> messages, bool isSmallScreen) {
    final double maxBubbleWidth =
        isSmallScreen ? chatWidth * 0.8 : chatWidth * 0.7;

    return ListView.builder(
      controller: _controller.scrollController,
      padding: EdgeInsets.symmetric(
          vertical: isSmallScreen ? 12 : 16,
          horizontal: isSmallScreen ? 12 : 16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return _MessageBubble(
          message: message,
          maxWidth: maxBubbleWidth,
          isSmallScreen: isSmallScreen,
          key: ValueKey('message_$index'),
        );
      },
    );
  }

  Widget _buildInputField(bool isSmallScreen) {
    final double iconSize = isSmallScreen ? 20.0 : 24.0;
    final double padding = isSmallScreen ? 8.0 : 12.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding / 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Microphone button
          Container(
            decoration: BoxDecoration(
              color: _isMicActive
                  ? AppColors.primaryColor.withOpacity(0.1)
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                _isMicActive ? Icons.mic : Icons.mic_none,
                color: _isMicActive
                    ? AppColors.primaryColor
                    : Colors.grey.shade600,
                size: iconSize,
              ),
              onPressed: _toggleMic,
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(
                minWidth: iconSize + 8,
                minHeight: iconSize + 8,
              ),
            ),
          ),

          // Text field
          Expanded(
            child: TextField(
              controller: _controller.messageController,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: isSmallScreen ? 13 : 14,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                    horizontal: padding, vertical: padding / 2),
              ),
              style: TextStyle(
                fontSize: isSmallScreen ? 13 : 14,
              ),
              onSubmitted: (text) {
                if (text.trim().isNotEmpty) {
                  _controller.sendMessage();
                }
              },
            ),
          ),

          // Send button
          Container(
            decoration: BoxDecoration(
            color: AppColors.primaryColor,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                Icons.send_rounded,
                  color: Colors.white,
                size: iconSize * 0.8,
              ),
              onPressed: () {
                final text = _controller.messageController.text.trim();
                if (text.isNotEmpty) {
                  _controller.sendMessage();
                  _playSound('success');
                }
              },
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(
                minWidth: iconSize + 8,
                minHeight: iconSize + 8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final double maxWidth;
  final bool isSmallScreen;

  const _MessageBubble({
    required this.message,
    required this.maxWidth,
    this.isSmallScreen = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double fontSize = isSmallScreen ? 12.0 : 14.0;
    final double padding = isSmallScreen ? 8.0 : 10.0;
    final double avatarSize = isSmallScreen ? 28.0 : 32.0;

    return Padding(
      padding: EdgeInsets.only(
        bottom: isSmallScreen ? 8 : 12,
        left: message.isUser ? avatarSize : 0,
        right: message.isUser ? 0 : avatarSize,
      ),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) 
            CircleAvatar(
              backgroundColor: AppColors.primaryColor.withOpacity(0.1),
              radius: avatarSize / 2,
              child: Icon(
                Icons.support_agent,
                color: AppColors.primaryColor,
                size: avatarSize / 2,
              ),
            ),
          if (!message.isUser) SizedBox(width: isSmallScreen ? 6 : 8),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: maxWidth,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: padding + 4,
                vertical: padding,
              ),
              decoration: BoxDecoration(
                color: message.isUser 
                    ? AppColors.primaryColor 
                    : message.isError
                        ? Colors.red.shade50
                        : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: SelectableText(
                message.text,
                style: TextStyle(
                  color: message.isUser 
                      ? Colors.white 
                      : message.isError
                          ? Colors.red.shade800
                          : Colors.black87,
                  fontSize: fontSize,
                ),
              ),
            ),
          ),
          if (message.isUser) SizedBox(width: isSmallScreen ? 6 : 8),
          if (message.isUser)
            CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              radius: avatarSize / 2,
              child: Icon(
                Icons.person,
                color: AppColors.primaryColor,
                size: avatarSize / 2,
              ),
            ),
        ],
      ),
    );
  }
}
