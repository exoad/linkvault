import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../../ai/chat/chat_service.dart';
import '../../ai/models/chat_model_registry.dart';
import '../../ai/runtime/inference_backend.dart';
import '../../ui/linkvault_ui.dart';

class ChatSettingsSheet extends StatefulWidget {
  const ChatSettingsSheet({super.key, required this.chat});

  final ChatService chat;

  @override
  State<ChatSettingsSheet> createState() => _ChatSettingsSheetState();
}

class _ChatSettingsSheetState extends State<ChatSettingsSheet> {
  late InferenceBackend _backend;
  late double _temperature;
  late double _topP;
  late double _topK;
  late double _maxOutput;
  late double _contextLimit;
  final _tokenController = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final prefs = widget.chat.inferencePrefs;
    _backend = widget.chat.backendPrefs.backend;
    _temperature = prefs.temperature;
    _topP = prefs.topP;
    _topK = prefs.topK.toDouble();
    _maxOutput = prefs.maxOutputTokens.toDouble();
    _contextLimit = prefs.contextTokenLimit.toDouble();
    _tokenController.text = widget.chat.hfTokenPrefs.token ?? '';
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _persistInference() async {
    final prefs = widget.chat.inferencePrefs;
    await prefs.setTemperature(_temperature);
    await prefs.setTopP(_topP);
    await prefs.setTopK(_topK.round());
    await prefs.setMaxOutputTokens(_maxOutput.round());
    await prefs.setContextTokenLimit(_contextLimit.round());
    await widget.chat.applyInferenceSettings();
  }

  Future<void> _setBackend(InferenceBackend backend) async {
    setState(() => _backend = backend);
    await widget.chat.backendPrefs.setBackend(backend);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backend: ${backend.label}. Reloading…')),
      );
    }
    try {
      await widget.chat.ensureModelReady();
      if (mounted) {
        setState(() => _backend = widget.chat.backendPrefs.backend);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reload failed: $e')),
        );
      }
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
    final confirmed = await showLinkvaultConfirmDialog(
      context: context,
      title: 'Delete model?',
      message:
          'Removes on-device weights. You will need to download again before chatting.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !mounted) return;

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

    return LinkvaultSheetBody(
      title: 'Model & inference',
      children: [
        SettingsGroup(
          title: 'Backend',
          children: [
            LinkvaultSheetTile(
              child: SegmentedButton<InferenceBackend>(
                segments: const [
                  ButtonSegment(value: InferenceBackend.gpu, label: Text('GPU')),
                  ButtonSegment(value: InferenceBackend.cpu, label: Text('CPU')),
                ],
                selected: {_backend},
                onSelectionChanged: _busy
                    ? null
                    : (value) => _setBackend(value.first),
              ),
            ),
          ],
        ),
        SizedBox(height: LinkvaultDesign.spaceXl),
        SettingsGroup(
          title: 'Sampling',
          children: [
            LinkvaultSheetTile(
              child: LinkvaultSliderTile(
                label: 'Temperature',
                value: _temperature,
                min: 0.1,
                max: 2.0,
                divisions: 19,
                display: _temperature.toStringAsFixed(2),
                onChanged: _busy ? null : (v) => setState(() => _temperature = v),
                onChangeEnd: (_) => _persistInference(),
              ),
            ),
            LinkvaultSheetTile(
              child: LinkvaultSliderTile(
                label: 'Top P',
                value: _topP,
                min: 0.05,
                max: 1.0,
                divisions: 19,
                display: _topP.toStringAsFixed(2),
                onChanged: _busy ? null : (v) => setState(() => _topP = v),
                onChangeEnd: (_) => _persistInference(),
              ),
            ),
            LinkvaultSheetTile(
              child: LinkvaultSliderTile(
                label: 'Top K',
                value: _topK,
                min: 1,
                max: 128,
                divisions: 127,
                display: _topK.round().toString(),
                onChanged: _busy ? null : (v) => setState(() => _topK = v),
                onChangeEnd: (_) => _persistInference(),
              ),
            ),
            LinkvaultSheetTile(
              child: LinkvaultSliderTile(
                label: 'Max output tokens',
                value: _maxOutput,
                min: 64,
                max: 2048,
                divisions: 20,
                display: _maxOutput.round().toString(),
                onChanged: _busy ? null : (v) => setState(() => _maxOutput = v),
                onChangeEnd: (_) => _persistInference(),
              ),
            ),
            LinkvaultSheetTile(
              child: LinkvaultSliderTile(
                label: 'Context limit',
                value: _contextLimit,
                min: 2048,
                max: 16384,
                divisions: 14,
                display: _contextLimit.round().toString(),
                onChanged: _busy ? null : (v) => setState(() => _contextLimit = v),
                onChangeEnd: (_) => _persistInference(),
              ),
            ),
          ],
        ),
        SizedBox(height: LinkvaultDesign.spaceXl),
        SettingsGroup(
          title: 'Model',
          children: [
            LinkvaultSheetTile(
              child: Text('${model.displayName} (${model.sizeLabel})'),
            ),
          ],
        ),
        SizedBox(height: LinkvaultDesign.spaceXl),
        SettingsGroup(
          title: 'Download',
          children: [
            LinkvaultSheetTile(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _tokenController,
                    decoration: const InputDecoration(
                      hintText: 'hf_… (optional)',
                      isDense: true,
                    ),
                    obscureText: true,
                    autocorrect: false,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _saveToken,
                      child: const Text('Save token'),
                    ),
                  ),
                  FutureBuilder(
                    future: docsFuture,
                    builder: (context, snapshot) {
                      return Text(
                        'Storage: ${snapshot.data?.path ?? '…'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      );
                    },
                  ),
                ],
              ),
            ),
            LinkvaultSheetTile(
              child: OutlinedButton(
                onPressed: _busy ? null : _deleteModel,
                child: const Text('Delete downloaded model'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
