import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../router/app_router.dart';
import '../../shared/models/pass_product.dart';
import '../../shared/providers/repository_providers.dart';
import '../../shared/widgets/app_shell.dart';
import '../../style/brand_theme.dart';
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

    return AppShell(
      trailing: TextButton(
        onPressed: () => isAuthenticated
            ? context.goNamed(AppRoute.profile.name)
            : context.goNamed(AppRoute.signIn.name),
        child: Text(isAuthenticated ? 'My profile' : 'Sign in'),
      ),
      hero: const _PassesHero(),
      body: passesAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 80),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => _ErrorState(error: error),
        data: (passes) => _PassCatalogue(
          passes: passes,
          selectedRole: selectedRole,
          onRoleSelected: (role) => ref.read(_selectedRoleProvider.notifier).state = role,
          onSelectPass: (pass) => context.pushNamed(
            AppRoute.register.name,
            extra: RegistrationFlowArgs(pass: pass, role: selectedRole),
          ),
        ),
      ),
    );
  }
}

class _PassesHero extends StatelessWidget {
  const _PassesHero();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Secure your AFCM Lagos pass',
          style: theme.textTheme.headlineLarge?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Choose the experience that fits your goals. Investor roundtables, curated deal rooms, and backstage access are available with every tier.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.75),
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _PassCatalogue extends StatelessWidget {
  const _PassCatalogue({
    required this.passes,
    required this.selectedRole,
    required this.onRoleSelected,
    required this.onSelectPass,
  });

  final List<PassProduct> passes;
  final String selectedRole;
  final ValueChanged<String> onRoleSelected;
  final ValueChanged<PassProduct> onSelectPass;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final theme = Theme.of(context);
        final isTablet = constraints.maxWidth >= 720;
        final isDesktop = constraints.maxWidth >= 1040;
        final crossAxisCount = isDesktop
            ? 3
            : isTablet
                ? 2
                : 1;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pick your focus area',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: PassesPage._roles
                  .map(
                    (role) => ChoiceChip(
                      label: Text(role['label']!),
                      selected: selectedRole == role['value'],
                      onSelected: (_) => onRoleSelected(role['value']!),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 36),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 24,
                crossAxisSpacing: 24,
                childAspectRatio: crossAxisCount == 1
                    ? 1.05
                    : crossAxisCount == 2
                        ? 0.95
                        : 0.88,
              ),
              itemCount: passes.length,
              itemBuilder: (context, index) {
                final pass = passes[index];
                return _PassCard(
                  pass: pass,
                  role: selectedRole,
                  onTap: () => onSelectPass(pass),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off_rounded,
              size: 48, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'We can’t reach the pass catalogue right now.',
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
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

    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pass.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pass.validityLabel,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withOpacity(0.64),
                        ),
                      ),
                    ],
                  ),
                ),
                if (pass.isEarlyBird)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.palette.heroAccent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Early bird',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.palette.heroAccent,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              nairaFormat.format(pass.amountNaira),
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (usdDisplay != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  usdDisplay,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Expanded(
              child: Text(
                pass.description,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onTap,
                child: Text(
                  'Continue as ${role[0].toUpperCase()}${role.substring(1)}',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
