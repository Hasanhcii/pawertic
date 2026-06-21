class UserModel {
  String username, password, role;

  UserModel({
    required this.username,
    required this.password,
    required this.role,
  });

  Map<String, dynamic> toMap() => {
    'username': username,
    'password': password,
    'role': role,
  };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
    username: map['username'] ?? '',
    password: map['password'] ?? '',
    role: map['role'] ?? 'technician',
  );
}
