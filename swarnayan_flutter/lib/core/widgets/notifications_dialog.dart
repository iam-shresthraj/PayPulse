import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/more/widgets/more_dialogs.dart';
import '../utils/dialog_helper.dart';
import 'primary_button.dart';

final unreadNotificationsProvider = StateProvider<int>((ref) => 0);

class NotificationsDialog extends ConsumerStatefulWidget {
  const NotificationsDialog({super.key});

  @override
  ConsumerState<NotificationsDialog> createState() => _NotificationsDialogState();
}

class _NotificationsDialogState extends ConsumerState<NotificationsDialog> {
  bool _loading = true;
  List<Map<String, dynamic>> _notifications = [];
  String? _error;

  bool _matchesTarget(Map<String, dynamic> item, dynamic user) {
    final targetCompanyId = item['target_company_id']?.toString();
    final targetRole = item['target_role']?.toString().toUpperCase() ?? 'ALL';
    final companyMatches = targetCompanyId == null || targetCompanyId.isEmpty || targetCompanyId == user.companyId;
    final roleMatches = targetRole == 'ALL' || targetRole == user.role.toUpperCase();
    return companyMatches && roleMatches;
  }

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final user = ref.read(authProvider).user;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('notifications')
          .select()
          .order('created_at', ascending: false)
          .limit(20);

      // Fetch read receipts for this user
      List<String> readNotificationIds = [];
      try {
        final readsResponse = await Supabase.instance.client
            .from('notification_reads')
            .select('notification_id')
            .eq('user_id', user.id);
        readNotificationIds = List<String>.from(
          (readsResponse as List).map((r) => r['notification_id'].toString())
        );
      } catch (_) {}

      if (mounted) {
        setState(() {
          final rawList = List<Map<String, dynamic>>.from(response)
              .where((item) {
                if (!_matchesTarget(item, user)) return false;
                
                final createdAtStr = item['created_at'];
                if (createdAtStr == null) return false;
                final notificationTime = DateTime.parse(createdAtStr.toString()).toLocal();
                final fourDaysAgo = DateTime.now().subtract(const Duration(days: 4));
                if (notificationTime.isBefore(fourDaysAgo)) return false;

                final userJoined = user.createdAt;
                if (userJoined != null && notificationTime.isBefore(userJoined)) return false;

                return true;
              })
              .toList();
          _notifications = rawList.map((item) {
            final isRead = readNotificationIds.contains(item['id'].toString());
            return {
              ...item,
              'is_read': isRead,
            };
          }).toList();
          _loading = false;
        });
      }
    } catch (e) {
      final missingTable = e.toString().contains('PGRST205') ||
          e.toString().contains("Could not find the table 'public.notifications'");
      if (missingTable && mounted) {
        setState(() {
          _notifications = [];
          _error = null;
          _loading = false;
        });
        return;
      }
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      try {
        await Supabase.instance.client.rpc('mark_notifications_as_read');
      } catch (rpcError) {
        // Fallback: insert read receipts directly
        final user = ref.read(authProvider).user;
        if (user != null && _notifications.isNotEmpty) {
          final inserts = _notifications.map((n) => {
            'notification_id': n['id'],
            'user_id': user.id,
          }).toList();
          await Supabase.instance.client.from('notification_reads').upsert(inserts);
        }
      }
      ref.read(unreadNotificationsProvider.notifier).state = 0;
      await _loadNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Marked as read'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to mark as read: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _markAsRead(String id) async {
    try {
      final user = ref.read(authProvider).user;
      if (user != null) {
        await Supabase.instance.client.from('notification_reads').upsert({
          'notification_id': id,
          'user_id': user.id,
        });
      }
      
      final currentUnread = ref.read(unreadNotificationsProvider);
      if (currentUnread > 0) {
        ref.read(unreadNotificationsProvider.notifier).state = currentUnread - 1;
      }
      
      await _loadNotifications();
    } catch (e) {
      print('DEBUG: _markAsRead failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassDialogWrapper(
      title: 'Notifications',
      showCloseIcon: false,
      headerAction: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: Icon(Icons.check_circle_outline_rounded, color: AppColors.error, size: 24),
            tooltip: 'Mark all as read',
            onPressed: _notifications.isEmpty ? null : _markAllAsRead,
          ),
          const SizedBox(width: 8),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: Icon(Icons.close_rounded, color: AppColors.error, size: 24),
            tooltip: 'Close',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      child: _loading
          ? const SizedBox(
              height: 150,
              child: Center(child: CircularProgressIndicator()),
            )
          : SizedBox(
              height: MediaQuery.of(context).size.height * 0.65,
              child: Column(
                children: [
                  Expanded(
                    child: _error != null
                        ? Center(
                            child: Text(
                              'Notifications are unavailable right now.',
                              style: AppTextStyles.bodyLg.copyWith(color: AppColors.onSurfaceMuted),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : _notifications.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 40),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Icon(Icons.notifications_none_rounded, size: 56, color: AppColors.onSurfaceMuted.withValues(alpha: 0.5)),
                                      const SizedBox(height: 14),
                                      Text(
                                        'No notifications yet',
                                        style: AppTextStyles.bodyLg.copyWith(color: AppColors.onSurfaceMuted),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'You\'ll see alerts and updates here',
                                        style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted.withValues(alpha: 0.6)),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ScrollConfiguration(
                                behavior: const ScrollBehavior().copyWith(scrollbars: false),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: _notifications.length,
                                  itemBuilder: (context, index) {
                                    final item = _notifications[index];
                                    final title = item['title'] ?? 'Alert';
                                    final body = item['body'] ?? '';
                                    final fileUrl = item['file_url']?.toString();
                                    final dateStr = item['created_at'] != null
                                        ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(item['created_at'].toString()).toLocal())
                                        : '';

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: Card(
                                        color: AppColors.surfaceContainer,
                                        margin: EdgeInsets.zero,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          side: BorderSide(color: AppColors.border, width: 0.5),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(14),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    dateStr,
                                                    style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted, fontSize: 10),
                                                  ),
                                                  IconButton(
                                                    padding: EdgeInsets.zero,
                                                    constraints: const BoxConstraints(),
                                                    icon: Icon(
                                                      item['is_read'] == true
                                                          ? Icons.check_circle_rounded
                                                          : Icons.check_circle_outline_rounded,
                                                      color: item['is_read'] == true ? Colors.green : AppColors.error,
                                                      size: 20,
                                                    ),
                                                    onPressed: item['is_read'] == false
                                                        ? () => _markAsRead(item['id'].toString())
                                                        : null,
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                body,
                                                maxLines: 4,
                                                overflow: TextOverflow.ellipsis,
                                                softWrap: true,
                                                style: AppTextStyles.bodyMd.copyWith(color: AppColors.onBackground),
                                              ),
                                              if (fileUrl != null && fileUrl.isNotEmpty) ...[
                                                const SizedBox(height: 12),
                                                GestureDetector(
                                                  onTap: () => launchUrl(Uri.parse(fileUrl)),
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.attachment_rounded, size: 14, color: AppColors.primary),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        'View Attachment',
                                                        style: AppTextStyles.bodySm.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                  ),
                ],
              ),
            ),
    );
  }
}

void showNotificationsDialog(BuildContext context) {
  showSingleDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => const NotificationsDialog(),
  );
}
