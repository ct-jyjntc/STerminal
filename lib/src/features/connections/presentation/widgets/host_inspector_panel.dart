import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sterminal/src/l10n/l10n.dart';

import '../../../../domain/models/host.dart';
import '../../../vault/application/credential_providers.dart';
import '../../application/hosts_providers.dart';

class HostInspectorPanel extends ConsumerWidget {
  const HostInspectorPanel({
    super.key,
    required this.onConnect,
    required this.onEdit,
    required this.onDelete,
    required this.onCreate,
  });

  final void Function(Host host) onConnect;
  final void Function(Host host) onEdit;
  final void Function(Host host) onDelete;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedHostId = ref.watch(selectedHostProvider);
    if (selectedHostId == null) {
      return _EmptyInspector(onCreateTap: onCreate);
    }

    final hostAsync = ref.watch(hostByIdProvider(selectedHostId));
    return hostAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text(context.l10n.hostInspectorLoadError('$error')),
      ),
      data: (host) {
        if (host == null) {
          return const _EmptyInspector();
        }
        final credentialAsync =
            ref.watch(credentialByIdProvider(host.credentialId));
        return Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        host.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      onPressed: () => onDelete(host),
                      icon: const Icon(Icons.delete_outline),
                      tooltip: context.l10n.hostDeleteTooltip,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  host.description ?? context.l10n.hostNoDescription,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                credentialAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (error, _) => Text(
                    context.l10n.genericErrorMessage('$error'),
                  ),
                  data: (credential) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _InfoRow(context.l10n.hostInspectorEndpoint,
                            '${host.address}:${host.port.toString()}'),
                        const SizedBox(height: 8),
                        _InfoRow(
                          context.l10n.hostInspectorCredential,
                          credential == null
                              ? context.l10n.hostMissingCredential
                              : '${credential.name} (${credential.username})',
                        ),
                        const SizedBox(height: 8),
                        _InfoRow(
                          context.l10n.hostInspectorTags,
                          host.tags.isEmpty
                              ? context.l10n.hostNoTags
                              : host.tags.join(', '),
                        ),
                      ],
                    );
                  },
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => onConnect(host),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(context.l10n.hostConnect),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => onEdit(host),
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(context.l10n.hostEdit),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

}

class _EmptyInspector extends StatelessWidget {
  const _EmptyInspector({this.onCreateTap});

  final VoidCallback? onCreateTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.computer_rounded, size: 48),
            const SizedBox(height: 12),
            Text(context.l10n.hostInspectorEmpty),
            if (onCreateTap != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: FilledButton(
                  onPressed: onCreateTap,
                  child: Text(context.l10n.hostCreateButton),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withAlpha((0.6 * 255).round()),
                ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
