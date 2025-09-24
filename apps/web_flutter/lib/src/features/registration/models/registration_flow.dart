import '../../../shared/models/order_models.dart';
import '../../../shared/models/pass_product.dart';

class RegistrationFlowArgs {
  const RegistrationFlowArgs({
    required this.pass,
    required this.role,
  });

  final PassProduct pass;
  final String role;
}

class RegistrationSuccessArgs {
  const RegistrationSuccessArgs({
    required this.result,
    required this.pass,
    required this.email,
    required this.fullName,
    required this.role,
  });

  final CreateOrderResult result;
  final PassProduct pass;
  final String email;
  final String fullName;
  final String role;
}
