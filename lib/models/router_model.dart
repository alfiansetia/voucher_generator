import 'package:equatable/equatable.dart';

class RouterModel extends Equatable {
  final int? id;
  final String name;
  final String ip;
  final String username;
  final String password;
  final int port;

  const RouterModel({
    this.id,
    required this.name,
    required this.ip,
    required this.username,
    required this.password,
    this.port = 8728,
  });

  RouterModel copyWith({
    int? id,
    String? name,
    String? ip,
    String? username,
    String? password,
    int? port,
  }) {
    return RouterModel(
      id: id ?? this.id,
      name: name ?? this.name,
      ip: ip ?? this.ip,
      username: username ?? this.username,
      password: password ?? this.password,
      port: port ?? this.port,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'ip': ip,
      'username': username,
      'password': password,
      'port': port,
    };
  }

  factory RouterModel.fromMap(Map<String, dynamic> map) {
    return RouterModel(
      id: map['id']?.toInt(),
      name: map['name'] ?? '',
      ip: map['ip'] ?? '',
      username: map['username'] ?? '',
      password: map['password'] ?? '',
      port: map['port']?.toInt() ?? 8728,
    );
  }

  @override
  List<Object?> get props => [id, name, ip, username, password, port];
}
