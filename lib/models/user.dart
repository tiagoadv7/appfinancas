class User {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;
  final String role; // 'owner', 'collaborator', 'viewer'

  User({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
    this.role = 'collaborator',
  });

  User.fromMap(Map<String, dynamic> data)
      : id = data['id'],
        email = data['email'],
        name = data['name'],
        photoUrl = data['photoUrl'],
        role = data['role'] ?? 'collaborator';

  Map<String, dynamic> toMap() => {
        'id': id,
        'email': email,
        'name': name,
        'photoUrl': photoUrl,
        'role': role,
      };
}
