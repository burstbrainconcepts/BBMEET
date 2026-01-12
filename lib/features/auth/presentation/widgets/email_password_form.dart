import 'package:flutter/material.dart';
import 'package:auth/auth.dart';
import 'package:bb_meet/core/app/colors/app_color.dart';
import 'package:bb_meet/core/utils/sizer/sizer.dart';
import 'package:bb_meet/features/app/bloc/bloc.dart';
import 'package:bb_meet/features/auth/presentation/bloc/auth_bloc.dart';

class EmailPasswordForm extends StatefulWidget {
  const EmailPasswordForm({super.key});

  @override
  State<EmailPasswordForm> createState() => _EmailPasswordFormState();
}

class _EmailPasswordFormState extends State<EmailPasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _auth = Auth();

  bool _isSignUp = false;
  bool _isVerification = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _infoMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _showError(Object error) {
    if (!mounted) {
      return;
    }
    String message = error.toString();

    // Parse specific Amplify/Cognito exceptions
    if (message.contains('UsernameExistsException') ||
        message.contains('User already exists')) {
      message = 'Account already exists. Please sign in.';
    } else if (message.contains('CodeMismatchException')) {
      message = 'Invalid verification code. Please try again.';
    } else if (message.contains('NotAuthorizedException') ||
        message.contains('Incorrect username or password')) {
      message = 'Incorrect email or password.';
    } else if (message.contains('UserNotConfirmedException')) {
      message = 'Account not verified. Please verify your email.';
    } else if (message.contains('LimitExceededException')) {
      message = 'Too many attempts. Please try again later.';
    } else if (message.contains('InvalidParameterException')) {
      message = 'Invalid details provided.';
    } else {
      // Clean up generic exception prefixes and JSON mess
      if (message.contains('"message":')) {
        // Try to extract clean message from JSON-like string
        final match = RegExp(r'"message":\s*"([^"]+)"').firstMatch(message);
        if (match != null) {
          message = match.group(1) ?? message;
        }
      }
      message = message.replaceAll('Exception: ', '');
    }

    setState(() {
      _errorMessage = message;
      _infoMessage = null;
    });
  }

  void _showInfo(String message) {
    if (!mounted) {
      return;
    }
    setState(() {
      _infoMessage = message;
      _errorMessage = null;
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    try {
      if (_isVerification) {
        await _handleVerification();
      } else if (_isSignUp) {
        await _handleSignUp();
      } else {
        await _handleSignIn();
      }
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleVerification() async {
    final success = await _auth.confirmSignUp(
      _emailController.text.trim(),
      _codeController.text.trim(),
    );

    if (success && mounted) {
      _showInfo("Verification successful! Signing in...");
      await _handleSignIn(skipLoading: true);
    } else if (mounted) {
      _showError(
        "Verification incomplete. Please check code or try signing in.",
      );
    }
  }

  Future<void> _handleSignUp() async {
    final success = await _auth.signUp(
      _emailController.text.trim(),
      _passwordController.text,
      _nameController.text.trim(),
    );

    if (mounted) {
      if (success) {
        // User already confirmed or no confirmation needed
        await _handleSignIn(skipLoading: true);
      } else {
        // Needs verification
        setState(() {
          _isVerification = true;
          _infoMessage =
              "A verification code has been sent to ${_emailController.text}";
        });
      }
    }
  }

  Future<void> _handleSignIn({bool skipLoading = false}) async {
    debugPrint("EmailPasswordForm: _handleSignIn called, skipLoading: $skipLoading");
    if (!skipLoading && !mounted) {
      debugPrint("EmailPasswordForm: widget not mounted, aborting");
      return;
    }

    try {
      debugPrint("EmailPasswordForm: Calling _auth.signIn");
      final success = await _auth.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );
      debugPrint("EmailPasswordForm: _auth.signIn result: $success");

      if (success && mounted) {
        // Small delay to ensure session propagation
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          debugPrint("EmailPasswordForm: Adding AuthLoggedIn event");
          AppBloc.authBloc.add(AuthLoggedIn());
        }
      } else if (mounted) {
        debugPrint("EmailPasswordForm: Sign in failed (success=false)");
        _showError("Sign in failed. Please try again.");
      }
    } catch (e) {
       debugPrint("EmailPasswordForm: Error failure $e");
    }
  }

  Future<void> _handleResendCode() async {
    // Note: You needs to implement resend code in AuthService if available
    // For now we just show a message or re-trigger sign up which might resend
    setState(() {
      _isLoading = true;
    });
    try {
      // Triggering signUp again often resends the code if user exists and is unconfirmed
      await _auth.signUp(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
      );
      _showInfo("Code resent! Check your email.");
    } catch (e) {
      _showError("Failed to resend code: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Info Message
          if (_infoMessage != null)
            Container(
              padding: EdgeInsets.all(12.sp),
              margin: EdgeInsets.only(bottom: 16.sp),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.sp),
                border: Border.all(color: Colors.blue),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 16.sp),
                  SizedBox(width: 8.sp),
                  Expanded(
                    child: Text(
                      _infoMessage!,
                      style: TextStyle(color: Colors.blue, fontSize: 12.sp),
                    ),
                  ),
                ],
              ),
            ),

          // Error Message
          if (_errorMessage != null)
            Container(
              padding: EdgeInsets.all(12.sp),
              margin: EdgeInsets.only(bottom: 16.sp),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.sp),
                border: Border.all(color: Colors.red),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 16.sp),
                  SizedBox(width: 8.sp),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red, fontSize: 12.sp),
                    ),
                  ),
                ],
              ),
            ),

          // Verification Code Input
          if (_isVerification) ...[
            Padding(
              padding: EdgeInsets.only(bottom: 12.sp),
              child: TextFormField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Verification Code',
                  hintText: '123456',
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.sp),
                  ),
                  prefixIcon: const Icon(Icons.security),
                ),
                validator: (v) => _isVerification && (v == null || v.isEmpty)
                    ? 'Enter code'
                    : null,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : _handleResendCode,
                  child: Text("Resend Code", style: TextStyle(fontSize: 12.sp)),
                ),
              ],
            ),
          ],

          // Name Input (Sign Up Only)
          if (_isSignUp && !_isVerification)
            Padding(
              padding: EdgeInsets.only(bottom: 12.sp),
              child: TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.sp),
                  ),
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (v) =>
                    _isSignUp && (v == null || v.isEmpty) ? 'Enter name' : null,
              ),
            ),

          // Email Input
          if (!_isVerification ||
              _isSignUp) // Show email except when verifying (or maybe show read-only)
            Padding(
              padding: EdgeInsets.only(bottom: 12.sp),
              child: TextFormField(
                controller: _emailController,
                enabled: !_isVerification,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.sp),
                  ),
                  prefixIcon: const Icon(Icons.email),
                ),
                validator: (v) => (v == null || !v.contains('@'))
                    ? 'Valid email required'
                    : null,
              ),
            ),

          // Password Input
          if (!_isVerification)
            Padding(
              padding: EdgeInsets.only(bottom: 16.sp),
              child: TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.sp),
                  ),
                  prefixIcon: const Icon(Icons.lock),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter password';
                  if (_isSignUp && v.length < 8) return 'Min 8 characters';
                  return null;
                },
              ),
            ),

          // Submit Button
          ElevatedButton(
            onPressed: _isLoading ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16.sp),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.sp),
              ),
            ),
            child: _isLoading
                ? SizedBox(
                    height: 20.sp,
                    width: 20.sp,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    _isVerification
                        ? 'Verify & Sign In'
                        : (_isSignUp ? 'Sign Up' : 'Sign In'),
                    style: TextStyle(fontSize: 14.sp),
                  ),
          ),

          SizedBox(height: 12.sp),

          // Toggle Mode Button
          if (!_isVerification)
            TextButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      setState(() {
                        _isSignUp = !_isSignUp;
                        _errorMessage = null;
                        _infoMessage = null;
                        _formKey.currentState?.reset();
                      });
                    },
              child: Text(
                _isSignUp
                    ? 'Already have an account? Sign In'
                    : "Don't have an account? Sign Up",
                style: TextStyle(fontSize: 12.sp, color: mGB),
              ),
            ),

          // Back to Sign Up/In from Verification
          if (_isVerification)
            TextButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      setState(() {
                        _isVerification = false;
                        _errorMessage = null;
                        _infoMessage = null;
                      });
                    },
              child: Text(
                'Cancel Verification',
                style: TextStyle(fontSize: 12.sp, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }
}
