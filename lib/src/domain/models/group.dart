import 'identifiable.dart';

class HostGroup implements Identifiable {
  const HostGroup({
    required this.id,
    required this.name,
    required this.colorHex,
    this.icon,
    this.description,
  });

  @override
  final String id;
  final String name;
  final String colorHex;
  final String? icon;
  final String? description;

  HostGroup copyWith({
    String? id,
    String? name,
    String? colorHex,
    String? icon,
    String? description,
  }) {
    return HostGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      icon: icon ?? this.icon,
      description: description ?? this.description,
    );
  }

  factory HostGroup.fromJson(Map<String, dynamic> json) {
    return HostGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      colorHex: json['colorHex'] as String? ?? '#90CAF9',
      icon: json['icon'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'colorHex': colorHex,
        'icon': icon,
        'description': description,
      };
}
