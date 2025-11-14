import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sterminal/src/l10n/l10n.dart';

import '../../../core/app_providers.dart';
import '../../../domain/models/credential.dart';
import '../application/credential_providers.dart';
import 'credential_form_sheet.dart';

class VaultPage extends ConsumerWidget {
  const VaultPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final credentials = ref.watch(credentialsStreamProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showCredentialFormSheet(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.vaultNew),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.vaultTitle,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: credentials.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) =>
                      Center(child: Text(l10n.genericErrorMessage('$error'))),
                  data: (items) {
                    if (items.isEmpty) {
                      return Center(child: Text(l10n.vaultEmpty));
                    }
                    return ListView.separated(
                      itemBuilder: (context, index) {
                        final credential = items[index];
                        final authLabel =
                            credential.authKind == CredentialAuthKind.password
                                ? l10n.credentialAuthPassword
                                : l10n.credentialAuthKeyPair;
                        return Card(
                          child: ListTile(
                            title: Text(credential.name),
                            subtitle: Text(
                              '${credential.username} • $authLabel',
                            ),
                            trailing: Wrap(
                              spacing: 8,
                              children: [
                                IconButton(
                                  onPressed: () =>
                                      showCredentialFormSheet(context, credential: credential),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      _deleteCredential(context, ref, credential.id),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemCount: items.length,
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

  Future<void> _deleteCredential(
    BuildContext context,
    WidgetRef ref,
    String credentialId,
  ) async {
    final l10n = context.l10n;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.vaultDeleteTitle),
        content: Text(l10n.vaultDeleteMessage),
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
    if (confirm != true) return;
    await ref.read(credentialsRepositoryProvider).remove(credentialId);
  }
}
