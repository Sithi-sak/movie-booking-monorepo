class DeveloperModel {
  final int id;
  final String name;
  final String role;
  final String imageUrl;
  final String description;
  final String email;
  final String github;

  DeveloperModel({
    required this.id,
    required this.name,
    required this.role,
    required this.imageUrl,
    required this.description,
    required this.email,
    required this.github,
  });

  // Convert from JSON
  factory DeveloperModel.fromJson(Map<String, dynamic> json) {
    return DeveloperModel(
      id: json['id'],
      name: json['name'],
      role: json['role'],
      imageUrl: json['image_url'],
      description: json['description'],
      email: json['email'],
      github: json['github'],
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'image_url': imageUrl,
      'description': description,
      'email': email,
      'github': github,
    };
  }
}
