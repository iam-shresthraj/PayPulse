import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/user.dart' as app_models;
import 'web_notification_helper.dart';

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _client = Supabase.instance.client;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  RealtimeChannel? _channel;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    // Only init local notifications on Android/iOS
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      await _localNotifications.initialize(
        settings: const InitializationSettings(android: androidInit, iOS: iosInit),
        onDidReceiveNotificationResponse: (response) async {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) {
            try {
              final uri = Uri.parse(payload);
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } catch (_) {}
          }
        },
      );
    }
    _initialized = true;
  }

  bool _isMissingNotificationsTableError(Object error) {
    final text = error.toString();
    return text.contains('PGRST205') || text.contains("Could not find the table 'public.notifications'");
  }

  Future<void> requestPermissions() async {
    if (kIsWeb) {
      await WebNotificationHelper.requestPermission();
      return;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.requestNotificationsPermission();
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final iosImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      await iosImplementation?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  void subscribe(app_models.User user, Function(Map<String, dynamic>) onMatchedNotification) {
    unsubscribe();

    try {
      _channel = _client.channel('public:notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          callback: (payload) {
            final record = payload.newRecord;
            final targetRole = record['target_role']?.toString().toUpperCase() ?? 'ALL';
            final targetCompanyId = record['target_company_id']?.toString();

            final matchesCompany = targetCompanyId == null || targetCompanyId.isEmpty || targetCompanyId == user.companyId;
            final matchesRole = targetRole == 'ALL' || targetRole == user.role.toUpperCase();

            if (matchesCompany && matchesRole) {
              final lifecycle = WidgetsBinding.instance.lifecycleState;
              final isForeground = lifecycle == null || lifecycle == AppLifecycleState.resumed;

              if (isForeground) {
                // Opened: show popup dialog on screen (no push notification)
                onMatchedNotification(record);
              } else {
                // Closed/Backgrounded: show native/web push notification
                if (kIsWeb) {
                  WebNotificationHelper.showNotification(
                    record['title'] ?? 'Notification',
                    record['body'] ?? '',
                  );
                } else {
                  _showLocalNotification(
                    record['title'] ?? 'Notification',
                    record['body'] ?? '',
                    record['file_url']?.toString(),
                  );
                }
              }
            }
          },
        )
        .subscribe();
    } catch (e) {
      if (_isMissingNotificationsTableError(e)) {
        _channel = null;
        return;
      }
      rethrow;
    }
  }

  void unsubscribe() {
    if (_channel != null) {
      _client.removeChannel(_channel!);
      _channel = null;
    }
  }

  Future<void> _showLocalNotification(String title, String body, String? fileUrl) async {
    if (kIsWeb) return;
    if (defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS) return;

    await requestPermissions();

    final androidDetails = AndroidNotificationDetails(
      'paypulse_notifications',
      'PayPulse Alerts',
      channelDescription: 'Push notifications from PayPulse Super Admin',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      actions: fileUrl != null && fileUrl.isNotEmpty
          ? <AndroidNotificationAction>[
              const AndroidNotificationAction(
                'open_url',
                'Open',
                showsUserInterface: true,
              ),
            ]
          : null,
    );
    const iosDetails = DarwinNotificationDetails();

    await _localNotifications.show(
      id: DateTime.now().millisecond,
      title: title,
      body: body,
      payload: fileUrl,
      notificationDetails: NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }
}
