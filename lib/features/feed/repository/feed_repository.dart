import 'dart:typed_data';

import '../../../core/services/supabase_service.dart';
import '../../../shared/models/post_model.dart';

class FeedRepository {
  final supabase = SupabaseService.client;

  // 🔥 IMAGE UPLOAD
  Future<String?> uploadImage(Uint8List fileBytes) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.png';

    await supabase.storage.from('posts').uploadBinary(
      fileName,
      fileBytes,
    );

    return supabase.storage.from('posts').getPublicUrl(fileName);
  }

  // CREATE POST (UPDATED)
  Future<void> createPost({
    required String content,
    required String type,
    Uint8List? imageBytes,
  }) async {
    final user = supabase.auth.currentUser;

    String? imageUrl;

    if (imageBytes != null) {
      imageUrl = await uploadImage(imageBytes);
    }

    await supabase.from('posts').insert({
      'content': content,
      'type': type,
      'user_id': user!.id,
      'image_url': imageUrl,
    });
  }

  // FETCH POSTS
  Future<List<PostModel>> fetchPosts() async {
    final res = await supabase
        .from('posts')
        .select('*, users(name)')
        .order('created_at', ascending: false);

    return (res as List)
        .map((e) => PostModel.fromMap(e))
        .toList();
  }

  // LIKE POST
  Future<void> toggleLike(String postId) async {
    final user = supabase.auth.currentUser;

    final existing = await supabase
        .from('likes')
        .select()
        .eq('post_id', postId)
        .eq('user_id', user!.id);

    if (existing.isNotEmpty) {
      await supabase
          .from('likes')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', user.id);
    } else {
      await supabase.from('likes').insert({
        'post_id': postId,
        'user_id': user.id,
      });
    }
  }

  // ADD COMMENT
  Future<void> addComment({
    required String postId,
    required String content,
  }) async {
    final user = supabase.auth.currentUser;

    await supabase.from('comments').insert({
      'post_id': postId,
      'content': content,
      'user_id': user!.id,
    });
  }

  // LIKE COUNT
  Future<int> getLikeCount(String postId) async {
    final res = await supabase
        .from('likes')
        .select()
        .eq('post_id', postId);

    return res.length;
  }

  // COMMENT COUNT
  Future<int> getCommentCount(String postId) async {
    final res = await supabase
        .from('comments')
        .select()
        .eq('post_id', postId);

    return res.length;
  }

  // FETCH COMMENTS
  Future<List<Map<String, dynamic>>> fetchComments(String postId) async {
    return await supabase
        .from('comments')
        .select('*, users(name)')
        .eq('post_id', postId)
        .order('created_at');
  }

  // 🔥 TOKEN SYSTEM
  Future<void> transferTokens({
    required String receiverId,
    required bool isLearning,
  }) async {
    final user = supabase.auth.currentUser;

    if (isLearning) {
      // subtract from current user
      await supabase.rpc('decrement_token', params: {
        'user_id': user!.id,
      });

      // add to teacher
      await supabase.rpc('increment_token', params: {
        'user_id': receiverId,
      });
    }
  }
}