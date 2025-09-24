import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  Stream<AuthState> authStateChanges() {
    return _client.auth.onAuthStateChange;
  }

  Session? get currentSession => _client.auth.currentSession;

  User? get currentUser => _client.auth.currentUser;

  Future<void> signOut() => _client.auth.signOut();

  Future<void> signInWithEmail({required String email}) async {
    await _client.auth.signInWithOtp(
      email: email,
      emailRedirectTo: null,
      shouldCreateUser: true,
      data: {
        'email_lower': email.toLowerCase(),
      },
    );
  }

  Future<AuthResponse> verifyEmailOtp({
    required String email,
    required String token,
    OtpType otpType = OtpType.email,
  }) {
    return _client.auth.verifyOTP(
      type: otpType,
      token: token,
      email: email,
    );
  }
}

