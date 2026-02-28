// lib/core/router/app_router.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/admin/presentation/screens/admin_home_screen.dart';
import '../../features/admin/presentation/screens/admin_users_screen.dart';
import '../../features/admin/presentation/screens/admin_requests_screen.dart';
import '../../features/admin/presentation/screens/admin_deliveries_screen.dart';
import '../../features/admin/presentation/screens/admin_analytics_screen.dart';
import '../../features/admin/presentation/screens/admin_revenues_screen.dart';
import '../../features/admin/presentation/screens/admin_schedules_screen.dart';
import '../../features/admin/presentation/screens/admin_shifts_screen.dart';
import '../../features/admin/presentation/screens/admin_assets_screen.dart';
import '../../features/admin/presentation/screens/dispenser_detail_screen.dart';
import '../../features/admin/presentation/screens/dispenser_settings_screen.dart';
import '../../features/admin/presentation/screens/admin_expenses_screen.dart';
import '../../features/admin/presentation/screens/admin_coupon_settings_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/client/presentation/screens/client_home_screen.dart';
import '../../features/worker/presentation/screens/worker_home_screen.dart';
import '../services/storage_service.dart';

// Router Provider
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      // Auth Routes - Fade Transition
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),

      // Client Routes - Cupertino Transition
      GoRoute(
        path: '/client/home',
        name: 'client-home',
        pageBuilder: (context, state) => const CupertinoPage(
          child: ClientHomeScreen(),
        ),
      ),

      // Worker Routes
      GoRoute(
        path: '/worker/home',
        name: 'worker-home',
        pageBuilder: (context, state) => const CupertinoPage(
          child: WorkerHomeScreen(),
        ),
      ),

      // Notifications Route (shared)
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        pageBuilder: (context, state) => const CupertinoPage(
          child: NotificationsScreen(),
        ),
      ),

      // Admin Routes
      GoRoute(
        path: '/admin/home',
        name: 'admin-home',
        pageBuilder: (context, state) => const CupertinoPage(
          child: AdminHomeScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/users',
        name: 'admin-users',
        pageBuilder: (context, state) => const CupertinoPage(
          child: AdminUsersScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/requests',
        name: 'admin-requests',
        pageBuilder: (context, state) {
          final index = int.tryParse(state.uri.queryParameters['index'] ?? '0') ?? 0;
          return CupertinoPage(
            child: AdminRequestsScreen(initialIndex: index),
          );
        },
      ),
      GoRoute(
        path: '/admin/deliveries',
        name: 'admin-deliveries',
        pageBuilder: (context, state) => const CupertinoPage(
          child: AdminDeliveriesScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/analytics',
        name: 'admin-analytics',
        pageBuilder: (context, state) => const CupertinoPage(
          child: AdminAnalyticsScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/revenues',
        name: 'admin-revenues',
        pageBuilder: (context, state) => const CupertinoPage(
          child: AdminRevenuesScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/schedules',
        name: 'admin-schedules',
        pageBuilder: (context, state) => const CupertinoPage(
          child: AdminSchedulesScreen(),
        ),
        routes: [
          GoRoute(
            path: 'shifts',
            name: 'admin-shifts',
            pageBuilder: (context, state) => const CupertinoPage(
              child: AdminShiftsScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/admin/expenses',
        name: 'admin-expenses',
        pageBuilder: (context, state) => const CupertinoPage(
          child: AdminExpensesScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/coupon-settings',
        name: 'admin-coupon-settings',
        pageBuilder: (context, state) => const CupertinoPage(
          child: AdminCouponSettingsScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/assets',
        name: 'admin-assets',
        pageBuilder: (context, state) => const CupertinoPage(
          child: AdminAssetsScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/dispenser-detail/:id',
        name: 'dispenser-detail-edit',
        pageBuilder: (context, state) => CupertinoPage(
          child: DispenserDetailScreen(dispenserId: int.tryParse(state.pathParameters['id'] ?? '')),
        ),
      ),
      GoRoute(
        path: '/admin/dispenser-detail',
        name: 'dispenser-detail-new',
        pageBuilder: (context, state) => const CupertinoPage(
          child: DispenserDetailScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/dispenser-settings',
        name: 'dispenser-settings',
        pageBuilder: (context, state) => const CupertinoPage(
          child: DispenserSettingsScreen(),
        ),
      ),
    ],
    redirect: (context, state) {
      final isLoggedIn = StorageService.isLoggedIn();
      final isLoginRoute = state.matchedLocation == '/login';
      final path = state.matchedLocation;

      // Redirect logic
      if (!isLoggedIn && !isLoginRoute) {
        return '/login';
      }

      if (isLoggedIn) {
        final isAdmin = StorageService.isAdmin();
        final isWorker = StorageService.isWorker();
        final isClient = StorageService.isClient();

        if (isLoginRoute) {
          // Redirect based on role priority on login
          if (isAdmin) return '/admin/home';

          if (isWorker) {
            // Determine initial worker view
            final roles = StorageService.getRoles();
            if (roles.contains('onsite_worker')) {
              StorageService.saveWorkerView('onsite');
            } else if (roles.contains('delivery_worker')) {
              StorageService.saveWorkerView('delivery');
            }
            return '/worker/home';
          }

          if (isClient) return '/client/home';

          return '/client/home'; // Fallback
        }

        // Protect Admin routes
        if (path.startsWith('/admin') && !isAdmin) {
          if (isWorker) return '/worker/home';
          return '/client/home';
        }

        // Protect Worker routes
        if (path.startsWith('/worker') && !isWorker) {
          if (isAdmin) return '/admin/home';
          return '/client/home';
        }

        // Protect Client routes
        if (path.startsWith('/client') && !isClient) {
          if (isAdmin) return '/admin/home';
          if (isWorker) return '/worker/home';
        }
      }

      return null; // No redirect
    },
  );
});
