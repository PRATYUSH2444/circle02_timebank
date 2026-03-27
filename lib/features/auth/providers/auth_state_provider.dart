import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/supabase_service.dart';

final authStateProvider = StreamProvider((ref) {
  return SupabaseService.client.auth.onAuthStateChange;
});