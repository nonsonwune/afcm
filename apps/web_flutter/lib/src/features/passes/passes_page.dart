import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../router/app_router.dart';
import '../../shared/models/pass_product.dart';
import '../../shared/providers/repository_providers.dart';
import '../auth/application/auth_providers.dart';
import '../registration/models/registration_flow.dart';

final _selectedRoleProvider =
    StateProvider.autoDispose<String>((ref) => 'investor');

class PassesPage extends ConsumerWidget {
  const PassesPage({super.key});

  static final _roles = <Map<String, String>>[
    {'label': 'Investor', 'value': 'investor'},
    {'label': 'Buyer', 'value': 'buyer'},
    {'label': 'Seller', 'value': 'seller'},
    {'label': 'Attendee', 'value': 'attendee'},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final passesAsync = ref.watch(passCatalogueProvider);
    final selectedRole = ref.watch(_selectedRoleProvider);
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Pass'),
        actions: [
          TextButton(
            onPressed: () => isAuthenticated
                ? context.goNamed(AppRoute.profile.name)
                : context.goNamed(AppRoute.signIn.name),
            child: Text(isAuthenticated ? 'My profile' : 'Sign in'),
          ),
        ],
      ),
      body: SafeArea(
        child: passesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Unable to load passes.\n${error.toString()}',
                textAlign: TextAlign.center,
              ),
            ),
          ),
          data: (passes) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 840;
                return SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 960),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select the role that best matches your participation, then choose a pass to continue.',
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: _roles
                                .map(
                                  (role) => ChoiceChip(
                                    label: Text(role['label']!),
                                    selected: selectedRole == role['value'],
                                    onSelected: (_) => ref
                                        .read(_selectedRoleProvider.notifier)
                                        .state = role['value']!,
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 32),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: isWide ? 2 : 1,
                              mainAxisSpacing: 20,
                              crossAxisSpacing: 20,
                              childAspectRatio: isWide ? 1.5 : 1.1,
                            ),
                            itemCount: passes.length,
                            itemBuilder: (context, index) {
                              final pass = passes[index];
                              return _PassCard(
                                pass: pass,
                                role: selectedRole,
                                onTap: () {
                                  context.pushNamed(
                                    AppRoute.register.name,
                                    extra: RegistrationFlowArgs(
                                        pass: pass, role: selectedRole),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _PassCard extends StatelessWidget {
  const _PassCard({
    required this.pass,
    required this.role,
    required this.onTap,
  });

  final PassProduct pass;
  final String role;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nairaFormat = NumberFormat.currency(symbol: '₦', decimalDigits: 0);
    final usdDisplay = pass.displayAmountUsd != null
        ? '~ USD ${NumberFormat.decimalPattern().format(pass.displayAmountUsd)}'
        : null;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    pass.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                if (pass.isEarlyBird)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Early Bird',
                      style: TextStyle(
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              nairaFormat.format(pass.amountNaira),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold),
            ),
            if (usdDisplay != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  usdDisplay,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            const SizedBox(height: 16),
            Text(pass.description),
            const SizedBox(height: 12),
            Text(
              pass.validityLabel,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onTap,
                child: Text(
                    'Register as ${role[0].toUpperCase()}${role.substring(1)}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
