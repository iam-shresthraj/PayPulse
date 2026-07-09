import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

      // Register Workmanager background task
      try {
        await Workmanager().initialize(
          callbackDispatcher,
          isInDebugMode: kDebugMode,
        );
        await Workmanager().registerPeriodicTask(
          'paypulse_periodic_notifications',
          'paypulse_fetch_notifications_task',
          frequency: const Duration(minutes: 15),
          existingWorkPolicy: ExistingWorkPolicy.keep,
          constraints: Constraints(
            networkType: NetworkType.connected,
          ),
        );
      } catch (e) {
        debugPrint('Workmanager init error: $e');
      }
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

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      // 1. Initialize Supabase in background isolate
      await Supabase.initialize(
        url: 'https://gnyzctxlqcidubanoiae.supabase.co',
        publishableKey: 'sb_publishable_h-fS9Q3g4ucAfmvD9btgWg_NwH4PKbH',
      );

      final client = Supabase.instance.client;
      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        return true; // Not logged in
      }

      // 2. Fetch User Profile
      final profileData = await client
          .from('profiles')
          .select()
          .eq('id', currentUser.id)
          .maybeSingle();

      if (profileData == null) {
        return true;
      }

      final role = profileData['role']?.toString().toUpperCase() ?? 'STAFF';
      final companyId = profileData['company_id']?.toString();
      final approvalStatus = profileData['approval_status']?.toString().toUpperCase() ?? 'PENDING';

      if (approvalStatus != 'APPROVED') {
        return true; // Not approved
      }

      // 3. Fetch latest notifications
      final notifications = await client
          .from('notifications')
          .select()
          .order('created_at', ascending: false)
          .limit(10);

      if (notifications.isEmpty) {
        return true;
      }

      final prefs = await SharedPreferences.getInstance();
      final lastCheckedId = prefs.getString('last_checked_notification_id');

      // 4. Find new notifications that match target company & role
      String? newLatestId;
      bool hasLastChecked = lastCheckedId != null && lastCheckedId.isNotEmpty;

      final newNotifications = <Map<String, dynamic>>[];
      for (final raw in notifications) {
        final record = raw as Map<String, dynamic>;
        final id = record['id']?.toString();
        if (id == null) continue;

        // Stop if we hit the last checked notification
        if (hasLastChecked && id == lastCheckedId) {
          break;
        }

        final targetRole = record['target_role']?.toString().toUpperCase() ?? 'ALL';
        final targetCompanyId = record['target_company_id']?.toString();

        final matchesCompany = targetCompanyId == null || targetCompanyId.isEmpty || targetCompanyId == companyId;
        final matchesRole = targetRole == 'ALL' || targetRole == role;

        if (matchesCompany && matchesRole) {
          newNotifications.add(record);
        }
      }

      final reversedNew = newNotifications.reversed.toList();

      // Show notifications
      final localNotifications = FlutterLocalNotificationsPlugin();
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings();
      await localNotifications.initialize(
        const InitializationSettings(android: androidInit, iOS: iosInit),
      );

      for (final record in reversedNew) {
        final title = record['title'] ?? 'Notification';
        final body = record['body'] ?? '';
        final fileUrl = record['file_url']?.toString();
        final id = record['id']?.toString();

        const androidDetails = AndroidNotificationDetails(
          'paypulse_notifications',
          'PayPulse Alerts',
          channelDescription: 'Push notifications from PayPulse Super Admin',
          importance: Importance.max,
          priority: Priority.high,
          enableVibration: true,
          playSound: true,
        );
        const iosDetails = DarwinNotificationDetails();

        await localNotifications.show(
          DateTime.now().millisecond + (id.hashCode % 10000),
          title,
          body,
          notificationDetails: const NotificationDetails(android: androidDetails, iOS: iosDetails),
          payload: fileUrl,
        );

        newLatestId = id;
      }

      if (!hasLastChecked && notifications.isNotEmpty) {
        newLatestId = notifications.first['id']?.toString();
      }

      if (newLatestId != null) {
        await prefs.setString('last_checked_notification_id', newLatestId);
      }

      return true;
    } catch (e) {
      debugPrint('Background Worker Error: $e');
      return false;
    }
  });
}
