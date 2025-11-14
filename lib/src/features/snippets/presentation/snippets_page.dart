import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sterminal/src/l10n/l10n.dart';

import '../../../core/app_providers.dart';
import '../../../domain/models/snippet.dart';
import '../application/snippet_providers.dart';
import 'snippet_form_sheet.dart';
import '../../../widgets/list_item_card.dart';

class SnippetsPage extends ConsumerWidget {
  const SnippetsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final snippets = ref.watch(snippetsStreamProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showSnippetFormSheet(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.snippetsNew),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.snippetsTitle,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: snippets.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) =>
                      Center(child: Text(l10n.genericErrorMessage('$error'))),
                  data: (snippetItems) {
                    if (snippetItems.isEmpty) {
                      return Center(child: Text(l10n.snippetsEmpty));
                    }
                    return ListView.separated(
                      itemCount: snippetItems.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final snippet = snippetItems[index];
                        return _SnippetRow(
                          snippet: snippet,
                          onEdit: () => showSnippetFormSheet(context, snippet: snippet),
                          onDelete: () => _confirmDelete(context, ref, snippet),
                          onCopy: () async {
                            await Clipboard.setData(
                              ClipboardData(text: snippet.command),
                            );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.snippetsCopyMessage)),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Snippet snippet,
  ) async {
    final l10n = context.l10n;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.snippetsDeleteTitle),
        content: Text(l10n.snippetsDeleteMessage(snippet.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(snippetsRepositoryProvider).remove(snippet.id);
    }
  }
}

class _SnippetRow extends StatelessWidget {
  const _SnippetRow({
    required this.snippet,
    required this.onCopy,
    required this.onEdit,
    required this.onDelete,
  });

  final Snippet snippet;
  final VoidCallback onCopy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return ListItemCard(
      leading: snippet.title.characters.first.toUpperCase(),
      accentColor: accent,
      title: snippet.title,
      subtitle: snippet.command,
      actions: [
        IconButton(
          onPressed: onCopy,
          icon: const Icon(Icons.copy_all_outlined),
        ),
        IconButton(
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
        ),
        IconButton(
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    );
  }
}
