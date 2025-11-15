import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/app.dart';
import 'src/core/app_providers.dart';
import 'src/core/window_arguments.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final windowArguments = await _loadWindowArguments();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        windowArgumentsProvider.overrideWithValue(windowArguments),
      ],
      child: const SterminalApp(),
    ),
  );
}

Future<AppWindowArguments> _loadWindowArguments() async {
  if (!_isDesktopPlatform) {
    return const AppWindowArguments.main();
  }
  try {
    final controller = await WindowController.fromCurrentEngine();
    return AppWindowArguments.fromEncoded(controller.arguments);
  } catch (_) {
    return const AppWindowArguments.main();
  }
}

bool get _isDesktopPlatform {
  if (kIsWeb) return false;
  return switch (defaultTargetPlatform) {
    TargetPlatform.linux ||
    TargetPlatform.macOS ||
    TargetPlatform.windows => true,
    _ => false,
  };
}
