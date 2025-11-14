import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sterminal/src/l10n/l10n.dart';

import '../../../core/app_providers.dart';
import '../../../domain/models/group.dart';
import '../../../utils/color_utils.dart';

Future<void> showGroupFormSheet(
  BuildContext context, {
  HostGroup? group,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: GroupFormSheet(group: group),
    ),
  );
}

class GroupFormSheet extends ConsumerStatefulWidget {
  const GroupFormSheet({super.key, this.group});

  final HostGroup? group;

  @override
  ConsumerState<GroupFormSheet> createState() => _GroupFormSheetState();
}

class _GroupFormSheetState extends ConsumerState<GroupFormSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late String _colorHex;

  static const _colors = [
    '#4DD0E1',
    '#F06292',
    '#9575CD',
    '#AED581',
    '#FFB74D',
    '#4FC3F7',
  ];

  @override
  void initState() {
    super.initState();
    final group = widget.group;
    _nameController = TextEditingController(text: group?.name);
    _descriptionController = TextEditingController(text: group?.description);
    _colorHex = group?.colorHex ?? _colors.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  widget.group == null
                      ? l10n.groupFormTitleNew
                      : l10n.groupFormTitleEdit,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration:
                  InputDecoration(labelText: l10n.groupFormNameLabel),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration:
                  InputDecoration(labelText: l10n.groupFormDescriptionLabel),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              children: [
                for (final color in _colors)
                  GestureDetector(
                    onTap: () => setState(() => _colorHex = color),
                    child: Container(
                      height: 32,
                      width: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: parseColor(color),
                        border: Border.all(
                          color:
                              _colorHex == color ? Colors.white : Colors.black12,
                          width: _colorHex == color ? 3 : 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                child: Text(l10n.groupFormSave),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.groupFormValidation)),
      );
      return;
    }
    final repo = ref.read(groupsRepositoryProvider);
    final uuid = ref.read(uuidProvider);
    final group = widget.group?.copyWith(
          name: _nameController.text.trim(),
          colorHex: _colorHex,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        ) ??
        HostGroup(
          id: uuid.v4(),
          name: _nameController.text.trim(),
          colorHex: _colorHex,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        );
    await repo.upsert(group);
    if (!mounted) return;
    Navigator.of(context).pop();
  }
}
