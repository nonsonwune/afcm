import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/application/auth_providers.dart';
import '../data/ticket_local_store.dart';
import '../data/ticket_repository.dart';

final sharedPreferencesProvider =
    FutureProvider<SharedPreferences>((ref) async {
  return SharedPreferences.getInstance();
});

final ticketRepositoryProvider = Provider<TicketRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return TicketRepository(client);
});

final ticketLocalStoreProvider = FutureProvider<TicketLocalStore>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return TicketLocalStore(prefs);
});

final ticketProvider = FutureProvider.autoDispose((ref) async {
  final repository = ref.watch(ticketRepositoryProvider);
  final session = ref.watch(supabaseSessionProvider);
  final store = await ref.watch(ticketLocalStoreProvider.future);

  if (session?.user?.email != null) {
    await repository.claimAttendeeRecords(session!.user!.email!);
  }

  try {
    final ticket = await repository.fetchLatestTicket();
    if (ticket != null) {
      await store.save(ticket);
      return ticket;
    }
    return store.read();
  } catch (_) {
    final cached = store.read();
    if (cached != null) return cached;
    rethrow;
  }
});
