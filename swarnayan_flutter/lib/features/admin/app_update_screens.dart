import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/primary_button.dart';
import 'platform_settings_provider.dart';

/// ────────────────────────────────────────────────────────────────────────────
/// 1. User side: Download App Screen
/// ────────────────────────────────────────────────────────────────────────────
class DownloadAppScreen extends ConsumerWidget {
  const DownloadAppScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(platformSettingsProvider);
    final isWide = MediaQuery.of(context).size.width >= 850;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: settingsAsync.when(
          data: (settings) {
            final logoUrl = settings.appLogoUrl ?? '';
            final apkUrl = settings.appApkUrl ?? '';
            final version = settings.appVersion.isEmpty ? '1.0.0' : settings.appVersion;
            final updateLog = settings.appUpdateLog.isEmpty ? 'Initial release' : settings.appUpdateLog;

            return Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 550),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (!isWide) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  if (Navigator.canPop(context)) {
                                    Navigator.pop(context);
                                  } else {
                                    context.go('/');
                                  }
                                },
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceContainer,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.glassBorder),
                                  ),
                                  child: Icon(
                                    Icons.arrow_back_rounded,
                                    color: AppColors.onSurface,
                                    size: 16,
                                  ),
                                ),
                              ),
                              Text(
                                'Download App',
                                style: AppTextStyles.titleLg.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      GlassCard(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            // App Logo Circle Preview
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceDim,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.15),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: logoUrl.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: logoUrl,
                                        fit: BoxFit.cover,
                                        placeholder: (ctx, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                        errorWidget: (ctx, url, err) => _buildFallbackLogo(),
                                      )
                                    : _buildFallbackLogo(),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // App Version Title
                            Text(
                              'PayPulse Mobile v$version',
                              style: AppTextStyles.titleLg.copyWith(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Android Application Package (APK)',
                              style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceMuted),
                              textAlign: TextAlign.center,
                            ),
                            
                            const SizedBox(height: 24),
                            const Divider(),
                            const SizedBox(height: 20),

                            // Update log details
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'WHAT\'S NEW',
                                style: AppTextStyles.labelSm.copyWith(
                                  color: AppColors.primary,
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainer.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(
                                  updateLog,
                                  style: AppTextStyles.bodyMd.copyWith(height: 1.4),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 32),

                            // Download Button
                            PrimaryButton(
                              label: apkUrl.isNotEmpty ? 'Download APK' : 'Download Unavailable',
                              onPressed: apkUrl.isNotEmpty
                                  ? () async {
                                      final url = Uri.parse(apkUrl);
                                      try {
                                        await launchUrl(url, mode: LaunchMode.externalApplication);
                                      } catch (e) {
                                        debugPrint('Could not launch URL: $e');
                                        try {
                                          await launchUrl(url);
                                        } catch (_) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Could not launch download URL')),
                                            );
                                          }
                                        }
                                      }
                                    }
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err', style: TextStyle(color: AppColors.error))),
        ),
      ),
    );
  }

  Widget _buildFallbackLogo() {
    return Container(
      color: Colors.black.withValues(alpha: 0.1),
      child: Center(
        child: Icon(Icons.phone_android_rounded, size: 42, color: AppColors.primary),
      ),
    );
  }
}

/// ────────────────────────────────────────────────────────────────────────────
/// 2. Super Admin side: App Update Settings Screen
/// ────────────────────────────────────────────────────────────────────────────
class AdminAppUpdateScreen extends ConsumerStatefulWidget {
  const AdminAppUpdateScreen({super.key});

  @override
  ConsumerState<AdminAppUpdateScreen> createState() => _AdminAppUpdateScreenState();
}

class _AdminAppUpdateScreenState extends ConsumerState<AdminAppUpdateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _logoController = TextEditingController();
  final _versionController = TextEditingController();
  final _logController = TextEditingController();
  final _apkController = TextEditingController();

  bool _isUploadingLogo = false;
  bool _isUploadingApk = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = ref.read(platformSettingsProvider).asData?.value;
      if (settings != null) {
        _logoController.text = settings.appLogoUrl ?? '';
        _versionController.text = settings.appVersion;
        _logController.text = settings.appUpdateLog;
        _apkController.text = settings.appApkUrl ?? '';
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _versionController.dispose();
    _logController.dispose();
    _apkController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadLogo() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) return;

      setState(() => _isUploadingLogo = true);
      final publicUrl = await ref.read(platformSettingsProvider.notifier).uploadLogoFile(bytes, file.name);
      if (publicUrl != null) {
        _logoController.text = publicUrl;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('App logo uploaded successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload failed. Please try again or paste a link.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isUploadingLogo = false);
    }
  }

  Future<void> _pickAndUploadApk() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['apk'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) return;

      setState(() => _isUploadingApk = true);
      final publicUrl = await ref.read(platformSettingsProvider.notifier).uploadApkFile(bytes, file.name);
      if (publicUrl != null) {
        _apkController.text = publicUrl;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('APK file uploaded successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('APK upload failed. Please try pasting a link.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isUploadingApk = false);
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final current = ref.read(platformSettingsProvider).asData?.value;
    if (current != null) {
      final updated = PlatformSettings(
        companyName: current.companyName,
        tagline: current.tagline,
        gstNo: current.gstNo,
        logoLightUrl: current.logoLightUrl,
        logoDarkUrl: current.logoDarkUrl,
        address: current.address,
        contactEmail: current.contactEmail,
        workingTime: current.workingTime,
        notifyOnSignup: current.notifyOnSignup,
        welcomeTitle: current.welcomeTitle,
        welcomeBody: current.welcomeBody,
        appLogoUrl: _logoController.text.trim(),
        appVersion: _versionController.text.trim(),
        appUpdateLog: _logController.text.trim(),
        appApkUrl: _apkController.text.trim(),
      );

      final error = await ref.read(platformSettingsProvider.notifier).updateSettings(updated);
      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('App Settings saved successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save settings: $error')),
        );
      }
    }
    setState(() => _isSaving = false);
  }

  Widget _buildPreviousReleasesCard() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Previous Releases',
                style: AppTextStyles.titleMd.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildReleaseHistoryItem(
            version: 'v0.9.9',
            date: '02 Jul 2026',
            log: 'Fixed decimal precision on invoice PDFs and added dynamic spacing controls for print margins.',
          ),
          const Divider(height: 24, thickness: 0.5, color: Colors.white24),
          _buildReleaseHistoryItem(
            version: 'v0.9.5',
            date: '18 Jun 2026',
            log: 'Introduced system branding custom themes, enhanced dark mode contrast, and optimized product search filters.',
          ),
          const Divider(height: 24, thickness: 0.5, color: Colors.white24),
          _buildReleaseHistoryItem(
            version: 'v0.9.0',
            date: '25 May 2026',
            log: 'Initial release of core billing engine, store-wise accounting records, and client access management systems.',
          ),
        ],
      ),
    );
  }

  Widget _buildReleaseHistoryItem({required String version, required String date, required String log}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 0.5),
              ),
              child: Text(
                version,
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              date,
              style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceMuted),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          log,
          style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceDim),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(platformSettingsProvider);
    final isWide = MediaQuery.of(context).size.width >= 850;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: isWide ? 40 : 20, vertical: isWide ? 32 : 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else {
                          context.go('/');
                        }
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainer.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.glassBorder, width: 0.5),
                        ),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'App Settings',
                      style: (isWide ? AppTextStyles.headlineLg : AppTextStyles.headlineLgMobile)
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                if (isWide) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Configure the mobile app download package, logo, version, and release notes.',
                    style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted),
                  ),
                ],
                const SizedBox(height: 24),
                
                settingsAsync.when(
                  data: (settings) {
                    final formContent = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Layout Preview of the User Page
                        Text(
                          'PREVIEW',
                          style: AppTextStyles.labelSm.copyWith(
                            color: AppColors.onSurfaceMuted,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Interactive Preview Card (Super Admin sees it live!)
                        ListenableBuilder(
                          listenable: Listenable.merge([_logoController, _versionController, _logController, _apkController]),
                          builder: (ctx, child) {
                            return GlassCard(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Logo Preview
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceDim,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(15),
                                      child: _logoController.text.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: _logoController.text.trim(),
                                              fit: BoxFit.cover,
                                              errorWidget: (c, u, e) => const Icon(Icons.phone_android_rounded),
                                            )
                                          : const Icon(Icons.phone_android_rounded),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'v${_versionController.text.isEmpty ? '1.0.0' : _versionController.text}',
                                          style: AppTextStyles.titleLg.copyWith(fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _logController.text.isEmpty ? 'Initial release update details...' : _logController.text,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _apkController.text.isEmpty ? 'APK not attached' : 'APK Attached: ${_apkController.text.split('/').last.split('?').first}',
                                          style: AppTextStyles.labelSm.copyWith(
                                            color: _apkController.text.isEmpty ? AppColors.error : AppColors.success,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        
                        const SizedBox(height: 32),
                        const Divider(),
                        const SizedBox(height: 24),

                        // Form Fields
                        _buildInputField(
                          label: 'App Version',
                          hint: '1.0.0',
                          controller: _versionController,
                          validator: (v) => v == null || v.trim().isEmpty ? 'App version is required' : null,
                        ),
                        const SizedBox(height: 20),

                        _buildInputField(
                          label: 'Update Log / Release Notes',
                          hint: 'Added billing improvements and resolved dashboard layout bugs.',
                          controller: _logController,
                          maxLines: 4,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Release notes are required' : null,
                        ),
                        const SizedBox(height: 24),

                        // File picker for Logo
                        Text(
                          'APP LOGO IMAGE',
                          style: AppTextStyles.labelMd.copyWith(
                            color: AppColors.onSurfaceMuted,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildInputField(
                                controller: _logoController,
                                hint: 'https://...',
                                showLabel: false,
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              height: 52,
                              child: ElevatedButton.icon(
                                onPressed: _isUploadingLogo ? null : _pickAndUploadLogo,
                                icon: _isUploadingLogo
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                    : const Icon(Icons.image_rounded, size: 18),
                                label: const Text('Upload'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.surfaceContainer,
                                  foregroundColor: AppColors.onBackground,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                                    side: BorderSide(color: AppColors.border),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // File picker for APK
                        Text(
                          'APK DOWNLOAD URL',
                          style: AppTextStyles.labelMd.copyWith(
                            color: AppColors.onSurfaceMuted,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildInputField(
                                controller: _apkController,
                                hint: 'https://...',
                                showLabel: false,
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              height: 52,
                              child: ElevatedButton.icon(
                                onPressed: _isUploadingApk ? null : _pickAndUploadApk,
                                icon: _isUploadingApk
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                    : const Icon(Icons.file_upload_outlined, size: 18),
                                label: const Text('Upload APK'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.surfaceContainer,
                                  foregroundColor: AppColors.onBackground,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                                    side: BorderSide(color: AppColors.border),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 40),

                        // Save Button
                        PrimaryButton(
                          label: _isSaving ? 'Saving...' : 'Save Settings',
                          isLoading: _isSaving,
                          onPressed: _saveSettings,
                        ),
                      ],
                    );

                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: formContent,
                          ),
                          const SizedBox(width: 40),
                          Expanded(
                            flex: 2,
                            child: _buildPreviousReleasesCard(),
                          ),
                        ],
                      );
                    } else {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          formContent,
                          const SizedBox(height: 40),
                          _buildPreviousReleasesCard(),
                        ],
                      );
                    }
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error loading configurations: $e')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    String? label,
    bool showLabel = true,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel && label != null) ...[
          Text(
            label.toUpperCase(),
            style: AppTextStyles.labelMd.copyWith(
              color: AppColors.onSurfaceMuted,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: AppTextStyles.bodyLg,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.bodyLg.copyWith(color: AppColors.onSurfaceMuted),
            filled: true,
            fillColor: AppColors.surfaceDim,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}
