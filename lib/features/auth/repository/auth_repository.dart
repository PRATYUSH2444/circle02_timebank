import '../../../core/services/supabase_service.dart';

class AuthRepository {
  final supabase = SupabaseService.client;

  // SIGN UP
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    final response = await supabase.auth.signUp(
      email: email,
      password: password,
    );

    final user = response.user;

    if (user != null) {
      await supabase.from('users').upsert({
        'id': user.id,
        'email': email,
        'name': name,
        'tokens': 5,
      });
    }
  }

  // LOGIN
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // LOGOUT
  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  // CURRENT USER
  get currentUser => supabase.auth.currentUser;
}