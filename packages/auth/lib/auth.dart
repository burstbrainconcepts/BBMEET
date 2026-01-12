import 'package:auth/services/auth_service.dart';
import 'package:auth/services/index.dart';

class Auth {
  final AuthService _authService = getInstance;

  Future<void> initialize() => _authService.initialize();
  Future<String> signInAnonymously() => _authService.signInAnonymously();
  Future<bool> signIn(String username, String password) =>
      _authService.signIn(username, password);
  Future<bool> signUp(String email, String password, String name) =>
      _authService.signUp(email, password, name);
  Future<bool> confirmSignUp(String email, String code) =>
      _authService.confirmSignUp(email, code);
  Future<void> signOut() => _authService.signOut();
}
