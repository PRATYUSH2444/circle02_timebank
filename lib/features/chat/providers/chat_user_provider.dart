import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final chatUserProvider =
FutureProvider.family<Map<String, dynamic>, String>((ref, sessionId) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser!.id;

  final session = await supabase
      .from('sessions')
      .select('''
        *,
        teacher_data:teacher_id(name, avatar_url),
        student_data:student_id(name, avatar_url)
      ''')
      .eq('id', sessionId)
      .single();

  final isTeacher = session['teacher_id'] == userId;
  return isTeacher ? session['student_data'] : session['teacher_data'];
});