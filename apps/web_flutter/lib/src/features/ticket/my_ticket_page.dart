// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:convert';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../router/app_router.dart';
import '../../shared/models/ticket_models.dart';
import '../../shared/widgets/app_shell.dart';
import '../../style/brand_theme.dart';
import '../auth/application/auth_providers.dart';
import 'application/ticket_providers.dart';

class MyTicketPage extends ConsumerWidget {
  const MyTicketPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    if (!isAuthenticated) {
      return AppShell(
        trailing: TextButton(
          onPressed: () => context.goNamed(AppRoute.signIn.name),
          child: const Text('Sign in'),
        ),
        hero: const _TicketFallbackHero(),
        body: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Use the email you registered with to unlock your NFC badge and QR ticket.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      );
    }

    final ticketAsync = ref.watch(ticketProvider);

    return AppShell(
      trailing: TextButton(
        onPressed: () async {
          await ref.read(authRepositoryProvider).signOut();
          final store = await ref.read(ticketLocalStoreProvider.future);
          await store.clear();
        },
        child: const Text('Sign out'),
      ),
      hero: const _TicketHero(),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(ticketProvider);
          await ref
              .read(ticketProvider.future)
              .timeout(const Duration(seconds: 10));
        },
        child: ticketAsync.when(
          loading: () => const _LoadingState(),
          error: (error, _) => _TicketErrorState(
            message: 'Unable to load ticket. ${error.toString()}',
            onRetry: () => ref.invalidate(ticketProvider),
          ),
          data: (ticket) {
            if (ticket == null) {
              return const _TicketPendingState();
            }

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 24),
              children: [
                _TicketCard(ticket: ticket),
                const SizedBox(height: 16),
                const _TicketSupportCard(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _TicketErrorState extends StatelessWidget {
  const _TicketErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message),
                const SizedBox(height: 12),
                OutlinedButton(
                    onPressed: onRetry, child: const Text('Try again')),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TicketPendingState extends StatelessWidget {
  const _TicketPendingState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ticket not issued yet',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  'Once your Paystack payment is confirmed, this page will display your QR ticket automatically. You will also receive an email copy.',
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.6),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TicketSupportCard extends StatelessWidget {
  const _TicketSupportCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Card(
        color: theme.palette.subtleCard,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Need a hand?',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'If you changed devices or can’t access your ticket, email tickets@afcm.app. Our concierge team can reissue your QR code instantly.',
                style: theme.textTheme.bodySmall?.copyWith(height: 1.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TicketHero extends StatelessWidget {
  const _TicketHero();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your NFC + QR ticket', style: theme.textTheme.headlineLarge),
        const SizedBox(height: 12),
        Text(
          'Keep this page handy at the door. You can also add the event to your calendar or download a static backup.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.78),
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _TicketFallbackHero extends StatelessWidget {
  const _TicketFallbackHero();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sign in to view tickets', style: theme.textTheme.headlineLarge),
        const SizedBox(height: 12),
        Text(
          'Your QR code is protected behind a secure sign-in. Use the email you registered with to continue.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.75),
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket});

  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('EEE, MMM d · h:mm a');
    final validFrom = formatter.format(ticket.validFrom.toLocal());
    final validTo = formatter.format(ticket.validTo.toLocal());

    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('AFCM 2025', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              ticket.passName,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: theme.colorScheme.surface,
                  border:
                      Border.all(color: theme.palette.subtleCard, width: 1.5),
                ),
                padding: const EdgeInsets.all(16),
                child: QrImageView(
                  data: ticket.payloadJson,
                  version: QrVersions.auto,
                  size: 220,
                  foregroundColor: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Serial: ${ticket.serialNumber}',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text('Valid from: $validFrom'),
            Text('Valid until: $validTo'),
            const SizedBox(height: 16),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: ticket.icsBase64 == null
                      ? null
                      : () => _downloadIcs(ticket),
                  icon: const Icon(Icons.calendar_month),
                  label: const Text('Add to calendar'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => _copyPayload(context, ticket),
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy QR payload'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Tip: save a screenshot or add to your wallet in case network coverage is limited onsite.',
              style: theme.textTheme.bodySmall?.copyWith(height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  void _downloadIcs(Ticket ticket) {
    final base64Data = ticket.icsBase64;
    if (base64Data == null || base64Data.isEmpty) {
      if (ticket.icsSignedUrl != null && ticket.icsSignedUrl!.isNotEmpty) {
        html.window.open(ticket.icsSignedUrl!, '_blank');
      }
      return;
    }
    final bytes = base64Decode(base64Data);
    final blob = html.Blob([bytes], 'text/calendar');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..download = 'afcm-ticket.ics'
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  void _copyPayload(BuildContext context, Ticket ticket) {
    html.window.navigator.clipboard?.writeText(ticket.payloadJson);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('QR payload copied.')),
    );
  }
}
