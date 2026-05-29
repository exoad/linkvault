import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../ai/chat/chat_service.dart';
import '../../models/chat_message.dart';
import '../../theme/linkvault_typography.dart';
import 'widgets/chat_ai_glow.dart';

class ChatDrawer extends StatelessWidget {
  const ChatDrawer({
    super.key,
    required this.chat,
    required this.activeSessionId,
    required this.onSessionSelected,
    required this.onNewChat,
    required this.onDeleteSession,
  });

  final ChatService chat;
  final String? activeSessionId;
  final ValueChanged<String> onSessionSelected;
  final VoidCallback onNewChat;
  final ValueChanged<String> onDeleteSession;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final phase = ChatAiGlowScope.phaseOf(context);
    final glow = ChatAiGlowColors.at(phase);

    return Drawer(
      backgroundColor: scheme.surface.withValues(alpha: 0.97),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  PhosphorIcon(
                    PhosphorIcons.chatsCircle,
                    color: glow.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text('Chats', style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onNewChat();
                },
                icon: PhosphorIcon(PhosphorIcons.plus, size: 18),
                label: const Text('New chat'),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<List<ChatSessionModel>>(
                stream: chat.watchSessions(),
                builder: (context, snapshot) {
                  final sessions = snapshot.data ?? [];
                  if (sessions.isEmpty) {
                    return Center(
                      child: Text(
                        'No conversations yet',
                        style: LinkvaultTypography.meta(scheme),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final session = sessions[index];
                      final selected = session.id == activeSessionId;
                      return _SessionTile(
                        session: session,
                        selected: selected,
                        glow: glow,
                        onTap: () {
                          Navigator.pop(context);
                          onSessionSelected(session.id);
                        },
                        onDelete: () => onDeleteSession(session.id),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({
    required this.session,
    required this.selected,
    required this.glow,
    required this.onTap,
    required this.onDelete,
  });

  final ChatSessionModel session;
  final bool selected;
  final ChatAiGlowColors glow;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final subtitle = _formatWhen(session.updatedAt);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: selected
            ? glow.primary.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          onTap: onTap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            session.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: LinkvaultTypography.meta(scheme),
          ),
          trailing: IconButton(
            icon: PhosphorIcon(
              PhosphorIcons.trash,
              size: 18,
              color: scheme.onSurface.withValues(alpha: 0.45),
            ),
            onPressed: onDelete,
          ),
        ),
      ),
    );
  }

  static String _formatWhen(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${time.month}/${time.day}';
  }
}
