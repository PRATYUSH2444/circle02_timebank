import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 🔥 PROVIDER (FIXES YOUR ERROR)
final sessionRepositoryProvider =
Provider<SessionRepository>((ref) {
  return SessionRepository();
});

class SessionRepository {
  final supabase = Supabase.instance.client;

  /// 🟡 BOOK SESSION (SAFE + PRODUCTION READY)
  Future<void> bookSession({
    required String listingId,
    required String teacherId,
    required String slotId,
    required DateTime slotTime,
    required int duration,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    final userId = user.id;

    /// 🚨 BLOCK SELF BOOKING
    if (userId == teacherId) {
      throw Exception("You cannot book your own session");
    }

    /// 🔍 CHECK USER TOKENS
    final userData = await supabase
        .from('users')
        .select('tokens')
        .eq('id', userId)
        .single();

    if ((userData['tokens'] ?? 0) <= 0) {
      throw Exception("Not enough tokens");
    }

    /// 🔍 CHECK SLOT
    final slot = await supabase
        .from('listing_slots')
        .select()
        .eq('id', slotId)
        .single();

    if (slot['is_booked'] == true) {
      throw Exception("Slot already booked");
    }

    final endTime = slotTime.add(Duration(minutes: duration));

    /// 🔥 CREATE SESSION
    await supabase.from('sessions').insert({
      'listing_id': listingId,
      'teacher_id': teacherId,
      'student_id': userId,
      'slot_time': slotTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'duration': duration,
      'status': 'booked',
      'token_status': 'held',
    });

    /// 🔒 LOCK SLOT
    await supabase
        .from('listing_slots')
        .update({'is_booked': true})
        .eq('id', slotId);
  }

  /// ✅ COMPLETE SESSION → TOKEN TRANSFER
  Future<void> completeSession(String sessionId) async {
    final session = await supabase
        .from('sessions')
        .select()
        .eq('id', sessionId)
        .single();

    if (session['status'] != 'booked') {
      throw Exception("Session not valid for completion");
    }

    /// 🔥 TOKEN TRANSFER (RPC)
    await supabase.rpc('transfer_tokens', params: {
      'sender': session['student_id'],
      'receiver': session['teacher_id'],
    });

    await supabase.from('sessions').update({
      'status': 'completed',
      'token_status': 'completed',
    }).eq('id', sessionId);
  }

  /// 🔁 CANCEL SESSION (SAFE)
  Future<void> cancelSession(String sessionId) async {
    final session = await supabase
        .from('sessions')
        .select()
        .eq('id', sessionId)
        .single();

    /// 🔓 UNLOCK SLOT
    await supabase
        .from('listing_slots')
        .update({'is_booked': false})
        .eq('listing_id', session['listing_id'])
        .eq('slot_time', session['slot_time']);

    await supabase.from('sessions').update({
      'status': 'cancelled',
      'token_status': 'refunded',
    }).eq('id', sessionId);
  }

  /// 🔗 ADD MEETING LINK
  Future<void> addMeetingLink(String id, String url) async {
    await supabase
        .from('sessions')
        .update({'meeting_url': url})
        .eq('id', id);
  }

  /// ⭐ RATE SESSION
  Future<void> rateSession(
      String id, int rating, String review) async {
    await supabase.from('sessions').update({
      'rating': rating,
      'review': review,
    }).eq('id', id);
  }

  /// ⚡ AUTO EXPIRE (IMPORTANT)
  Future<void> autoExpireSessions() async {
    final now = DateTime.now().toIso8601String();

    await supabase
        .from('sessions')
        .update({'status': 'completed'})
        .lt('end_time', now)
        .eq('status', 'booked');
  }
}