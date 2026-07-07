import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../models/user.dart';

class AuthState {
  final User? user;
  final bool isAuthenticated;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.user,
    this.isAuthenticated = false,
    this.isLoading = false,
    this.errorMessage,
  });

  /// True when logged in but the account is still waiting for approval.
  bool get isPendingApproval =>
      isAuthenticated && user != null && !user!.isApproved && !user!.isDeassociated;

  bool get isDeassociated =>
      isAuthenticated && user != null && user!.isDeassociated;

  bool get isExpired =>
      isAuthenticated && user != null && user!.isExpired;


  AuthState copyWith({
    User? user,
    bool? isAuthenticated,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final sb.SupabaseClient _client = sb.Supabase.instance.client;

  AuthNotifier() : super(const AuthState()) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    state = state.copyWith(isLoading: true);
    try {
      final session = _client.auth.currentSession;
      if (session != null) {
        final profile = await _fetchProfile(session.user.id);
        if (profile != null) {
          state = AuthState(
            user: profile,
            isAuthenticated: true,
            isLoading: false,
          );
        } else {
          state = const AuthState(isAuthenticated: false, isLoading: false);
        }
      } else {
        state = const AuthState(isAuthenticated: false, isLoading: false);
      }
    } catch (e) {
      state = const AuthState(isAuthenticated: false, isLoading: false);
    }
  }

  Future<User?> _fetchProfile(String uid) async {
    try {
      final data = await _client
          .from('profiles')
          .select('*, companies(category, renew_date)')
          .eq('id', uid)
          .maybeSingle();
      if (data != null) {
        return User.fromJson(data);
      }
    } catch (e) {
      // Profile fetch failed; treated as unauthenticated.
    }
    return null;
  }

  /// Refresh the current profile (used by the pending-approval screen).
  Future<void> refreshProfile() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    final profile = await _fetchProfile(uid);
    if (profile != null) {
      state = AuthState(
        user: profile,
        isAuthenticated: true,
        isLoading: false,
      );
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        final profile = await _fetchProfile(response.user!.id);
        if (profile == null) {
          state = state.copyWith(
            isLoading: false,
            errorMessage: 'Failed to retrieve user profile.',
          );
          return false;
        }

        if (profile.approvalStatus == 'REJECTED') {
          await _client.auth.signOut();
          state = state.copyWith(
            isLoading: false,
            errorMessage:
                'Your access request was rejected. Contact your manager or owner.',
          );
          return false;
        }

        if (!profile.isActive && profile.isApproved) {
          await _client.auth.signOut();
          state = state.copyWith(
            isLoading: false,
            errorMessage: 'Your account has been deactivated. Contact the owner.',
          );
          return false;
        }

        if (profile.isApproved) {
          await _client.from('profiles').update({
            'last_login': DateTime.now().toIso8601String(),
          }).eq('id', profile.id);
        }

        state = AuthState(
          user: profile,
          isAuthenticated: true,
          isLoading: false,
        );
        return true;
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Invalid login credentials.',
      );
      return false;
    } catch (e) {
      String msg = 'Failed to connect to the authentication server.';
      if (e is sb.AuthException) {
        msg = e.message;
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: msg,
      );
      return false;
    }
  }

  /// Validates an 8-character company code without exposing other codes.
  /// Returns the role the code grants (STAFF / MANAGER / OWNER) or null.
  Future<({String companyName, String role})?> validateCompanyCode(
      String code) async {
    final result = await _client.rpc('validate_company_code',
        params: {'p_code': code.trim().toUpperCase()});
    if (result is List && result.isNotEmpty) {
      final row = Map<String, dynamic>.from(result.first);
      return (
        companyName: (row['company_name'] ?? '').toString(),
        role: (row['role'] ?? 'STAFF').toString(),
      );
    }
    return null;
  }

  Future<bool> signUp(
    String email,
    String password,
    String name,
    String phone,
    String companyCode,
  ) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      // 1. Validate the company code first so the user gets a clear error.
      final validation = await validateCompanyCode(companyCode);
      if (validation == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Invalid company code. Please check with your company.',
        );
        return false;
      }

      // 2. Create the account; the DB trigger assigns role + approval status.
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'phone': phone,
          'company_code': companyCode.trim().toUpperCase(),
        },
      );

      if (response.user != null) {
        if (response.session == null) {
          state = state.copyWith(
            isLoading: false,
            errorMessage: 'Account created! Please check your email and click the confirmation link before logging in.',
          );
          return false;
        }

        // Give the DB trigger a moment to create the profile.
        User? profile;
        for (var attempt = 0; attempt < 3; attempt++) {
          await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
          profile = await _fetchProfile(response.user!.id);
          if (profile != null) break;
        }

        if (profile != null) {
          state = AuthState(
            user: profile,
            isAuthenticated: true,
            isLoading: false,
          );
          return true;
        }

        state = state.copyWith(
          isLoading: false,
          errorMessage:
              'Account created, but profile initialization failed. Please try logging in.',
        );
        return false;
      }

      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to create account.',
      );
      return false;
    } catch (e) {
      String msg = 'Failed to create account.';
      if (e is sb.AuthException) {
        msg = e.message;
      } else if (e.toString().contains('Invalid company code')) {
        msg = 'Invalid company code. Please check with your company.';
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: msg,
      );
      return false;
    }
  }

  Future<void> updateProfile({
    required String name,
    required String phone,
    required String address,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) throw Exception('No logged in user found');

      await _client.from('profiles').update({
        'name': name,
        'phone': phone,
        'address': address,
      }).eq('id', currentUser.id);

      final updatedProfile = await _fetchProfile(currentUser.id);
      state = state.copyWith(user: updatedProfile, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  /// Uploads a profile photo to the `avatars` bucket and stores its URL.
  Future<void> uploadProfilePhoto(Uint8List bytes, String extension) async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) throw Exception('No logged in user found');

    final safeExt = extension.replaceAll('.', '').toLowerCase();
    final path = '${currentUser.id}.$safeExt';
    await _client.storage.from('avatars').uploadBinary(
          path,
          bytes,
          fileOptions: sb.FileOptions(
            upsert: true,
            contentType: safeExt == 'png' ? 'image/png' : 'image/jpeg',
          ),
        );

    // Cache-bust so the new photo shows immediately.
    final publicUrl = _client.storage.from('avatars').getPublicUrl(path);
    final url = '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';

    await _client
        .from('profiles')
        .update({'avatar_url': url}).eq('id', currentUser.id);

    final updatedProfile = await _fetchProfile(currentUser.id);
    state = state.copyWith(user: updatedProfile, isLoading: false);
  }

  Future<bool> reassociateCompany(String code) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _client.rpc('reassociate_company', params: {'p_code': code.trim().toUpperCase()});
      final profile = await _fetchProfile(_client.auth.currentUser!.id);
      if (profile != null) {
        state = AuthState(
          user: profile,
          isAuthenticated: true,
          isLoading: false,
        );
        return true;
      }
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to fetch updated profile.');
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    try {
      await _client.auth.signOut();
      state = const AuthState(isAuthenticated: false, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
