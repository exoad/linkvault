import 'dart:async' show StreamSubscription, Timer, unawaited;

import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../ai/chat/chat_service.dart';
import '../../ai/runtime/local_llm_runtime.dart';
import '../../app_scope.dart';
import '../../hub/modules/chat_hub_module.dart';
import '../../models/chat_message.dart';
import '../../theme/hub_app_colors.dart';
import '../../theme/linkvault_typography.dart';
import '../../widgets/hub_app_back_button.dart';
import '../../widgets/linkvault_ambient_background.dart';
import '../../widgets/linkvault_animated_ambient.dart';
import 'chat_drawer.dart';
import 'chat_input_bar.dart';
import 'chat_message_tile.dart';
import 'chat_settings_sheet.dart';
import 'chat_streaming_draft.dart';
import 'widgets/chat_ai_glow.dart';
import 'widgets/chat_context_ring.dart';

enum _ChatUiPhase { checking, needsDownload, downloading, loading, ready, error }

class ChatAppScreen extends StatefulWidget {
  const ChatAppScreen({super.key});

  @override
  State<ChatAppScreen> createState() => _ChatAppScreenState();
}

class _ChatAppScreenState extends State<ChatAppScreen> {
  static const _app = ChatHubModule.appDefinition;

  _ChatUiPhase _phase = _ChatUiPhase.checking;
  String? _error;
  int _downloadProgress = 0;
  String? _sessionId;
  bool _isGenerating = false;
  String _backendLabel = '';
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  StreamSubscription<LlmStreamEvent>? _streamSub;
  ChatStreamingDraft? _draft;
  bool _thinkingExpanded = true;
  int _contextUsed = 0;
  int _contextMax = 8192;
  Timer? _contextTimer;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  ChatService get _chat => AppScope.chatServiceOf(context);

  @override
  void initState() {
    super.initState();
    _inputController.addListener(() => setState(() {}));
    _contextTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => unawaited(_refreshContext()),
    );
    _bootstrap();
  }

  @override
  void dispose() {
    _contextTimer?.cancel();
    _streamSub?.cancel();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _phase = _ChatUiPhase.checking;
      _error = null;
    });

    try {
      final installed = await _chat.isModelInstalled();
      if (!mounted) return;
      if (!installed) {
        setState(() => _phase = _ChatUiPhase.needsDownload);
        return;
      }
      await _openReadySession();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _ChatUiPhase.error;
        _error = e.toString();
      });
    }
  }

  Future<void> _downloadModel() async {
    setState(() {
      _phase = _ChatUiPhase.downloading;
      _downloadProgress = 0;
      _error = null;
    });

    try {
      await _chat.installModel(
        onProgress: (p) {
          if (mounted) setState(() => _downloadProgress = p);
        },
      );
      if (!mounted) return;
      await _openReadySession();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _ChatUiPhase.error;
        _error = e.toString();
      });
    }
  }

  Future<void> _refreshContext() async {
    final sessionId = _sessionId;
    if (sessionId == null || _phase != _ChatUiPhase.ready) return;
    try {
      final usage = await _chat.contextUsageFor(sessionId);
      if (!mounted) return;
      setState(() {
        _contextUsed = usage.usedTokens;
        _contextMax = usage.maxTokens;
      });
    } catch (_) {}
  }

  Future<void> _openReadySession({String? sessionId}) async {
    setState(() => _phase = _ChatUiPhase.loading);

    try {
      var id = sessionId ?? _sessionId ?? await _chat.savedSessionId;
      if (id != null) {
        try {
          await _chat.prepareSession(id);
        } catch (_) {
          id = null;
        }
      }
      id ??= await _chat.createSession();
      await _refreshContext();
      if (!mounted) return;
      setState(() {
        _sessionId = id;
        _phase = _ChatUiPhase.ready;
        _backendLabel = _chat.backendStatusLabel;
        _draft = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _ChatUiPhase.error;
        _error = e.toString();
      });
    }
  }

  Future<void> _newChat() async {
    await _streamSub?.cancel();
    final sessionId = await _chat.createSession();
    await _openReadySession(sessionId: sessionId);
    if (!mounted) return;
    setState(() {
      _draft = null;
      _isGenerating = false;
    });
  }

  Future<void> _switchSession(String sessionId) async {
    await _streamSub?.cancel();
    await _openReadySession(sessionId: sessionId);
    if (!mounted) return;
    setState(() {
      _draft = null;
      _isGenerating = false;
    });
  }

  Future<void> _deleteSession(String sessionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete chat?'),
        content: const Text('This conversation will be removed from this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _chat.deleteSession(sessionId);
    if (_sessionId == sessionId) {
      await _newChat();
    }
  }

  Future<void> _compressChat() async {
    final sessionId = _sessionId;
    if (sessionId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Compress conversation?'),
        content: const Text(
          'Older messages are merged into a short summary. '
          'The last 8 turns stay intact to free context.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Compress'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _phase = _ChatUiPhase.loading);
    try {
      final removed = await _chat.compressSession(sessionId);
      await _refreshContext();
      if (!mounted) return;
      setState(() => _phase = _ChatUiPhase.ready);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            removed > 0
                ? 'Compressed $removed older messages'
                : 'Nothing to compress yet',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _phase = _ChatUiPhase.ready);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Compress failed: $e')),
      );
    }
  }

  Future<void> _clearSession() async {
    final sessionId = _sessionId;
    if (sessionId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear conversation?'),
        content: const Text('Messages in this chat will be removed from this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _chat.clearSessionMessages(sessionId);
    await _chat.prepareSession(sessionId);
    if (!mounted) return;
    setState(() {
      _draft = null;
      _isGenerating = false;
    });
  }

  List<ChatMessageModel> _visibleMessages(List<ChatMessageModel> persisted) {
    final draft = _draft;
    if (!_isGenerating || draft == null) return persisted;
    final lastUser = persisted.lastIndexWhere((m) => m.isUser);
    final head = lastUser >= 0 ? persisted.sublist(0, lastUser + 1) : persisted;
    return [
      ...head,
      ...draft.buildMessages(includeEmptyAssistant: true),
    ];
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final sessionId = _sessionId;
    if (sessionId == null || _isGenerating) return;

    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    _inputController.clear();
    final draft = ChatStreamingDraft(sessionId: sessionId);
    setState(() {
      _isGenerating = true;
      _draft = draft;
      _thinkingExpanded = true;
    });
    _scrollToBottom();

    await _streamSub?.cancel();
    _streamSub = _chat.sendMessage(sessionId: sessionId, text: text).listen(
      (event) {
        if (!mounted) return;
        switch (event) {
          case LlmThinkingTokenEvent(:final token):
            draft.appendThinking(token);
            setState(() {});
            _scrollToBottom();
          case LlmThinkingDoneEvent():
            setState(() {});
          case LlmTokenEvent(:final token):
            draft.appendAssistant(token);
            setState(() {});
            _scrollToBottom();
          case LlmToolCallEvent(:final name, :final args, :final argsSummary):
            draft.addToolCall(
              name: name,
              label: _chat.toolLabel(name),
              argsSummary: argsSummary,
              args: args,
            );
            setState(() {});
            _scrollToBottom();
          case LlmToolResultEvent(:final name, :final result):
            for (final tool in draft.tools) {
              if (tool.name == name && tool.running) {
                tool.result = result;
                tool.running = false;
                break;
              }
            }
            setState(() {});
          case LlmDoneEvent():
            setState(() {
              _draft = null;
              _isGenerating = false;
            });
            unawaited(_refreshContext());
          case LlmErrorEvent(:final message):
            draft.appendAssistant(
              draft.assistantText.isEmpty ? message : draft.assistantText,
            );
            setState(() {
              _draft = null;
              _isGenerating = false;
            });
        }
      },
      onError: (Object e) {
        if (!mounted) return;
        setState(() {
          _draft = null;
          _isGenerating = false;
          _error = e.toString();
        });
      },
      onDone: () {
        if (!mounted) return;
        setState(() {
          _draft = null;
          _isGenerating = false;
        });
      },
    );
  }

  Future<void> _stop() async {
    await _chat.stopGeneration();
    await _streamSub?.cancel();
    if (mounted) {
      setState(() {
        _isGenerating = false;
        _draft = null;
      });
    }
  }

  void _openSettings() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => ChatSettingsSheet(chat: _chat),
    );
  }

  @override
  Widget build(BuildContext context) {
    final phase = AmbientMotionScope.maybeOf(context)?.value ?? 0.0;
    final hubColors = HubAppColors.palette(_app, phase);
    final sessionId = _sessionId;

    return ChatAiGlowScope(
      child: LinkvaultAmbientScaffold(
      key: _scaffoldKey,
      drawer: _phase == _ChatUiPhase.ready
          ? ChatDrawer(
              chat: _chat,
              activeSessionId: sessionId,
              onSessionSelected: _switchSession,
              onNewChat: _newChat,
              onDeleteSession: _deleteSession,
            )
          : null,
      appBar: AppBar(
        leading: const HubAppBackButton(),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_app.name, style: Theme.of(context).textTheme.titleMedium),
            if (_backendLabel.isNotEmpty)
              Text(
                _backendLabel,
                style: LinkvaultTypography.meta(Theme.of(context).colorScheme)
                    .copyWith(color: hubColors.primary.withValues(alpha: 0.85)),
              ),
          ],
        ),
        actions: [
          if (_phase == _ChatUiPhase.ready) ...[
            ChatContextRing(
              usedTokens: _contextUsed,
              maxTokens: _contextMax,
              onTap: _compressChat,
            ),
            IconButton(
              tooltip: 'Chats',
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              icon: PhosphorIcon(PhosphorIcons.sidebarSimple),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'settings':
                    _openSettings();
                  case 'new':
                    _newChat();
                  case 'compress':
                    _compressChat();
                  case 'clear':
                    _clearSession();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'settings', child: Text('Model settings')),
                PopupMenuItem(value: 'new', child: Text('New chat')),
                PopupMenuItem(value: 'compress', child: Text('Compress chat')),
                PopupMenuItem(value: 'clear', child: Text('Clear messages')),
              ],
            ),
          ],
        ],
      ),
      body: switch (_phase) {
        _ChatUiPhase.checking || _ChatUiPhase.loading => Center(
            child: _GlowingLoader(phase: phase),
          ),
        _ChatUiPhase.needsDownload => _DownloadCard(
            onDownload: _downloadModel,
            error: _error,
          ),
        _ChatUiPhase.downloading => _DownloadingCard(progress: _downloadProgress),
        _ChatUiPhase.error => _ErrorCard(
            message: _error ?? 'Unknown error',
            onRetry: _bootstrap,
          ),
        _ChatUiPhase.ready when sessionId != null => Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    ChatAiEdgeAtmosphere(phase: phase),
                    StreamBuilder<List<ChatMessageModel>>(
                      stream: _chat.repository.watchMessages(sessionId),
                      builder: (context, snapshot) {
                        final messages = _visibleMessages(snapshot.data ?? []);
                        if (messages.isEmpty && !_isGenerating) {
                          return _ChatEmptyState(phase: phase);
                        }
                        return ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final msg = messages[index];
                            final draft = _draft;
                            final isPendingAssistant =
                                msg.id == 'pending-assistant' && _isGenerating;
                            final pendingTool = draft?.toolById(msg.id);
                            return ChatMessageTile(
                              message: msg,
                              pulsing: isPendingAssistant ||
                                  (msg.isThinking && _isGenerating) ||
                                  (pendingTool?.running ?? false),
                              toolLabel: msg.isTool
                                  ? _chat.toolLabel(msg.toolName ?? '')
                                  : null,
                              toolRunning: pendingTool?.running ?? false,
                              thinkingExpanded: _thinkingExpanded,
                              onThinkingToggle: msg.isThinking
                                  ? () => setState(
                                        () => _thinkingExpanded =
                                            !_thinkingExpanded,
                                      )
                                  : null,
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              ChatInputBar(
                controller: _inputController,
                onSend: _send,
                onStop: _stop,
                isGenerating: _isGenerating,
                enabled: true,
              ),
            ],
          ),
        _ => const SizedBox.shrink(),
      },
    ),
    );
  }
}

class _ChatEmptyState extends StatelessWidget {
  const _ChatEmptyState({required this.phase});

  final double phase;

  @override
  Widget build(BuildContext context) {
    final glow = ChatAiGlowColors.at(phase);
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: ChatAiGlowFrame(
          phase: phase,
          pulsing: true,
          intensity: 0.9,
          borderRadius: 24,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  PhosphorIcons.sparkle,
                  size: 36,
                  color: glow.primary.withValues(alpha: 0.95),
                ),
                const SizedBox(height: 16),
                Text(
                  'On-device AI',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: glow.secondary.withValues(alpha: 0.95),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ask anything — inference stays local. Tools can search the web or open links.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.65),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DownloadCard extends StatelessWidget {
  const _DownloadCard({required this.onDownload, this.error});

  final VoidCallback onDownload;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final phase = ChatAiGlowScope.phaseOf(context);
    final glow = ChatAiGlowColors.at(phase);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ChatAiGlowFrame(
          phase: phase,
          pulsing: true,
          intensity: 1,
          borderRadius: 24,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PhosphorIcon(
                  PhosphorIcons.robot,
                  size: 48,
                  color: glow.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Download Gemma 4 E2B',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  '~3 GB on-device model. Inference stays local; web is only used for tools.',
                  textAlign: TextAlign.center,
                ),
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: onDownload,
                  icon: PhosphorIcon(PhosphorIcons.downloadSimple),
                  label: const Text('Download model'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DownloadingCard extends StatelessWidget {
  const _DownloadingCard({required this.progress});

  final int progress;

  @override
  Widget build(BuildContext context) {
    final phase = ChatAiGlowScope.phaseOf(context);
    final glow = ChatAiGlowColors.at(phase);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ChatAiGlowFrame(
          phase: phase,
          pulsing: true,
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    value: progress > 0 ? progress / 100 : null,
                    color: glow.primary,
                    backgroundColor: glow.secondary.withValues(alpha: 0.2),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Downloading… $progress%'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlowingLoader extends StatelessWidget {
  const _GlowingLoader({required this.phase});

  final double phase;

  @override
  Widget build(BuildContext context) {
    final glow = ChatAiGlowColors.at(phase, pulse: 1);

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: glow.bubbleShadows(intensity: 1.1, pulse: 1),
      ),
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        color: glow.primary,
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
