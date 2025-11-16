import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sterminal/src/l10n/l10n.dart';

import '../../../core/app_providers.dart';
import '../../connections/application/hosts_providers.dart';
import '../application/group_providers.dart';
import 'group_form_sheet.dart';
import '../../../widgets/list_item_card.dart';

class GroupsPage extends ConsumerWidget {
  const GroupsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final groups = ref.watch(groupsStreamProvider);
    final hosts = ref.watch(hostsStreamProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showGroupFormSheet(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.groupsNew),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.groupsTitle,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: groups.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) =>
                      Center(child: Text(l10n.genericErrorMessage('$error'))),
                  data: (groupItems) {
                    final hostCounts = <String, int>{};
                    final hostList = hosts.value ?? [];
                    for (final host in hostList) {
                      if (host.groupId != null) {
                        hostCounts[host.groupId!] =
                            (hostCounts[host.groupId!] ?? 0) + 1;
                      }
                    }
                    return ListView.separated(
                      itemCount: groupItems.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final group = groupItems[index];
                        final count = hostCounts[group.id] ?? 0;
                        final description =
                            group.description?.trim().isNotEmpty == true
                            ? group.description!
                            : l10n.groupsNoDescription;
                        final subtitle =
                            '${l10n.groupsHostCount(count)} • $description';
                        return ListItemCard(
                          title: group.name,
                          subtitle: subtitle,
                          onTap: () =>
                              showGroupFormSheet(context, group: group),
                          actions: [
                            IconButton(
                              onPressed: () =>
                                  showGroupFormSheet(context, group: group),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              onPressed: () =>
                                  _deleteGroup(context, ref, group.id),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
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

  Future<void> _deleteGroup(
    BuildContext context,
    WidgetRef ref,
    String groupId,
  ) async {
    final l10n = context.l10n;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.groupsDeleteTitle),
        content: Text(l10n.groupsDeleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final repo = ref.read(groupsRepositoryProvider);
    await repo.remove(groupId);
    final hostsRepo = ref.read(hostsRepositoryProvider);
    final hosts = hostsRepo.snapshot
        .where((host) => host.groupId == groupId)
        .map((host) => host.copyWith(groupId: null))
        .toList();
    await hostsRepo.upsertMany(hosts);
  }
}
