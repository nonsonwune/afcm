import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../router/app_router.dart';
import '../../shared/providers/app_providers.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Access your AFCM ticket',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Enter the email you used to register. We will send a one-time passcode to sign you in securely.',
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _emailController,
                  enabled: !_codeSent,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email address *'),
                ),
                const SizedBox(height: 16),
                if (_codeSent)
                  TextField(
                    controller: _otpController,
                    maxLength: 6,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '6-digit code *'),
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isLoading ? null : () => _codeSent ? _verifyOtp() : _sendOtp(config.siteUrl),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_codeSent ? 'Verify code' : 'Send sign-in code'),
                  ),
                ),
                if (_feedback != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      _feedback!,
                      style: TextStyle(color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                if (_codeSent)
                  TextButton(
                    onPressed: _isLoading ? null : () => _sendOtp(config.siteUrl, resend: true),
                    child: const Text('Resend code'),
                  ),
              ],
            ),
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
        _feedback = resend ? 'Code resent. Check your inbox.' : 'Code sent. Please check your email.';
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
      await ref.read(authRepositoryProvider).verifyEmailOtp(email: email, token: otp);
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

