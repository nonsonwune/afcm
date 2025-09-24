import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../router/app_router.dart';
import '../data/auth_repository.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthRepository(client);
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges();
});

final supabaseSessionProvider = Provider<Session?>((ref) {
  final authState = ref.watch(authStateProvider).value;
  return authState?.session ?? Supabase.instance.client.auth.currentSession;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final session = ref.watch(supabaseSessionProvider);
  return session != null;
});

class GoRouterRefreshAuth extends ChangeNotifier {
  GoRouterRefreshAuth(this.ref) {
    _sub = ref.listen<AuthState?>(
      authStateProvider.select((value) => value.value),
      (_, __) => notifyListeners(),
    );
  }

  final Ref ref;
  late final ProviderSubscription<AuthState?> _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}
