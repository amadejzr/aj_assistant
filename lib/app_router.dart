import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/logging/log.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_state.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/signup_screen.dart';
import 'features/home/home_screen.dart';
import 'features/marketplace/screens/marketplace_screen.dart';
import 'features/marketplace/screens/template_detail_screen.dart';
import 'features/capabilities/screens/reminders_screen.dart';
import 'features/modules/screens/module_info_screen.dart';
import 'features/modules/screens/module_viewer_screen.dart';
import 'features/shell/shell_screen.dart';
import 'features/splash/splash_screen.dart';

const _tag = 'Router';

GoRouter createRouter(AuthBloc authBloc) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) {
      final authState = authBloc.state;
      final location = state.matchedLocation;

      final isResolving = authState is AuthInitial;
      final isAuthenticated = authState is AuthAuthenticated;
      final isOnAuth =
          location == '/login' || location == '/signup';
      final isOnSplash = location == '/splash';

      // Still resolving and not on splash → send to splash
      if (isResolving && !isOnSplash) {
        Log.d('auth resolving → /splash', tag: _tag);
        return '/splash';
      }

      // Splash owns its own exit — never redirect away from it
      if (isOnSplash) return null;

      // Unauthenticated on a protected page → login
      if (!isAuthenticated && !isOnAuth) {
        Log.d('unauthenticated → /login', tag: _tag);
        return '/login';
      }

      // Authenticated but still on auth pages → home
      if (isAuthenticated && isOnAuth) {
        Log.d('authenticated → /home', tag: _tag);
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _pageFadeSlide(
          key: state.pageKey,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/signup',
        pageBuilder: (context, state) => _pageFadeSlide(
          key: state.pageKey,
          child: const SignupScreen(),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return ShellScreen(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
        ],
      ),
      // Marketplace — full-screen, outside the shell
      GoRoute(
        path: '/marketplace',
        pageBuilder: (context, state) => _pageFadeSlide(
          key: state.pageKey,
          child: const MarketplaceScreen(),
        ),
        routes: [
          GoRoute(
            path: ':templateId',
            pageBuilder: (context, state) {
              final templateId = state.pathParameters['templateId']!;
              return _pageFadeSlide(
                key: state.pageKey,
                child: TemplateDetailScreen(templateId: templateId),
              );
            },
          ),
        ],
      ),
      // Reminders — full-screen, outside the shell
      GoRoute(
        path: '/reminders',
        pageBuilder: (context, state) {
          final moduleId = state.uri.queryParameters['module'];
          return _pageFadeSlide(
            key: state.pageKey,
            child: RemindersScreen(moduleId: moduleId),
          );
        },
      ),
      // Module viewer — full-screen, outside the shell (no bottom nav / chat FAB)
      GoRoute(
        path: '/module/:moduleId',
        pageBuilder: (context, state) {
          final moduleId = state.pathParameters['moduleId']!;
          return _pageFadeSlide(
            key: state.pageKey,
            child: ModuleViewerScreen(moduleId: moduleId),
          );
        },
        routes: [
          GoRoute(
            path: 'info',
            pageBuilder: (context, state) {
              final moduleId = state.pathParameters['moduleId']!;
              return _pageFadeSlide(
                key: state.pageKey,
                child: ModuleInfoScreen(moduleId: moduleId),
              );
            },
          ),
        ],
      ),
    ],
  );
}

/// Page transition: fade in + gentle upward slide — like a notebook
/// page being placed down.
CustomTransitionPage<void> _pageFadeSlide({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 500),
    reverseTransitionDuration: const Duration(milliseconds: 350),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fade = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
      );
      final slide = Tween(
        begin: const Offset(0, 0.03),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      ));

      return FadeTransition(
        opacity: fade,
        child: SlideTransition(position: slide, child: child),
      );
    },
  );
}

/// Converts a [Stream] into a [ChangeNotifier] for GoRouter's
/// `refreshListenable`.
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
