import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_providers.dart';
import '../../../domain/models/credential.dart';
import '../../../domain/models/group.dart';
import '../../../domain/models/host.dart';
import '../../../domain/models/snippet.dart';
import '../../terminal/application/command_history_service.dart';
import 'settings_controller.dart';

class BackupService {
  BackupService(this._ref);

  final Ref _ref;

  Future<String> exportAll() async {
    final hosts = _ref.read(hostsRepositoryProvider).snapshot;
    final credentials = _ref.read(credentialsRepositoryProvider).snapshot;
    final groups = _ref.read(groupsRepositoryProvider).snapshot;
    final snippets = _ref.read(snippetsRepositoryProvider).snapshot;
    final settings = _ref.read(settingsControllerProvider);
    final history = _ref.read(commandHistoryServiceProvider).load();

    final payload = _BackupPayload(
      hosts: hosts,
      credentials: credentials,
      groups: groups,
      snippets: snippets,
      settings: settings,
      commandHistory: history,
    );
    return jsonEncode(payload.toJson());
  }

  Future<void> importAll(String rawJson) async {
    final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
    final payload = _BackupPayload.fromJson(decoded);

    final hostsRepo = _ref.read(hostsRepositoryProvider);
    final credentialsRepo = _ref.read(credentialsRepositoryProvider);
    final groupsRepo = _ref.read(groupsRepositoryProvider);
    final snippetsRepo = _ref.read(snippetsRepositoryProvider);
    final settingsController = _ref.read(settingsControllerProvider.notifier);
    final historyService = _ref.read(commandHistoryServiceProvider);

    await groupsRepo.clear();
    await credentialsRepo.clear();
    await hostsRepo.clear();
    await snippetsRepo.clear();
    await historyService.clear();

    if (payload.groups.isNotEmpty) {
      await groupsRepo.upsertMany(payload.groups);
    }
    if (payload.credentials.isNotEmpty) {
      await credentialsRepo.upsertMany(payload.credentials);
    }
    if (payload.hosts.isNotEmpty) {
      await hostsRepo.upsertMany(payload.hosts);
    }
    if (payload.snippets.isNotEmpty) {
      await snippetsRepo.upsertMany(payload.snippets);
    }
    if (payload.commandHistory.isNotEmpty) {
      await historyService.save(payload.commandHistory);
    }
    settingsController.replaceAll(payload.settings);
  }
}

class _BackupPayload {
  const _BackupPayload({
    required this.hosts,
    required this.credentials,
    required this.groups,
    required this.snippets,
    required this.settings,
    required this.commandHistory,
  });

  final List<Host> hosts;
  final List<Credential> credentials;
  final List<HostGroup> groups;
  final List<Snippet> snippets;
  final SettingsState settings;
  final List<String> commandHistory;

  Map<String, dynamic> toJson() => {
        'version': 1,
        'hosts': hosts.map((e) => e.toJson()).toList(),
        'credentials': credentials.map((e) => e.toJson()).toList(),
        'groups': groups.map((e) => e.toJson()).toList(),
        'snippets': snippets.map((e) => e.toJson()).toList(),
        'settings': settings.toJson(),
        'commandHistory': commandHistory,
      };

  factory _BackupPayload.fromJson(Map<String, dynamic> json) {
    List<T> parseList<T>(
      String key,
      T Function(Map<String, dynamic>) decoder,
    ) {
      final values = json[key];
      if (values is! List) return const [];
      return values
          .whereType<Map>()
          .map((item) => decoder(item.cast<String, dynamic>()))
          .toList();
    }

    final settingsJson = json['settings'];
    final settings = settingsJson is Map<String, dynamic>
        ? SettingsState.fromJson(settingsJson)
        : SettingsState.defaults();

    return _BackupPayload(
      hosts: parseList('hosts', Host.fromJson),
      credentials: parseList('credentials', Credential.fromJson),
      groups: parseList('groups', HostGroup.fromJson),
      snippets: parseList('snippets', Snippet.fromJson),
      settings: settings,
      commandHistory: (json['commandHistory'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
    );
  }
}

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(ref);
});
