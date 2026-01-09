abstract class AuthService {
  Future<void> initialize();
  Future<String> signInAnonymously();
  Future<bool> signIn(String username, String password);
  Future<bool> signUp(String email, String password, String name);
  Future<void> signOut();
}
