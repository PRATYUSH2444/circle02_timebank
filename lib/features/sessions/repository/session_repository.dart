import 'package:supabase_flutter/supabase_flutter.dart';

class SessionRepository {
  final supabase = Supabase.instance.client;

  Future<void> bookSession({
    required String teacherId,
    required String skill,
  }) async {
    final user = supabase.auth.currentUser;

    // 🧠 CHECK TOKENS FIRST
    final userData = await supabase
        .from('users')
        .select()
        .eq('id', user!.id)
        .single();

    if (userData['tokens'] <= 0) {
      throw Exception("Not enough tokens");
    }

    // 💰 TRANSFER TOKENS
    await supabase.rpc('transfer_tokens', params: {
      'sender': user.id,
      'receiver': teacherId,
    });

    // 📅 CREATE SESSION
    await supabase.from('sessions').insert({
      'teacher_id': teacherId,
      'student_id': user.id,
      'skill': skill,
      'status': 'booked',
      'scheduled_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List> getMySessions() async {
    final user = supabase.auth.currentUser;

    return await supabase
        .from('sessions')
        .select('*, users!sessions_teacher_id_fkey(name)')
        .or('teacher_id.eq.${user!.id},student_id.eq.${user.id}')
        .order('created_at', ascending: false);
  }
}