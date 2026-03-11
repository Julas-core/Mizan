import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api/api_service.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthState {
  final bool isLoading;
  final String? userId;

  AuthState({this.isLoading = true, this.userId});

  bool get isAuthenticated => userId != null && userId!.isNotEmpty;
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState()) {
    _init();
  }

  Future<void> _init() async {
    // API Service initializes persistence internally
    await ApiService.initialize();
    state = AuthState(
      isLoading: false,
      userId: ApiService.currentUserId.isEmpty
          ? null
          : ApiService.currentUserId,
    );
  }

  Future<void> login(String userId) async {
    // Actually the app creates users inside ApiService.createUser(), setting the id
    // We should probably just refresh the auth state.
    state = AuthState(isLoading: false, userId: userId);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user_id');
    // Note: since ApiService has static state, we might need a way to clear it there too,
    // although this is a simple prototype.
    state = AuthState(isLoading: false, userId: null);
  }
}
