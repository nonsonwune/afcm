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

class PassesPage extends ConsumerStatefulWidget {
  const PassesPage({super.key});

  static final _roles = <Map<String, String>>[
    {'label': 'Investor', 'value': 'investor'},
    {'label': 'Buyer', 'value': 'buyer'},
    {'label': 'Seller', 'value': 'seller'},
    {'label': 'Attendee', 'value': 'attendee'},
  ];

  @override
  ConsumerState<PassesPage> createState() => _PassesPageState();
}

class _PassesPageState extends ConsumerState<PassesPage> {
  PassProduct? _selectedPass;

  @override
  Widget build(BuildContext context) {
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
        data: (passes) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PassCatalogue(
              passes: passes,
              selectedRole: selectedRole,
              selectedPass: _selectedPass,
              onRoleSelected: (role) {
                ref.read(_selectedRoleProvider.notifier).state = role;
                setState(() => _selectedPass = null);
              },
              onSelectPass: (pass) {
                setState(() => _selectedPass = pass);
              },
              onContinue: (pass) => _navigateToRegistration(pass, selectedRole),
            ),
            const SizedBox(height: 24),
            if (_selectedPass != null)
              FilledButton.icon(
                onPressed: () =>
                    _navigateToRegistration(_selectedPass!, selectedRole),
                icon: const Icon(Icons.arrow_forward),
                label: Text(
                  'Continue to registration as '
                  '${selectedRole[0].toUpperCase()}${selectedRole.substring(1)}',
                ),
              )
            else if (passes.isEmpty)
              const _EmptyCatalogueNotice()
            else
              Text(
                'Select a pass above to continue.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(height: 1.5),
              ),
          ],
        ),
      ),
    );
  }

  void _navigateToRegistration(PassProduct pass, String role) {
    context.pushNamed(
      AppRoute.register.name,
      extra: RegistrationFlowArgs(pass: pass, role: role),
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
    required this.selectedPass,
    required this.onRoleSelected,
    required this.onSelectPass,
    required this.onContinue,
  });

  final List<PassProduct> passes;
  final String selectedRole;
  final PassProduct? selectedPass;
  final ValueChanged<String> onRoleSelected;
  final ValueChanged<PassProduct> onSelectPass;
  final ValueChanged<PassProduct> onContinue;

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
            const SizedBox(height: 16),
            Text(
              'Select a pass below to continue as '
              '${selectedRole[0].toUpperCase()}${selectedRole.substring(1)}.',
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
            const SizedBox(height: 24),
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
                  isSelected: selectedPass?.id == pass.id,
                  onSelect: () => onSelectPass(pass),
                  onContinue: () => onContinue(pass),
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
    required this.onSelect,
    required this.onContinue,
    required this.isSelected,
  });

  final PassProduct pass;
  final String role;
  final VoidCallback onSelect;
  final VoidCallback onContinue;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final nairaFormat = NumberFormat.currency(symbol: '₦', decimalDigits: 0);
    final usdDisplay = pass.displayAmountUsd != null
        ? '~ USD ${NumberFormat.decimalPattern().format(pass.displayAmountUsd)}'
        : null;

    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.palette.subtleCard,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(24),
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
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onSelect,
                      child: const Text('Select pass'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: onContinue,
                      child: Text(
                        'Register as ${role[0].toUpperCase()}${role.substring(1)}',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCatalogueNotice extends StatelessWidget {
  const _EmptyCatalogueNotice();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.palette.subtleCard,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'No passes are currently available. Please check back soon or contact tickets@afcm.app for assistance.',
        style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
      ),
    );
  }
}
