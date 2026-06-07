import 'package:churn_v1/frontend/constants/app_colors.dart';
import 'package:churn_v1/frontend/models/chat_message.dart';
import 'package:flutter/material.dart';  

class ChatSection extends StatefulWidget {
  final List<ChatMessage> initialMessages;

  /// Preguntas sugeridas que se muestran en el cuadro desplegable de abajo.
  final List<String> suggestions;

  /// Hook opcional para conectar con el backend real. Recibe la pregunta del
  /// usuario; si devuelve un texto, se agrega como respuesta de la API.
  /// Mientras no haya API, se usa [placeholderReply].
  final Future<String?> Function(String question)? onAsk;

  /// Respuesta simulada que se agrega cuando todavía no hay API conectada.
  final String placeholderReply;

  const ChatSection({
    this.initialMessages = const [],
    this.suggestions = const [
      '¿Cuál es su historial de compras?',
      '¿Tiene pagos pendientes?',
      '¿Por qué aumentó su riesgo?',
      '¿Cuál es su límite de crédito?',
    ],
    this.onAsk,
    this.placeholderReply =
        'Aquí aparecerá la respuesta de la API. Por ahora es un texto de ejemplo '
        'que crece según el largo de la respuesta real que devuelva el modelo.',
    super.key,
  });

  @override
  State<ChatSection> createState() => _ChatSectionState();
}

class _ChatSectionState extends State<ChatSection> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  late List<ChatMessage> _messages;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _messages = List.of(widget.initialMessages);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String _now() {
    final t = TimeOfDay.now();
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final p = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $p';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Agrega la pregunta del usuario y luego la respuesta (real o simulada),
  /// haciendo que el diálogo crezca.
  Future<void> _ask(String text) async {
    final q = text.trim();
    if (q.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: q, isUser: true, time: _now()));
      _controller.clear();
    });
    _scrollToBottom();

    final reply =
        widget.onAsk != null ? await widget.onAsk!(q) : widget.placeholderReply;

    if (reply != null && mounted) {
      setState(() {
        _messages.add(ChatMessage(text: reply, isUser: false, time: _now()));
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text('API',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              SizedBox(width: 8),
              CircleAvatar(radius: 4, backgroundColor: AppColors.redAccent),
            ],
          ),
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260),
            child: ListView.builder(
              controller: _scroll,
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _messages.length,
              itemBuilder: (_, i) => _Bubble(message: _messages[i]),
            ),
          ),
          const SizedBox(height: 12),
          _inputRow(),
          _suggestionsBox(),
        ],
      ),
    );
  }

  Widget _inputRow() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            style: const TextStyle(color: AppColors.textPrimary),
            textInputAction: TextInputAction.send,
            onSubmitted: _ask,
            decoration: InputDecoration(
              hintText: 'Escribe tu pregunta...',
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.red),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.redAccent, width: 1.4),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => _ask(_controller.text),
          child: Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.redAccent,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.send, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  /// Cuadro de sugerencias desplegable en la parte de abajo.
  Widget _suggestionsBox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _showSuggestions = !_showSuggestions),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline,
                    color: AppColors.amber, size: 18),
                const SizedBox(width: 8),
                const Text('Sugerencias',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                const Spacer(),
                Icon(
                  _showSuggestions ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: _showSuggestions
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: const SizedBox(width: double.infinity, height: 0),
          secondChild: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  widget.suggestions.map((s) => _suggestionChip(s)).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _suggestionChip(String text) {
    return GestureDetector(
      onTap: () => _ask(text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          text,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage message;
  const _Bubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? AppColors.bubbleOut : AppColors.bubbleIn,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isUser ? 14 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 14),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isUser
                          ? AppColors.bubbleOutText
                          : AppColors.bubbleInText,
                      fontSize: 14,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.time,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 11),
                      ),
                      if (isUser) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.done_all,
                            color: AppColors.textSecondary, size: 14),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}