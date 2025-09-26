import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../data/staff_repository.dart';

final staffRepositoryProvider = Provider<StaffRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return StaffRepository(client);
});

final isStaffProvider = FutureProvider<bool>((ref) async {
  final session = ref.watch(supabaseSessionProvider);
  final userId = session?.user.id;
  if (userId == null) {
    return false;
  }
  final repository = ref.watch(staffRepositoryProvider);
  try {
    return await repository.isStaff(userId);
  } catch (_) {
    return false;
  }
});

final staffOrdersProvider = FutureProvider.autoDispose
    .family<List<StaffOrder>, String>((ref, status) async {
  final repository = ref.watch(staffRepositoryProvider);
  return repository.fetchOrders(status: status);
});

final staffAttendeesProvider = FutureProvider.autoDispose
    .family<List<StaffAttendee>, String>((ref, status) async {
  final repository = ref.watch(staffRepositoryProvider);
  return repository.fetchAttendees(status: status);
});
