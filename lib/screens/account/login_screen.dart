import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mydpar/screens/account/register_screen.dart';
import 'package:mydpar/screens/main/home_screen.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';
import 'package:mydpar/localization/app_localizations.dart';
import 'package:mydpar/services/language_service.dart';

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
    final localizations = AppLocalizations.of(context);
    final languageService = Provider.of<LanguageService>(context);

    return Scaffold(
      backgroundColor: colors.bg200,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(themeProvider, colors, languageService),
                _buildContent(colors),
              ],
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

  /// Builds the header with theme toggle and language selector.
  Widget _buildHeader(ThemeProvider themeProvider, AppColorTheme colors,
      LanguageService languageService) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: _paddingValue, vertical: _spacingSmall),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Theme toggle on the left
          SizedBox(
            child: Switch(
              value: themeProvider.isDarkMode,
              onChanged: (_) => themeProvider.toggleTheme(),
              activeColor: colors.accent200,
              activeTrackColor: colors.accent200.withOpacity(0.3),
              inactiveThumbColor: Colors.amber,
              inactiveTrackColor: Colors.amber.withOpacity(0.3),
              thumbIcon: MaterialStateProperty.resolveWith<Icon?>(
                (Set<MaterialState> states) {
                  return Icon(
                    themeProvider.isDarkMode
                        ? Icons.dark_mode
                        : Icons.light_mode,
                    size: 16,
                    color:
                        themeProvider.isDarkMode ? colors.bg100 : Colors.white,
                  );
                },
              ),
              trackOutlineColor: MaterialStateProperty.resolveWith(
                (states) => themeProvider.isDarkMode
                    ? colors.bg300.withOpacity(0.2)
                    : Colors.transparent,
              ),
            ),
          ),

          // Language selector on the right
          PopupMenuButton<String>(
            offset: const Offset(0, 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: colors.bg100,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: LanguageService.english,
                child: Row(
                  children: [
                    Text(
                      'EN',
                      style: TextStyle(
                        color: colors.text100,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'English',
                      style: TextStyle(
                        color: colors.text200,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: LanguageService.malay,
                child: Row(
                  children: [
                    Text(
                      'BM',
                      style: TextStyle(
                        color: colors.text100,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Bahasa Melayu',
                      style: TextStyle(
                        color: colors.text200,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: LanguageService.mandarin,
                child: Row(
                  children: [
                    Text(
                      'ZH',
                      style: TextStyle(
                        color: colors.text100,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '中文',
                      style: TextStyle(
                        color: colors.text200,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            onSelected: (String value) {
              languageService.changeLanguage(value);
            },
            child: Container(
              height: 32,
              width: 48,
              decoration: BoxDecoration(
                color: colors.accent200.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colors.accent200.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  languageService.currentLanguageCode,
                  style: TextStyle(
                    color: colors.accent200,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the main content area with login form.
  Widget _buildContent(AppColorTheme colors) {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(_paddingValue),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildAppTitle(colors),
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
    );
  }

  Widget _buildAppTitle(AppColorTheme colors) {
    final localizations = AppLocalizations.of(context);

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
        const SizedBox(height: _spacingSmall),
        Text(
          localizations.translate('welcome_back_sign_in'),
          style: TextStyle(fontSize: 16, color: colors.text200),
        ),
      ],
    );
  }

  Widget _buildEmailField(AppColorTheme colors) {
    final localizations = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.translate('email'),
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
          decoration: _inputDecoration(
              colors, localizations.translate('enter_your_email')),
          validator: (value) => value!.isEmpty || !value.contains('@')
              ? localizations.translate('invalid_email')
              : null,
        ),
      ],
    );
  }

  Widget _buildPasswordField(AppColorTheme colors) {
    final localizations = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.translate('password'),
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
          decoration: _inputDecoration(
                  colors, localizations.translate('enter_your_password'))
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
          validator: (value) => value!.isEmpty
              ? localizations.translate('password_required')
              : null,
        ),
      ],
    );
  }

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

  Widget _buildSignInButton(BuildContext context, AppColorTheme colors) {
    final localizations = AppLocalizations.of(context);

    return ElevatedButton(
      onPressed:
          _isFormValid() && !_isLoading ? () => _handleSignIn(context) : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.accent200,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        disabledBackgroundColor: colors.accent200.withOpacity(0.5),
      ),
      child: Text(
        localizations.translate('sign_in'),
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildSignUpLink(BuildContext context, AppColorTheme colors) {
    final localizations = AppLocalizations.of(context);

    return Column(
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
            localizations.translate('forgot_password'),
            style: TextStyle(
              color: colors.accent200,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  bool _isFormValid() =>
      _emailController.text.trim().isNotEmpty &&
      _passwordController.text.isNotEmpty;

  Future<void> _handleSignIn(BuildContext context) async {
    final localizations = AppLocalizations.of(context);
    final loginData = LoginData(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    setState(() => _isLoading = true);

    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
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
          errorMessage = localizations.translate('invalid_credentials');
          break;
        case 'user-not-found':
          errorMessage = localizations.translate('no_account_exists');
          break;
        case 'wrong-password':
          errorMessage = localizations.translate('incorrect_password');
          break;
        case 'invalid-email':
          errorMessage = localizations.translate('invalid_email_address');
          break;
        case 'user-disabled':
          errorMessage = localizations.translate('account_disabled');
          break;
        case 'too-many-requests':
          errorMessage = localizations.translate('too_many_login_attempts');
          break;
        case 'network-request-failed':
          errorMessage = localizations.translate('network_error');
          break;
        default:
          errorMessage = localizations.translate(
              'login_failed', {'message': e.message ?? '', 'code': e.code});
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
    final localizations = AppLocalizations.of(context);
    final email = _emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.translate('enter_valid_email'))),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _auth.sendPasswordResetEmail(email: email);
      debugPrint('Attempted to send reset email to: $email');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.translate('reset_email_sent'))),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'invalid-email':
          errorMessage = localizations.translate('invalid_email_address');
          break;
        case 'too-many-requests':
          errorMessage = localizations.translate('too_many_requests');
          break;
        case 'network-request-failed':
          errorMessage = localizations.translate('network_error');
          break;
        default:
          errorMessage = localizations.translate(
              'error_with_code', {'message': e.message ?? '', 'code': e.code});
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
