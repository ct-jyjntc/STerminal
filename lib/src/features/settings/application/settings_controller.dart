import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/app_providers.dart';

const _settingsKey = 'settings/v1';

class SettingsState {
  const SettingsState({
    required this.themeMode,
    required this.syncEnabled,
    required this.biometricLock,
    required this.confirmBeforeConnect,
  });

  final ThemeMode themeMode;
  final bool syncEnabled;
  final bool biometricLock;
  final bool confirmBeforeConnect;

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? syncEnabled,
    bool? biometricLock,
    bool? confirmBeforeConnect,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      syncEnabled: syncEnabled ?? this.syncEnabled,
      biometricLock: biometricLock ?? this.biometricLock,
      confirmBeforeConnect:
          confirmBeforeConnect ?? this.confirmBeforeConnect,
    );
  }

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode.name,
        'syncEnabled': syncEnabled,
        'biometricLock': biometricLock,
        'confirmBeforeConnect': confirmBeforeConnect,
      };

  factory SettingsState.fromJson(Map<String, dynamic> json) {
    final themeName = json['themeMode'] as String? ?? ThemeMode.dark.name;
    return SettingsState(
      themeMode: ThemeMode.values
          .firstWhere((mode) => mode.name == themeName, orElse: () => ThemeMode.dark),
      syncEnabled: json['syncEnabled'] as bool? ?? true,
      biometricLock: json['biometricLock'] as bool? ?? false,
      confirmBeforeConnect: json['confirmBeforeConnect'] as bool? ?? true,
    );
  }

  static SettingsState defaults() => const SettingsState(
        themeMode: ThemeMode.dark,
        syncEnabled: true,
        biometricLock: false,
        confirmBeforeConnect: true,
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

  void toggleSync(bool value) {
    state = state.copyWith(syncEnabled: value);
    _persist();
  }

  void toggleBiometric(bool value) {
    state = state.copyWith(biometricLock: value);
    _persist();
  }

  void toggleConfirmation(bool value) {
    state = state.copyWith(confirmBeforeConnect: value);
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
