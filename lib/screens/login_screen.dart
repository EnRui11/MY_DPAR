import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mydpar/screens/register_screen.dart';
import 'package:mydpar/screens/home_screen.dart';
import 'package:mydpar/theme/theme_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isPasswordVisible = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.currentTheme;

    return Scaffold(
      backgroundColor: colors.bg200,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              _buildHeader(colors),
              const SizedBox(height: 32),
              _buildEmailField(colors),
              const SizedBox(height: 16),
              _buildPasswordField(colors),
              const SizedBox(height: 24),
              _buildSignInButton(context, colors),
              const SizedBox(height: 32),
              _buildSignUpLink(context, colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(dynamic colors) {
    return Column(
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
        const SizedBox(height: 8),
        Text(
          'Welcome back, sign in to continue',
          style: TextStyle(fontSize: 16, color: colors.text200),
        ),
      ],
    );
  }

  Widget _buildEmailField(dynamic colors) {
    return Column(
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
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: _inputDecoration(colors, 'Enter your email'),
        ),
      ],
    );
  }

  Widget _buildPasswordField(dynamic colors) {
    return Column(
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
        const SizedBox(height: 8),
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
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(dynamic colors, String hintText) {
    return InputDecoration(
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
  }

  Widget _buildSignInButton(BuildContext context, dynamic colors) {
    return ElevatedButton(
      onPressed: () => _handleSignIn(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.accent200,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: const Text(
        'Sign In',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildSignUpLink(BuildContext context, dynamic colors) {
    return Row(
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
  }

  void _handleSignIn(BuildContext context) {
    // TODO: Implement actual login logic (e.g., validate inputs, API call)
    _navigateTo(context, const HomeScreen(), replace: true);
  }

  void _navigateTo(BuildContext context, Widget screen,
      {bool replace = false}) {
    if (replace) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => screen));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    }
  }
}
