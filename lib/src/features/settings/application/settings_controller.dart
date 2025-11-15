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
  });

  final ThemeMode themeMode;
  final bool confirmBeforeConnect;
  final String? downloadDirectory;

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? confirmBeforeConnect,
    String? downloadDirectory,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      confirmBeforeConnect:
          confirmBeforeConnect ?? this.confirmBeforeConnect,
      downloadDirectory: downloadDirectory ?? this.downloadDirectory,
    );
  }

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode.name,
        'confirmBeforeConnect': confirmBeforeConnect,
        'downloadDirectory': downloadDirectory,
      };

  factory SettingsState.fromJson(Map<String, dynamic> json) {
    final themeName = json['themeMode'] as String? ?? ThemeMode.dark.name;
    return SettingsState(
      themeMode: ThemeMode.values
          .firstWhere((mode) => mode.name == themeName, orElse: () => ThemeMode.dark),
      confirmBeforeConnect: json['confirmBeforeConnect'] as bool? ?? true,
      downloadDirectory: json['downloadDirectory'] as String?,
    );
  }

  static SettingsState defaults() => const SettingsState(
        themeMode: ThemeMode.dark,
        confirmBeforeConnect: true,
        downloadDirectory: null,
      );
}

class SettingsController extends StateNotifier<SettingsState> {
  SettingsController(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static SettingsState _load(SharedPreferences prefs) {
    final raw = prefs.getString(_settingsKey);
    if (raw == null) return SettingsState.defaults();
    return SettingsState.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
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

  void _persist() {
    _prefs.setString(_settingsKey, jsonEncode(state.toJson()));
  }
}

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, SettingsState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsController(prefs);
});
