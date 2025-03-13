import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mydpar/screens/register_screen.dart';
import 'package:mydpar/screens/home_screen.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';

// Model for login data, Firebase-ready
class LoginData {
  final String email;
  final String password;

  const LoginData({
    required this.email,
    required this.password,
  });

  // Convert to JSON if needed (e.g., for custom backend)
  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password, // In practice, hash or use Firebase Auth
  };
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controllers initialized in initState for proper lifecycle management
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  // Password visibility state
  bool _isPasswordVisible = false;

  // Constants for consistency and easy tweaking
  static const double _paddingValue = 24.0;
  static const double _spacingSmall = 8.0;
  static const double _spacingMedium = 16.0;
  static const double _spacingLarge = 32.0;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final AppColorTheme colors = themeProvider.currentTheme; // Updated type

    return Scaffold(
      backgroundColor: colors.bg200,
      body: SafeArea(
        child: SingleChildScrollView(
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
      ),
    );
  }

  /// Builds the header with app name and welcome message
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

  /// Email field with basic validation
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
        validator: (value) =>
        value!.isEmpty || !value.contains('@') ? 'Invalid email' : null,
      ),
    ],
  );

  /// Password field with visibility toggle
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
        decoration: _inputDecoration(colors, 'Enter your password').copyWith(
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

  /// Consistent input decoration for text fields
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

  /// Sign-in button with action handler
  Widget _buildSignInButton(BuildContext context, AppColorTheme colors) =>
      ElevatedButton(
        onPressed: _isFormValid() ? () => _handleSignIn(context) : null,
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

  /// Link to the registration screen
  Widget _buildSignUpLink(BuildContext context, AppColorTheme colors) => Row(
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
  );

  /// Checks if the form is valid for submission
  bool _isFormValid() =>
      _emailController.text.isNotEmpty && _passwordController.text.isNotEmpty;

  /// Handles sign-in logic, prepped for Firebase Auth
  void _handleSignIn(BuildContext context) {
    final loginData = LoginData(
      email: _emailController.text,
      password: _passwordController.text,
    );

    // TODO: Replace with Firebase Auth logic
    // Example:
    // try {
    //   await FirebaseAuth.instance.signInWithEmailAndPassword(
    //     email: loginData.email,
    //     password: loginData.password,
    //   );
    //   _navigateTo(context, const HomeScreen(), replace: true);
    // } catch (e) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text('Login failed: $e')),
    //   );
    // }

    // Temporary navigation for testing
    _navigateTo(context, const HomeScreen(), replace: true);
  }

  /// Navigates to a new screen, optionally replacing the current one
  void _navigateTo(BuildContext context, Widget screen, {bool replace = false}) {
    if (replace) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => screen));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    }
  }
}