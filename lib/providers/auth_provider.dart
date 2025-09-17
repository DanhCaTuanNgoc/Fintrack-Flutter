import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/auth_service.dart';

class AuthState {
  final bool isLoading;
  final GoogleSignInAccount? user;
  final Object? error;

  const AuthState({this.isLoading = false, this.user, this.error});

  AuthState copyWith(
      {bool? isLoading, GoogleSignInAccount? user, Object? error}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error,
    );
  }
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  AuthNotifier(this._authService) : super(const AuthState());

  Future<void> loadSession() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final logged = await _authService.isLoggedIn();
      if (logged) {
        // Try silent sign-in to restore account
        final GoogleSignInAccount? acc = await GoogleSignIn().signInSilently();
        state = state.copyWith(isLoading: false, user: acc);
      } else {
        state = state.copyWith(isLoading: false, user: null);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<bool> signIn() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final acc = await _authService.signInWithGoogle();
      state = state.copyWith(isLoading: false, user: acc);
      return acc != null;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
      return false;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.signOut();
      state = state.copyWith(isLoading: false, user: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final svc = ref.read(authServiceProvider);
  return AuthNotifier(svc);
});
