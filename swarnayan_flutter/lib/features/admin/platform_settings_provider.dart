import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PlatformSettings {
  final String companyName;
  final String tagline;
  final String? gstNo;
  final String? logoLightUrl;
  final String? logoDarkUrl;
  final String? address;
  final String contactEmail;
  final String workingTime;
  final bool notifyOnSignup;
  final String welcomeTitle;
  final String welcomeBody;
  
  // App Download/Update fields
  final String? appLogoUrl;
  final String appVersion;
  final String appUpdateLog;
  final String? appApkUrl;

  PlatformSettings({
    required this.companyName,
    required this.tagline,
    this.gstNo,
    this.logoLightUrl,
    this.logoDarkUrl,
    this.address,
    required this.contactEmail,
    required this.workingTime,
    this.notifyOnSignup = true,
    this.welcomeTitle = 'Welcome to PayPulse',
    this.welcomeBody =
        'Welcome to PayPulse! Your account has been created successfully. Please complete your profile and start exploring the app.',
    this.appLogoUrl = '',
    this.appVersion = '1.0.0',
    this.appUpdateLog = 'Initial release',
    this.appApkUrl = '',
  });

  factory PlatformSettings.fromJson(Map<String, dynamic> json) {
    final companyName = (json['company_name'] ?? '').toString().trim().isEmpty
        ? 'PayPulse'
        : json['company_name'].toString();
    final contactEmail = (json['contact_email'] ?? '').toString().trim().isEmpty
        ? 'contact.shresthraj@gmail.com'
        : json['contact_email'].toString();
    return PlatformSettings(
      companyName: companyName,
      tagline: json['tagline'] ?? '',
      gstNo: json['gst_no'],
      logoLightUrl: json['logo_light_url'],
      logoDarkUrl: json['logo_dark_url'],
      address: json['address'],
      contactEmail: contactEmail,
      workingTime: json['working_time'] ?? '10:00 AM - 08:00 PM (Mon - Sat)',
      notifyOnSignup: json['notify_on_signup'] ?? true,
      welcomeTitle: json['welcome_title'] ?? 'Welcome to PayPulse',
      welcomeBody: json['welcome_body'] ??
          'Welcome to PayPulse! Your account has been created successfully. Please complete your profile and start exploring the app.',
      appLogoUrl: json['app_logo_url'] ?? '',
      appVersion: json['app_version'] ?? '1.0.0',
      appUpdateLog: json['app_update_log'] ?? 'Initial release',
      appApkUrl: json['app_apk_url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'company_name': companyName,
        'tagline': tagline,
        'logo_light_url': logoLightUrl,
        'logo_dark_url': logoDarkUrl,
        'address': address,
        'contact_email': contactEmail,
        'working_time': workingTime,
        'notify_on_signup': notifyOnSignup,
        'welcome_title': welcomeTitle,
        'welcome_body': welcomeBody,
        'app_logo_url': appLogoUrl,
        'app_version': appVersion,
        'app_update_log': appUpdateLog,
        'app_apk_url': appApkUrl,
      };
}

class PlatformSettingsNotifier extends StateNotifier<AsyncValue<PlatformSettings>> {
  final _client = Supabase.instance.client;

  PlatformSettingsNotifier() : super(const AsyncValue.loading()) {
    loadSettings();
  }

  PlatformSettings _fallbackSettings() {
    return PlatformSettings(
      companyName: 'PayPulse',
      tagline: 'Business Management, Simplified',
      contactEmail: 'contact.shresthraj@gmail.com',
      workingTime: '10:00 AM - 08:00 PM (Mon - Sat)',
      notifyOnSignup: true,
      welcomeTitle: 'Welcome to PayPulse',
      welcomeBody:
          'Welcome to PayPulse! Your account has been created successfully. Please complete your profile and start exploring the app.',
      appLogoUrl: '',
      appVersion: '1.0.0',
      appUpdateLog: 'Initial release',
      appApkUrl: '',
    );
  }

  Future<void> loadSettings() async {
    try {
      state = const AsyncValue.loading();
      final data = await _client
          .from('platform_settings')
          .select()
          .eq('id', 'global')
          .maybeSingle();
      if (data != null) {
        state = AsyncValue.data(PlatformSettings.fromJson(data));
      } else {
        state = AsyncValue.data(_fallbackSettings());
      }
    } catch (_) {
      // Keep the app usable if the settings table is missing or temporarily unavailable.
      state = AsyncValue.data(_fallbackSettings());
    }
  }

  Future<String?> updateSettings(PlatformSettings settings) async {
    try {
      final payload = settings.toJson();
      await _client
          .from('platform_settings')
          .upsert({'id': 'global', ...payload});
      state = AsyncValue.data(settings);
      return null;
    } catch (e) {
      print('DEBUG: updateSettings failed: $e');
      return e.toString();
    }
  }

  Future<String?> uploadLogoFile(Uint8List bytes, String fileName) async {
    try {
      final path = 'logos/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      await _client.storage.from('platform_assets').uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );
      final publicUrl = _client.storage.from('platform_assets').getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      print('DEBUG: uploadLogoFile failed: $e');
      return null;
    }
  }

  Future<String?> uploadApkFile(Uint8List bytes, String fileName) async {
    try {
      final path = 'apks/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      await _client.storage.from('platform_assets').uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(contentType: 'application/vnd.android.package-archive', cacheControl: '3600', upsert: true),
      );
      final publicUrl = _client.storage.from('platform_assets').getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      print('DEBUG: uploadApkFile failed: $e');
      return null;
    }
  }
}

final platformSettingsProvider =
    StateNotifierProvider<PlatformSettingsNotifier, AsyncValue<PlatformSettings>>((ref) {
  return PlatformSettingsNotifier();
});
