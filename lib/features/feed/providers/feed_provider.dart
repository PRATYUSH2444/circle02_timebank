import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/supabase_service.dart';
import '../../../shared/models/post_model.dart';
import '../repository/feed_repository.dart';

final feedRepositoryProvider = Provider((ref) => FeedRepository());
final feedProvider = StreamProvider<List<PostModel>>((ref) {
  return SupabaseService.client
      .from('posts')
      .stream(primaryKey: ['id'])
      .map((data) =>
      data.map((e) => PostModel.fromMap(e)).toList());
});