import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../animations/animated_sheet.dart';
import '../../app_scope.dart';
import '../../data/bookmark_repository.dart';
import '../../models/folder.dart';
import '../../theme/folder_color_palette.dart';
import '../../theme/phosphor_icon_registry.dart';
import '../../widgets/phosphor_app_icon.dart';
import '../../widgets/pin_pad.dart';

class FolderEditorResult {
  const FolderEditorResult._({
    required this.upsert,
    this.isEdit = false,
    this.folderId,
  });

  final FolderUpsert upsert;
  final bool isEdit;
  final String? folderId;

  factory FolderEditorResult.create(FolderUpsert upsert) =>
      FolderEditorResult._(upsert: upsert);

  factory FolderEditorResult.edit({
    required String folderId,
    required FolderUpsert upsert,
  }) =>
      FolderEditorResult._(upsert: upsert, isEdit: true, folderId: folderId);
}

Future<FolderEditorResult?> showFolderEditorSheet(
  BuildContext context, {
  FolderModel? existing,
}) {
  return showAppBottomSheet<FolderEditorResult>(
    context: context,
    builder: (context) => FolderEditorSheet(existing: existing),
  );
}

class FolderEditorSheet extends StatefulWidget {
  const FolderEditorSheet({super.key, this.existing});

  final FolderModel? existing;

  @override
  State<FolderEditorSheet> createState() => _FolderEditorSheetState();
}

class _FolderEditorSheetState extends State<FolderEditorSheet> {
  late final TextEditingController _nameController;
  late Color _selectedColor;
  late String _selectedIcon;
  late bool _lockEnabled;
  String? _newPin;
  String? _confirmPin;
  bool _pinStepConfirm = false;
  String _iconQuery = '';

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _selectedColor = existing?.color ?? const Color(FolderModel.defaultColorValue);
    _selectedIcon = existing?.iconName ?? FolderModel.defaultIconName;
    _lockEnabled = existing?.isLocked ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  List<String> get _filteredIcons {
    final q = _iconQuery.trim().toLowerCase();
    if (q.isEmpty) {
      return PhosphorIconRegistry.allNames.take(120).toList();
    }
    return PhosphorIconRegistry.allNames
        .where((name) => name.toLowerCase().contains(q))
        .take(120)
        .toList();
  }

  void _onPinEntered(String pin) {
    if (!_pinStepConfirm) {
      setState(() {
        _newPin = pin;
        _pinStepConfirm = true;
      });
      return;
    }
    setState(() {
      _confirmPin = pin;
      if (_newPin != _confirmPin) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PINs do not match. Try again.')),
        );
        _newPin = null;
        _confirmPin = null;
        _pinStepConfirm = false;
      }
    });
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    if (_lockEnabled && (_isEdit ? widget.existing!.hasPin == false : true)) {
      if (_newPin == null || _newPin != _confirmPin) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Set and confirm a 4-digit PIN')),
        );
        return;
      }
    }

    final upsert = FolderUpsert(
      name: name,
      colorValue: _selectedColor.toARGB32(),
      iconName: _selectedIcon,
      enableLock: _lockEnabled,
      pin: _newPin,
      removeLock: _isEdit && !_lockEnabled && widget.existing!.hasPin,
    );

    if (_isEdit) {
      Navigator.pop(
        context,
        FolderEditorResult.edit(folderId: widget.existing!.id, upsert: upsert),
      );
    } else {
      Navigator.pop(context, FolderEditorResult.create(upsert));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final showPinSetup = _lockEnabled &&
        (!_isEdit || !(widget.existing?.hasPin ?? false)) &&
        _newPin != _confirmPin;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEdit ? 'Edit folder' : 'New folder',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              autofocus: !showPinSetup,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text('Color', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: FolderColorPalette.choices.map((color) {
                final selected = color.toARGB32() == _selectedColor.toARGB32();
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        width: selected ? 3 : 1,
                        color: selected
                            ? Theme.of(context).colorScheme.onSurface
                            : Colors.transparent,
                      ),
                    ),
                    child: selected
                        ? PhosphorIcon(
                            PhosphorIcons.checkBold,
                            color: Colors.white,
                            size: 18,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Search icons',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _iconQuery = v),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 160,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                itemCount: _filteredIcons.length,
                itemBuilder: (context, index) {
                  final name = _filteredIcons[index];
                  final selected = name == _selectedIcon;
                  return InkWell(
                    onTap: () => setState(() => _selectedIcon = name),
                    borderRadius: BorderRadius.circular(8),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: selected
                            ? _selectedColor.withValues(alpha: 0.2)
                            : null,
                        borderRadius: BorderRadius.circular(8),
                        border: selected
                            ? Border.all(color: _selectedColor, width: 2)
                            : null,
                      ),
                      child: PhosphorAppIcon(
                        name,
                        color: selected
                            ? _selectedColor
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),
            if (!_isEdit || !widget.existing!.isSystem) ...[
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Lock with 4-digit PIN'),
                subtitle: const Text('Require PIN to open this folder'),
                secondary: PhosphorIcon(PhosphorIcons.lock),
                value: _lockEnabled,
                onChanged: (v) => setState(() {
                  _lockEnabled = v;
                  _newPin = null;
                  _confirmPin = null;
                  _pinStepConfirm = false;
                }),
              ),
            ],
            if (showPinSetup) ...[
              const SizedBox(height: 8),
              PinPad(
                title: _pinStepConfirm ? 'Confirm PIN' : 'Create PIN',
                subtitle: widget.existing?.name,
                onCompleted: _onPinEntered,
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _save,
              child: Text(_isEdit ? 'Save' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> showUnlockFolderSheet(
  BuildContext context, {
  required FolderModel folder,
}) async {
  var attempts = 0;
  final repo = AppScope.of(context);

  final unlocked = await showAppBottomSheet<bool>(
    context: context,
    builder: (sheetContext) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: PinPad(
          title: 'Unlock folder',
          subtitle: folder.name,
          onCompleted: (pin) async {
            final ok = await repo.unlockFolder(folder.id, pin);
            if (!sheetContext.mounted) return;
            if (ok) {
              Navigator.pop(sheetContext, true);
            } else {
              attempts++;
              ScaffoldMessenger.of(sheetContext).showSnackBar(
                SnackBar(
                  content: Text(
                    attempts >= 3
                        ? 'Incorrect PIN. Try again later.'
                        : 'Incorrect PIN',
                  ),
                ),
              );
            }
          },
        ),
      );
    },
  );

  return unlocked ?? false;
}
