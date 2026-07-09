import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/theme/app_text_styles.dart';
import '../more/daily_rates_provider.dart';
import '../more/daily_rate_prompt_dialog.dart';
import '../more/widgets/more_dialogs.dart';
import '../auth/auth_provider.dart';
import '../more/role_permissions_provider.dart';
import '../billing/billing_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/services/notification_service.dart';
import '../admin/platform_settings_provider.dart';
import '../../core/utils/dialog_helper.dart';
import '../../core/widgets/notifications_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Main application shell supporting both mobile bottom navigation bar 
/// and desktop left-navigation sidebar.
class AppShell extends ConsumerStatefulWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> with WidgetsBindingObserver {
  bool _prompted = false;
  DateTime? _lastBackPressTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NotificationService.instance.init().then((_) {
      NotificationService.instance.requestPermissions();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupNotificationSubscription();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    NotificationService.instance.unsubscribe();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchInitialUnreadCount();
    }
  }

  Future<void> _fetchInitialUnreadCount() async {
    try {
      final user = ref.read(authProvider).user;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('notifications')
          .select('id, target_company_id, target_role, created_at')
          .order('created_at', ascending: false)
          .limit(50);

      final readsResponse = await Supabase.instance.client
          .from('notification_reads')
          .select('notification_id')
          .eq('user_id', user.id);
      final readIds = Set<String>.from(
        (readsResponse as List).map((r) => r['notification_id'].toString())
      );

      int unread = 0;
      for (final item in response) {
        final targetCompanyId = item['target_company_id']?.toString();
        final targetRole = item['target_role']?.toString().toUpperCase() ?? 'ALL';
        final companyMatches = targetCompanyId == null || targetCompanyId.isEmpty || targetCompanyId == user.companyId;
        final roleMatches = targetRole == 'ALL' || targetRole == user.role.toUpperCase();

        if (companyMatches && roleMatches) {
          final createdAtStr = item['created_at'];
          if (createdAtStr != null) {
            final notificationTime = DateTime.parse(createdAtStr.toString()).toLocal();
            final fourDaysAgo = DateTime.now().subtract(const Duration(days: 4));
            if (notificationTime.isBefore(fourDaysAgo)) continue;

            final userJoined = user.createdAt;
            if (userJoined != null && notificationTime.isBefore(userJoined)) continue;
          }

          if (!readIds.contains(item['id'].toString())) {
            unread++;
          }
        }
      }

      if (mounted) {
        ref.read(unreadNotificationsProvider.notifier).state = unread;
      }
    } catch (e) {
      print('DEBUG: _fetchInitialUnreadCount failed: $e');
    }
  }

  void _setupNotificationSubscription() {
    final user = ref.read(authProvider).user;
    if (user != null) {
      _fetchInitialUnreadCount();
      NotificationService.instance.subscribe(user, (notification) {
        if (mounted) {
          HapticFeedback.vibrate();
          _showNotificationPopup(notification);
          _fetchInitialUnreadCount();
        }
      });
    }
  }

  void _showNotificationPopup(Map<String, dynamic> notification) {
    final title = notification['title'] ?? 'New Notification';
    final body = notification['body'] ?? '';
    final fileUrl = notification['file_url']?.toString();
    final overlayContext = shellNavigatorKey.currentContext ?? context;
    final isWide = MediaQuery.of(overlayContext).size.width >= 850;

    showGeneralDialog(
      context: overlayContext,
      barrierDismissible: true,
      barrierLabel: 'Notification',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        Future.delayed(const Duration(seconds: 5), () {
          if (Navigator.of(dialogContext, rootNavigator: true).canPop()) {
            Navigator.of(dialogContext, rootNavigator: true).pop();
          }
        });

        return SafeArea(
          child: Align(
            alignment: isWide ? Alignment.topRight : Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(
                top: 16,
                right: isWide ? 16 : 12,
                left: isWide ? 0 : 12,
              ),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: isWide ? 360 : double.infinity,
                  margin: EdgeInsets.only(left: isWide ? 0 : 0),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer.withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.glassBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 28,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.notifications_active_rounded, color: AppColors.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.titleLg.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.close_rounded),
                            color: AppColors.onSurfaceMuted,
                            onPressed: () => Navigator.pop(dialogContext),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        body,
                        style: AppTextStyles.bodyMd.copyWith(color: AppColors.onBackground),
                      ),
                      if (fileUrl != null && fileUrl.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          onPressed: () => launchUrl(Uri.parse(fileUrl)),
                          icon: const Icon(Icons.open_in_new_rounded),
                          label: const Text('Open'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.08),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/admin/businesses')) return 101;
    if (location.startsWith('/admin/customers')) return 102;
    if (location.startsWith('/admin/users')) return 103;
    if (location.startsWith('/admin/notifications')) return 8;
    if (location.startsWith('/admin/branding')) return 105;
    if (location.startsWith('/billing')) return 1;
    if (location.startsWith('/more/rates')) return 7;
    if (location.startsWith('/customers')) return 2;
    if (location.startsWith('/products')) return 3;
    if (location.startsWith('/reports')) return 4;
    if (location.contains('/records')) return 5;
    if (location.startsWith('/more')) return 6;
    return 0;
  }

  bool _hasUnsavedChanges(BillingState billing) {
    if (billing.products.isNotEmpty) return true;
    if (billing.customerPhone != null && billing.customerPhone!.isNotEmpty) return true;
    if (billing.customerName != null && billing.customerName!.isNotEmpty) return true;
    if (billing.editingInvoice != null) return true;
    if (billing.cashAmount > 0 || billing.upiAmount > 0 || billing.cardAmount > 0) return true;
    return false;
  }

  Future<bool?> _showDraftDialog(BuildContext context) async {
    return showDialog<bool?>(
      context: shellNavigatorKey.currentContext ?? context,
      useRootNavigator: false,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceContainer,
        title: const Text('Unsaved Invoice Draft'),
        content: const Text('Do you want to save this invoice as a draft or discard it?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null), // Cancel
            child: Text('Cancel', style: TextStyle(color: AppColors.onSurfaceDim)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false), // Discard
            child: const Text('Discard', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(context, true), // Save Draft
            child: const Text('Save Draft', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _onTap(BuildContext context, int index) async {
    HapticFeedback.lightImpact();
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/billing') && index != 1) {
      final billingState = ref.read(billingProvider);
      if (_hasUnsavedChanges(billingState)) {
        final result = await _showDraftDialog(context);
        if (result == null) return;
        if (result == false) {
          ref.read(billingProvider.notifier).reset();
        }
      }
    }

    if (!context.mounted) return;

    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/billing');
        break;
      case 2:
        context.go('/customers');
        break;
      case 3:
        context.go('/products');
        break;
      case 4:
        context.go('/reports');
        break;
      case 5:
        context.go('/more/records');
        break;
      case 6:
        context.go('/more');
        break;
      case 7:
        context.go('/more/rates');
        break;
    }
  }

  int _bottomBarIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/billing')) return 1;
    if (location.startsWith('/customers')) return 2;
    if (location.startsWith('/products')) return 3;
    if (location.startsWith('/reports') || location.contains('/records') || location.startsWith('/more')) return 4;
    return 0;
  }

  void _onBottomBarTap(BuildContext context, int index) async {
    HapticFeedback.lightImpact();
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/billing') && index != 1) {
      final billingState = ref.read(billingProvider);
      if (_hasUnsavedChanges(billingState)) {
        final result = await _showDraftDialog(context);
        if (result == null) return;
        if (result == false) {
          ref.read(billingProvider.notifier).reset();
        }
      }
    }

    if (!context.mounted) return;

    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/billing');
        break;
      case 2:
        context.go('/customers');
        break;
      case 3:
        context.go('/products');
        break;
      case 4:
        context.go('/more');
        break;
    }
  }

  void _checkRates() {
    if (_prompted) return;

    final user = ref.read(authProvider).user;
    if (user == null || !user.isJewellery) return; // Skip daily rates prompt if not jewellery category

    final ratesState = ref.read(dailyRatesProvider);
    if (ratesState is AsyncData) {
      final hasToday = ref.read(dailyRatesProvider.notifier).isTodayRateEntered();
      if (!hasToday) {
        _prompted = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showSingleDialog(
            context: shellNavigatorKey.currentContext ?? context,
            useRootNavigator: false,
            barrierDismissible: true,
            builder: (context) => const DailyRatePromptDialog(isDismissible: false),
          );
        });
      }
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showSingleDialog<bool>(
      context: shellNavigatorKey.currentContext ?? context,
      useRootNavigator: false,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: AlertDialog(
          backgroundColor: AppColors.surfaceContainer.withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.glassBorder),
          ),
          title: Text(
            'Sign Out',
            style: AppTextStyles.titleLg.copyWith(color: AppColors.error),
          ),
          content: Text(
            'Are you sure you want to sign out?',
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.onBackground),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceDim),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Sign Out',
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.error),
              ),
            ),
          ],
        ),
      ),
    );
    if (confirm == true) {
      await ref.read(authProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (previous, next) {
      if (previous?.user?.id != next.user?.id) {
        if (next.user != null) {
          _setupNotificationSubscription();
        } else {
          NotificationService.instance.unsubscribe();
        }
      }
    });

    // Watch dailyRatesProvider to trigger loading if not already
    final ratesState = ref.watch(dailyRatesProvider);

    // Call checkRates when rates data is loaded
    if (ratesState is AsyncData && !_prompted) {
      _checkRates();
    }

    // Also set up a listener to trigger on changes
    ref.listen(dailyRatesProvider, (previous, next) {
      if (next is AsyncData && !_prompted) {
        _checkRates();
      }
    });

    final bottomIndex = _bottomBarIndex(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isWide = MediaQuery.of(context).size.width >= 850;

    final Widget mainContent;
    if (isWide) {
      mainContent = Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          children: [
            _buildLeftSidebar(context),
            Expanded(
              child: widget.child,
            ),
          ],
        ),
      );
    } else {
      mainContent = Scaffold(
        backgroundColor: AppColors.background,
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0.0;
            if (velocity == 0.0) return;
            final int currentIndex = _bottomBarIndex(context); // 0 (Dashboard), 1 (Invoice), 4 (More)
            
            if (velocity < -300) {
              // Swipe right-to-left -> Next Page
              if (currentIndex == 0) {
                _onBottomBarTap(context, 1); // Go to Invoice
              } else if (currentIndex == 1) {
                _onBottomBarTap(context, 4); // Go to More
              }
            } else if (velocity > 300) {
              // Swipe left-to-right -> Previous Page
              if (currentIndex == 4) {
                _onBottomBarTap(context, 1); // Go to Invoice
              } else if (currentIndex == 1) {
                _onBottomBarTap(context, 0); // Go to Dashboard
              }
            }
          },
          child: widget.child,
        ),
        extendBody: true,
        bottomNavigationBar: Builder(
          builder: (context) {
            final user = ref.watch(authProvider).user;
            final isSuperAdmin = user?.isSuperAdmin ?? false;
            final isDark = Theme.of(context).brightness == Brightness.dark;
            int selectedTab = -1;
            if (bottomIndex == 0) selectedTab = 0;
            if (bottomIndex == 4) selectedTab = 1;
            final isBillingActive = bottomIndex == 1;

            Widget buildCapsuleContent() {
              if (isBillingActive) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: () => _onBottomBarTap(context, 0),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.home_outlined, 
                          color: isDark ? Colors.white.withValues(alpha: 0.6) : Colors.black.withValues(alpha: 0.5), 
                          size: 22,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _onBottomBarTap(context, 4),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.menu_rounded, 
                          color: isDark ? Colors.white.withValues(alpha: 0.6) : Colors.black.withValues(alpha: 0.5), 
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                );
              }

              if (selectedTab == 0) {
                return Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _onBottomBarTap(context, 0),
                        child: Container(
                          height: 42,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(21),
                            border: Border.all(
                              color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.home_rounded, color: isDark ? Colors.white : Colors.black, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Dashboard',
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => _onBottomBarTap(context, 4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Icon(
                          isSuperAdmin ? Icons.analytics_rounded : Icons.menu_rounded, 
                          color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.4), 
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  GestureDetector(
                    onTap: () => _onBottomBarTap(context, 0),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Icon(
                        Icons.home_outlined, 
                        color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.4), 
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _onBottomBarTap(context, 4),
                      child: Container(
                        height: 42,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(21),
                          border: Border.all(
                            color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(isSuperAdmin ? Icons.analytics_rounded : Icons.menu_rounded, color: isDark ? Colors.white : Colors.black, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Management',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            Widget buildAddButton() {
              final buttonWidget = Container(
                height: 58,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppColors.primaryGradient,
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(29),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGlow,
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: isBillingActive
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_rounded, color: Colors.white, size: 24),
                            SizedBox(width: 8),
                            Text(
                              'Invoice',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        )
                      : const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                ),
              );

              final buttonGesture = GestureDetector(
                onTap: () {
                  if (isSuperAdmin) {
                    context.go('/admin/notifications');
                  } else {
                    _onBottomBarTap(context, 1);
                  }
                },
                child: buttonWidget,
              );

              return isBillingActive
                  ? Expanded(child: buttonGesture)
                  : SizedBox(width: 75, child: buttonGesture);
            }

            return Container(
              margin: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: bottomPadding + 12,
              ),
              child: Row(
                children: [
                  if (isBillingActive)
                    SizedBox(
                      width: 110,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        clipBehavior: Clip.antiAlias,
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Container(
                            height: 58,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.white.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: isDark 
                                    ? Colors.white.withValues(alpha: 0.12) 
                                    : Colors.white.withValues(alpha: 0.45),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: buildCapsuleContent(),
                          ),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        clipBehavior: Clip.antiAlias,
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Container(
                            height: 58,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.white.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: isDark 
                                    ? Colors.white.withValues(alpha: 0.12) 
                                    : Colors.white.withValues(alpha: 0.45),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: buildCapsuleContent(),
                          ),
                        ),
                      ),
                    ),
                  if (!isSuperAdmin) ...[
                    const SizedBox(width: 12),
                    buildAddButton(),
                  ],
                ],
              ),
            );
          },
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          final location = GoRouterState.of(context).uri.toString();
          if (location != '/' && location != '/login' && location != '/pending') {
            context.go('/');
          } else {
            final now = DateTime.now();
            if (_lastBackPressTime == null ||
                now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
              _lastBackPressTime = now;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Press back again to exit PayPulse'),
                  duration: Duration(seconds: 2),
                ),
              );
            } else {
              await SystemNavigator.pop();
            }
          }
        },
        child: mainContent,
      ),
    );
  }

  Widget _buildLeftSidebar(BuildContext context) {
    final currentIndex = _currentIndex(context);
    final themeOverride = ref.watch(themeModeProvider);
    final isLight = themeOverride ?? (MediaQuery.of(context).size.width >= 850);
    final unreadCount = ref.watch(unreadNotificationsProvider);

    final user = ref.watch(authProvider).user;
    final rolePermissions = ref.watch(rolePermissionsProvider).value ?? {};
    final canManage = user?.canManage ?? false;

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          right: BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo & Branding
          Padding(
            padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 32.0, bottom: 20.0),
            child: Builder(
              builder: (context) {
                final platformSettingsAsync = ref.watch(platformSettingsProvider);
                final platformSettings = platformSettingsAsync.asData?.value;
                final logoUrl = isLight
                    ? platformSettings?.logoLightUrl
                    : platformSettings?.logoDarkUrl;
                if (logoUrl != null && logoUrl.isNotEmpty) {
                  return CachedNetworkImage(
                    imageUrl: logoUrl,
                    height: 36,
                    fit: BoxFit.contain,
                    alignment: Alignment.centerLeft,
                    placeholder: (context, url) => const SizedBox(
                      height: 36,
                      width: 36,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    errorWidget: (context, url, error) => Image.asset(
                      isLight ? 'assets/images/paypulse2.png' : 'assets/images/paypulse1.png',
                      height: 36,
                      fit: BoxFit.contain,
                      alignment: Alignment.centerLeft,
                    ),
                  );
                }
                return Image.asset(
                  isLight
                      ? 'assets/images/paypulse2.png'
                      : 'assets/images/paypulse1.png',
                  height: 36,
                  fit: BoxFit.contain,
                  alignment: Alignment.centerLeft,
                );
              }
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              children: [
                if (user?.isSuperAdmin ?? false) ...[
                  _buildSidebarHeader('ADMIN PANEL'),
                  _buildSidebarItem(
                    icon: Icons.admin_panel_settings_rounded,
                    label: 'Admin Dashboard',
                    isActive: currentIndex == 0,
                    onTap: () => context.go('/'),
                  ),
                  _buildSidebarItem(
                    icon: Icons.business_rounded,
                    label: 'Businesses & Codes',
                    isActive: currentIndex == 101,
                    onTap: () => context.go('/admin/businesses'),
                  ),
                  _buildSidebarItem(
                    icon: Icons.people_alt_rounded,
                    label: 'Customer Directory',
                    isActive: currentIndex == 102,
                    onTap: () => context.go('/admin/customers'),
                  ),
                  _buildSidebarItem(
                    icon: Icons.lock_person_rounded,
                    label: 'User Access Control',
                    isActive: currentIndex == 103,
                    onTap: () => context.go('/admin/users'),
                  ),
                  _buildSidebarItem(
                    icon: Icons.palette_rounded,
                    label: 'System Branding',
                    isActive: currentIndex == 105,
                    onTap: () => context.go('/admin/branding'),
                  ),
                ] else ...[
                  _buildSidebarHeader('MENU'),
                  if (user?.hasAccess('dashboard', rolePermissions) ?? true)
                    _buildSidebarItem(
                      icon: Icons.dashboard_rounded,
                      label: 'Dashboard',
                      isActive: currentIndex == 0,
                      onTap: () => _onTap(context, 0),
                    ),
                  if (user?.hasAccess('invoices', rolePermissions) ?? true)
                    _buildSidebarItem(
                      icon: Icons.receipt_long_rounded,
                      label: 'Invoice',
                      isActive: currentIndex == 1,
                      onTap: () => _onTap(context, 1),
                    ),
                  if ((user?.hasAccess('rates', rolePermissions) ?? true) && (user?.isJewellery ?? true))
                    _buildSidebarItem(
                      icon: Icons.trending_up_rounded,
                      label: 'Rate Management',
                      isActive: currentIndex == 7,
                      onTap: () => _onTap(context, 7),
                    ),
                  if (user?.hasAccess('customers', rolePermissions) ?? true)
                    _buildSidebarItem(
                      icon: Icons.people_alt_rounded,
                      label: 'Customers',
                      isActive: currentIndex == 2,
                      onTap: () => _onTap(context, 2),
                    ),
                  if (user?.hasAccess('inventory', rolePermissions) ?? true)
                    _buildSidebarItem(
                      icon: Icons.diamond_rounded,
                      label: 'Products',
                      isActive: currentIndex == 3,
                      onTap: () => _onTap(context, 3),
                    ),
                  if (canManage && (user?.hasAccess('reports', rolePermissions) ?? true))
                    _buildSidebarItem(
                      icon: Icons.analytics_rounded,
                      label: 'Reports',
                      isActive: currentIndex == 4,
                      onTap: () => _onTap(context, 4),
                    ),
                  if (user?.hasAccess('records', rolePermissions) ?? true)
                    _buildSidebarItem(
                      icon: Icons.book_rounded,
                      label: 'Record Book',
                      isActive: currentIndex == 5,
                      onTap: () => _onTap(context, 5),
                    ),
                  if (user?.hasAccess('staff', rolePermissions) ?? true)
                    _buildSidebarItem(
                      icon: Icons.folder_shared_rounded,
                      label: 'Management',
                      isActive: currentIndex == 6,
                      onTap: () => _onTap(context, 6),
                    ),
                ],
                const SizedBox(height: 16),
                _buildSidebarHeader('GENERAL'),
                _buildSidebarItem(
                  icon: Icons.notifications_rounded,
                  label: 'Notifications',
                  isActive: currentIndex == 8,
                  badgeCount: unreadCount,
                  onTap: () {
                    if (user?.isSuperAdmin ?? false) {
                      context.go('/admin/notifications');
                    } else {
                      showSingleDialog(
                        context: shellNavigatorKey.currentContext ?? context,
                        useRootNavigator: false,
                        builder: (context) => const NotificationsDialog(),
                      );
                    }
                  },
                ),
                _buildSidebarItem(
                  icon: isLight ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  label: isLight ? 'Dark Mode' : 'Light Mode',
                  isActive: false,
                  onTap: () {
                    ref.read(themeModeProvider.notifier).toggleTheme(isLight);
                  },
                ),
                if (!(user?.isSuperAdmin ?? false))
                  _buildSidebarItem(
                    icon: Icons.help_outline_rounded,
                    label: 'Help',
                    isActive: false,
                    onTap: () {
                      showSingleDialog(
                        context: shellNavigatorKey.currentContext ?? context,
                        useRootNavigator: false,
                        builder: (context) => const HelpSupportDialog(),
                      );
                    },
                  ),
                _buildSidebarItem(
                  icon: Icons.logout_rounded,
                  label: 'Logout',
                  isActive: false,
                  textColor: AppColors.error,
                  iconColor: AppColors.error,
                  onTap: () => _handleLogout(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Text(
              DateFormat('dd MMMM yyyy').format(DateTime.now()).toUpperCase(),
              style: AppTextStyles.labelMd.copyWith(
                color: AppColors.onSurfaceMuted,
                letterSpacing: 1.2,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        title,
        style: AppTextStyles.labelSm.copyWith(
          color: AppColors.onSurfaceMuted,
          letterSpacing: 1.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
    int? badgeCount,
  }) {
    final activeBg = AppColors.primary.withValues(alpha: 0.08);
    final activeFg = AppColors.primary;
    final defaultFg = AppColors.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isActive ? activeBg : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isActive
                  ? Border.all(color: AppColors.primary.withValues(alpha: 0.15), width: 1)
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isActive ? activeFg : (iconColor ?? AppColors.onSurfaceDim),
                  size: 20,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.bodyLg.copyWith(
                      color: isActive ? activeFg : (textColor ?? defaultFg),
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (badgeCount != null && badgeCount > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badgeCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (isActive)
                  Container(
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
