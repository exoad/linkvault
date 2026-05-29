import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

class ChatInputBar extends StatelessWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onStop,
    required this.isGenerating,
    required this.enabled,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onStop;
  final bool isGenerating;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Material(
      color: scheme.surface.withValues(alpha: 0.72),
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 8, 12, 8 + bottom),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled && !isGenerating,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'Message…',
                  filled: true,
                  fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: isGenerating
                  ? onStop
                  : (enabled && controller.text.trim().isNotEmpty ? onSend : null),
              icon: PhosphorIcon(
                isGenerating ? PhosphorIcons.stop : PhosphorIcons.paperPlaneRight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
