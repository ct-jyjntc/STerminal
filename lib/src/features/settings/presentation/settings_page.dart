import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sterminal/src/l10n/l10n.dart';

import 'package:sterminal/src/widgets/list_item_card.dart';
import '../application/settings_controller.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final l10n = context.l10n;

    final primaryColor = Theme.of(context).colorScheme.primary;
    final accent = Theme.of(context).colorScheme.secondary;
    final tertiary = Theme.of(context).colorScheme.tertiary;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              l10n.settingsTitle,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListItemCard(
              leading: l10n.settingsAppearance.characters.first.toUpperCase(),
              accentColor: primaryColor,
              title: l10n.settingsAppearance,
              subtitle: l10n.settingsThemeSystem,
              actions: [
                SizedBox(
                  width: 260,
                  child: SegmentedButton<ThemeMode>(
                    segments: [
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text(l10n.settingsThemeLight),
                        icon: const Icon(Icons.light_mode_outlined),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text(l10n.settingsThemeDark),
                        icon: const Icon(Icons.dark_mode_outlined),
                      ),
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text(l10n.settingsThemeSystem),
                        icon: const Icon(Icons.computer),
                      ),
                    ],
                    selected: {settings.themeMode},
                    onSelectionChanged: (selection) =>
                        controller.setThemeMode(selection.first),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListItemCard(
              leading: l10n.settingsSync.characters.first.toUpperCase(),
              accentColor: accent,
              title: l10n.settingsSync,
              subtitle: l10n.settingsSyncSubtitle,
              actions: [
                Switch.adaptive(
                  value: settings.syncEnabled,
                  onChanged: controller.toggleSync,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListItemCard(
              leading: l10n.settingsBiometric.characters.first.toUpperCase(),
              accentColor: tertiary,
              title: l10n.settingsBiometric,
              subtitle: l10n.settingsBiometricSubtitle,
              actions: [
                Switch.adaptive(
                  value: settings.biometricLock,
                  onChanged: controller.toggleBiometric,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListItemCard(
              leading: l10n.settingsConfirm.characters.first.toUpperCase(),
              accentColor: primaryColor,
              title: l10n.settingsConfirm,
              subtitle: l10n.settingsConfirmSubtitle,
              actions: [
                Switch.adaptive(
                  value: settings.confirmBeforeConnect,
                  onChanged: controller.toggleConfirmation,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListItemCard(
              leading: l10n.settingsExport.characters.first.toUpperCase(),
              accentColor: accent,
              title: l10n.settingsExport,
              subtitle: l10n.settingsExportSubtitle,
              actions: [
                IconButton(
                  tooltip: l10n.settingsExport,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.settingsExportComingSoon),
                      ),
                    );
                  },
                  icon: const Icon(Icons.download_outlined),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
