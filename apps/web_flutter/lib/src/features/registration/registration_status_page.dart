import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../router/app_router.dart';
import '../../shared/models/order_models.dart';
import 'application/registration_controller.dart';
import 'models/registration_flow.dart';

class RegistrationStatusPage extends ConsumerWidget {
  const RegistrationStatusPage({super.key, this.args});

  final RegistrationSuccessArgs? args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = this.args;
    if (args == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Payment Sent')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Registration session expired. Start again.'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.goNamed(AppRoute.passes.name),
                child: const Text('Back to passes'),
              ),
            ],
          ),
        ),
      );
    }

    final controllerState = ref.watch(registrationControllerProvider);
    final isLoading = controllerState.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Invoice Sent')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.15),
                        child: Icon(Icons.check,
                            color: Theme.of(context).colorScheme.primary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Paystack invoice sent to ${args.email}',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Order reference: ${args.result.paymentRequestCode}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Next steps:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const _StepBullet(
                      text:
                          'Check your inbox for the Paystack invoice (including spam/junk).'),
                  const _StepBullet(
                      text: 'Complete payment securely via Paystack.'),
                  const _StepBullet(
                      text:
                          'Once confirmed, we will email your QR ticket and calendar invite automatically.'),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(
                        onPressed: args.result.hostedLink.isEmpty
                            ? null
                            : () => launchUrlString(args.result.hostedLink),
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Open Paystack invoice'),
                      ),
                      OutlinedButton(
                        onPressed: isLoading
                            ? null
                            : () => _resendInvoice(context, ref, args),
                        child: isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Resend invoice email'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),
                  Card(
                    elevation: 0,
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Need help?',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          const Text(
                            'If you do not receive the invoice within a few minutes, tap “Resend invoice” or contact tickets@afcm.market.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _resendInvoice(
    BuildContext context,
    WidgetRef ref,
    RegistrationSuccessArgs args,
  ) async {
    final payload = CreateOrderPayload(
      passSku: args.pass.sku,
      fullName: args.fullName,
      email: args.email,
      attendeeRole: args.role,
      resendInvoice: true,
    );

    try {
      await ref
          .read(registrationControllerProvider.notifier)
          .resendInvoice(payload);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Invoice resent. Check your email again.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to resend invoice: $error')),
      );
    }
  }
}

class _StepBullet extends StatelessWidget {
  const _StepBullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
