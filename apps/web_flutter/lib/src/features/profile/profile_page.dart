import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../router/app_router.dart';
import '../../shared/widgets/app_shell.dart';
import '../../style/brand_theme.dart';
import '../auth/application/auth_providers.dart';
import 'application/profile_providers.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    if (!isAuthenticated) {
      return AppShell(
        trailing: TextButton(
          onPressed: () => context.goNamed(AppRoute.passes.name),
          child: const Text('View passes'),
        ),
        hero: const _ProfileFallbackHero(),
        body: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sign in to view your registration status and ticket.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.goNamed(AppRoute.signIn.name),
                  child: const Text('Sign in'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final profileAsync = ref.watch(attendeeProfileProvider);

    return AppShell(
      trailing: TextButton(
        onPressed: () => ref.read(authRepositoryProvider).signOut(),
        child: const Text('Sign out'),
      ),
      hero: const _ProfileHero(),
      body: profileAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 80),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => _ProfileErrorState(
          message: 'Unable to load profile: ${error.toString()}',
          onRetry: () => ref.invalidate(attendeeProfileProvider),
        ),
        data: (profile) {
          if (profile == null) {
            return const _ProfileEmptyState();
          }

          final passName = profile['pass_products']?['name'] as String? ??
              'Pending assignment';
          final fullName = (profile['full_name'] ?? '') as String;
          final role = (profile['attendee_role'] ?? '') as String;
          final email = (profile['email'] ?? '') as String;
          final status = (profile['status'] ?? 'UNPAID') as String;
          final paid = status.toUpperCase() == 'PAID';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProfileBadgeRow(status: status, paid: paid),
              const SizedBox(height: 24),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(26),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName.isEmpty ? 'AFCM attendee' : fullName,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        email,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.7),
                            ),
                      ),
                      const SizedBox(height: 20),
                      _ProfileRow(label: 'Role', value: role.capitalize()),
                      const SizedBox(height: 12),
                      _ProfileRow(label: 'Pass', value: passName),
                      const SizedBox(height: 12),
                      _ProfileRow(label: 'Status', value: status),
                      const SizedBox(height: 28),
                      FilledButton(
                        onPressed: () =>
                            context.goNamed(AppRoute.myTicket.name),
                        child: Text(
                            paid ? 'View my ticket' : 'View payment status'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

extension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your AFCM hub', style: theme.textTheme.headlineLarge),
        const SizedBox(height: 12),
        Text(
          'Track your invoice status, download tickets, and manage event essentials from one place.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.78),
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _ProfileFallbackHero extends StatelessWidget {
  const _ProfileFallbackHero();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sign in to continue', style: theme.textTheme.headlineLarge),
        const SizedBox(height: 12),
        Text(
          'We’ll reconnect you with your invoices and tickets once you confirm your email.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _ProfileErrorState extends StatelessWidget {
  const _ProfileErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message),
                const SizedBox(height: 12),
                OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileEmptyState extends StatelessWidget {
  const _ProfileEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No registration found yet',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'Once your payment is confirmed, your ticket and attendee details will appear here automatically.',
              style: theme.textTheme.bodySmall?.copyWith(height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileBadgeRow extends StatelessWidget {
  const _ProfileBadgeRow({required this.status, required this.paid});

  final String status;
  final bool paid;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.palette;
    final color = paid ? theme.colorScheme.primary : palette.heroAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(paid ? Icons.verified : Icons.hourglass_top, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            paid ? 'Ticket ready' : 'Payment pending',
            style: theme.textTheme.labelLarge?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
