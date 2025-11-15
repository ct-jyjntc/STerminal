import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../data/credentials/credentials_repository.dart';
import '../data/groups/groups_repository.dart';
import '../data/hosts/hosts_repository.dart';
import '../data/snippets/snippets_repository.dart';
import '../domain/models/credential.dart';
import '../domain/models/group.dart';
import '../domain/models/host.dart';
import '../domain/models/snippet.dart';
import 'window_arguments.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences not initialized');
});

final windowArgumentsProvider = Provider<AppWindowArguments>((ref) {
  return const AppWindowArguments.main();
});

final uuidProvider = Provider<Uuid>((ref) => const Uuid());

final hostsRepositoryProvider = Provider<HostsRepository>((ref) {
  final repo = HostsRepository(prefs: ref.watch(sharedPreferencesProvider));
  ref.onDispose(repo.dispose);
  return repo;
});

final groupsRepositoryProvider = Provider<GroupsRepository>((ref) {
  final repo = GroupsRepository(prefs: ref.watch(sharedPreferencesProvider));
  ref.onDispose(repo.dispose);
  return repo;
});

final credentialsRepositoryProvider = Provider<CredentialsRepository>((ref) {
  final repo = CredentialsRepository(
    prefs: ref.watch(sharedPreferencesProvider),
  );
  ref.onDispose(repo.dispose);
  return repo;
});

final snippetsRepositoryProvider = Provider<SnippetsRepository>((ref) {
  final repo = SnippetsRepository(prefs: ref.watch(sharedPreferencesProvider));
  ref.onDispose(repo.dispose);
  return repo;
});

final bootstrapProvider = FutureProvider<void>((ref) async {
  // Ensure repositories are initialized; no default seed data on first launch.
  ref.read(hostsRepositoryProvider);
  ref.read(groupsRepositoryProvider);
  ref.read(credentialsRepositoryProvider);
  ref.read(snippetsRepositoryProvider);
});
