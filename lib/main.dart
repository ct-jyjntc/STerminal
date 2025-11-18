import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'src/app.dart';
import 'src/core/app_providers.dart';
import 'src/core/window_arguments.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (_isDesktopPlatform) {
    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions(
      titleBarStyle: TitleBarStyle.hidden,
      minimumSize: Size(900, 600),
      backgroundColor: Colors.transparent,
      windowButtonVisibility: false,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.setAsFrameless();
      await windowManager.setHasShadow(true);
      await windowManager.setResizable(true);
      await windowManager.setMovable(true);
      await windowManager.show();
      await windowManager.focus();
    });
  }
  final prefs = await SharedPreferences.getInstance();
  final windowArguments = _loadWindowArguments(args);

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

AppWindowArguments _loadWindowArguments(List<String> args) {
  if (!_isDesktopPlatform) {
    return const AppWindowArguments.main();
  }
  final encoded = _extractArgumentsFromArgs(args);
  if (encoded == null) {
    return const AppWindowArguments.main();
  }
  return AppWindowArguments.fromEncoded(encoded);
}

String? _extractArgumentsFromArgs(List<String> args) {
  if (args.isEmpty) return null;
  final multiWindowIndex = args.indexOf('multi_window');
  if (multiWindowIndex == -1) return null;
  final argumentIndex = multiWindowIndex + 2;
  if (argumentIndex >= args.length) return null;
  return args[argumentIndex];
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
