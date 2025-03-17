import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mydpar/screens/account/register_screen.dart';
import 'package:mydpar/screens/main/home_screen.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';

class LoginData {
  final String email;
  final String password;

  const LoginData({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
  };
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  static const double _paddingValue = 24.0;
  static const double _spacingSmall = 8.0;
  static const double _spacingMedium = 16.0;
  static const double _spacingLarge = 32.0;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();

    _emailController.addListener(() => setState(() {}));
    _passwordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final AppColorTheme colors = themeProvider.currentTheme;

    return Scaffold(
      backgroundColor: colors.bg200,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(_paddingValue),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  _buildHeader(colors),
                  const SizedBox(height: _spacingLarge),
                  _buildEmailField(colors),
                  const SizedBox(height: _spacingMedium),
                  _buildPasswordField(colors),
                  const SizedBox(height: 24),
                  _buildSignInButton(context, colors),
                  const SizedBox(height: _spacingLarge),
                  _buildSignUpLink(context, colors),
                ],
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppColorTheme colors) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'MY_DPAR',
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: colors.primary300,
        ),
      ),
      const SizedBox(height: _spacingSmall),
      Text(
        'Welcome back, sign in to continue',
        style: TextStyle(fontSize: 16, color: colors.text200),
      ),
    ],
  );

  Widget _buildEmailField(AppColorTheme colors) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Email',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: colors.text200,
        ),
      ),
      const SizedBox(height: _spacingSmall),
      TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        decoration: _inputDecoration(colors, 'Enter your email'),
        validator: (value) => value!.isEmpty || !value.contains('@')
            ? 'Invalid email'
            : null,
      ),
    ],
  );

  Widget _buildPasswordField(AppColorTheme colors) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Password',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: colors.text200,
        ),
      ),
      const SizedBox(height: _spacingSmall),
      TextFormField(
        controller: _passwordController,
        obscureText: !_isPasswordVisible,
        decoration: _inputDecoration(colors, 'Enter your password')
            .copyWith(
          suffixIcon: IconButton(
            icon: Icon(
              _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
              color: colors.text200,
            ),
            onPressed: () =>
                setState(() => _isPasswordVisible = !_isPasswordVisible),
          ),
        ),
        validator: (value) =>
        value!.isEmpty ? 'Password is required' : null,
      ),
    ],
  );

  InputDecoration _inputDecoration(AppColorTheme colors, String hintText) =>
      InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: colors.text200.withOpacity(0.5)),
        filled: true,
        fillColor: colors.bg100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(16),
      );

  Widget _buildSignInButton(BuildContext context, AppColorTheme colors) =>
      ElevatedButton(
        onPressed:
        _isFormValid() && !_isLoading ? () => _handleSignIn(context) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.accent200,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          disabledBackgroundColor: colors.accent200.withOpacity(0.5),
        ),
        child: const Text(
          'Sign In',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      );

  Widget _buildSignUpLink(BuildContext context, AppColorTheme colors) => Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Don\'t have an account? ',
            style: TextStyle(color: colors.text200),
          ),
          GestureDetector(
            onTap: () => _navigateTo(context, const RegisterScreen()),
            child: Text(
              'Sign Up',
              style: TextStyle(
                color: colors.accent200,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: _spacingSmall),
      GestureDetector(
        onTap: () => _handleForgotPassword(context),
        child: Text(
          'Forgot Password?',
          style: TextStyle(
            color: colors.accent200,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );

  bool _isFormValid() =>
      _emailController.text.trim().isNotEmpty &&
          _passwordController.text.isNotEmpty;

  Future<void> _handleSignIn(BuildContext context) async {
    final loginData = LoginData(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    setState(() => _isLoading = true);

    try {
      final UserCredential credential =
      await _auth.signInWithEmailAndPassword(
        email: loginData.email,
        password: loginData.password,
      );

      debugPrint('User signed in with UID: ${credential.user?.uid}');

      if (mounted) {
        _navigateTo(context, const HomeScreen(), replace: true);
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'invalid-credential':
          errorMessage =
          'Invalid email or password. Please check your credentials.';
          break;
        case 'user-not-found':
          errorMessage = 'No account exists with this email.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password. Please try again.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many login attempts. Please try again later.';
          break;
        case 'network-request-failed':
          errorMessage = 'Network error. Please check your connection.';
          break;
        default:
          errorMessage = 'Login failed: ${e.message} (Code: ${e.code})';
      }
      debugPrint('FirebaseAuthException: ${e.code} - ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Unexpected error: $e\nStack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleForgotPassword(BuildContext context) async {
    final email = _emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _auth.sendPasswordResetEmail(email: email);
      debugPrint('Attempted to send reset email to: $email');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
              Text('If an account exists, a reset email has been sent.')),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many requests. Please try again later.';
          break;
        case 'network-request-failed':
          errorMessage = 'Network error. Please check your connection.';
          break;
        default:
          errorMessage = 'Error: ${e.message} (Code: ${e.code})';
      }
      debugPrint('FirebaseAuthException in reset: ${e.code} - ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Unexpected error in reset: $e\nStack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateTo(BuildContext context, Widget screen, {bool replace = false}) {
    if (replace) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => screen));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    }
  }
}