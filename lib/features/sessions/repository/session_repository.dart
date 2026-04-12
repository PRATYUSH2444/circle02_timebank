import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepository();
});

class SessionRepository {
  final supabase = Supabase.instance.client;

  // ─── Book session ─────────────────────────────────────────────────────────

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

    if (userId == teacherId) {
      throw Exception("You cannot book your own session");
    }

    final userData = await supabase
        .from('users')
        .select('tokens, name')
        .eq('id', userId)
        .single();

    if ((userData['tokens'] ?? 0) <= 0) {
      throw Exception("Not enough tokens");
    }

    final slot = await supabase
        .from('listing_slots')
        .select()
        .eq('id', slotId)
        .single();

    if (slot['is_booked'] == true) {
      throw Exception("Slot already booked");
    }

    final endTime = slotTime.add(Duration(minutes: duration));

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

    await supabase
        .from('listing_slots')
        .update({'is_booked': true})
        .eq('id', slotId);

    await _logActivity(
      userId: userId,
      type: 'debit',
      title: 'Session booked',
      subtitle: 'Slot reserved',
      amount: -1,
      icon: 'book',
    );
  }

  // ─── Complete session ─────────────────────────────────────────────────────

  Future<void> completeSession(String sessionId) async {
    final session = await supabase
        .from('sessions')
        .select()
        .eq('id', sessionId)
        .single();

    if (session['status'] != 'booked') {
      throw Exception("Session not valid for completion");
    }

    await supabase.rpc('transfer_tokens', params: {
      'sender': session['student_id'],
      'receiver': session['teacher_id'],
    });

    await supabase.from('sessions').update({
      'status': 'completed',
      'token_status': 'completed',
    }).eq('id', sessionId);

    await _logActivity(
      userId: session['student_id'],
      type: 'debit',
      title: 'Session completed',
      subtitle: 'Token transferred to teacher',
      amount: -1,
      icon: 'check',
    );

    await _logActivity(
      userId: session['teacher_id'],
      type: 'credit',
      title: 'Session completed',
      subtitle: 'Token received from student',
      amount: 1,
      icon: 'star',
    );
  }

  // ─── Cancel session ───────────────────────────────────────────────────────

  Future<void> cancelSession(String sessionId) async {
    final session = await supabase
        .from('sessions')
        .select()
        .eq('id', sessionId)
        .single();

    await supabase
        .from('listing_slots')
        .update({'is_booked': false})
        .eq('listing_id', session['listing_id'])
        .eq('slot_time', session['slot_time']);

    await supabase.from('sessions').update({
      'status': 'cancelled',
      'token_status': 'refunded',
    }).eq('id', sessionId);

    final userId = supabase.auth.currentUser!.id;
    await _logActivity(
      userId: userId,
      type: 'refund',
      title: 'Session cancelled',
      subtitle: 'Token refunded',
      amount: 0,
      icon: 'cancel',
    );
  }

  // ─── Add meeting link ─────────────────────────────────────────────────────

  Future<void> addMeetingLink(String id, String url) async {
    await supabase
        .from('sessions')
        .update({'meeting_url': url})
        .eq('id', id);
  }

  // ─── Rate session ─────────────────────────────────────────────────────────

  Future<void> rateSession(String id, int rating, String review) async {
    await supabase.from('sessions').update({
      'rating': rating,
      'review': review,
    }).eq('id', id);
  }

  // ─── Auto expire ──────────────────────────────────────────────────────────

  Future<void> autoExpireSessions() async {
    final now = DateTime.now().toIso8601String();
    await supabase
        .from('sessions')
        .update({'status': 'completed'})
        .lt('end_time', now)
        .eq('status', 'booked');
  }

  // ─── Activity log helper ──────────────────────────────────────────────────

  Future<void> _logActivity({
    required String userId,
    required String type,
    required String title,
    required String subtitle,
    required int amount,
    required String icon,
  }) async {
    try {
      await supabase.from('activity_logs').insert({
        'user_id': userId,
        'type': type,
        'title': title,
        'subtitle': subtitle,
        'amount': amount,
        'icon': icon,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      // non-critical
    }
  }
}