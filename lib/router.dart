import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'presentation/auth/login_screen.dart';
import 'presentation/auth/register_screen.dart';
import 'presentation/user/user_shell.dart';
import 'presentation/user/home_screen.dart';
import 'presentation/user/my_bookings_screen.dart';
import 'presentation/user/profile_screen.dart';
import 'presentation/user/room_detail_screen.dart';
import 'presentation/admin/admin_shell.dart';
import 'presentation/admin/dashboard_screen.dart';
import 'presentation/admin/manage_rooms_screen.dart';
import 'presentation/admin/manage_bookings_screen.dart';
import 'presentation/admin/manage_users_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _userShellKey = GlobalKey<NavigatorState>(debugLabel: 'userShell');
final _adminShellKey = GlobalKey<NavigatorState>(debugLabel: 'adminShell');

GoRouter buildRouter(BuildContext context) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    redirect: (ctx, state) {
      final auth = ctx.read<AuthProvider>();
      final loggedIn = auth.isLoggedIn;
      final isAuth = state.matchedLocation == '/login' || state.matchedLocation == '/register';

      // If user is blocked, logout and redirect to login
      if (loggedIn && auth.currentUser?.isBlocked == true) {
        auth.logout();
        return '/login';
      }

      if (!loggedIn && !isAuth) return '/login';
      if (loggedIn && isAuth) {
        return auth.isAdmin ? '/admin' : '/user';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),

      // User flow
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: _rootNavigatorKey,
        builder: (ctx, state, navigationShell) =>
            UserShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            navigatorKey: _userShellKey,
            routes: [
              GoRoute(
                path: '/user',
                pageBuilder: (_, state) => CustomTransitionPage(
                  key: state.pageKey,
                  child: const HomeScreen(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.0, 0.05),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                ),
                routes: [
                  GoRoute(
                    path: 'room/:id',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (_, state) => RoomDetailScreen(
                      roomId: int.parse(state.pathParameters['id']!),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/user/bookings',
                pageBuilder: (_, state) => CustomTransitionPage(
                  key: state.pageKey,
                  child: const MyBookingsScreen(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.0, 0.05),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/user/profile',
                pageBuilder: (_, state) => CustomTransitionPage(
                  key: state.pageKey,
                  child: const ProfileScreen(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.0, 0.05),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),

      // Admin flow
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: _rootNavigatorKey,
        builder: (ctx, state, navigationShell) =>
            AdminShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            navigatorKey: _adminShellKey,
            routes: [
              GoRoute(path: '/admin', builder: (_, __) => const DashboardScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/admin/rooms', builder: (_, __) => const ManageRoomsScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/admin/bookings', builder: (_, __) => const ManageBookingsScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/admin/users', builder: (_, __) => const ManageUsersScreen()),
            ],
          ),
        ],
      ),
    ],
  );
}
