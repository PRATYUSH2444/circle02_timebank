import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/auth/providers/auth_state_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',

    redirect: (context, state) {
      final user = Supabase.instance.client.auth.currentUser;

      final isLoggedIn = user != null;
      final isAuthRoute =
          state.matchedLocation == '/login' ||
              state.matchedLocation == '/signup';

      // NOT logged in → allow login/signup
      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }

      // Logged in → block login/signup
      if (isLoggedIn && isAuthRoute) {
        return '/home';
      }

      return null;
    },

    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),

      GoRoute(
        path: '/home',
        builder: (context, state) => const DashboardScreen(),
      ),
    ],
  );
});