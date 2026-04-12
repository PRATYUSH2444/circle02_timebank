import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final sessionProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser!.id;

  return supabase
      .from('sessions')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .asyncMap((_) async {

    final data = await supabase
        .from('sessions')
        .select('''
          *,
          teacher_data:teacher_id(name, avatar_url),
          student_data:student_id(name, avatar_url)
        ''')
        .or('teacher_id.eq.$userId,student_id.eq.$userId')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  });
});