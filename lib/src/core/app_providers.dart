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

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences not initialized');
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
  final repo =
      CredentialsRepository(prefs: ref.watch(sharedPreferencesProvider));
  ref.onDispose(repo.dispose);
  return repo;
});

final snippetsRepositoryProvider = Provider<SnippetsRepository>((ref) {
  final repo = SnippetsRepository(prefs: ref.watch(sharedPreferencesProvider));
  ref.onDispose(repo.dispose);
  return repo;
});

final bootstrapProvider = FutureProvider<void>((ref) async {
  final uuid = ref.read(uuidProvider);
  final hostsRepo = ref.read(hostsRepositoryProvider);
  final groupsRepo = ref.read(groupsRepositoryProvider);
  final credentialsRepo = ref.read(credentialsRepositoryProvider);
  final snippetsRepo = ref.read(snippetsRepositoryProvider);

  if (groupsRepo.snapshot.isEmpty) {
    final defaultGroups = [
      HostGroup(
        id: uuid.v4(),
        name: 'Production',
        colorHex: '#F06292',
        icon: 'shield',
        description: 'Critical workloads',
      ),
      HostGroup(
        id: uuid.v4(),
        name: 'Staging',
        colorHex: '#4DD0E1',
        icon: 'lab',
        description: 'Pre-release environment',
      ),
    ];
    await groupsRepo.upsertMany(defaultGroups);
  }

  if (credentialsRepo.snapshot.isEmpty) {
    final defaultCredential = Credential(
      id: uuid.v4(),
      name: 'Demo root',
      username: 'root',
      authKind: CredentialAuthKind.password,
      password: 'changeme',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await credentialsRepo.upsert(defaultCredential);
  }

  if (hostsRepo.snapshot.isEmpty) {
    final defaultCredentialId = credentialsRepo.snapshot.first.id;
    await hostsRepo.upsert(
      Host(
        id: uuid.v4(),
        name: 'Demo Server',
        address: 'demo.server.local',
        port: 22,
        credentialId: defaultCredentialId,
        groupId: groupsRepo.snapshot.first.id,
        colorHex: '#4DD0E1',
        tags: const ['demo', 'linux'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        description: 'Sample endpoint to showcase UI',
      ),
    );
  }

  if (snippetsRepo.snapshot.isEmpty) {
    await snippetsRepo.upsertMany([
      Snippet(
        id: uuid.v4(),
        title: 'Update apt cache',
        command: 'sudo apt update && sudo apt upgrade',
        description: 'Keeps packages up to date',
        tags: const ['maintenance'],
      ),
      Snippet(
        id: uuid.v4(),
        title: 'Tail syslog',
        command: 'sudo tail -f /var/log/syslog',
      ),
    ]);
  }
});
