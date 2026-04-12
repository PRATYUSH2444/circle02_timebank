import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final sessionProvider = FutureProvider((ref) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser!.id;

  /// 🔥 STEP 1: GET SESSIONS ONLY
  final sessions = await supabase
      .from('sessions')
      .select()
      .or('teacher_id.eq.$userId,student_id.eq.$userId')
      .order('slot_time');

  /// 🔥 STEP 2: COLLECT USER IDS
  final userIds = <String>{};

  for (var s in sessions) {
    userIds.add(s['teacher_id']);
    userIds.add(s['student_id']);
  }

  /// 🔥 STEP 3: FETCH USERS SEPARATELY
  final users = await supabase
      .from('users')
      .select()
      .inFilter('id', userIds.toList());

  /// 🔥 STEP 4: MAP USERS
  final userMap = {
    for (var u in users) u['id']: u,
  };

  /// 🔥 STEP 5: ATTACH DATA
  return sessions.map((s) {
    return {
      ...s,
      'teacher_data': userMap[s['teacher_id']],
      'student_data': userMap[s['student_id']],
    };
  }).toList();
});