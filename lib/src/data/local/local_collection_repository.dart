import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/identifiable.dart';

typedef LocalDecoder<T> = T Function(Map<String, dynamic>);
typedef LocalEncoder<T> = Map<String, dynamic> Function(T);

class LocalCollectionRepository<T extends Identifiable> {
  LocalCollectionRepository({
    required SharedPreferences prefs,
    required String storageKey,
    required LocalDecoder<T> decoder,
    required LocalEncoder<T> encoder,
  })  : _prefs = prefs,
        _storageKey = storageKey,
        _decoder = decoder,
        _encoder = encoder {
    _load();
  }

  final SharedPreferences _prefs;
  final String _storageKey;
  final LocalDecoder<T> _decoder;
  final LocalEncoder<T> _encoder;
  final _controller = StreamController<List<T>>.broadcast();

  List<T> _cache = const [];

  List<T> get snapshot => List.unmodifiable(_cache);

  T? maybeById(String id) {
    for (final item in _cache) {
      if (item.id == id) return item;
    }
    return null;
  }

  Stream<List<T>> watchAll() async* {
    yield snapshot;
    yield* _controller.stream;
  }

  Stream<T?> watchById(String id) {
    return watchAll().map((items) {
      for (final item in items) {
        if (item.id == id) return item;
      }
      return null;
    });
  }

  Future<void> upsert(T item) async {
    final index = _cache.indexWhere((element) => element.id == item.id);
    if (index >= 0) {
      _cache = List<T>.from(_cache)..[index] = item;
    } else {
      _cache = List<T>.from(_cache)..add(item);
    }
    await _persist();
  }

  Future<void> upsertMany(Iterable<T> items) async {
    final updated = Map<String, T>.fromEntries(
      _cache.map((item) => MapEntry(item.id, item)),
    );
    for (final item in items) {
      updated[item.id] = item;
    }
    _cache = updated.values.toList();
    await _persist();
  }

  Future<void> remove(String id) async {
    _cache = _cache.where((element) => element.id != id).toList();
    await _persist();
  }

  Future<void> clear() async {
    _cache = const [];
    await _persist();
  }

  void dispose() {
    _controller.close();
  }

  void _load() {
    final raw = _prefs.getString(_storageKey);
    if (raw == null) {
      _cache = const [];
    } else {
      final decoded = jsonDecode(raw) as List<dynamic>;
      _cache = decoded
          .map((item) => _decoder((item as Map).cast<String, dynamic>()))
          .toList(growable: false);
    }
    _emit();
  }

  Future<void> _persist() async {
    final payload = jsonEncode(_cache.map(_encoder).toList());
    await _prefs.setString(_storageKey, payload);
    _emit();
  }

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(List.unmodifiable(_cache));
    }
  }
}
