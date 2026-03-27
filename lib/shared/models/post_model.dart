class PostModel {
  final String id;
  final String content;
  final String type;
  final String userId;
  final String userName;
  final String? avatarUrl;
  final String? imageUrl; // ✅ ADDED
  final DateTime createdAt;

  PostModel({
    required this.id,
    required this.content,
    required this.type,
    required this.userId,
    required this.userName,
    this.avatarUrl,
    this.imageUrl, // ✅ ADDED
    required this.createdAt,
  });

  factory PostModel.fromMap(Map<String, dynamic> map) {
    return PostModel(
      id: map['id'],
      content: map['content'],
      type: map['type'] ?? '',
      userId: map['user_id'],
      userName: map['users']?['name'] ?? 'Unknown',
      avatarUrl: map['users']?['avatar_url'],
      imageUrl: map['image_url'], // ✅ ADDED
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}