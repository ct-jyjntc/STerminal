import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sterminal/l10n/app_localizations.dart';

import 'core/app_providers.dart';
import 'features/settings/application/settings_controller.dart';
import 'routing/app_router.dart';
import 'theme/app_theme.dart';

class SterminalApp extends ConsumerWidget {
  const SterminalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    ref.watch(bootstrapProvider);
    final settings = ref.watch(settingsControllerProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: settings.themeMode,
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => child ?? const SizedBox.shrink(),
    );
  }
}
