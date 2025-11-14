import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sterminal/src/l10n/l10n.dart';

import '../../../core/app_providers.dart';
import '../../../domain/models/group.dart';
import '../../../domain/models/host.dart';
import '../../../routing/app_route.dart';
import '../../groups/application/group_providers.dart';
import '../../settings/application/settings_controller.dart';
import '../../vault/application/credential_providers.dart';
import '../application/hosts_providers.dart';
import 'widgets/host_card.dart';
import 'widgets/host_form_sheet.dart';

class ConnectionsPage extends ConsumerWidget {
  const ConnectionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final hosts = ref.watch(filteredHostsProvider);
    final groups = ref.watch(groupsStreamProvider);
    final credentials = ref.watch(credentialsStreamProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showHostFormSheet(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.connectionsNewHost),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Toolbar(groupsAsync: groups),
              const SizedBox(height: 16),
              Expanded(
                child: hosts.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, _) => Center(
                    child: Text(l10n.connectionsLoadError('$error')),
                  ),
                  data: (hostItems) {
                    final credentialMap = {
                      for (final credential in credentials.value ?? [])
                        credential.id: credential,
                    };
                    return ListView.separated(
                      itemCount: hostItems.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final host = hostItems[index];
                        final credential = credentialMap[host.credentialId];
                        final subtitle =
                            '${credential?.username ?? l10n.credentialUnknownUser} @ ${host.address}:${host.port}';
                        final selectedHost = ref.watch(selectedHostProvider);
                        return HostCard(
                          host: host,
                          selected: selectedHost == host.id,
                          onTap: () =>
                              ref.read(selectedHostProvider.notifier).state =
                                  host.id,
                          onConnectRequested: () =>
                              _handleConnect(context, ref, host),
                          onEditRequested: () => showHostFormSheet(
                            context,
                            host: host,
                          ),
                          onDeleteRequested: () =>
                              _confirmDeleteHost(context, ref, host),
                          subtitle: subtitle,
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

  Future<void> _confirmDeleteHost(
    BuildContext context,
    WidgetRef ref,
    Host host,
  ) async {
    final l10n = context.l10n;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.hostDeleteTitle),
        content: Text(l10n.hostDeleteMessage(host.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final repo = ref.read(hostsRepositoryProvider);
      await repo.remove(host.id);
      final selectedNotifier = ref.read(selectedHostProvider.notifier);
      if (selectedNotifier.state == host.id) {
        selectedNotifier.state = null;
      }
    }
  }

  Future<void> _handleConnect(
    BuildContext context,
    WidgetRef ref,
    Host host,
  ) async {
    final allowed = await _maybeConfirmConnect(context, ref, host);
    if (!allowed) return;
    ref.read(selectedHostProvider.notifier).state = host.id;
    if (!context.mounted) return;
    context.pushNamed(
      AppRoute.terminal.name,
      pathParameters: {'hostId': host.id},
    );
  }

  Future<bool> _maybeConfirmConnect(
    BuildContext context,
    WidgetRef ref,
    Host host,
  ) async {
    final settings = ref.read(settingsControllerProvider);
    if (!settings.confirmBeforeConnect) {
      return true;
    }
    final l10n = context.l10n;
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.settingsConfirmDialogTitle(host.name)),
        content: Text(l10n.settingsConfirmDialogMessage(host.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.hostConnect),
          ),
        ],
      ),
    );
    return result == true;
  }
}

class _Toolbar extends ConsumerStatefulWidget {
  const _Toolbar({required this.groupsAsync});

  final AsyncValue<List<HostGroup>> groupsAsync;

  @override
  ConsumerState<_Toolbar> createState() => _ToolbarState();
}

class _ToolbarState extends ConsumerState<_Toolbar> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController =
        TextEditingController(text: ref.read(hostSearchQueryProvider));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final groupsAsync = widget.groupsAsync;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.connectionsTitle,
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: l10n.connectionsSearchHint,
                ),
                onChanged: (value) =>
                    ref.read(hostSearchQueryProvider.notifier).state = value,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        groupsAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (error, _) => Text(l10n.genericErrorMessage('$error')),
          data: (groupItems) {
            final selectedGroup = ref.watch(hostGroupFilterProvider);
            return Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: Text(l10n.filterAll),
                  selected: selectedGroup == null,
                  onSelected: (_) =>
                      ref.read(hostGroupFilterProvider.notifier).state = null,
                ),
                ChoiceChip(
                  label: Text(l10n.filterUngrouped),
                  selected: selectedGroup == 'ungrouped',
                  onSelected: (_) => ref
                      .read(hostGroupFilterProvider.notifier)
                      .state = 'ungrouped',
                ),
                for (final group in groupItems)
                  ChoiceChip(
                    label: Text(group.name),
                    selected: selectedGroup == group.id,
                    onSelected: (_) => ref
                        .read(hostGroupFilterProvider.notifier)
                        .state = group.id,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
