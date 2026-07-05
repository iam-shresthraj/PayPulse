import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/glass_input.dart';
import '../../core/widgets/primary_button.dart';
import 'auth_provider.dart';
import '../billing/invoices_provider.dart';
import '../more/daily_rates_provider.dart';
import '../customers/customers_provider.dart';
import '../products/products_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyCodeController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSignUp = false;

  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _loginButtonFocusNode = FocusNode();
  
  final _signUpNameFocusNode = FocusNode();
  final _signUpPhoneFocusNode = FocusNode();
  final _signUpCodeFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isSignUp) {
        _signUpNameFocusNode.requestFocus();
      } else {
        _emailFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _companyCodeController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _loginButtonFocusNode.dispose();
    _signUpNameFocusNode.dispose();
    _signUpPhoneFocusNode.dispose();
    _signUpCodeFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleAction() async {
    if (!_formKey.currentState!.validate()) return;

    final success = _isSignUp
        ? await ref.read(authProvider.notifier).signUp(
              _emailController.text.trim(),
              _passwordController.text,
              _nameController.text.trim(),
              _phoneController.text.trim(),
              _companyCodeController.text.trim().toUpperCase(),
            )
        : await ref.read(authProvider.notifier).login(
              _emailController.text.trim(),
              _passwordController.text,
            );

    if (success && mounted) {
      // Invalidate all data providers so they refetch with the new token.
      ref.invalidate(invoicesProvider);
      ref.invalidate(dailyRatesProvider);
      ref.invalidate(customersProvider);
      ref.invalidate(productsProvider);
      final auth = ref.read(authProvider);
      context.go(auth.isPendingApproval ? '/pending' : '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final themeOverride = ref.watch(themeModeProvider);
    final isWide = MediaQuery.of(context).size.width >= 850;
    final isLight = themeOverride ?? isWide;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Ambient Background Glows ──
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.15),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: const SizedBox(),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.1),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
                child: const SizedBox(),
              ),
            ),
          ),

          // ── Centered Glass Card ──
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  border: Border.all(color: AppColors.glassBorder, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Logo/Title
                            Center(
                              child: Column(
                                children: [
                                  Image.asset(
                                    isLight
                                        ? 'assets/images/paypulse2.png'
                                        : 'assets/images/paypulse1.png',
                                    height: 52,
                                    fit: BoxFit.contain,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'BILLING & INVENTORY SYSTEM',
                                    style: AppTextStyles.labelMd.copyWith(
                                      color: AppColors.onSurfaceMuted,
                                      fontSize: 9,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 40),

                            // Name & Company Code Fields (Sign Up Only)
                            if (_isSignUp) ...[
                              GlassInput(
                                controller: _nameController,
                                focusNode: _signUpNameFocusNode,
                                label: 'Full Name',
                                hint: 'Enter your full name',
                                prefixIcon:  Icon(Icons.person_outline, color: AppColors.onSurfaceMuted, size: 20),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) return 'Name is required';
                                  return null;
                                },
                                onFieldSubmitted: (_) => _signUpPhoneFocusNode.requestFocus(),
                              ),
                              const SizedBox(height: 20),
                              GlassInput(
                                controller: _phoneController,
                                focusNode: _signUpPhoneFocusNode,
                                label: 'Phone Number',
                                hint: 'Enter your phone number',
                                keyboardType: TextInputType.phone,
                                prefixIcon: Icon(Icons.phone_outlined, color: AppColors.onSurfaceMuted, size: 20),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) return 'Phone number is required';
                                  return null;
                                },
                                onFieldSubmitted: (_) => _signUpCodeFocusNode.requestFocus(),
                              ),
                              const SizedBox(height: 20),
                              GlassInput(
                                controller: _companyCodeController,
                                focusNode: _signUpCodeFocusNode,
                                label: 'Company Code',
                                hint: '8-character access code',
                                prefixIcon: Icon(Icons.vpn_key_outlined, color: AppColors.onSurfaceMuted, size: 20),
                                validator: (val) {
                                  final v = val?.trim() ?? '';
                                  if (v.isEmpty) return 'Company code is required';
                                  if (v.length != 8) return 'Code must be exactly 8 characters';
                                  return null;
                                },
                                onFieldSubmitted: (_) => _emailFocusNode.requestFocus(),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Ask your owner or manager for your company access code. It decides your role.',
                                style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted, fontSize: 10),
                              ),
                              const SizedBox(height: 14),
                            ],

                            // Email Field
                            GlassInput(
                              controller: _emailController,
                              focusNode: _emailFocusNode,
                              label: 'Email Address',
                              hint: 'Enter your email address',
                              keyboardType: TextInputType.emailAddress,
                              prefixIcon:  Icon(Icons.email_outlined, color: AppColors.onSurfaceMuted, size: 20),
                              validator: (val) {
                                if (val == null || val.isEmpty) return 'Email is required';
                                if (!val.contains('@')) return 'Please enter a valid email';
                                return null;
                              },
                              onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
                            ),
                            const SizedBox(height: 20),

                            // Password Field
                            GlassInput(
                              controller: _passwordController,
                              focusNode: _passwordFocusNode,
                              label: 'Password',
                              hint: 'Enter your password',
                              obscureText: _obscurePassword,
                              prefixIcon:  Icon(Icons.lock_outlined, color: AppColors.onSurfaceMuted, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  color: AppColors.onSurfaceMuted,
                                  size: 20,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty) return 'Password is required';
                                if (_isSignUp && val.length < 6) return 'Password must be at least 6 characters';
                                return null;
                              },
                              onFieldSubmitted: (_) => _loginButtonFocusNode.requestFocus(),
                            ),
                            const SizedBox(height: 16),

                            // Error Message
                            if (authState.errorMessage != null) ...[
                              Text(
                                authState.errorMessage!,
                                style: AppTextStyles.bodySm.copyWith(color: AppColors.error),
                              ),
                              const SizedBox(height: 16),
                            ],

                            const SizedBox(height: 12),

                            // Primary Action Button
                            Focus(
                              focusNode: _loginButtonFocusNode,
                              onKeyEvent: (node, event) {
                                if (event is KeyDownEvent && (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.numpadEnter)) {
                                  if (!authState.isLoading) {
                                    _handleAction();
                                  }
                                  return KeyEventResult.handled;
                                }
                                return KeyEventResult.ignored;
                              },
                              child: Builder(
                                builder: (context) {
                                  final isFocused = Focus.of(context).hasFocus;
                                  return Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: isFocused ? Border.all(color: AppColors.primary, width: 2) : null,
                                    ),
                                    padding: const EdgeInsets.all(2),
                                    child: PrimaryButton(
                                      label: _isSignUp ? 'CREATE ACCOUNT' : 'LOG IN',
                                      isLoading: authState.isLoading,
                                      onPressed: _handleAction,
                                    ),
                                  );
                                }
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Toggle View Button
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isSignUp = !_isSignUp;
                                    _formKey.currentState?.reset();
                                    // Reset AuthState error messages
                                    ref.invalidate(authProvider);

                                    // Request focus on the first field of the new view
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      if (_isSignUp) {
                                        _signUpNameFocusNode.requestFocus();
                                      } else {
                                        _emailFocusNode.requestFocus();
                                      }
                                    });
                                  });
                                },
                                child: Text(
                                  _isSignUp
                                      ? 'Already have an account? Log In'
                                      : 'Don\'t have an account? Create Account',
                                  style: AppTextStyles.bodySm.copyWith(color: AppColors.primary),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
