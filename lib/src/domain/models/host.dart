import 'identifiable.dart';

class Host implements Identifiable {
  const Host({
    required this.id,
    required this.name,
    required this.address,
    required this.port,
    required this.credentialId,
    required this.groupId,
    required this.colorHex,
    required this.favorite,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.lastConnectedAt,
  });

  @override
  final String id;
  final String name;
  final String address;
  final int port;
  final String credentialId;
  final String? groupId;
  final String colorHex;
  final bool favorite;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? description;
  final DateTime? lastConnectedAt;

  Host copyWith({
    String? id,
    String? name,
    String? address,
    int? port,
    String? credentialId,
    String? groupId,
    String? colorHex,
    bool? favorite,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? description,
    DateTime? lastConnectedAt,
  }) {
    return Host(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      port: port ?? this.port,
      credentialId: credentialId ?? this.credentialId,
      groupId: groupId ?? this.groupId,
      colorHex: colorHex ?? this.colorHex,
      favorite: favorite ?? this.favorite,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      description: description ?? this.description,
      lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
    );
  }

  factory Host.fromJson(Map<String, dynamic> json) {
    return Host(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      port: (json['port'] as num?)?.toInt() ?? 22,
      credentialId: json['credentialId'] as String,
      groupId: json['groupId'] as String?,
      colorHex: json['colorHex'] as String? ?? '#4DD0E1',
      favorite: json['favorite'] as bool? ?? false,
      tags: (json['tags'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      description: json['description'] as String?,
      lastConnectedAt: json['lastConnectedAt'] == null
          ? null
          : DateTime.tryParse(json['lastConnectedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'port': port,
        'credentialId': credentialId,
        'groupId': groupId,
        'colorHex': colorHex,
        'favorite': favorite,
        'tags': tags,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'description': description,
        'lastConnectedAt': lastConnectedAt?.toIso8601String(),
      };
}
