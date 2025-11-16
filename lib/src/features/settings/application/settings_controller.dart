import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/app_providers.dart';

const _settingsKey = 'settings/v1';
const _undefined = Object();

class SettingsState {
  const SettingsState({
    required this.themeMode,
    required this.confirmBeforeConnect,
    this.downloadDirectory,
    this.historyLimit = 50,
    this.openConnectionsInNewWindow = false,
    this.terminalSidebarDefaultTab = TerminalSidebarDefaultTab.commands,
    this.terminalHighlightKeywords = const [],
  });

  final ThemeMode themeMode;
  final bool confirmBeforeConnect;
  final String? downloadDirectory;
  final int historyLimit;
  final bool openConnectionsInNewWindow;
  final TerminalSidebarDefaultTab terminalSidebarDefaultTab;
  final List<String> terminalHighlightKeywords;

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? confirmBeforeConnect,
    Object? downloadDirectory = _undefined,
    int? historyLimit,
    bool? openConnectionsInNewWindow,
    TerminalSidebarDefaultTab? terminalSidebarDefaultTab,
    List<String>? terminalHighlightKeywords,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      confirmBeforeConnect: confirmBeforeConnect ?? this.confirmBeforeConnect,
      downloadDirectory: downloadDirectory == _undefined
          ? this.downloadDirectory
          : downloadDirectory as String?,
      historyLimit: historyLimit ?? this.historyLimit,
      openConnectionsInNewWindow:
          openConnectionsInNewWindow ?? this.openConnectionsInNewWindow,
      terminalSidebarDefaultTab:
          terminalSidebarDefaultTab ?? this.terminalSidebarDefaultTab,
      terminalHighlightKeywords:
          terminalHighlightKeywords ?? this.terminalHighlightKeywords,
    );
  }

  Map<String, dynamic> toJson() => {
    'themeMode': themeMode.name,
    'confirmBeforeConnect': confirmBeforeConnect,
    'downloadDirectory': downloadDirectory,
    'historyLimit': historyLimit,
    'openConnectionsInNewWindow': openConnectionsInNewWindow,
    'terminalSidebarDefaultTab': terminalSidebarDefaultTab.name,
    'terminalHighlightKeywords': terminalHighlightKeywords,
  };

  factory SettingsState.fromJson(Map<String, dynamic> json) {
    final themeName = json['themeMode'] as String? ?? ThemeMode.dark.name;
    return SettingsState(
      themeMode: ThemeMode.values.firstWhere(
        (mode) => mode.name == themeName,
        orElse: () => ThemeMode.dark,
      ),
      confirmBeforeConnect: json['confirmBeforeConnect'] as bool? ?? true,
      downloadDirectory: json['downloadDirectory'] as String?,
      historyLimit: json['historyLimit'] as int? ?? 50,
      openConnectionsInNewWindow:
          json['openConnectionsInNewWindow'] as bool? ?? false,
      terminalSidebarDefaultTab: _parseSidebarDefaultTab(
        json['terminalSidebarDefaultTab'] as String?,
      ),
      terminalHighlightKeywords:
          (json['terminalHighlightKeywords'] as List<dynamic>? ?? const [])
              .whereType<String>()
              .where((keyword) => keyword.isNotEmpty)
              .toList(),
    );
  }

  static SettingsState defaults() => const SettingsState(
    themeMode: ThemeMode.dark,
    confirmBeforeConnect: true,
    downloadDirectory: null,
    historyLimit: 50,
    openConnectionsInNewWindow: false,
    terminalSidebarDefaultTab: TerminalSidebarDefaultTab.commands,
    terminalHighlightKeywords: [],
  );
}

class SettingsController extends StateNotifier<SettingsState> {
  SettingsController(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static SettingsState _load(SharedPreferences prefs) {
    final raw = prefs.getString(_settingsKey);
    if (raw == null) return SettingsState.defaults();
    return SettingsState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _persist();
  }

  void toggleConfirmation(bool value) {
    state = state.copyWith(confirmBeforeConnect: value);
    _persist();
  }

  void setDownloadDirectory(String? path) {
    state = state.copyWith(downloadDirectory: path);
    _persist();
  }

  void setHistoryLimit(int value) {
    state = state.copyWith(historyLimit: value);
    _persist();
  }

  void setOpenConnectionsInNewWindow(bool value) {
    state = state.copyWith(openConnectionsInNewWindow: value);
    _persist();
  }

  void setTerminalSidebarDefaultTab(TerminalSidebarDefaultTab value) {
    state = state.copyWith(terminalSidebarDefaultTab: value);
    _persist();
  }

  void setTerminalHighlightKeywords(List<String> value) {
    state = state.copyWith(
      terminalHighlightKeywords: value
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(),
    );
    _persist();
  }

  void replaceAll(SettingsState newState) {
    state = newState;
    _persist();
  }

  void _persist() {
    _prefs.setString(_settingsKey, jsonEncode(state.toJson()));
  }
}

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, SettingsState>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return SettingsController(prefs);
    });

enum TerminalSidebarDefaultTab { files, commands, history }

TerminalSidebarDefaultTab _parseSidebarDefaultTab(String? value) {
  return TerminalSidebarDefaultTab.values.firstWhere(
    (tab) => tab.name == value,
    orElse: () => TerminalSidebarDefaultTab.commands,
  );
}
