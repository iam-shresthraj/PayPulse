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
import '../../features/reports/reports_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/splash_screen.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/auth/pending_approval_screen.dart';
import '../../features/auth/deassociated_screen.dart';
import '../../features/auth/expired_screen.dart';
import '../../features/more/role_permissions_provider.dart';
import '../../models/product.dart';
import '../../models/customer.dart';
import '../../features/admin/admin_sub_screens.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: SplashConfig.hasSeenSplash ? '/' : '/splash',
    redirect: (context, state) {
      final authState = ref.read(authProvider);

      if (authState.isLoading) return null;

      final location = state.uri.toString();
      final isSplash = location == '/splash';
      if (isSplash) {
        if (SplashConfig.hasSeenSplash) {
          return '/';
        }
        return null;
      }

      final isLoggingIn = location == '/login';
      final isPendingPage = location == '/pending';
      final isDeassociatedPage = location == '/deassociated';
      final isExpiredPage = location == '/expired';

      if (!authState.isAuthenticated) {
        return '/login';
      }

      // Expiry check
      if (authState.isExpired) {
        return isExpiredPage ? null : '/expired';
      }

      // Deassociated users only see /deassociated page.
      if (authState.isDeassociated) {
        return isDeassociatedPage ? null : '/deassociated';
      }

      // Approved users never see login/pending; pending users only see /pending.
      if (authState.isPendingApproval) {
        return isPendingPage ? null : '/pending';
      }

      if (isLoggingIn || isPendingPage || isDeassociatedPage || isExpiredPage) {
        return '/';
      }

      final user = authState.user;
      final rolePermissions = ref.read(rolePermissionsProvider).value ?? {};

      // Dashboard check
      if (location == '/') {
        final accessDashboard = user?.hasAccess('dashboard', rolePermissions) ?? true;
        if (!accessDashboard) {
          if (user?.hasAccess('invoices', rolePermissions) ?? true) return '/billing';
          if (user?.hasAccess('customers', rolePermissions) ?? true) return '/customers';
          if (user?.hasAccess('inventory', rolePermissions) ?? true) return '/products';
          return '/more';
        }
      }

      // Non-managers/non-owners cannot access reports, and it requires reports access
      if (location.startsWith('/reports')) {
        final canManage = user?.canManage ?? false;
        final accessReports = user?.hasAccess('reports', rolePermissions) ?? true;
        if (!canManage || !accessReports) {
          return '/';
        }
      }

      // Feature-wise checks for other routes
      if (location.startsWith('/billing')) {
        final accessInvoices = user?.hasAccess('invoices', rolePermissions) ?? true;
        if (!accessInvoices) return '/';
      }

      if (location.startsWith('/customers')) {
        if (user?.isSuperAdmin ?? false) {
          return '/admin/customers';
        }
        final accessCustomers = user?.hasAccess('customers', rolePermissions) ?? true;
        if (!accessCustomers) return '/';
      }

      if (location.startsWith('/products')) {
        final accessInventory = user?.hasAccess('inventory', rolePermissions) ?? true;
        if (!accessInventory) return '/';
      }

      if (location.startsWith('/more/rates')) {
        final accessRates = user?.hasAccess('rates', rolePermissions) ?? true;
        if (!accessRates) return '/';
      }

      if (location.startsWith('/more/records')) {
        final accessRecords = user?.hasAccess('records', rolePermissions) ?? true;
        if (!accessRecords) return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => _buildPage(
          const SplashScreen(),
          state,
        ),
      ),
      GoRoute(
        path: '/login',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => _buildPage(
          const LoginScreen(),
          state,
        ),
      ),
      GoRoute(
        path: '/pending',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => _buildPage(
          const PendingApprovalScreen(),
          state,
        ),
      ),
      GoRoute(
        path: '/deassociated',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => _buildPage(
          const DeassociatedScreen(),
          state,
        ),
      ),
      GoRoute(
        path: '/expired',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => _buildPage(
          const ExpiredScreen(),
          state,
        ),
      ),
      ShellRoute(
        navigatorKey: shellNavigatorKey,
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
                pageBuilder: (context, state) => _buildSlidePage(
                  const AddCustomerDialog(),
                  state,
                ),
              ),
              GoRoute(
                path: 'edit',
                pageBuilder: (context, state) => _buildSlidePage(
                  AddCustomerDialog(customerToEdit: state.extra as Customer?),
                  state,
                ),
              ),
              GoRoute(
                path: ':id',
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
                pageBuilder: (context, state) => _buildSlidePage(
                  const AddProductScreen(),
                  state,
                ),
              ),
              GoRoute(
                path: 'edit',
                pageBuilder: (context, state) => _buildSlidePage(
                  AddProductScreen(product: state.extra as Product?),
                  state,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/reports',
            pageBuilder: (context, state) => _buildPage(
              const ReportsScreen(),
              state,
            ),
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
                pageBuilder: (context, state) => _buildPage(
                  const RateManagementScreen(),
                  state,
                ),
              ),
              GoRoute(
                path: 'records',
                pageBuilder: (context, state) => _buildPage(
                  const RecordBookScreen(),
                  state,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/admin/businesses',
            pageBuilder: (context, state) => _buildPage(
              const AdminBusinessesScreen(),
              state,
            ),
          ),
          GoRoute(
            path: '/admin/customers',
            pageBuilder: (context, state) => _buildPage(
              const AdminCustomersScreen(),
              state,
            ),
          ),
          GoRoute(
            path: '/admin/users',
            pageBuilder: (context, state) => _buildPage(
              const AdminUsersScreen(),
              state,
            ),
          ),
          GoRoute(
            path: '/admin/notifications',
            pageBuilder: (context, state) => _buildPage(
              const AdminNotificationsScreen(),
              state,
            ),
          ),
          GoRoute(
            path: '/admin/branding',
            pageBuilder: (context, state) => _buildPage(
              const AdminBrandingScreen(),
              state,
            ),
          ),
        ],
      ),
    ],
  );

  ref.listen<AuthState>(authProvider, (previous, next) {
    if (previous?.isAuthenticated != next.isAuthenticated ||
        previous?.isLoading != next.isLoading ||
        previous?.user?.approvalStatus != next.user?.approvalStatus ||
        previous?.user?.companyId != next.user?.companyId ||
        previous?.user?.companyRenewDate != next.user?.companyRenewDate) {
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
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOutCubic,
      );
      return FadeTransition(opacity: curved, child: child);
    },
    transitionDuration: const Duration(milliseconds: 300),
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
        curve: Curves.easeOutQuint,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    },
    transitionDuration: const Duration(milliseconds: 400),
  );
}
