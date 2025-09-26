import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/application/auth_providers.dart';
import '../features/auth/sign_in_page.dart';
import '../features/passes/passes_page.dart';
import '../features/profile/profile_page.dart';
import '../features/registration/registration_page.dart';
import '../features/registration/registration_status_page.dart';
import '../features/registration/models/registration_flow.dart';
import '../features/ticket/my_ticket_page.dart';
import '../features/staff/staff_attendees_page.dart';
import '../features/staff/staff_orders_page.dart';

enum AppRoute {
  passes('/passes'),
  register('/register'),
  registrationStatus('/register/status'),
  myTicket('/me/ticket'),
  profile('/me/profile'),
  signIn('/sign-in'),
  staffOrders('/staff/orders'),
  staffAttendees('/staff/attendees');

  const AppRoute(this.path);

  final String path;
}

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final goRouterProvider = Provider<GoRouter>((ref) {
  final refreshAuth = GoRouterRefreshAuth(ref);
  ref.onDispose(refreshAuth.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoute.passes.path,
    refreshListenable: refreshAuth,
    routes: [
      GoRoute(
        path: AppRoute.passes.path,
        name: AppRoute.passes.name,
        builder: (context, state) => const PassesPage(),
      ),
      GoRoute(
        path: AppRoute.register.path,
        name: AppRoute.register.name,
        builder: (context, state) => RegistrationPage(
          args: state.extra as RegistrationFlowArgs?,
        ),
      ),
      GoRoute(
        path: AppRoute.registrationStatus.path,
        name: AppRoute.registrationStatus.name,
        builder: (context, state) => RegistrationStatusPage(
          args: state.extra as RegistrationSuccessArgs?,
        ),
      ),
      GoRoute(
        path: AppRoute.signIn.path,
        name: AppRoute.signIn.name,
        builder: (context, state) => const SignInPage(),
      ),
      GoRoute(
        path: AppRoute.myTicket.path,
        name: AppRoute.myTicket.name,
        builder: (context, state) => const MyTicketPage(),
      ),
      GoRoute(
        path: AppRoute.profile.path,
        name: AppRoute.profile.name,
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: AppRoute.staffOrders.path,
        name: AppRoute.staffOrders.name,
        builder: (context, state) => const StaffOrdersPage(),
      ),
      GoRoute(
        path: AppRoute.staffAttendees.path,
        name: AppRoute.staffAttendees.name,
        builder: (context, state) => const StaffAttendeesPage(),
      ),
    ],
    redirect: (context, state) {
      final isLoggedIn = ref.read(isAuthenticatedProvider);
      final loggingIn = state.matchedLocation == AppRoute.signIn.path;

      if (!isLoggedIn &&
          (state.matchedLocation.startsWith('/me') ||
              state.matchedLocation.startsWith('/staff'))) {
        return AppRoute.signIn.path;
      }
      if (isLoggedIn && loggingIn) {
        return AppRoute.profile.path;
      }
      return null;
    },
  );
});
