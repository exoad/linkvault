import 'dart:async' show StreamSubscription, Timer, unawaited;

import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../ai/chat/chat_service.dart';
import '../../ai/runtime/local_llm_runtime.dart';
import '../../app_scope.dart';
import '../../hub/modules/chat_hub_module.dart';
import '../../models/chat_message.dart';
import '../../ui/linkvault_ui.dart';
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
    final confirmed = await showLinkvaultConfirmDialog(
      context: context,
      title: 'Delete chat?',
      message: 'This conversation will be removed from this device.',
      confirmLabel: 'Delete',
      destructive: true,
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
    final confirmed = await showLinkvaultConfirmDialog(
      context: context,
      title: 'Compress conversation?',
      message:
          'Older messages are merged into a short summary. '
          'The last 8 turns stay intact to free context.',
      confirmLabel: 'Compress',
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
    final confirmed = await showLinkvaultConfirmDialog(
      context: context,
      title: 'Clear conversation?',
      message: 'Messages in this chat will be removed from this device.',
      confirmLabel: 'Clear',
      destructive: true,
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
    showAppBottomSheet<void>(
      context: context,
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
        _ChatUiPhase.checking || _ChatUiPhase.loading => LinkvaultHubLoader(
            app: _app,
          ),
        _ChatUiPhase.needsDownload => LinkvaultHubPanel(
            app: _app,
            icon: PhosphorIcons.robot,
            title: 'Download Gemma 4 E2B',
            subtitle:
                '~2.6 GB on-device model. Inference stays local; web is only used for tools.',
            errorMessage: _error,
            primaryAction: FilledButton.icon(
              onPressed: _downloadModel,
              icon: PhosphorIcon(PhosphorIcons.downloadSimple),
              label: const Text('Download model'),
            ),
          ),
        _ChatUiPhase.downloading => LinkvaultHubPanel(
            app: _app,
            icon: PhosphorIcons.downloadSimple,
            title: 'Downloading… $_downloadProgress%',
            child: Builder(
              builder: (context) {
                final hub = HubAppColors.palette(_app, phase);
                return SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    value: _downloadProgress > 0 ? _downloadProgress / 100 : null,
                    color: hub.primary,
                    backgroundColor: hub.secondary.withValues(alpha: 0.2),
                  ),
                );
              },
            ),
          ),
        _ChatUiPhase.error => LinkvaultHubPanel(
            app: _app,
            icon: PhosphorIcons.warningCircle,
            title: 'Something went wrong',
            subtitle: _error ?? 'Unknown error',
            primaryAction: FilledButton(
              onPressed: _bootstrap,
              child: const Text('Retry'),
            ),
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
                          return LinkvaultHubPanel(
                            app: _app,
                            icon: PhosphorIcons.sparkle,
                            title: 'On-device AI',
                            subtitle:
                                'Ask anything — inference stays local. '
                                'Tools can search the web or open links.',
                          );
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
