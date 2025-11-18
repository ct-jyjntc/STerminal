import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

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
      builder: (context, child) {
        final content = child ?? const SizedBox.shrink();
        if (!_isDesktopPlatform) return content;

        final colorScheme = Theme.of(context).colorScheme;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 18,
                spreadRadius: 0,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: DragToResizeArea(
            resizeEdgeSize: 8,
            child: Stack(
              children: [
                content,
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 24,
                  child: DragToMoveArea(child: SizedBox.expand()),
                ),
              ],
            ),
          ),
        );
      },
    );
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
}
