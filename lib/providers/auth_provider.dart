import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../data/models/user.dart';
import '../data/repositories/user_repository.dart';

// Auth state
enum AuthStatus { initial, authenticated, unauthenticated, loading, pinRequired }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? error;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
    );
  }

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;
  bool get isLoading => status == AuthStatus.loading;
  bool get isPinRequired => status == AuthStatus.pinRequired;
  bool get isAdmin => user?.isAdmin ?? false;
  bool get isManager => user?.isManager ?? false;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final UserRepository _userRepository;

  AuthNotifier(this._userRepository) : super(const AuthState());

  /// Initialize without auto-login (let splash screen handle routing)
  Future<void> initialize() async {
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Restore session for PIN-only login
  Future<void> restoreSession(String userId) async {
    try {
      final user = await _userRepository.getById(userId);
      if (user != null) {
        state = AuthState(status: AuthStatus.pinRequired, user: user);
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /// Login with email/phone and password (full login)
  Future<bool> loginWithEmail(String identifier, String password) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    
    try {
      // Find user by email or phone
      final user = await _userRepository.getByEmailOrPhone(identifier);
      
      if (user == null) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          error: 'Account not found. Please check your email/phone.',
        );
        return false;
      }

      // Verify password
      final authenticated = await _userRepository.authenticateWithEmail(
        user.email,
        password,
      );

      if (authenticated != null) {
        state = AuthState(status: AuthStatus.authenticated, user: authenticated);
        await _saveSession(authenticated.id);
        return true;
      } else {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          error: 'Invalid password. Please try again.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: 'Login failed. Please try again.',
      );
      return false;
    }
  }

  /// Login with PIN (quick unlock)
  Future<bool> loginWithPin(String pin) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    
    try {
      // If we have a user from session restore, verify their PIN
      if (state.user != null) {
        final user = await _userRepository.authenticateWithPin(pin);
        if (user != null && user.id == state.user!.id) {
          state = AuthState(status: AuthStatus.authenticated, user: user);
          return true;
        }
      } else {
        // General PIN login
        final user = await _userRepository.authenticateWithPin(pin);
        if (user != null) {
          state = AuthState(status: AuthStatus.authenticated, user: user);
          await _saveSession(user.id);
          return true;
        }
      }
      
      state = state.copyWith(
        status: AuthStatus.pinRequired,
        error: 'Invalid PIN',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.pinRequired,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Save session for quick unlock on app reopen
  Future<void> _saveSession(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.lastLoggedInUserKey, userId);
      await prefs.setBool(AppConstants.hasActiveSessionKey, true);
    } catch (e) {
      // Ignore session save errors
    }
  }

  /// Clear session on logout
  Future<void> _clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.lastLoggedInUserKey);
      await prefs.setBool(AppConstants.hasActiveSessionKey, false);
    } catch (e) {
      // Ignore session clear errors
    }
  }

  /// Logout and clear session
  Future<void> logout() async {
    await _clearSession();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void updateUser(User user) {
    state = state.copyWith(user: user);
  }

  /// Check if user has set up their PIN
  bool get hasPin => state.user?.pinHash != null || state.user?.pin != null;
}

// Providers
final userRepositoryProvider = Provider((ref) => UserRepository());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(userRepositoryProvider));
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

/// Check if any users exist in the database
final hasUsersProvider = FutureProvider<bool>((ref) async {
  final userRepository = ref.watch(userRepositoryProvider);
  final users = await userRepository.getAll();
  return users.isNotEmpty;
});
