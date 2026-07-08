import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/splash_screen.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SplashConfig.init();

  await Supabase.initialize(
    url: 'https://gnyzctxlqcidubanoiae.supabase.co',
    publishableKey: 'sb_publishable_h-fS9Q3g4ucAfmvD9btgWg_NwH4PKbH',
  );

  // Force dark status bar for the dark theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const ProviderScope(child: PayPulseApp()));
}

class PayPulseApp extends ConsumerWidget {
  const PayPulseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeOverride = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'PayPulse',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final isWide = mediaQuery.size.width >= 850;
        final isLight = themeOverride ?? isWide;
        AppColors.useLightMode(isLight);
        return Theme(
          key: ValueKey(isLight),
          data: isLight ? AppTheme.lightTheme : AppTheme.darkTheme,
          child: child!,
        );
      },
    );
  }
}
