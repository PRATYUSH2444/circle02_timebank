class PostModel {
  final String id;
  final String userId;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;

  final String userName;
  final String? avatarUrl;

  final int likeCount;
  final int commentCount;

  /// ✅ NEW FIELD
  final bool isLiked;

  PostModel({
    required this.id,
    required this.userId,
    required this.content,
    this.imageUrl,
    required this.createdAt,
    required this.userName,
    this.avatarUrl,
    required this.likeCount,
    required this.commentCount,

    /// ✅ ADD IN CONSTRUCTOR
    required this.isLiked,
  });

  factory PostModel.fromMap(Map<String, dynamic> map) {
    return PostModel(
      id: map['id'],
      userId: map['user_id'],
      content: map['content'],
      imageUrl: map['image_url'],
      createdAt: DateTime.parse(map['created_at']),

      /// 🔥 IMPORTANT (FROM RPC)
      userName: map['name'] ?? 'Unknown',
      avatarUrl: map['avatar_url'],

      likeCount: (map['like_count'] ?? 0) as int,
      commentCount: (map['comment_count'] ?? 0) as int,

      /// ✅ NEW FIELD MAPPED
      isLiked: map['is_liked'] ?? false,
    );
  }
}