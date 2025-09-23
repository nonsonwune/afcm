import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/sign_in_page.dart';
import '../features/home/home_page.dart';
import '../features/passes/passes_page.dart';
import '../features/ticket/my_ticket_page.dart';
import '../shared/providers/auth_providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/passes',
        name: 'passes',
        builder: (context, state) => const PassesPage(),
      ),
      GoRoute(
        path: '/me/ticket',
        name: 'ticket',
        builder: (context, state) => const MyTicketPage(),
      ),
      GoRoute(
        path: '/signin',
        name: 'signin',
        builder: (context, state) => const SignInPage(),
      ),
    ],
    redirect: (context, state) {
      final authStatus = ref.read(authStatusProvider);
      final isSigningIn = state.matchedLocation == '/signin';
      final requiresAuth = state.matchedLocation.startsWith('/me');

      if (authStatus == AuthStatus.signedOut && requiresAuth) {
        return '/signin';
      }

      if (authStatus == AuthStatus.signedIn && isSigningIn) {
        return '/';
      }

      return null;
    },
    debugLogDiagnostics: true,
  );
});
