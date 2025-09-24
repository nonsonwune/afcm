import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/auth_providers.dart';
import '../data/pass_repository.dart';

final passRepositoryProvider = Provider<PassRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return PassRepository(client);
});

final passCatalogueProvider = FutureProvider((ref) async {
  final repository = ref.watch(passRepositoryProvider);
  return repository.fetchActivePasses();
});
