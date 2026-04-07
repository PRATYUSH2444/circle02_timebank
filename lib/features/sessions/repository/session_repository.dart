import 'package:supabase_flutter/supabase_flutter.dart';

class SessionRepository {
  final supabase = Supabase.instance.client;

  // 🟡 BOOK SESSION (HOLD TOKEN)
  Future<void> bookSession({
    required String listingId,
    required String teacherId,
    required String slotId,
    required DateTime slotTime,
    required int duration,
  }) async {
    final user = supabase.auth.currentUser;

    final userData = await supabase
        .from('users')
        .select()
        .eq('id', user!.id)
        .single();

    if (userData['tokens'] <= 0) {
      throw Exception("Not enough tokens");
    }

    final endTime = slotTime.add(Duration(minutes: duration));

    await supabase.from('sessions').insert({
      'listing_id': listingId,
      'teacher_id': teacherId,
      'student_id': user.id,
      'slot_time': slotTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'duration': duration,
      'status': 'booked',
      'token_status': 'held',
    });

    await supabase
        .from('listing_slots')
        .update({'is_booked': true}).eq('id', slotId);
  }

  // ✅ COMPLETE → TOKEN TRANSFER
  Future<void> completeSession(String sessionId) async {
    final session = await supabase
        .from('sessions')
        .select()
        .eq('id', sessionId)
        .single();

    await supabase.rpc('transfer_tokens', params: {
      'sender': session['student_id'],
      'receiver': session['teacher_id'],
    });

    await supabase.from('sessions').update({
      'status': 'completed',
      'token_status': 'completed',
    }).eq('id', sessionId);
  }

  // 🔁 CANCEL
  Future<void> cancelSession(String sessionId) async {
    final session = await supabase
        .from('sessions')
        .select()
        .eq('id', sessionId)
        .single();

    await supabase.from('listing_slots').update({
      'is_booked': false,
    }).eq('slot_time', session['slot_time']);

    await supabase.from('sessions').update({
      'status': 'cancelled',
      'token_status': 'refunded',
    }).eq('id', sessionId);
  }

  // 🔗 ADD LINK
  Future<void> addMeetingLink(String id, String url) async {
    await supabase
        .from('sessions')
        .update({'meeting_url': url}).eq('id', id);
  }

  // ⭐ RATE
  Future<void> rateSession(
      String id, int rating, String review) async {
    await supabase.from('sessions').update({
      'rating': rating,
      'review': review,
    }).eq('id', id);
  }
}