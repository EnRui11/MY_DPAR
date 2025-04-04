import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mydpar/screens/account/register_screen.dart';
import 'package:mydpar/screens/main/bottom_nav_container.dart';
import 'package:mydpar/services/language_service.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';
import 'package:mydpar/localization/app_localizations.dart';
import 'package:mydpar/services/user_information_service.dart';

/// Data model for login credentials.
class LoginData {
  final String email;
  final String password;

  const LoginData({required this.email, required this.password});

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

/// Screen for user login with email and password.
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

  static const _padding = 24.0;
  static const _spacingSmall = 8.0;
  static const _spacingMedium = 16.0;
  static const _spacingLarge = 32.0;

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
    final themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    final colors = themeProvider.currentTheme;
    final languageService = Provider.of<LanguageService>(context, listen: true);
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: colors.bg200,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(themeProvider, colors, languageService),
            _buildContent(colors, localizations),
          ],
        ),
      ),
    );
  }

  /// Handles the sign-in process with Firebase Authentication.
  Future<void> _signIn(BuildContext context) async {
    final localizations = AppLocalizations.of(context);
    final userService =
        Provider.of<UserInformationService>(context, listen: false);
    final colors =
        Provider.of<ThemeProvider>(context, listen: false).currentTheme;

    setState(() => _isLoading = true);
    _showSnackBar(
        context, localizations.translate('signing_in'), colors.accent200);

    try {
      final credential = await userService.loginUser(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      debugPrint('User signed in with UID: ${credential.user?.uid}');
      if (mounted) {
        _navigateTo(context, const BottomNavContainer(), replace: true);
      }
    } catch (e) {
      _showErrorSnackBar(context, _mapErrorToMessage(e, localizations));
      debugPrint('Sign-in error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Handles the password reset process.
  Future<void> _resetPassword(BuildContext context) async {
    final localizations = AppLocalizations.of(context);
    final userService =
        Provider.of<UserInformationService>(context, listen: false);
    final colors =
        Provider.of<ThemeProvider>(context, listen: false).currentTheme;
    final email = _emailController.text.trim();

    if (!_isValidEmail(email)) {
      _showErrorSnackBar(context, localizations.translate('enter_valid_email'));
      return;
    }

    setState(() => _isLoading = true);
    _showSnackBar(context, localizations.translate('sending_reset_email'),
        colors.accent200);

    try {
      await userService.resetPassword(email);
      if (mounted) {
        _showSnackBar(context, localizations.translate('reset_email_sent'),
            colors.accent200);
      }
    } catch (e) {
      _showErrorSnackBar(context, _mapErrorToMessage(e, localizations));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Builds the header with theme toggle and language selector.
  Widget _buildHeader(
    ThemeProvider themeProvider,
    AppColorTheme colors,
    LanguageService languageService,
  ) =>
      Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: _padding, vertical: _spacingSmall),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildThemeToggle(themeProvider, colors),
            _buildLanguageSelector(languageService, colors),
          ],
        ),
      );

  /// Builds the theme toggle switch.
  Widget _buildThemeToggle(ThemeProvider themeProvider, AppColorTheme colors) =>
      Switch(
        value: themeProvider.isDarkMode,
        onChanged: (_) => themeProvider.toggleTheme(),
        activeColor: colors.accent200,
        activeTrackColor: colors.accent200.withOpacity(0.3),
        inactiveThumbColor: Colors.amber,
        inactiveTrackColor: Colors.amber.withOpacity(0.3),
        thumbIcon: MaterialStateProperty.resolveWith<Icon?>(
          (states) => Icon(
            themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
            size: 16,
            color: themeProvider.isDarkMode ? colors.bg100 : Colors.white,
          ),
        ),
        trackOutlineColor: MaterialStateProperty.resolveWith(
          (states) => themeProvider.isDarkMode
              ? colors.bg300.withOpacity(0.2)
              : Colors.transparent,
        ),
      );

  /// Builds the language selector popup menu.
  Widget _buildLanguageSelector(
          LanguageService languageService, AppColorTheme colors) =>
      PopupMenuButton<String>(
        offset: const Offset(0, 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: colors.bg100,
        itemBuilder: (_) => [
          _buildLanguageOption(
              LanguageService.english, 'EN', 'English', colors),
          _buildLanguageOption(
              LanguageService.malay, 'BM', 'Bahasa Melayu', colors),
          _buildLanguageOption(LanguageService.mandarin, 'ZH', '中文', colors),
        ],
        onSelected: languageService.changeLanguage,
        child: Container(
          height: 32,
          width: 48,
          decoration: BoxDecoration(
            color: colors.accent200.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.accent200.withOpacity(0.3)),
          ),
          child: Center(
            child: Text(
              languageService.currentLanguageCode,
              style: TextStyle(
                  color: colors.accent200,
                  fontWeight: FontWeight.w600,
                  fontSize: 14),
            ),
          ),
        ),
      );

  /// Builds a single language option for the popup menu.
  PopupMenuItem<String> _buildLanguageOption(
    String value,
    String code,
    String name,
    AppColorTheme colors,
  ) =>
      PopupMenuItem(
        value: value,
        child: Row(
          children: [
            Text(code,
                style: TextStyle(
                    color: colors.text100, fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Text(name, style: TextStyle(color: colors.text200)),
          ],
        ),
      );

  /// Builds the main content area with the login form.
  Widget _buildContent(AppColorTheme colors, AppLocalizations localizations) =>
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(_padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildAppTitle(colors, localizations),
              const SizedBox(height: _spacingLarge),
              _buildEmailField(colors, localizations),
              const SizedBox(height: _spacingMedium),
              _buildPasswordField(colors, localizations),
              const SizedBox(height: 24),
              _buildSignInButton(colors, localizations),
              const SizedBox(height: _spacingLarge),
              _buildSignUpLink(colors, localizations),
            ],
          ),
        ),
      );

  /// Builds the app title and welcome message.
  Widget _buildAppTitle(AppColorTheme colors, AppLocalizations localizations) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MY_DPAR',
            style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: colors.primary300),
          ),
          const SizedBox(height: _spacingSmall),
          Text(
            localizations.translate('welcome_back_sign_in'),
            style: TextStyle(fontSize: 16, color: colors.text200),
          ),
        ],
      );

  /// Builds the email input field.
  Widget _buildEmailField(
          AppColorTheme colors, AppLocalizations localizations) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel(localizations.translate('email'), colors),
          const SizedBox(height: _spacingSmall),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: _buildInputDecoration(
                colors, localizations.translate('enter_your_email')),
            validator: (value) => value!.isEmpty || !value.contains('@')
                ? localizations.translate('invalid_email')
                : null,
          ),
        ],
      );

  /// Builds the password input field with visibility toggle.
  Widget _buildPasswordField(
          AppColorTheme colors, AppLocalizations localizations) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel(localizations.translate('password'), colors),
          const SizedBox(height: _spacingSmall),
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            decoration: _buildInputDecoration(
                    colors, localizations.translate('enter_your_password'))
                .copyWith(suffixIcon: _buildPasswordVisibilityToggle(colors)),
            validator: (value) => value!.isEmpty
                ? localizations.translate('password_required')
                : null,
          ),
        ],
      );

  /// Builds the password visibility toggle icon.
  Widget _buildPasswordVisibilityToggle(AppColorTheme colors) => IconButton(
        icon: Icon(
          _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
          color: colors.text200,
        ),
        onPressed: () =>
            setState(() => _isPasswordVisible = !_isPasswordVisible),
      );

  /// Builds a common input decoration for text fields.
  InputDecoration _buildInputDecoration(
          AppColorTheme colors, String hintText) =>
      InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: colors.text200.withOpacity(0.5)),
        filled: true,
        fillColor: colors.bg100,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.all(16),
      );

  /// Builds the sign-in button.
  Widget _buildSignInButton(
          AppColorTheme colors, AppLocalizations localizations) =>
      ElevatedButton(
        onPressed:
            _isFormValid() && !_isLoading ? () => _signIn(context) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.accent200,
          minimumSize: const Size(double.infinity, 56),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          disabledBackgroundColor: colors.accent200.withOpacity(0.5),
        ),
        child: Text(
          localizations.translate('sign_in'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      );

  /// Builds the sign-up link and forgot password option.
  Widget _buildSignUpLink(
          AppColorTheme colors, AppLocalizations localizations) =>
      Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                localizations.translate('dont_have_account'),
                style: TextStyle(color: colors.text200),
              ),
              GestureDetector(
                onTap: () => _navigateTo(context, const RegisterScreen()),
                child: Text(
                  localizations.translate('sign_up'),
                  style: TextStyle(
                      color: colors.accent200, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: _spacingSmall),
          GestureDetector(
            onTap: () => _resetPassword(context),
            child: Text(
              localizations.translate('forgot_password'),
              style: TextStyle(
                  color: colors.accent200, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      );

  /// Builds the loading overlay for async operations.
  Widget _buildLoadingOverlay(AppColorTheme colors) => Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: colors.bg100,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Signing in...',
                  style: TextStyle(
                    color: colors.text100,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  /// Builds a field label with consistent styling.
  Widget _buildFieldLabel(String text, AppColorTheme colors) => Text(
        text,
        style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w500, color: colors.text200),
      );

  /// Validates the form data.
  bool _isFormValid() =>
      _emailController.text.trim().isNotEmpty &&
      _passwordController.text.isNotEmpty;

  /// Maps FirebaseAuthException codes to localized messages for sign-in.
  String _mapErrorToMessage(dynamic e, AppLocalizations localizations) {
    if (e is FirebaseAuthException) {
      const errorMap = {
        'invalid-credential': 'invalid_credentials',
        'user-not-found': 'no_account_exists',
        'wrong-password': 'incorrect_password',
        'invalid-email': 'invalid_email_address',
        'user-disabled': 'account_disabled',
        'too-many-requests': 'too_many_login_attempts',
        'network-request-failed': 'network_error',
      };
      return localizations.translate(
        errorMap[e.code] ?? 'error_with_code',
        {'message': e.message ?? '', 'code': e.code},
      );
    }
    return localizations
        .translate('error_with_code', {'message': e.toString(), 'code': ''});
  }

  bool _isValidEmail(String email) => email.isNotEmpty && email.contains('@');

  void _navigateTo(BuildContext context, Widget screen,
      {bool replace = false}) {
    final route = MaterialPageRoute(builder: (_) => screen);
    if (replace) {
      Navigator.pushReplacement(context, route);
    } else {
      Navigator.push(context, route);
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  void _showSnackBar(
      BuildContext context, String message, Color backgroundColor) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: backgroundColor),
      );
    }
  }
}
