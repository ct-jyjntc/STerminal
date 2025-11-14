import 'identifiable.dart';

enum CredentialAuthKind {
  password,
  keyPair,
}

class Credential implements Identifiable {
  const Credential({
    required this.id,
    required this.name,
    required this.username,
    required this.authKind,
    required this.createdAt,
    required this.updatedAt,
    this.password,
    this.privateKey,
    this.passphrase,
  });

  @override
  final String id;
  final String name;
  final String username;
  final CredentialAuthKind authKind;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? password;
  final String? privateKey;
  final String? passphrase;

  Credential copyWith({
    String? id,
    String? name,
    String? username,
    CredentialAuthKind? authKind,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? password,
    String? privateKey,
    String? passphrase,
  }) {
    return Credential(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      authKind: authKind ?? this.authKind,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      password: password ?? this.password,
      privateKey: privateKey ?? this.privateKey,
      passphrase: passphrase ?? this.passphrase,
    );
  }

  factory Credential.fromJson(Map<String, dynamic> json) {
    return Credential(
      id: json['id'] as String,
      name: json['name'] as String,
      username: json['username'] as String,
      authKind: CredentialAuthKind.values
          .byName(json['authKind'] as String? ?? 'password'),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      password: json['password'] as String?,
      privateKey: json['privateKey'] as String?,
      passphrase: json['passphrase'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'username': username,
        'authKind': authKind.name,
        'password': password,
        'privateKey': privateKey,
        'passphrase': passphrase,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
