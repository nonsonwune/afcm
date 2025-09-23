import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AuthStatus { unknown, signedOut, signedIn }

final authStatusProvider = StateProvider<AuthStatus>((ref) {
  return AuthStatus.signedOut;
});
