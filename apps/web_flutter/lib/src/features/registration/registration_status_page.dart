import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../router/app_router.dart';
import '../../shared/models/order_models.dart';
import '../../shared/widgets/app_shell.dart';
import '../../style/brand_theme.dart';
import 'application/registration_controller.dart';
import 'models/registration_flow.dart';

class RegistrationStatusPage extends ConsumerWidget {
  const RegistrationStatusPage({super.key, this.args});

  final RegistrationSuccessArgs? args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = this.args;
    if (args == null) {
      return AppShell(
        trailing: TextButton(
          onPressed: () => context.goNamed(AppRoute.passes.name),
          child: const Text('View passes'),
        ),
        hero: const _StatusFallbackHero(),
        body: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Registration session expired. Please restart from the pass catalogue.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.goNamed(AppRoute.passes.name),
                  child: const Text('Browse passes'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final controllerState = ref.watch(registrationControllerProvider);
    final isLoading = controllerState.isLoading;

    return AppShell(
      trailing: TextButton(
        onPressed: () => context.goNamed(AppRoute.profile.name),
        child: const Text('Go to profile'),
      ),
      hero: _StatusHero(email: args.email, hostedLink: args.result.hostedLink),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const [
              _ProgressBadge(step: 'Invoice sent', isActive: true),
              _ProgressBadge(step: 'Complete payment'),
              _ProgressBadge(step: 'Ticket unlocked'),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order ${args.result.paymentRequestCode}',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  const _StepBullet(
                      text:
                          'Check your inbox (and spam folder) for “Paystack Invoice”.'),
                  const _StepBullet(
                      text:
                          'Pay online via card, bank transfer, or Paystack balance.'),
                  const _StepBullet(
                      text:
                          'Once payment clears, we send your QR ticket, calendar invite, and receipt automatically.'),
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
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const _StatusSupportCard(),
        ],
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
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBadge extends StatelessWidget {
  const _ProgressBadge({
    required this.step,
    this.isActive = false,
  });

  final String step;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = isActive
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withValues(alpha: 0.7);
    final background = isActive
        ? theme.colorScheme.primary.withValues(alpha: 0.1)
        : theme.palette.subtleCard;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: foreground,
          ),
          const SizedBox(width: 8),
          Text(
            step,
            style: theme.textTheme.labelLarge?.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}

class _StatusHero extends StatelessWidget {
  const _StatusHero({required this.email, required this.hostedLink});

  final String email;
  final String hostedLink;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Invoice on its way',
          style: theme.textTheme.headlineLarge,
        ),
        const SizedBox(height: 12),
        Text(
          'We’ve emailed a Paystack invoice to $email. Complete payment to unlock your NFC badge and digital ticket.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.78),
            height: 1.5,
          ),
        ),
        if (hostedLink.isNotEmpty) ...[
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => launchUrlString(hostedLink),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open invoice now'),
          ),
        ],
      ],
    );
  }
}

class _StatusSupportCard extends StatelessWidget {
  const _StatusSupportCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      color: theme.palette.subtleCard,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Need help?',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'Invoices usually arrive within 2 minutes. If you still don’t see it, use “Resend invoice email” above or contact tickets@afcm.market.',
              style: theme.textTheme.bodySmall?.copyWith(height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusFallbackHero extends StatelessWidget {
  const _StatusFallbackHero();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Registration expired',
          style: theme.textTheme.headlineLarge,
        ),
        const SizedBox(height: 12),
        Text(
          'For security, registration sessions time out. Restart from the pass catalogue to send a new invoice.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
