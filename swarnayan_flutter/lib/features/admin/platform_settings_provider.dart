import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PlatformSettings {
  final String companyName;
  final String? gstNo;
  final String? logoLightUrl;
  final String? logoDarkUrl;
  final String? address;
  final String contactEmail;
  final String workingTime;

  PlatformSettings({
    required this.companyName,
    this.gstNo,
    this.logoLightUrl,
    this.logoDarkUrl,
    this.address,
    required this.contactEmail,
    required this.workingTime,
  });

  factory PlatformSettings.fromJson(Map<String, dynamic> json) {
    return PlatformSettings(
      companyName: json['company_name'] ?? 'Swarnayan Jewellers',
      gstNo: json['gst_no'],
      logoLightUrl: json['logo_light_url'],
      logoDarkUrl: json['logo_dark_url'],
      address: json['address'],
      contactEmail: json['contact_email'] ?? 'contact.shresthraj@gmail.com',
      workingTime: json['working_time'] ?? '10:00 AM - 08:00 PM (Mon - Sat)',
    );
  }

  Map<String, dynamic> toJson() => {
        'company_name': companyName,
        'gst_no': gstNo,
        'logo_light_url': logoLightUrl,
        'logo_dark_url': logoDarkUrl,
        'address': address,
        'contact_email': contactEmail,
        'working_time': workingTime,
      };
}

class PlatformSettingsNotifier extends StateNotifier<AsyncValue<PlatformSettings>> {
  final _client = Supabase.instance.client;

  PlatformSettingsNotifier() : super(const AsyncValue.loading()) {
    loadSettings();
  }

  PlatformSettings _fallbackSettings() {
    return PlatformSettings(
      companyName: 'Swarnayan Jewellers',
      contactEmail: 'contact.shresthraj@gmail.com',
      workingTime: '10:00 AM - 08:00 PM (Mon - Sat)',
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

  Future<bool> updateSettings(PlatformSettings settings) async {
    try {
      final payload = settings.toJson();
      await _client
          .from('platform_settings')
          .upsert({'id': 'global', ...payload});
      state = AsyncValue.data(settings);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<String?> uploadLogoFile(Uint8List bytes, String fileName) async {
    try {
      final path = 'logos/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      // Ensure the public bucket "platform_assets" exists or we fallback to link
      await _client.storage.from('platform_assets').uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );
      final publicUrl = _client.storage.from('platform_assets').getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      return null;
    }
  }
}

final platformSettingsProvider =
    StateNotifierProvider<PlatformSettingsNotifier, AsyncValue<PlatformSettings>>((ref) {
  return PlatformSettingsNotifier();
});
