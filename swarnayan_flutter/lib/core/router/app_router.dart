import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/shell/app_shell.dart';
import '../../features/home/home_screen.dart';
import '../../features/billing/billing_screen.dart';
import '../../features/customers/customers_screen.dart';
import '../../features/customers/customer_detail_screen.dart';
import '../../features/customers/add_customer_dialog.dart';
import '../../features/products/products_screen.dart';
import '../../features/products/add_product_screen.dart';
import '../../features/more/more_screen.dart';
import '../../features/more/rate_management_screen.dart';
import '../../features/more/record_book_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/auth_provider.dart';
import '../../models/product.dart';
import '../../models/customer.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      final authState = ref.read(authProvider);

      if (authState.isLoading) return null;

      final isLoggingIn = state.uri.toString() == '/login';

      if (!authState.isAuthenticated) {
        return '/login';
      }

      if (isLoggingIn) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _buildPage(
          const LoginScreen(),
          state,
        ),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => _buildPage(
              const HomeScreen(),
              state,
            ),
          ),
          GoRoute(
            path: '/billing',
            pageBuilder: (context, state) => _buildPage(
              const BillingScreen(),
              state,
            ),
          ),
          GoRoute(
            path: '/customers',
            pageBuilder: (context, state) => _buildPage(
              const CustomersScreen(),
              state,
            ),
            routes: [
              GoRoute(
                path: 'add',
                parentNavigatorKey: _rootNavigatorKey,
                pageBuilder: (context, state) => _buildSlidePage(
                  const AddCustomerDialog(),
                  state,
                ),
              ),
              GoRoute(
                path: 'edit',
                parentNavigatorKey: _rootNavigatorKey,
                pageBuilder: (context, state) => _buildSlidePage(
                  AddCustomerDialog(customerToEdit: state.extra as Customer?),
                  state,
                ),
              ),
              GoRoute(
                path: ':id',
                parentNavigatorKey: _rootNavigatorKey,
                pageBuilder: (context, state) => _buildSlidePage(
                  CustomerDetailScreen(
                    customerId: state.pathParameters['id']!,
                  ),
                  state,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/products',
            pageBuilder: (context, state) => _buildPage(
              const ProductsScreen(),
              state,
            ),
            routes: [
              GoRoute(
                path: 'add',
                parentNavigatorKey: _rootNavigatorKey,
                pageBuilder: (context, state) => _buildSlidePage(
                  const AddProductScreen(),
                  state,
                ),
              ),
              GoRoute(
                path: 'edit',
                parentNavigatorKey: _rootNavigatorKey,
                pageBuilder: (context, state) => _buildSlidePage(
                  AddProductScreen(product: state.extra as Product?),
                  state,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/more',
            pageBuilder: (context, state) => _buildPage(
              const MoreScreen(),
              state,
            ),
            routes: [
              GoRoute(
                path: 'rates',
                parentNavigatorKey: _rootNavigatorKey,
                pageBuilder: (context, state) => _buildSlidePage(
                  const RateManagementScreen(),
                  state,
                ),
              ),
              GoRoute(
                path: 'records',
                parentNavigatorKey: _rootNavigatorKey,
                pageBuilder: (context, state) => _buildSlidePage(
                  const RecordBookScreen(),
                  state,
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  ref.listen<AuthState>(authProvider, (previous, next) {
    if (previous?.isAuthenticated != next.isAuthenticated ||
        previous?.isLoading != next.isLoading) {
      router.refresh();
    }
  });

  return router;
});

/// Fade transition for tab pages
CustomTransitionPage _buildPage(Widget child, GoRouterState state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
    transitionDuration: const Duration(milliseconds: 250),
  );
}

/// Slide-up transition for detail/form pages
CustomTransitionPage _buildSlidePage(Widget child, GoRouterState state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    },
    transitionDuration: const Duration(milliseconds: 350),
  );
}
