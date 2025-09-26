import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'application/staff_providers.dart';
import 'data/staff_repository.dart';
import 'widgets/staff_scaffold.dart';
import '../../style/brand_theme.dart';

final _orderStatusFilterProvider = StateProvider<String>((ref) => 'pending');

class StaffOrdersPage extends ConsumerStatefulWidget {
  const StaffOrdersPage({super.key});

  @override
  ConsumerState<StaffOrdersPage> createState() => _StaffOrdersPageState();
}

class _StaffOrdersPageState extends ConsumerState<StaffOrdersPage> {
  final Set<String> _pendingActions = <String>{};
  final _currencyFormat = NumberFormat.currency(symbol: '₦', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final statusFilter = ref.watch(_orderStatusFilterProvider);
    final ordersAsync = ref.watch(staffOrdersProvider(statusFilter));

    return StaffScaffold(
      currentSection: StaffSection.orders,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Orders',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                _StatusFilterChip(
                  label: 'Pending',
                  value: 'pending',
                  groupValue: statusFilter,
                  onSelected: (value) =>
                      ref.read(_orderStatusFilterProvider.notifier).state = value,
                ),
                const SizedBox(width: 8),
                _StatusFilterChip(
                  label: 'Paid',
                  value: 'paid',
                  groupValue: statusFilter,
                  onSelected: (value) =>
                      ref.read(_orderStatusFilterProvider.notifier).state = value,
                ),
                const SizedBox(width: 8),
                _StatusFilterChip(
                  label: 'All',
                  value: 'all',
                  groupValue: statusFilter,
                  onSelected: (value) =>
                      ref.read(_orderStatusFilterProvider.notifier).state = value,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ordersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _ErrorState(
                  message: 'Unable to load orders: $error',
                  onRetry: () => ref.invalidate(staffOrdersProvider(statusFilter)),
                ),
                data: (orders) {
                  if (orders.isEmpty) {
                    return const _EmptyState(
                      message: 'No orders match the selected filter yet.',
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(staffOrdersProvider(statusFilter));
                    },
                    child: ListView.separated(
                      itemCount: orders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        final amountDisplay = order.currency.toUpperCase() == 'NGN'
                            ? _currencyFormat.format(order.amountMajor)
                            : '${order.currency.toUpperCase()} ${NumberFormat.decimalPattern().format(order.amountMajor)}';
                        final processing = _pendingActions.contains(order.id);
                        return Card(
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      order.passName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                    const Spacer(),
                                    _StatusBadge(status: order.status),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 16,
                                  runSpacing: 8,
                                  children: [
                                    _InfoChip(
                                      icon: Icons.person,
                                      label: order.attendeeName,
                                    ),
                                    _InfoChip(
                                      icon: Icons.email,
                                      label: order.attendeeEmail,
                                    ),
                                    _InfoChip(
                                      icon: Icons.confirmation_number,
                                      label: order.passSku,
                                    ),
                                    _InfoChip(
                                      icon: Icons.attach_money,
                                      label: amountDisplay,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Created ${DateFormat.yMMMd().add_jm().format(order.createdAt.toLocal())}',
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
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    FilledButton.icon(
                                      onPressed: (order.status == 'pending' && !processing)
                                          ? () => _markPaid(context, order.id, statusFilter)
                                          : null,
                                      icon: processing
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2),
                                            )
                                          : const Icon(Icons.check_circle),
                                      label: const Text('Mark paid'),
                                    ),
                                    const SizedBox(width: 12),
                                    OutlinedButton.icon(
                                      onPressed: (order.status == 'pending' && !processing)
                                          ? () => _markFailed(context, order.id, statusFilter)
                                          : null,
                                      icon: const Icon(Icons.cancel),
                                      label: const Text('Mark failed'),
                                    ),
                                  ],
                                ),
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

  Future<void> _markPaid(
      BuildContext context, String orderId, String statusFilter) async {
    setState(() => _pendingActions.add(orderId));
    final repository = ref.read(staffRepositoryProvider);
    try {
      await repository.markOrderPaid(orderId);
      ref.invalidate(staffOrdersProvider(statusFilter));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Order marked paid.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Unable to mark paid: $error')));
      }
    } finally {
      if (mounted) {
        setState(() => _pendingActions.remove(orderId));
      }
    }
  }

  Future<void> _markFailed(
      BuildContext context, String orderId, String statusFilter) async {
    setState(() => _pendingActions.add(orderId));
    final repository = ref.read(staffRepositoryProvider);
    try {
      await repository.markOrderFailed(orderId);
      ref.invalidate(staffOrdersProvider(statusFilter));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order marked as failed.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Unable to update order: $error')));
      }
    } finally {
      if (mounted) {
        setState(() => _pendingActions.remove(orderId));
      }
    }
  }
}

class _StatusFilterChip extends StatelessWidget {
  const _StatusFilterChip({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onSelected,
  });

  final String label;
  final String value;
  final String groupValue;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: groupValue == value,
      onSelected: (_) => onSelected(value),
    );
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
      case 'FAILED':
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
