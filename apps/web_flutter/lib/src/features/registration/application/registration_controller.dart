import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/order_models.dart';
import '../../auth/application/auth_providers.dart';
import '../data/registration_repository.dart';

final registrationRepositoryProvider = Provider<RegistrationRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return RegistrationRepository(client);
});

class RegistrationController extends StateNotifier<AsyncValue<CreateOrderResult?>> {
  RegistrationController(this._repository) : super(const AsyncValue.data(null));

  final RegistrationRepository _repository;

  Future<CreateOrderResult> submit(CreateOrderPayload payload) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.createOrder(payload);
      state = AsyncValue.data(result);
      return result;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<CreateOrderResult> resendInvoice(CreateOrderPayload payload) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.resendInvoice(payload);
      state = AsyncValue.data(result);
      return result;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}

final registrationControllerProvider =
    StateNotifierProvider<RegistrationController, AsyncValue<CreateOrderResult?>>((ref) {
  final repository = ref.watch(registrationRepositoryProvider);
  return RegistrationController(repository);
});

