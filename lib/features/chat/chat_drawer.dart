import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../ai/chat/chat_service.dart';
import '../../hub/modules/chat_hub_module.dart';
import '../../models/chat_message.dart';
import '../../ui/linkvault_ui.dart';
import '../../widgets/linkvault_animated_ambient.dart';

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

  static const _app = ChatHubModule.appDefinition;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final phase = AmbientMotionScope.maybeOf(context)?.value ?? 0.0;
    final hub = HubAppColors.palette(_app, phase);

    return Drawer(
      backgroundColor: Colors.transparent,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(LinkvaultDesign.spaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  LinkvaultDesign.spaceSm,
                  LinkvaultDesign.spaceSm,
                  LinkvaultDesign.spaceSm,
                  LinkvaultDesign.spaceMd,
                ),
                child: Row(
                  children: [
                    LinkvaultIconChip(
                      dimension: 40,
                      color: hub.primary,
                      child: PhosphorIcon(
                        PhosphorIcons.chatsCircle,
                        color: hub.primary,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: LinkvaultDesign.spaceMd),
                    Text(
                      'Chats',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ).heroEntrance(context),
              ),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onNewChat();
                },
                icon: PhosphorIcon(PhosphorIcons.plus, size: 18),
                label: const Text('New chat'),
              ),
              SizedBox(height: LinkvaultDesign.spaceMd),
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
                    return ListView.separated(
                      itemCount: sessions.length,
                      separatorBuilder: (_, _) =>
                          SizedBox(height: LinkvaultDesign.spaceXs),
                      itemBuilder: (context, index) {
                        final session = sessions[index];
                        final selected = session.id == activeSessionId;
                        return _SessionTile(
                          session: session,
                          selected: selected,
                          hub: hub,
                          listIndex: index,
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
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({
    required this.session,
    required this.selected,
    required this.hub,
    required this.listIndex,
    required this.onTap,
    required this.onDelete,
  });

  final ChatSessionModel session;
  final bool selected;
  final HubAppPalette hub;
  final int listIndex;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return LinkvaultSurface(
      onTap: onTap,
      borderRadius: LinkvaultDesign.radiusControl,
      color: selected
          ? hub.primary.withValues(alpha: 0.14)
          : scheme.surfaceContainerLow.withValues(alpha: 0.5),
      padding: const EdgeInsets.symmetric(
        horizontal: LinkvaultDesign.spaceMd,
        vertical: LinkvaultDesign.spaceSm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
                Text(
                  _formatWhen(session.updatedAt),
                  style: LinkvaultTypography.meta(scheme),
                ),
              ],
            ),
          ),
          AliveIconButton(
            onPressed: onDelete,
            icon: PhosphorIcon(
              PhosphorIcons.trash,
              size: 18,
              color: scheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    ).listEntrance(context, index: listIndex);
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
