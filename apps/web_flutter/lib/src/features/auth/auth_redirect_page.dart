import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../router/app_router.dart';
import '../ticket/application/ticket_providers.dart';

class AuthRedirectPage extends ConsumerStatefulWidget {
  const AuthRedirectPage({super.key, required this.uri});

  final Uri uri;

  @override
  ConsumerState<AuthRedirectPage> createState() => _AuthRedirectPageState();
}

class _AuthRedirectPageState extends ConsumerState<AuthRedirectPage> {
  String? _error;

  @override
  void initState() {
    super.initState();
    _handleRedirect();
  }

  Future<void> _handleRedirect() async {
    try {
      final client = Supabase.instance.client;
      await client.auth.getSessionFromUrl(widget.uri, storeSession: true);
      final email = client.auth.currentUser?.email;
      if (email != null) {
        await ref
            .read(ticketRepositoryProvider)
            .claimAttendeeRecords(email);
      }
      if (!mounted) return;
      context.goNamed(AppRoute.profile.name);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _error == null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Verifying your sign-in link…',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline,
                        size: 48, color: theme.colorScheme.error),
                    const SizedBox(height: 12),
                    Text(
                      'We couldn’t verify your sign-in link.',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => context.goNamed(AppRoute.signIn.name),
                      child: const Text('Back to sign in'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
