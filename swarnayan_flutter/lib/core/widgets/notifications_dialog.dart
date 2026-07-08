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
          .or('target_company_id.is.null,target_company_id.eq.${user.companyId}')
          .or('target_role.eq.ALL,target_role.eq.${user.role.toUpperCase()}')
          .order('created_at', ascending: false)
          .limit(20);

      if (mounted) {
        setState(() {
          _notifications = List<Map<String, dynamic>>.from(response);
          _loading = false;
        });
        
        // Mark all as read in database
        try {
          await Supabase.instance.client.rpc('mark_notifications_as_read');
        } catch (_) {}
        
        // Clear local unread count
        ref.read(unreadNotificationsProvider.notifier).state = 0;
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

  @override
  Widget build(BuildContext context) {
    return GlassDialogWrapper(
      title: 'Notifications',
      child: _loading
          ? const SizedBox(
              height: 150,
              child: Center(child: CircularProgressIndicator()),
            )
          : _error != null
              ? SizedBox(
                  height: 150,
                  child: Center(
                    child: Text(
                      'Notifications are unavailable right now.',
                      style: AppTextStyles.bodyLg.copyWith(color: AppColors.onSurfaceMuted),
                      textAlign: TextAlign.center,
                    ),
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
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          final item = _notifications[index];
                          final title = item['title'] ?? 'Alert';
                          final body = item['body'] ?? '';
                          final fileUrl = item['file_url']?.toString();
                          final dateStr = item['created_at'] != null
                              ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(item['created_at'].toString()).toLocal())
                              : '';

                          return Card(
                            color: AppColors.surfaceContainer,
                            margin: const EdgeInsets.only(bottom: 12),
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
                                      Expanded(
                                        child: Text(
                                          title,
                                          style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
                                        ),
                                      ),
                                      Text(
                                        dateStr,
                                        style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted, fontSize: 10),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    body,
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
                          );
                        },
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
