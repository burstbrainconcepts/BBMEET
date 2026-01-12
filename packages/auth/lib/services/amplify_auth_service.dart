import 'package:amplify_flutter/amplify_flutter.dart';

import 'package:auth/services/auth_service.dart';

class AmplifyAuthService extends AuthService {
  @override
  Future<void> initialize() async {
    // Amplify is configured in main.dart, so we might not need to do anything here
    // or we can check if configured.
  }

  @override
  Future<String> signInAnonymously() async {
    // Cognito User Pools doesn't support "Anonymous" in the same way.
    // Use Guest access or throw error if not supported.
    // For now, we'll try to fetch the current session or auth guest.
    try {
      safePrint("AmplifyAuthService: fetchAuthSession start");
      final result = await Amplify.Auth.fetchAuthSession();
      safePrint("AmplifyAuthService: fetchAuthSession done, isSignedIn: ${result.isSignedIn}");
      if (result.isSignedIn) {
        // Get the current user to retrieve userId
        safePrint("AmplifyAuthService: getCurrentUser start");
        final user = await Amplify.Auth.getCurrentUser();
        safePrint("AmplifyAuthService: getCurrentUser done, userId: ${user.userId}");
        return user.userId;
      } else {
        // If not signed in, we can't really "sign in anonymously" to a User Pool.
        // We might validly return empty or throw.
        throw Exception(
            'Anonymous auth not supported with User Pools. Please usage signIn/signUp.');
      }
    } catch (e) {
      throw Exception('Auth failed: $e');
    }
  }

  // New methods
  @override
  Future<bool> signIn(String username, String password) async {
    try {
      safePrint("AmplifyAuthService: signIn called for user: $username");
      // Ensure clean state
      await Amplify.Auth.signOut();
      safePrint("AmplifyAuthService: signOut complete, calling signIn");

      final result = await Amplify.Auth.signIn(
        username: username,
        password: password,
      );
      safePrint("AmplifyAuthService: signIn returned, isSignedIn: ${result.isSignedIn}");
      if (!result.isSignedIn) {
        safePrint("Sign In incomplete. Next step: ${result.nextStep.signInStep}");
      }
      return result.isSignedIn;
    } catch (e) {
      safePrint("AmplifyAuthService: signIn failed: $e");
      rethrow;
    }
  }

  @override
  Future<bool> signUp(String email, String password, String name) async {
    try {
      final userAttributes = {
        AuthUserAttributeKey.email: email,
        AuthUserAttributeKey.name: name,
      };
      final result = await Amplify.Auth.signUp(
        username: email,
        password: password,
        options: SignUpOptions(userAttributes: userAttributes),
      );
      return result.isSignUpComplete;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> confirmSignUp(String email, String code) async {
    try {
      final result = await Amplify.Auth.confirmSignUp(
        username: email,
        confirmationCode: code,
      );
      safePrint(
          "confirmSignUp result: isSignUpComplete=${result.isSignUpComplete}, nextStep=${result.nextStep.signUpStep}");
      return result.isSignUpComplete;
    } catch (e) {
      safePrint("confirmSignUp failed: $e");
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    await Amplify.Auth.signOut();
  }
}
