class UserModel {
  final String id;
  final String email;
  final String token;

  UserModel({
    required this.id,
    required this.email,
    required this.token,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'token': token,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      token: map['token'] ?? '',
    );
  }
}
