import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// AUTH
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/auth/providers/auth_state_provider.dart';

/// CORE
import '../../features/dashboard/presentation/dashboard_screen.dart';

/// NEW SCREENS
import '../../features/profile/presentation/wallet_screen.dart';
import '../../features/chat/presentation/chat_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',

    /// 🔥 FIXED REDIRECT LOGIC
    redirect: (context, state) {
      final user = Supabase.instance.client.auth.currentUser;

      final isLoggedIn = user != null;
      final isAuthRoute =
          state.matchedLocation == '/login' ||
              state.matchedLocation == '/signup';

      /// ❌ NOT LOGGED IN
      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }

      /// ✅ LOGGED IN
      if (isLoggedIn && isAuthRoute) {
        return '/home';
      }

      return null;
    },

    routes: [
      /// 🔐 AUTH ROUTES
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),

      /// 🏠 MAIN APP
      GoRoute(
        path: '/home',
        builder: (context, state) => const DashboardScreen(),
      ),

      /// 💰 WALLET
      GoRoute(
        path: '/wallet',
        builder: (context, state) => const WalletScreen(),
      ),

      /// 💬 CHAT (SESSION BASED) ✅ UPDATED
      GoRoute(
        path: '/chat/:sessionId',
        builder: (context, state) {
          final sessionId = state.pathParameters['sessionId']!;
          return ChatScreen(sessionId: sessionId);
        },
      ),
    ],
  );
});