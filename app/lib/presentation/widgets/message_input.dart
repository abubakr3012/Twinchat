import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Поле ввода сообщения с кнопками прикрепления и отправки.
class MessageInput extends StatefulWidget {
  const MessageInput({
    super.key,
    this.controller,
    this.onSend,
    this.onAttach,
    this.onVoice,
    this.hintText,
    this.isLoading = false,
  });

  final TextEditingController? controller;
  final VoidCallback? onSend;
  final VoidCallback? onAttach;
  final VoidCallback? onVoice;
  final String? hintText;
  final bool isLoading;

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  late final TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (_hasText != hasText) {
      setState(() => _hasText = hasText);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Attach button
            IconButton(
              onPressed: widget.onAttach,
              icon: Icon(
                Icons.add_circle_outline_rounded,
                color: scheme.onSurfaceVariant,
              ),
            ),

            // Text field
            Expanded(
              child: TextField(
                controller: _controller,
                onSubmitted: (_) => widget.onSend?.call(),
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.send,
                style: GoogleFonts.inter(fontSize: 15),
                decoration: InputDecoration(
                  hintText: widget.hintText ?? 'Сообщение...',
                  hintStyle: GoogleFonts.inter(
                    color: scheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                  filled: true,
                  fillColor: scheme.surfaceContainerHighest.withOpacity(0.3),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Send / Voice button
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: _hasText
                  ? IconButton(
                      onPressed: widget.isLoading ? null : widget.onSend,
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: scheme.primary.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: widget.isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: scheme.onPrimary,
                                ),
                              )
                            : Icon(
                                Icons.send_rounded,
                                color: scheme.onPrimary,
                                size: 20,
                              ),
                      ),
                    )
                  : IconButton(
                      onPressed: widget.onVoice,
                      icon: Icon(
                        Icons.mic_rounded,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
