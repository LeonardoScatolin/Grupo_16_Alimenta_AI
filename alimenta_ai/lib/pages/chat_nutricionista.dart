import 'package:flutter/material.dart';
import 'dart:async';

class ChatNutricionista extends StatefulWidget {
  const ChatNutricionista({super.key});

  @override
  State<ChatNutricionista> createState() => _ChatNutricionistaState();
}

class _ChatNutricionistaState extends State<ChatNutricionista> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  late AnimationController _typingController;
  late List<Animation<double>> _typingAnimations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startInitialMessages();
  }

  void _initializeAnimations() {
    _typingController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _typingAnimations = List.generate(3, (index) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(
        CurvedAnimation(
          parent: _typingController,
          curve: Interval(
            index * 0.2,
            (index * 0.2) + 0.4,
            curve: Curves.easeInOut,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingController.dispose();
    super.dispose();
  }

  void _startInitialMessages() async {
    await Future.delayed(const Duration(milliseconds: 800));
    _showTypingAnimation();
    
    await Future.delayed(const Duration(milliseconds: 2000));
    _addMessage("Olá, tudo bem?", isUser: false);
    
    await Future.delayed(const Duration(milliseconds: 1000));
    _showTypingAnimation();
    
    await Future.delayed(const Duration(milliseconds: 2500));
    _addMessage("Sou o chat Nutri, como posso te ajudar hoje?", isUser: false);
    
    _hideTypingAnimation();
  }

  void _showTypingAnimation() {
    if (mounted) {
      setState(() {
        _isTyping = true;
      });
      _typingController.repeat();
      _scrollToBottom();
    }
  }

  void _hideTypingAnimation() {
    if (mounted) {
      setState(() {
        _isTyping = false;
      });
      _typingController.stop();
    }
  }

  void _addMessage(String text, {required bool isUser}) {
    if (mounted) {
      setState(() {
        _messages.add(ChatMessage(
          text: text,
          isUser: isUser,
          timestamp: DateTime.now(),
        ));
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _addMessage(text, isUser: true);
    _messageController.clear();

    // Simular resposta do nutricionista
    Future.delayed(const Duration(milliseconds: 1000), () {
      _showTypingAnimation();
    });

    Future.delayed(const Duration(milliseconds: 3000), () {
      _simulateNutritionistResponse(text);
      _hideTypingAnimation();
    });
  }

  void _simulateNutritionistResponse(String userMessage) {
    String response = "Obrigado pela sua pergunta! ";
    
    if (userMessage.toLowerCase().contains('dieta') || 
        userMessage.toLowerCase().contains('alimentação')) {
      response += "Vou te ajudar com orientações sobre alimentação saudável. É importante manter uma dieta equilibrada com frutas, verduras e proteínas.";
    } else if (userMessage.toLowerCase().contains('peso')) {
      response += "Para questões relacionadas ao peso, é fundamental combinar uma alimentação adequada com exercícios regulares.";
    } else if (userMessage.toLowerCase().contains('receita')) {
      response += "Posso sugerir algumas receitas saudáveis! Que tipo de prato você gostaria de preparar?";
    } else {
      response += "Entendi sua questão. Para uma orientação mais específica, recomendo que agendemos uma consulta presencial.";
    }
    
    _addMessage(response, isUser: false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xff92A3FD),
              child: Text(
                'DC',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dr. Carlos',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Nutricionista',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return _buildTypingIndicator();
                }
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final theme = Theme.of(context);
    final isUser = message.isUser;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xff92A3FD),
              child: Text(
                'DC',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser 
                    ? const Color(0xff92A3FD)
                    : theme.brightness == Brightness.dark
                        ? theme.cardColor
                        : Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
                border: !isUser && theme.brightness == Brightness.dark
                    ? Border.all(color: const Color(0xff92A3FD).withOpacity(0.3))
                    : null,
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isUser 
                      ? Colors.white
                      : theme.colorScheme.onSurface,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.brightness == Brightness.dark
                  ? Colors.grey[700]
                  : Colors.grey[300],
              child: Icon(
                Icons.person,
                size: 20,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xff92A3FD),
            child: Text(
              'DC',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? theme.cardColor
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
              border: theme.brightness == Brightness.dark
                  ? Border.all(color: const Color(0xff92A3FD).withOpacity(0.3))
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                return AnimatedBuilder(
                  animation: _typingAnimations[index],
                  builder: (context, child) {
                    return Container(
                      margin: EdgeInsets.only(right: index < 2 ? 4 : 0),
                      child: Opacity(
                        opacity: _typingAnimations[index].value,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark 
                    ? theme.cardColor 
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
                border: theme.brightness == Brightness.dark
                    ? Border.all(color: const Color(0xff92A3FD).withOpacity(0.3))
                    : null,
              ),
              child: TextField(
                controller: _messageController,
                style: TextStyle(color: theme.colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'Digite sua mensagem...',
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              color: Color(0xff92A3FD),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.send,
                color: Colors.white,
                size: 20,
              ),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}

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
