import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../router/app_router.dart';
import '../../shared/models/order_models.dart';
import '../../shared/widgets/app_shell.dart';
import '../../style/brand_theme.dart';
import 'application/registration_controller.dart';
import 'models/registration_flow.dart';

const _termsUrl = 'https://afcm.app/terms';
const _privacyUrl = 'https://afcm.app/privacy';

class RegistrationPage extends ConsumerStatefulWidget {
  const RegistrationPage({super.key, this.args});

  final RegistrationFlowArgs? args;

  @override
  ConsumerState<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends ConsumerState<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _companyController;
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;
  String _selectedCurrency = 'NGN';
  bool _acceptedTerms = false;
  bool _termsTouched = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _companyController = TextEditingController();
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () => _openLink(_termsUrl);
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () => _openLink(_privacyUrl);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  Future<void> _openLink(String url) async {
    final success = await launchUrlString(url);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open link right now.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = widget.args;
    if (args == null) {
      return AppShell(
        trailing: TextButton(
          onPressed: () => context.goNamed(AppRoute.passes.name),
          child: const Text('View passes'),
        ),
        hero: const _RegistrationFallbackHero(),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose a pass to get started.',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Once you’ve selected a pass, we’ll capture your details and send a Paystack invoice instantly.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(height: 1.6),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () => context.goNamed(AppRoute.passes.name),
                      child: const Text('Browse passes'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final controllerState = ref.watch(registrationControllerProvider);

    return AppShell(
      trailing: TextButton(
        onPressed: controllerState.isLoading
            ? null
            : () => context.goNamed(AppRoute.passes.name),
        child: const Text('Change pass'),
      ),
      hero: _RegistrationHero(passName: args.pass.name, role: args.role),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 920;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: const [
                  _ProgressBadge(step: 'Attendee details', isActive: true),
                  _ProgressBadge(step: 'Invoice sent'),
                  _ProgressBadge(step: 'Payment + ticket'),
                ],
              ),
              const SizedBox(height: 24),
              Flex(
                direction: isWide ? Axis.horizontal : Axis.vertical,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tell us about you',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'These details appear on your invoice and ticket. We’ll only use them for event communications.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(height: 1.5),
                              ),
                              const SizedBox(height: 24),
                              _buildTextField(
                                controller: _nameController,
                                label: 'Full name *',
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                        ? 'Enter your name'
                                        : null,
                              ),
                              const SizedBox(height: 20),
                              _buildTextField(
                                controller: _emailController,
                                label: 'Email address *',
                                keyboardType: TextInputType.emailAddress,
                                helperText:
                                    'Invoice, confirmations, and ticket delivery will go here.',
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Enter your email';
                                  }
                                  final emailRegex =
                                      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                                  if (!emailRegex.hasMatch(value.trim())) {
                                    return 'Enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              _buildTextField(
                                controller: _phoneController,
                                label: 'Phone number *',
                                keyboardType: TextInputType.phone,
                                helperText:
                                    'Optional for WhatsApp updates, but strongly recommended.',
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                        ? 'Enter your phone number'
                                        : null,
                              ),
                              const SizedBox(height: 20),
                              _buildTextField(
                                controller: _companyController,
                                label: 'Company / Organisation',
                                helperText:
                                    'Appears on your badge so partners can identify you quickly.',
                              ),
                              const SizedBox(height: 20),
                              DropdownButtonFormField<String>(
                                value: _selectedCurrency,
                                decoration: const InputDecoration(
                                  labelText: 'Invoice currency',
                                  helperText:
                                      'Choose the currency displayed on your Paystack invoice.',
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'NGN',
                                    child: Text('Nigerian Naira (₦)'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'USD',
                                    child:
                                        Text('US Dollar (shown for reference)'),
                                  ),
                                ],
                                onChanged: controllerState.isLoading
                                    ? null
                                    : (value) => setState(() {
                                          _selectedCurrency = value ?? 'NGN';
                                        }),
                              ),
                              const SizedBox(height: 20),
                              CheckboxListTile(
                                value: _acceptedTerms,
                                onChanged: controllerState.isLoading
                                    ? null
                                    : (value) => setState(() {
                                          _acceptedTerms = value ?? false;
                                          _termsTouched = true;
                                        }),
                                contentPadding: EdgeInsets.zero,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                title: RichText(
                                  text: TextSpan(
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(height: 1.5),
                                    children: [
                                      const TextSpan(text: 'I agree to the '),
                                      TextSpan(
                                        text: 'AFCM terms of service',
                                        style: TextStyle(
                                          decoration: TextDecoration.underline,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                        recognizer: _termsRecognizer,
                                      ),
                                      const TextSpan(text: ' and '),
                                      TextSpan(
                                        text: 'privacy notice',
                                        style: TextStyle(
                                          decoration: TextDecoration.underline,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                        recognizer: _privacyRecognizer,
                                      ),
                                      const TextSpan(text: '.'),
                                    ],
                                  ),
                                ),
                              ),
                              if (!_acceptedTerms && _termsTouched)
                                if (!_acceptedTerms && _termsTouched)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 12, bottom: 8),
                                    child: Text(
                                      'Please accept the terms to continue.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .error,
                                          ),
                                    ),
                                  ),
                              const SizedBox(height: 28),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: controllerState.isLoading
                                      ? null
                                      : () => _submit(args),
                                  child: controllerState.isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        )
                                      : const Text('Send Paystack invoice'),
                                ),
                              ),
                              if (controllerState.hasError)
                                Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(18),
                                      color: Theme.of(context)
                                          .colorScheme
                                          .error
                                          .withOpacity(0.12),
                                    ),
                                    child: Text(
                                      controllerState.error.toString(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .error,
                                          ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: isWide ? 24 : 0, height: isWide ? 0 : 24),
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _PassSummaryCard(
                          args: args,
                          selectedCurrency: _selectedCurrency,
                        ),
                        const SizedBox(height: 16),
                        const _RegistrationSupportCard(),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _submit(RegistrationFlowArgs args) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptedTerms) {
      setState(() => _termsTouched = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please accept the terms to proceed.')),
        );
      }
      return;
    }

    final payload = CreateOrderPayload(
      passSku: args.pass.sku,
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim().toLowerCase(),
      attendeeRole: args.role,
      phone: _phoneController.text.trim(),
      company: _companyController.text.trim().isEmpty
          ? null
          : _companyController.text.trim(),
      currency: _selectedCurrency,
      acceptedTerms: _acceptedTerms,
      termsVersion: registrationTermsVersion,
    );

    try {
      final result = await ref
          .read(registrationControllerProvider.notifier)
          .submit(payload);
      if (!mounted) return;
      context.goNamed(
        AppRoute.registrationStatus.name,
        extra: RegistrationSuccessArgs(
          result: result,
          pass: args.pass,
          email: payload.email,
          fullName: payload.fullName,
          role: args.role,
          currency: _selectedCurrency,
        ),
      );
    } catch (_) {
      // Errors surfaced via controller state.
    }
  }
}

TextFormField _buildTextField({
  required TextEditingController controller,
  required String label,
  TextInputType? keyboardType,
  String? helperText,
  String? Function(String?)? validator,
}) {
  return TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    decoration: InputDecoration(
      labelText: label,
      helperText: helperText,
    ),
    validator: validator,
  );
}

class _RegistrationHero extends StatelessWidget {
  const _RegistrationHero({required this.passName, required this.role});

  final String passName;
  final String role;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Confirm your AFCM registration',
          style: theme.textTheme.headlineLarge,
        ),
        const SizedBox(height: 12),
        Text(
          '$passName · ${role[0].toUpperCase()}${role.substring(1)}',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Complete the attendee form and we’ll email a Paystack invoice immediately. Once payment is captured, your ticket and QR code unlock automatically.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.75),
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _RegistrationFallbackHero extends StatelessWidget {
  const _RegistrationFallbackHero();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose a pass to continue',
          style: theme.textTheme.headlineLarge,
        ),
        const SizedBox(height: 12),
        Text(
          'Pass selection kickstarts registration. Every pass includes QR ticketing, meeting access, and onsite concierge support.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.75),
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _ProgressBadge extends StatelessWidget {
  const _ProgressBadge({
    required this.step,
    this.isActive = false,
  });

  final String step;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = isActive
        ? theme.colorScheme.primary.withOpacity(0.1)
        : theme.palette.subtleCard;
    final foreground = isActive
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withOpacity(0.7);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: foreground,
          ),
          const SizedBox(width: 8),
          Text(
            step,
            style: theme.textTheme.labelLarge?.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}

class _PassSummaryCard extends StatelessWidget {
  const _PassSummaryCard({
    required this.args,
    required this.selectedCurrency,
  });

  final RegistrationFlowArgs args;
  final String selectedCurrency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nairaFormat = NumberFormat.currency(symbol: '₦', decimalDigits: 0);
    final usdReference = args.pass.displayAmountUsd;
    final usdDisplay = usdReference != null
        ? 'USD ' + NumberFormat.decimalPattern().format(usdReference)
        : null;
    final priceNaira = nairaFormat.format(args.pass.amountNaira);
    return Card(
      margin: EdgeInsets.zero,
      color: theme.palette.subtleCard,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pass summary',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _summaryRow(
              context,
              label: 'Role',
              value: args.role.isEmpty
                  ? 'Attendee'
                  : args.role[0].toUpperCase() + args.role.substring(1),
            ),
            const SizedBox(height: 12),
            _summaryRow(context, label: 'Pass', value: args.pass.name),
            const SizedBox(height: 12),
            _summaryRow(
              context,
              label: 'Price (₦)',
              value: priceNaira,
            ),
            if (usdDisplay != null) ...[
              const SizedBox(height: 12),
              _summaryRow(
                context,
                label: 'USD reference',
                value: '~ ' + usdDisplay,
              ),
            ],
            const SizedBox(height: 12),
            _summaryRow(
              context,
              label: 'Access',
              value: args.pass.validityLabel,
            ),
            const SizedBox(height: 20),
            Text(
              selectedCurrency == 'USD'
                  ? 'Your Paystack invoice is settled in NGN. USD pricing is shown for planning only.'
                  : 'You’ll receive a Paystack invoice and email receipt immediately. Please settle payment within 48 hours to secure your seat.',
              style: theme.textTheme.bodySmall?.copyWith(height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(BuildContext context,
      {required String label, required String value}) {
    final theme = Theme.of(context);
    return Row(
      children: [
        SizedBox(
          width: 88,
          child: Text(
            label,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _RegistrationSupportCard extends StatelessWidget {
  const _RegistrationSupportCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What happens next?',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _infoRow(
              icon: Icons.receipt_long,
              text:
                  'Paystack invoice arrives instantly—check spam if you don’t see it within 2 minutes.',
            ),
            const SizedBox(height: 12),
            _infoRow(
              icon: Icons.verified_user,
              text:
                  'Payment confirmation triggers your ticket email, calendar invite, and QR code.',
            ),
            const SizedBox(height: 12),
            _infoRow(
              icon: Icons.support_agent,
              text:
                  'Questions? Email tickets@afcm.app and our concierge team will assist.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow({required IconData icon, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(height: 1.5),
          ),
        ),
      ],
    );
  }
}
