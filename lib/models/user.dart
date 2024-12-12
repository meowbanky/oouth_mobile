class User {
  final String id;
  final String email;
  final String token;
  final String name;

  User({
    required this.id,
    required this.email,
    required this.token,
    required this.name,
  });

  factory User.fromJson(Map<String, dynamic> json, String token) {
    return User(
      id: json['id'].toString(),
      email: json['email'] as String,
      token: token,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'token': token,
        'name': name,
      };
}
