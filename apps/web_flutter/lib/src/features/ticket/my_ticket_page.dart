import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class MyTicketPage extends StatelessWidget {
  const MyTicketPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Ticket')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              QrImageView(
                data: 'AFCM1.demo.ticket',
                version: QrVersions.auto,
                size: 200,
                gapless: false,
              ),
              const SizedBox(height: 16),
              Text(
                'Ticket preview is available offline once cached by the service worker.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {},
                child: const Text('Download ICS'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
