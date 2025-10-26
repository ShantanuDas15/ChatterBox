class User {
  final String id; // This is the MongoDB ID
  final String username;
  final String email;
  final String googleId;
  final String? photoUrl;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.googleId,
    this.photoUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      googleId: json['googleId'],
      photoUrl: json['photoUrl'],
    );
  }
}
