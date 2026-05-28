import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../services/pin_service.dart';
import '../theme/app_motion.dart';

class PinPad extends StatefulWidget {
  const PinPad({
    super.key,
    required this.onCompleted,
    this.title = 'Enter PIN',
    this.subtitle,
  });

  final ValueChanged<String> onCompleted;
  final String title;
  final String? subtitle;

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  String _pin = '';

  void _addDigit(String digit) {
    if (_pin.length >= PinService.pinLength) return;
    HapticFeedback.lightImpact();
    setState(() => _pin += digit);
    if (_pin.length == PinService.pinLength) {
      widget.onCompleted(_pin);
    }
  }

  void _backspace() {
    if (_pin.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.title, style: theme.textTheme.titleLarge),
        if (widget.subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.subtitle!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(PinService.pinLength, (index) {
            final filled = index < _pin.length;
            return AnimatedContainer(
              duration: AppMotion.fast,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
              ),
            );
          }),
        ),
        const SizedBox(height: 24),
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
          ['', '0', 'back'],
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: row.map((key) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _PinKey(
                      label: key == 'back' ? null : key,
                      icon: key == 'back' ? PhosphorIcons.backspace : null,
                      onTap: key.isEmpty
                          ? null
                          : key == 'back'
                              ? _backspace
                              : () => _addDigit(key),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class _PinKey extends StatelessWidget {
  const _PinKey({this.label, this.icon, this.onTap});

  final String? label;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onTap == null
          ? Colors.transparent
          : Theme.of(context).colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 52,
          child: Center(
            child: icon != null
                ? PhosphorIcon(icon!, size: 22)
                : Text(
                    label ?? '',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
          ),
        ),
      ),
    );
  }
}
