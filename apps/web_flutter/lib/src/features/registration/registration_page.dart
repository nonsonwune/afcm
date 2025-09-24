import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../router/app_router.dart';
import '../../shared/models/order_models.dart';
import 'application/registration_controller.dart';
import 'models/registration_flow.dart';

class RegistrationPage extends ConsumerStatefulWidget {
  const RegistrationPage({super.key, this.args});

  final RegistrationFlowArgs? args;

  @override
  ConsumerState<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends ConsumerState<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _companyController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _companyController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = widget.args;
    if (args == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Register')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Please select a pass to start registration.'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.goNamed(AppRoute.passes.name),
                child: const Text('Browse Passes'),
              ),
            ],
          ),
        ),
      );
    }

    final controllerState = ref.watch(registrationControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Register – ${args.pass.name}')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 900;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Flex(
                    direction: isWide ? Axis.horizontal : Axis.vertical,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tell us about you',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall,
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _nameController,
                                    decoration: const InputDecoration(
                                        labelText: 'Full name *'),
                                    validator: (value) =>
                                        value == null || value.trim().isEmpty
                                            ? 'Enter your name'
                                            : null,
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _emailController,
                                    decoration: const InputDecoration(
                                        labelText: 'Email address *'),
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Enter your email';
                                      }
                                      final emailRegex =
                                          RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                                      if (!emailRegex.hasMatch(value.trim())) {
                                        return 'Enter a valid email';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _phoneController,
                                    decoration: const InputDecoration(
                                        labelText: 'Phone number *'),
                                    keyboardType: TextInputType.phone,
                                    validator: (value) =>
                                        value == null || value.trim().isEmpty
                                            ? 'Enter your phone number'
                                            : null,
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _companyController,
                                    decoration: const InputDecoration(
                                        labelText:
                                            'Company / Organisation (optional)'),
                                  ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton(
                                      onPressed: controllerState.isLoading
                                          ? null
                                          : () => _submit(args),
                                      child: controllerState.isLoading
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2),
                                            )
                                          : const Text('Send Paystack invoice'),
                                    ),
                                  ),
                                  if (controllerState.hasError)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: Text(
                                        controllerState.error.toString(),
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .error),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: isWide ? 24 : 0, height: isWide ? 0 : 24),
                      Expanded(
                        flex: 2,
                        child: Card(
                          elevation: 0,
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Summary',
                                    style:
                                        Theme.of(context).textTheme.titleLarge),
                                const SizedBox(height: 12),
                                Text(
                                    'Role: ${args.role[0].toUpperCase()}${args.role.substring(1)}'),
                                const SizedBox(height: 8),
                                Text('Pass: ${args.pass.name}'),
                                const SizedBox(height: 8),
                                Text(
                                    'Price: ₦${args.pass.amountNaira.toStringAsFixed(0)}'),
                                const SizedBox(height: 8),
                                Text(args.pass.validityLabel),
                                const SizedBox(height: 16),
                                const Divider(),
                                const SizedBox(height: 16),
                                const Text(
                                  'You will receive a Paystack invoice via email. After payment, your ticket and QR code will be issued automatically.',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _submit(RegistrationFlowArgs args) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final payload = CreateOrderPayload(
      passSku: args.pass.sku,
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim().toLowerCase(),
      attendeeRole: args.role,
      phone: _phoneController.text.trim(),
      company: _companyController.text.trim().isEmpty
          ? null
          : _companyController.text.trim(),
    );

    try {
      final result = await ref
          .read(registrationControllerProvider.notifier)
          .submit(payload);
      if (!mounted) return;
      context.goNamed(
        AppRoute.registrationStatus.name,
        extra: RegistrationSuccessArgs(
          result: result,
          pass: args.pass,
          email: payload.email,
          fullName: payload.fullName,
          role: args.role,
        ),
      );
    } catch (_) {
      // Errors surfaced via controller state.
    }
  }
}
