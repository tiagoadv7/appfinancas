class User {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;
  final String role; // 'owner', 'collaborator', 'viewer'
  final double salary; // Salário do usuário

  User({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
    this.role = 'collaborator',
    this.salary = 0.0,
  });

  User.fromMap(Map<String, dynamic> data)
    : id = data['id'],
      email = data['email'],
      name = data['name'],
      photoUrl = data['photoUrl'],
      role = data['role'] ?? 'collaborator',
      salary = (data['salary'] as num?)?.toDouble() ?? 0.0;

  Map<String, dynamic> toMap() => {
    'id': id,
    'email': email,
    'name': name,
    'photoUrl': photoUrl,
    'role': role,
    'salary': salary,
  };
}
