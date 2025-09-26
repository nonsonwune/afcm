import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../router/app_router.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/app_shell.dart';
import '../../style/brand_theme.dart';
import '../ticket/application/ticket_providers.dart';
import 'application/auth_providers.dart';

class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  bool _codeSent = false;
  String? _feedback;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);

    return AppShell(
      trailing: TextButton(
        onPressed: () => context.goNamed(AppRoute.passes.name),
        child: const Text('View passes'),
      ),
      hero: const _SignInHero(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AuthFieldGroup(
                emailController: _emailController,
                otpController: _otpController,
                codeSent: _codeSent,
                isLoading: _isLoading,
                onPrimaryAction: () =>
                    _codeSent ? _verifyOtp() : _sendOtp(config.siteUrl),
              ),
              const SizedBox(height: 16),
              if (_feedback != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.08),
                  ),
                  child: Text(
                    _feedback!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.9),
                        ),
                  ),
                ),
              if (_codeSent)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => _sendOtp(config.siteUrl, resend: true),
                      child: const Text('Resend email'),
                    ),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              setState(() {
                                _codeSent = false;
                                _otpController.clear();
                              });
                            },
                      child: const Text('Enter a different email'),
                    ),
                  ],
                ),
              const SizedBox(height: 32),
              const _SignInSupportPanel(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendOtp(String siteUrl, {bool resend = false}) async {
    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty) {
      setState(() => _feedback = 'Enter your email address.');
      return;
    }
    setState(() {
      _isLoading = true;
      _feedback = null;
    });
    try {
      await ref.read(authRepositoryProvider).signInWithEmail(email: email);
      setState(() {
        _codeSent = true;
        _feedback = resend
            ? 'A fresh sign-in email is on its way. Follow the link or use the 6-digit code inside.'
            : 'We just sent a secure sign-in email. Open it on this device and tap the link or enter the 6-digit code below.';
      });
    } catch (error) {
      setState(() => _feedback = 'Unable to send code: $error');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final email = _emailController.text.trim().toLowerCase();
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() => _feedback = 'Enter the 6-digit code from your email.');
      return;
    }
    setState(() {
      _isLoading = true;
      _feedback = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .verifyEmailOtp(email: email, token: otp);
      await ref.read(ticketRepositoryProvider).claimAttendeeRecords(email);
      if (!mounted) return;
      context.goNamed(AppRoute.profile.name);
    } catch (error) {
      setState(() => _feedback = 'Verification failed: $error');
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

class _SignInHero extends StatelessWidget {
  const _SignInHero();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sign in to manage your AFCM experience',
          style: theme.textTheme.headlineLarge,
        ),
        const SizedBox(height: 12),
        Text(
          'We’ll send a secure magic link and a six-digit code to your registered email. You can use either to get back into your tickets.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.75),
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _AuthFieldGroup extends StatelessWidget {
  const _AuthFieldGroup({
    required this.emailController,
    required this.otpController,
    required this.codeSent,
    required this.isLoading,
    required this.onPrimaryAction,
  });

  final TextEditingController emailController;
  final TextEditingController otpController;
  final bool codeSent;
  final bool isLoading;
  final VoidCallback onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: emailController,
          enabled: !codeSent,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email address *',
            helperText: 'This must match the email you used at registration.',
          ),
        ),
        if (codeSent) ...[
          const SizedBox(height: 20),
          TextField(
            controller: otpController,
            maxLength: 6,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '6-digit code',
              helperText:
                  'You can also tap the magic link in the email if you prefer.',
            ),
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: isLoading ? null : onPrimaryAction,
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(codeSent ? 'Verify and continue' : 'Send sign-in email'),
          ),
        ),
      ],
    );
  }
}

class _SignInSupportPanel extends StatelessWidget {
  const _SignInSupportPanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.palette.subtleCard,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Need help?',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '• Search your inbox (and spam folder) for “AFCM sign-in”.\n'
            '• Magic links expire after 5 minutes—request a new one if needed.\n'
            '• Contact support@afcm.app if you switch email providers.',
            style: theme.textTheme.bodySmall?.copyWith(height: 1.6),
          ),
        ],
      ),
    );
  }
}
