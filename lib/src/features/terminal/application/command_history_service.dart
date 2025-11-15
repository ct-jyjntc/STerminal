import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/app_providers.dart';

class CommandHistoryService {
  CommandHistoryService({required this.prefs});

  final SharedPreferences prefs;
  static const _key = 'terminal/history';

  List<String> load() {
    return prefs.getStringList(_key) ?? const [];
  }

  Future<void> save(List<String> history) async {
    await prefs.setStringList(_key, history);
  }

  Future<void> clear() async {
    await prefs.remove(_key);
  }
}

final commandHistoryServiceProvider = Provider<CommandHistoryService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return CommandHistoryService(prefs: prefs);
});
