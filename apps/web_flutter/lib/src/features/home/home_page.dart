import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_config.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AFCM Event Platform'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Welcome to the AFCM event experience.',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Text(
                'This preview confirms that the Flutter PWA shell, routing, and theme are configured.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Image.asset(
                AppConfig.fromEnvironment().floorPlanAsset,
                height: 200,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 32),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 16,
                children: <Widget>[
                  ElevatedButton(
                    onPressed: () => context.go('/passes'),
                    child: const Text('View Passes'),
                  ),
                  OutlinedButton(
                    onPressed: () => context.go('/me/ticket'),
                    child: const Text('My Ticket'),
                  ),
                  TextButton(
                    onPressed: () => context.go('/signin'),
                    child: const Text('Staff Sign In'),
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
