import 'package:file_selector/file_selector.dart' as file_selector;
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

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              l10n.settingsTitle,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
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
              leading: l10n.settingsMultiWindow.characters.first.toUpperCase(),
              accentColor: Theme.of(context).colorScheme.tertiary,
              title: l10n.settingsMultiWindow,
              subtitle: l10n.settingsMultiWindowSubtitle,
              actions: [
                Switch.adaptive(
                  value: settings.openConnectionsInNewWindow,
                  onChanged: controller.setOpenConnectionsInNewWindow,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListItemCard(
              leading: l10n.settingsDownloadPath.characters.first.toUpperCase(),
              accentColor: Theme.of(context).colorScheme.secondary,
              title: l10n.settingsDownloadPath,
              subtitle: (settings.downloadDirectory?.isNotEmpty ?? false)
                  ? settings.downloadDirectory!
                  : l10n.settingsDownloadPathUnset,
              actions: [
                if (settings.downloadDirectory?.isNotEmpty ?? false)
                  IconButton(
                    tooltip: l10n.settingsDownloadPathClear,
                    onPressed: () => controller.setDownloadDirectory(null),
                    icon: const Icon(Icons.close),
                  ),
                FilledButton.icon(
                  onPressed: () => _pickDownloadDirectory(controller),
                  icon: const Icon(Icons.folder_open),
                  label: Text(l10n.settingsDownloadPathChoose),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListItemCard(
              leading: l10n.settingsHistoryLimit.characters.first.toUpperCase(),
              accentColor: Theme.of(context).colorScheme.primaryContainer,
              title: l10n.settingsHistoryLimit,
              subtitle: l10n.settingsHistoryLimitSubtitle(
                settings.historyLimit,
              ),
              actions: [
                SizedBox(
                  width: 220,
                  child: Slider(
                    value: settings.historyLimit.toDouble(),
                    min: 10,
                    max: 200,
                    divisions: 19,
                    label: settings.historyLimit.toString(),
                    onChanged: (value) => controller.setHistoryLimit(
                      value.round().clamp(10, 200),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDownloadDirectory(SettingsController controller) async {
    final selected = await file_selector.getDirectoryPath();
    controller.setDownloadDirectory(selected);
  }
}
