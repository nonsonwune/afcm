import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router/router.dart';

class AFCMApp extends ConsumerWidget {
  const AFCMApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'AFCM Event',
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }

  ThemeData _buildLightTheme() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: const Color(0xFF005D5D),
        secondary: const Color(0xFF00A6A6),
        surface: Colors.white,
      ),
      textTheme: base.textTheme.apply(fontFamily: 'Roboto'),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  ThemeData _buildDarkTheme() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: const Color(0xFF4DD0E1),
        secondary: const Color(0xFF80DEEA),
      ),
      textTheme: base.textTheme.apply(fontFamily: 'Roboto'),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}
