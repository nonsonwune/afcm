import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../router/app_router.dart';
import '../../auth/application/auth_providers.dart';
import '../application/staff_providers.dart';

enum StaffSection { orders, attendees }

class StaffScaffold extends ConsumerWidget {
  const StaffScaffold({
    super.key,
    required this.currentSection,
    required this.child,
  });

  final StaffSection currentSection;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isStaffAsync = ref.watch(isStaffProvider);

    return isStaffAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => _AccessDenied(message: 'Unable to verify staff access: $error'),
      data: (isStaff) {
        if (!isStaff) {
          return const Scaffold(
            body: _AccessDenied(),
          );
        }

        final theme = Theme.of(context);
        final navItems = [
          _NavItem(
            label: 'Orders',
            section: StaffSection.orders,
            route: AppRoute.staffOrders,
          ),
          _NavItem(
            label: 'Attendees',
            section: StaffSection.attendees,
            route: AppRoute.staffAttendees,
          ),
        ];

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Row(
                    children: [
                      Text(
                        'AFCM Staff Console',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => context.goNamed(AppRoute.passes.name),
                        child: const Text('View site'),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: () => context.goNamed(AppRoute.profile.name),
                        child: const Text('My profile'),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: () => ref.read(authRepositoryProvider).signOut(),
                        child: const Text('Sign out'),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: navItems
                        .map(
                          (item) => ChoiceChip(
                            label: Text(item.label),
                            selected: item.section == currentSection,
                            onSelected: (selected) {
                              if (!selected) return;
                              if (item.route == AppRoute.staffOrders) {
                                context.goNamed(AppRoute.staffOrders.name);
                              } else {
                                context.goNamed(AppRoute.staffAttendees.name);
                              }
                            },
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.label,
    required this.section,
    required this.route,
  });

  final String label;
  final StaffSection section;
  final AppRoute route;
}

class _AccessDenied extends StatelessWidget {
  const _AccessDenied({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Staff access required',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message ??
                  'Sign in with a staff account or contact the ops team to request access.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.72),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
