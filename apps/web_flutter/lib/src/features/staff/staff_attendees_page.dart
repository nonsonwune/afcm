import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'application/staff_providers.dart';
import 'data/staff_repository.dart';
import 'widgets/staff_scaffold.dart';
import '../../style/brand_theme.dart';

final _attendeeStatusFilterProvider = StateProvider<String>((ref) => 'all');

class StaffAttendeesPage extends ConsumerWidget {
  const StaffAttendeesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusFilter = ref.watch(_attendeeStatusFilterProvider);
    final attendeesAsync = ref.watch(staffAttendeesProvider(statusFilter));

    return StaffScaffold(
      currentSection: StaffSection.attendees,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Attendees',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                DropdownButton<String>(
                  value: statusFilter,
                  onChanged: (value) {
                    if (value == null) return;
                    ref.read(_attendeeStatusFilterProvider.notifier).state = value;
                  },
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All statuses')),
                    DropdownMenuItem(value: 'PAID', child: Text('Paid')),
                    DropdownMenuItem(value: 'UNPAID', child: Text('Unpaid')),
                    DropdownMenuItem(value: 'CANCELLED', child: Text('Cancelled')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: attendeesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _ErrorState(
                  message: 'Unable to load attendees: $error',
                  onRetry: () => ref.invalidate(staffAttendeesProvider(statusFilter)),
                ),
                data: (attendees) {
                  if (attendees.isEmpty) {
                    return const _EmptyState(
                      message: 'No attendees found for this filter yet.',
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(staffAttendeesProvider(statusFilter));
                    },
                    child: ListView.separated(
                      itemCount: attendees.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final attendee = attendees[index];
                        final firstOrder = attendee.orders.isEmpty
                            ? null
                            : attendee.orders.first;
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      attendee.fullName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                    const Spacer(),
                                    _StatusBadge(status: attendee.status),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 16,
                                  runSpacing: 8,
                                  children: [
                                    _InfoChip(
                                      icon: Icons.email,
                                      label: attendee.email,
                                    ),
                                    _InfoChip(
                                      icon: Icons.badge,
                                      label: attendee.role.isEmpty
                                          ? 'Role TBD'
                                          : attendee.role[0].toUpperCase() +
                                              attendee.role.substring(1),
                                    ),
                                    _InfoChip(
                                      icon: Icons.event,
                                      label: attendee.passName,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Registered ${DateFormat.yMMMd().add_jm().format(attendee.createdAt.toLocal())}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.65),
                                      ),
                                ),
                                if (firstOrder != null) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    'Latest order: ${firstOrder.status.toUpperCase()} • ${firstOrder.invoiceUrl.isEmpty ? 'No invoice' : 'Invoice link available'}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  if (firstOrder.invoiceUrl.isNotEmpty)
                                    TextButton.icon(
                                      onPressed: () =>
                                          _openInvoice(context, firstOrder.invoiceUrl),
                                      icon: const Icon(Icons.open_in_new),
                                      label: const Text('Open invoice'),
                                    ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openInvoice(BuildContext context, String url) async {
    if (url.isEmpty) return;
    final opened = await launchUrlString(url);
    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open invoice link.')),
      );
    }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final normalized = status.toUpperCase();
    Color background;
    Color foreground;
    switch (normalized) {
      case 'PAID':
        background = theme.colorScheme.primary.withOpacity(0.12);
        foreground = theme.colorScheme.primary;
        break;
      case 'CANCELLED':
        background = theme.colorScheme.error.withOpacity(0.12);
        foreground = theme.colorScheme.error;
        break;
      default:
        background = theme.palette.subtleCard;
        foreground = theme.colorScheme.onSurface.withOpacity(0.8);
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        normalized,
        style: theme.textTheme.labelMedium?.copyWith(color: foreground),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.palette.subtleCard,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
