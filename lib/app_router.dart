import 'package:go_router/go_router.dart';

import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/signup_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupScreen(),
    ),
  ],
);
