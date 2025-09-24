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
import '../auth/application/auth_providers.dart';
import 'application/ticket_providers.dart';

class MyTicketPage extends ConsumerWidget {
  const MyTicketPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    if (!isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Ticket')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                  'Sign in with the email you used during registration to view your ticket.'),
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

    final ticketAsync = ref.watch(ticketProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Ticket'),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
              final store = await ref.read(ticketLocalStoreProvider.future);
              await store.clear();
            },
            child: const Text('Sign out'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(ticketProvider);
          await ref
              .read(ticketProvider.future)
              .timeout(const Duration(seconds: 10));
        },
        child: ticketAsync.when(
          loading: () => const _LoadingState(),
          error: (error, _) => ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text('Unable to load ticket. ${error.toString()}'),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => ref.invalidate(ticketProvider),
                child: const Text('Try again'),
              ),
            ],
          ),
          data: (ticket) {
            if (ticket == null) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: const [
                  Text(
                    'No ticket found yet. Once your payment is confirmed, return to this page to see your QR ticket.',
                  ),
                ],
              );
            }

            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _TicketCard(ticket: ticket),
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

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket});

  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('EEE, MMM d · h:mm a');
    final validFrom = formatter.format(ticket.validFrom.toLocal());
    final validTo = formatter.format(ticket.validTo.toLocal());

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('AFCM 2025', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(ticket.passName,
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 24),
            Center(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade200),
                ),
                padding: const EdgeInsets.all(16),
                child: QrImageView(
                  data: ticket.payloadJson,
                  version: QrVersions.auto,
                  size: 220,
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Serial: ${ticket.serialNumber}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
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
          ],
        ),
      ),
    );
  }

  void _downloadIcs(Ticket ticket) {
    final base64Data = ticket.icsBase64;
    if (base64Data == null || base64Data.isEmpty) {
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
