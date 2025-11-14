import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_providers.dart';
import '../../../domain/models/host.dart';

final hostsStreamProvider = StreamProvider<List<Host>>((ref) {
  return ref.watch(hostsRepositoryProvider).watchAll();
});

final hostSearchQueryProvider = StateProvider<String>((ref) => '');

final hostGroupFilterProvider = StateProvider<String?>((ref) => null);

final selectedHostProvider = StateProvider<String?>((ref) => null);

final filteredHostsProvider = Provider<AsyncValue<List<Host>>>((ref) {
  final hosts = ref.watch(hostsStreamProvider);
  final query = ref.watch(hostSearchQueryProvider).trim().toLowerCase();
  final groupFilter = ref.watch(hostGroupFilterProvider);

  return hosts.whenData((items) {
    return items
        .where((host) {
          final matchesQuery = query.isEmpty ||
              host.name.toLowerCase().contains(query) ||
              host.address.toLowerCase().contains(query) ||
              host.tags.any((tag) => tag.toLowerCase().contains(query));
          final matchesGroup = groupFilter == null ||
              groupFilter == host.groupId ||
              (groupFilter == 'ungrouped' && host.groupId == null);
          return matchesQuery && matchesGroup;
        })
        .toList(growable: false);
  });
});

final hostByIdProvider =
    StreamProvider.family<Host?, String>((ref, id) => ref.watch(hostsRepositoryProvider).watchById(id));
