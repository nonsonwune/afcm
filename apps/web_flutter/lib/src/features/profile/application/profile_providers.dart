import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../data/profile_repository.dart';
import '../../ticket/application/ticket_providers.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ProfileRepository(client);
});

final attendeeProfileProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final session = ref.watch(supabaseSessionProvider);
  final repository = ref.watch(profileRepositoryProvider);
  final email = session?.user?.email;
  if (email != null) {
    await ref.watch(ticketRepositoryProvider).claimAttendeeRecords(email);
  }
  final userId = session?.user?.id;
  if (userId == null) {
    return null;
  }
  return repository.fetchLatestAttendee(userId);
});
