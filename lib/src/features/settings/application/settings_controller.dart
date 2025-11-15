import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/app_providers.dart';

const _settingsKey = 'settings/v1';

class SettingsState {
  const SettingsState({
    required this.themeMode,
    required this.confirmBeforeConnect,
    this.downloadDirectory,
    this.historyLimit = 50,
    this.openConnectionsInNewWindow = false,
  });

  final ThemeMode themeMode;
  final bool confirmBeforeConnect;
  final String? downloadDirectory;
  final int historyLimit;
  final bool openConnectionsInNewWindow;

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? confirmBeforeConnect,
    String? downloadDirectory,
    int? historyLimit,
    bool? openConnectionsInNewWindow,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      confirmBeforeConnect: confirmBeforeConnect ?? this.confirmBeforeConnect,
      downloadDirectory: downloadDirectory ?? this.downloadDirectory,
      historyLimit: historyLimit ?? this.historyLimit,
      openConnectionsInNewWindow:
          openConnectionsInNewWindow ?? this.openConnectionsInNewWindow,
    );
  }

  Map<String, dynamic> toJson() => {
    'themeMode': themeMode.name,
    'confirmBeforeConnect': confirmBeforeConnect,
    'downloadDirectory': downloadDirectory,
    'historyLimit': historyLimit,
    'openConnectionsInNewWindow': openConnectionsInNewWindow,
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
    );
  }

  static SettingsState defaults() => const SettingsState(
    themeMode: ThemeMode.dark,
    confirmBeforeConnect: true,
    downloadDirectory: null,
    historyLimit: 50,
    openConnectionsInNewWindow: false,
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

  void _persist() {
    _prefs.setString(_settingsKey, jsonEncode(state.toJson()));
  }
}

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, SettingsState>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return SettingsController(prefs);
    });
