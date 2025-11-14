import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sterminal/src/l10n/l10n.dart';

import '../../../core/app_providers.dart';
import '../../../domain/models/snippet.dart';

Future<void> showSnippetFormSheet(
  BuildContext context, {
  Snippet? snippet,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SnippetFormSheet(snippet: snippet),
    ),
  );
}

class SnippetFormSheet extends ConsumerStatefulWidget {
  const SnippetFormSheet({super.key, this.snippet});

  final Snippet? snippet;

  @override
  ConsumerState<SnippetFormSheet> createState() => _SnippetFormSheetState();
}

class _SnippetFormSheetState extends ConsumerState<SnippetFormSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _commandController;

  @override
  void initState() {
    super.initState();
    final snippet = widget.snippet;
    _titleController = TextEditingController(text: snippet?.title);
    _commandController = TextEditingController(text: snippet?.command);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _commandController.dispose();
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
                  widget.snippet == null
                      ? l10n.snippetFormTitleNew
                      : l10n.snippetFormTitleEdit,
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
              controller: _titleController,
              decoration:
                  InputDecoration(labelText: l10n.snippetFormTitleLabel),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _commandController,
              maxLines: 4,
              decoration:
                  InputDecoration(labelText: l10n.snippetFormCommandLabel),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                child: Text(l10n.snippetFormSave),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty ||
        _commandController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.snippetFormValidation)),
      );
      return;
    }
    final repo = ref.read(snippetsRepositoryProvider);
    final uuid = ref.read(uuidProvider);
    final snippet = widget.snippet?.copyWith(
          title: _titleController.text.trim(),
          command: _commandController.text,
        ) ??
        Snippet(
          id: uuid.v4(),
          title: _titleController.text.trim(),
          command: _commandController.text,
        );
    await repo.upsert(snippet);
    if (!mounted) return;
    Navigator.of(context).pop();
  }
}
