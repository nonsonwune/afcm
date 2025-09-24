import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../router/app_router.dart';
import '../auth/application/auth_providers.dart';
import 'application/profile_providers.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    if (!isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Profile')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Sign in to view your registration status.'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.goNamed(AppRoute.signIn.name),
                child: const Text('Sign in'),
              ),
            ],
          ),
        ),
      );
    }

    final profileAsync = ref.watch(attendeeProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          TextButton(
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
            child: const Text('Sign out'),
          ),
        ],
      ),
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Unable to load profile: ${error.toString()}'),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => ref.invalidate(attendeeProfileProvider),
                    child: const Text('Try again'),
                  ),
                ],
              ),
            ),
          ),
          data: (profile) {
            if (profile == null) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                      'No registration found yet. Complete your invoice to appear here.'),
                ),
              );
            }

            final passName = profile['pass_products']?['name'] as String? ??
                'Pending assignment';
            final fullName = (profile['full_name'] ?? '') as String;
            final role = (profile['attendee_role'] ?? '') as String;
            final email = (profile['email'] ?? '') as String;
            final status = (profile['status'] ?? 'UNPAID') as String;

            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(fullName.isEmpty ? 'AFCM Attendee' : fullName,
                            style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 8),
                        Text(email, style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 16),
                        _ProfileRow(label: 'Role', value: role.capitalize()),
                        const SizedBox(height: 8),
                        _ProfileRow(label: 'Status', value: status),
                        const SizedBox(height: 8),
                        _ProfileRow(label: 'Pass', value: passName),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: () =>
                              context.goNamed(AppRoute.myTicket.name),
                          child: const Text('View my ticket'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
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
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
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
