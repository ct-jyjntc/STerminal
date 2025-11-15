import 'dart:convert';

enum AppWindowKind { main, terminal }

class AppWindowArguments {
  const AppWindowArguments({required this.kind, this.hostId});

  const AppWindowArguments.main() : this(kind: AppWindowKind.main);

  factory AppWindowArguments.terminal(String hostId) {
    return AppWindowArguments(kind: AppWindowKind.terminal, hostId: hostId);
  }

  factory AppWindowArguments.fromEncoded(String? raw) {
    if (raw == null || raw.isEmpty) {
      return const AppWindowArguments.main();
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return const AppWindowArguments.main();
      }
      final map = decoded.cast<String, dynamic>();
      final kindName = map['kind'] as String? ?? AppWindowKind.main.name;
      final hostId = map['hostId'] as String?;
      final kind = AppWindowKind.values.firstWhere(
        (value) => value.name == kindName,
        orElse: () => AppWindowKind.main,
      );
      if (kind == AppWindowKind.terminal &&
          (hostId == null || hostId.isEmpty)) {
        return const AppWindowArguments.main();
      }
      return AppWindowArguments(kind: kind, hostId: hostId);
    } catch (_) {
      return const AppWindowArguments.main();
    }
  }

  final AppWindowKind kind;
  final String? hostId;

  bool get shouldStartInTerminal =>
      kind == AppWindowKind.terminal && (hostId?.isNotEmpty ?? false);

  String encode() {
    final map = <String, dynamic>{'kind': kind.name};
    if (hostId?.isNotEmpty ?? false) {
      map['hostId'] = hostId;
    }
    return jsonEncode(map);
  }
}
