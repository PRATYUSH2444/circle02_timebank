import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 🔥 MESSAGES — realtime stream
final chatProvider =
StreamProvider.family<List<Map<String, dynamic>>, String>(
        (ref, sessionId) {
      final supabase = Supabase.instance.client;

      return supabase
          .from('messages')
          .stream(primaryKey: ['id'])
          .eq('session_id', sessionId)
          .order('created_at', ascending: true);
    });

/// 🔥 TYPING STATUS — realtime stream
final typingProvider =
StreamProvider.family<List<Map<String, dynamic>>, String>(
        (ref, sessionId) {
      final supabase = Supabase.instance.client;

      return supabase
          .from('typing_status')
          .stream(primaryKey: ['id'])
          .eq('session_id', sessionId);
    });