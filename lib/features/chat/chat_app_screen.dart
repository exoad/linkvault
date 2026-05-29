import 'dart:async';

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
import 'chat_input_bar.dart';
import 'chat_message_tile.dart';
import 'chat_settings_sheet.dart';

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
  final List<ChatMessageModel> _pendingMessages = [];

  ChatService get _chat => AppScope.chatServiceOf(context);

  @override
  void initState() {
    super.initState();
    _inputController.addListener(() => setState(() {}));
    _bootstrap();
  }

  @override
  void dispose() {
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

  Future<void> _openReadySession() async {
    setState(() => _phase = _ChatUiPhase.loading);

    try {
      var sessionId = _sessionId;
      sessionId ??= await _chat.createSession();
      await _chat.prepareSession(sessionId);
      if (!mounted) return;
      setState(() {
        _sessionId = sessionId;
        _phase = _ChatUiPhase.ready;
        _backendLabel = _chat.backendStatusLabel;
        _pendingMessages.clear();
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
    await _chat.prepareSession(sessionId);
    if (!mounted) return;
    setState(() {
      _sessionId = sessionId;
      _pendingMessages.clear();
      _isGenerating = false;
    });
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
      _pendingMessages.clear();
      _isGenerating = false;
    });
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
    setState(() => _isGenerating = true);

    final pendingAssistant = ChatMessageModel(
      id: 'pending-assistant',
      sessionId: sessionId,
      role: ChatMessageRole.assistant,
      content: '',
      createdAt: DateTime.now(),
    );

    setState(() {
      _pendingMessages
        ..clear()
        ..add(pendingAssistant);
    });
    _scrollToBottom();

    var assistantText = '';
    await _streamSub?.cancel();
    _streamSub = _chat.sendMessage(sessionId: sessionId, text: text).listen(
      (event) {
        if (!mounted) return;
        switch (event) {
          case LlmTokenEvent(:final token):
            assistantText += token;
            setState(() {
              _pendingMessages[0] = ChatMessageModel(
                id: pendingAssistant.id,
                sessionId: sessionId,
                role: ChatMessageRole.assistant,
                content: assistantText,
                createdAt: pendingAssistant.createdAt,
              );
            });
            _scrollToBottom();
          case LlmToolCallEvent(:final name, :final argsSummary):
            setState(() {
              _pendingMessages.add(
                ChatMessageModel(
                  id: 'pending-tool-${_pendingMessages.length}',
                  sessionId: sessionId,
                  role: ChatMessageRole.tool,
                  content: argsSummary,
                  toolName: name,
                  createdAt: DateTime.now(),
                ),
              );
            });
          case LlmDoneEvent():
            setState(() {
              _pendingMessages.clear();
              _isGenerating = false;
            });
          case LlmErrorEvent(:final message):
            if (assistantText.isEmpty) {
              assistantText = message;
            }
            setState(() {
              _pendingMessages.clear();
              _isGenerating = false;
            });
        }
      },
      onError: (Object e) {
        if (!mounted) return;
        setState(() {
          _pendingMessages.clear();
          _isGenerating = false;
          _error = e.toString();
        });
      },
      onDone: () {
        if (!mounted) return;
        setState(() => _isGenerating = false);
      },
    );
  }

  Future<void> _stop() async {
    await _chat.stopGeneration();
    await _streamSub?.cancel();
    if (mounted) {
      setState(() {
        _isGenerating = false;
        _pendingMessages.clear();
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

    return LinkvaultAmbientScaffold(
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
          if (_phase == _ChatUiPhase.ready)
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'settings':
                    _openSettings();
                  case 'new':
                    _newChat();
                  case 'clear':
                    _clearSession();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'settings', child: Text('Settings')),
                PopupMenuItem(value: 'new', child: Text('New chat')),
                PopupMenuItem(value: 'clear', child: Text('Clear session')),
              ],
            ),
        ],
      ),
      body: switch (_phase) {
        _ChatUiPhase.checking || _ChatUiPhase.loading => const Center(
            child: CircularProgressIndicator(),
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
                child: StreamBuilder<List<ChatMessageModel>>(
                  stream: _chat.repository.watchMessages(sessionId),
                  builder: (context, snapshot) {
                    final messages = [
                      ...?snapshot.data,
                      ..._pendingMessages,
                    ];
                    if (messages.isEmpty && !_isGenerating) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Ask anything — runs on-device. Tools can search the web or open links.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        return ChatMessageTile(message: messages[index]);
                      },
                    );
                  },
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
    );
  }
}

class _DownloadCard extends StatelessWidget {
  const _DownloadCard({required this.onDownload, this.error});

  final VoidCallback onDownload;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(PhosphorIcons.robot, size: 48),
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
              Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
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
    );
  }
}

class _DownloadingCard extends StatelessWidget {
  const _DownloadingCard({required this.progress});

  final int progress;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(value: progress > 0 ? progress / 100 : null),
            const SizedBox(height: 16),
            Text('Downloading… $progress%'),
          ],
        ),
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
