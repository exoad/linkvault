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
        SnackBar(content: Text('Backend: ${backend.label}. Reloading model…')),
      );
    }
    try {
      await widget.chat.ensureModelReady();
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete model?'),
        content: const Text(
          'Removes on-device weights. Download again before chatting.',
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Model & inference', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 20),
              Text('Backend', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              SegmentedButton<InferenceBackend>(
                segments: const [
                  ButtonSegment(value: InferenceBackend.gpu, label: Text('GPU')),
                  ButtonSegment(value: InferenceBackend.cpu, label: Text('CPU')),
                ],
                selected: {_backend},
                onSelectionChanged: _busy
                    ? null
                    : (value) => _setBackend(value.first),
              ),
              const SizedBox(height: 20),
              _SliderRow(
                label: 'Temperature',
                value: _temperature,
                min: 0.1,
                max: 2.0,
                divisions: 19,
                display: _temperature.toStringAsFixed(2),
                onChanged: _busy
                    ? null
                    : (v) => setState(() => _temperature = v),
                onChangeEnd: (_) => _persistInference(),
              ),
              _SliderRow(
                label: 'Top P',
                value: _topP,
                min: 0.05,
                max: 1.0,
                divisions: 19,
                display: _topP.toStringAsFixed(2),
                onChanged: _busy ? null : (v) => setState(() => _topP = v),
                onChangeEnd: (_) => _persistInference(),
              ),
              _SliderRow(
                label: 'Top K',
                value: _topK,
                min: 1,
                max: 128,
                divisions: 127,
                display: _topK.round().toString(),
                onChanged: _busy ? null : (v) => setState(() => _topK = v),
                onChangeEnd: (_) => _persistInference(),
              ),
              _SliderRow(
                label: 'Max output tokens',
                value: _maxOutput,
                min: 64,
                max: 2048,
                divisions: 20,
                display: _maxOutput.round().toString(),
                onChanged: _busy ? null : (v) => setState(() => _maxOutput = v),
                onChangeEnd: (_) => _persistInference(),
              ),
              _SliderRow(
                label: 'Context limit',
                value: _contextLimit,
                min: 2048,
                max: 16384,
                divisions: 14,
                display: _contextLimit.round().toString(),
                onChanged: _busy
                    ? null
                    : (v) => setState(() => _contextLimit = v),
                onChangeEnd: (_) => _persistInference(),
              ),
              const SizedBox(height: 16),
              Text('Model', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text('${model.displayName} (${model.sizeLabel})'),
              const SizedBox(height: 20),
              Text('Hugging Face token', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              const Text(
                'Optional for gated downloads.',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _tokenController,
                decoration: const InputDecoration(hintText: 'hf_…', isDense: true),
                obscureText: true,
                autocorrect: false,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: _saveToken, child: const Text('Save token')),
              ),
              FutureBuilder(
                future: docsFuture,
                builder: (context, snapshot) {
                  final path = snapshot.data?.path ?? '…';
                  return Text(
                    'Storage: $path',
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
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.display,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String display;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(label, style: Theme.of(context).textTheme.titleSmall),
            const Spacer(),
            Text(display, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
          onChangeEnd: onChangeEnd,
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}
