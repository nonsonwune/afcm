import 'package:flutter/material.dart';

class PassesPage extends StatelessWidget {
  const PassesPage({super.key});

  static const _passes = <Map<String, String>>[
    {'name': '1-Day Pass', 'price': 'NGN 75,000', 'summary': 'Single-day access to conference programming.'},
    {'name': '2-Day Pass', 'price': 'NGN 135,000', 'summary': 'Choose any two consecutive event days.'},
    {'name': '3-Day Pass', 'price': 'NGN 202,500', 'summary': 'Great for extended networking and meetings.'},
    {'name': '4-Day All-Access', 'price': 'NGN 270,000', 'summary': 'Full access across all venues and activations.'},
    {'name': 'Early-Bird 4-Day', 'price': 'NGN 240,000', 'summary': 'Limited-time offer for the full experience.'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Passes')),
      body: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemBuilder: (context, index) {
          final pass = _passes[index];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    pass['name']!,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(pass['summary']!),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        pass['price']!,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      FilledButton(
                        onPressed: () {},
                        child: const Text('Select'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemCount: _passes.length,
      ),
    );
  }
}
