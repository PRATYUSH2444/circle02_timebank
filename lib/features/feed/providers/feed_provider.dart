import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/supabase_service.dart';
import '../../../shared/models/post_model.dart';
import '../repository/feed_repository.dart';

final feedRepositoryProvider = Provider((ref) => FeedRepository());
final feedProvider = StreamProvider((ref) {
  final supabase = SupabaseService.client;

  return supabase
      .from('posts')
      .stream(primaryKey: ['id'])
      .order('created_at')
      .asyncMap((_) async {

    final response = await supabase.rpc('get_feed_with_counts');

    return (response as List)
        .map((e) => PostModel.fromMap(e))
        .toList();
  });
});