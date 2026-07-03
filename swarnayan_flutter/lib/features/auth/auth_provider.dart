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
      if (session != null && session.user != null) {
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
          .select()
          .eq('id', uid)
          .maybeSingle();
      if (data != null) {
        final userMap = {
          '_id': data['id'],
          'name': data['name'],
          'email': data['email'],
          'role': data['role'] ?? 'STAFF',
          'isActive': data['is_active'] ?? true,
          'phone': data['phone'],
          'address': data['address'],
          'lastLogin': data['last_login'],
        };
        return User.fromJson(userMap);
      }
    } catch (e) {
      // Log or handle error
    }
    return null;
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

        if (!profile.isActive) {
          await _client.auth.signOut();
          state = state.copyWith(
            isLoading: false,
            errorMessage: 'Your account has been deactivated. Contact the owner.',
          );
          return false;
        }

        // Update last login in profiles table
        await _client.from('profiles').update({
          'last_login': DateTime.now().toIso8601String(),
        }).eq('id', profile.id);

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

  Future<bool> signUp(String email, String password, String name) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final role = email.toLowerCase() == 'swarnayanjewellers@gmail.com' ? 'OWNER' : 'STAFF';
      
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'role': role,
        },
      );

      if (response.user != null) {
        // Wait a small bit for DB trigger to complete and then fetch profile
        await Future.delayed(const Duration(milliseconds: 500));
        final profile = await _fetchProfile(response.user!.id);
        
        if (profile != null) {
          // If we want immediate login after sign up
          state = AuthState(
            user: profile,
            isAuthenticated: true,
            isLoading: false,
          );
          return true;
        } else {
          // Trigger might still be running or delayed, try one more time
          await Future.delayed(const Duration(seconds: 1));
          final retryProfile = await _fetchProfile(response.user!.id);
          if (retryProfile != null) {
            state = AuthState(
              user: retryProfile,
              isAuthenticated: true,
              isLoading: false,
            );
            return true;
          }
        }
        
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Account created, but profile initialization failed. Please try logging in.',
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
