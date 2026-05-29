import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../ai/chat/chat_service.dart';
import '../../ai/models/chat_model_registry.dart';
import '../../ai/runtime/inference_backend.dart';

class ChatSettingsSheet extends StatefulWidget {
  const ChatSettingsSheet({super.key, required this.chat});

  final ChatService chat;

  @override
  State<ChatSettingsSheet> createState() => _ChatSettingsSheetState();
}

class _ChatSettingsSheetState extends State<ChatSettingsSheet> {
  late InferenceBackend _backend;
  final _tokenController = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _backend = widget.chat.backendPrefs.backend;
    _tokenController.text = widget.chat.hfTokenPrefs.token ?? '';
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _setBackend(InferenceBackend backend) async {
    setState(() => _backend = backend);
    await widget.chat.backendPrefs.setBackend(backend);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backend set to ${backend.label}. Reload chat to apply.')),
      );
    }
  }

  Future<void> _saveToken() async {
    await widget.chat.hfTokenPrefs.setToken(_tokenController.text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hugging Face token saved')),
      );
    }
  }

  Future<void> _deleteModel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete model?'),
        content: const Text(
          'This removes the downloaded weights from device storage. '
          'You will need to download again before chatting.',
        ),
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

    setState(() => _busy = true);
    try {
      await widget.chat.uninstallModel();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = ChatModelRegistry.defaultModel;
    final docsFuture = getApplicationDocumentsDirectory();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Chat settings', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            Text('Inference backend', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<InferenceBackend>(
              segments: const [
                ButtonSegment(value: InferenceBackend.gpu, label: Text('GPU')),
                ButtonSegment(value: InferenceBackend.cpu, label: Text('CPU')),
              ],
              selected: {_backend},
              onSelectionChanged: _busy
                  ? null
                  : (Set<InferenceBackend> value) => _setBackend(value.first),
            ),
            const SizedBox(height: 20),
            Text('Model', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text('${model.displayName} (${model.sizeLabel})'),
            const SizedBox(height: 20),
            Text('Hugging Face token', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            const Text(
              'Required for gated Gemma downloads. Create at huggingface.co/settings/tokens.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _tokenController,
              decoration: const InputDecoration(
                hintText: 'hf_…',
                isDense: true,
              ),
              obscureText: true,
              autocorrect: false,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: _saveToken, child: const Text('Save token')),
            ),
            const SizedBox(height: 12),
            FutureBuilder(
              future: docsFuture,
              builder: (context, snapshot) {
                final path = snapshot.data?.path ?? '…';
                return Text(
                  'App storage: $path',
                  style: Theme.of(context).textTheme.bodySmall,
                );
              },
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _busy ? null : _deleteModel,
              child: const Text('Delete downloaded model'),
            ),
          ],
        ),
      ),
    );
  }
}
