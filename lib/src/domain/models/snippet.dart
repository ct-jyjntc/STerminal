import 'identifiable.dart';

class Snippet implements Identifiable {
  const Snippet({
    required this.id,
    required this.title,
    required this.command,
    this.description,
    this.tags = const [],
  });

  @override
  final String id;
  final String title;
  final String command;
  final String? description;
  final List<String> tags;

  Snippet copyWith({
    String? id,
    String? title,
    String? command,
    String? description,
    List<String>? tags,
  }) {
    return Snippet(
      id: id ?? this.id,
      title: title ?? this.title,
      command: command ?? this.command,
      description: description ?? this.description,
      tags: tags ?? this.tags,
    );
  }

  factory Snippet.fromJson(Map<String, dynamic> json) {
    return Snippet(
      id: json['id'] as String,
      title: json['title'] as String,
      command: json['command'] as String,
      description: json['description'] as String?,
      tags: (json['tags'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'command': command,
        'description': description,
        'tags': tags,
      };
}
