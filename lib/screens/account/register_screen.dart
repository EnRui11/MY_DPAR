import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';
import 'package:mydpar/screens/main/home_screen.dart';

// User model for registration data, Firebase-ready
class UserRegistrationData {
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String phoneNumber;
  final EmergencyContact? emergencyContact;

  const UserRegistrationData({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.phoneNumber,
    this.emergencyContact,
  });

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phoneNumber': phoneNumber,
        'emergencyContact': emergencyContact?.toJson(),
        'createdAt': FieldValue.serverTimestamp(),
      };
}

// Emergency contact model, nullable for optional input
class EmergencyContact {
  final String name;
  final String relation;
  final String phone;

  const EmergencyContact({
    required this.name,
    required this.relation,
    required this.phone,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'relation': relation,
        'phone': phone,
      };
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  late final TextEditingController _phoneNumberController;
  late final TextEditingController _emergencyNameController;
  late final TextEditingController _emergencyRelationController;
  late final TextEditingController _emergencyPhoneController;

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _hasMinLength = false;
  bool _hasUpperCase = false;
  bool _hasLowerCase = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;
  bool _passwordsMatch = false;
  bool _isLoading = false;

  static const int _minPasswordLength = 8;
  static const double _paddingValue = 24.0;
  static const double _spacingSmall = 8.0;
  static const double _spacingMedium = 16.0;
  static const double _spacingLarge = 32.0;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _phoneNumberController = TextEditingController();
    _emergencyNameController = TextEditingController();
    _emergencyRelationController = TextEditingController();
    _emergencyPhoneController = TextEditingController();

    _passwordController.addListener(_updatePasswordRequirements);
    _confirmPasswordController.addListener(_updatePasswordRequirements);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneNumberController.dispose();
    _emergencyNameController.dispose();
    _emergencyRelationController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  void _updatePasswordRequirements() {
    final String password = _passwordController.text;
    final String confirmPassword = _confirmPasswordController.text;
    setState(() {
      _hasMinLength = password.length >= _minPasswordLength;
      _hasUpperCase = password.contains(RegExp(r'[A-Z]'));
      _hasLowerCase = password.contains(RegExp(r'[a-z]'));
      _hasNumber = password.contains(RegExp(r'[0-9]'));
      _hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
      _passwordsMatch =
          password == confirmPassword && confirmPassword.isNotEmpty;
    });
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(colors),
                    const SizedBox(height: _spacingLarge),
                    _buildPersonalInfoSection(colors),
                    _buildPasswordSection(colors),
                    _buildEmergencyContactSection(colors),
                    const SizedBox(height: _spacingLarge),
                    _buildSubmitButton(colors),
                    _buildSignInLink(colors),
                  ],
                ),
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
          const SizedBox(height: 40),
          Text(
            'Get Started',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: colors.primary300,
            ),
          ),
          const SizedBox(height: _spacingSmall),
          Text(
            'Create your account to continue',
            style: TextStyle(fontSize: 16, color: colors.text200),
          ),
        ],
      );

  Widget _buildPersonalInfoSection(AppColorTheme colors) => Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _firstNameController,
                  label: 'First Name',
                  hint: 'First name',
                  colors: colors,
                  isRequired: true,
                ),
              ),
              const SizedBox(width: _spacingMedium),
              Expanded(
                child: _buildTextField(
                  controller: _lastNameController,
                  label: 'Last Name',
                  hint: 'Last name',
                  colors: colors,
                  isRequired: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: _spacingMedium),
          _buildTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'Enter your email',
            colors: colors,
            keyboardType: TextInputType.emailAddress,
            isRequired: true,
            validator: (value) =>
                value!.isEmpty || !value.contains('@') ? 'Invalid email' : null,
          ),
          const SizedBox(height: _spacingMedium),
          _buildTextField(
            controller: _phoneNumberController,
            label: 'Phone Number',
            hint: 'Enter your phone number',
            colors: colors,
            keyboardType: TextInputType.phone,
            isRequired: true,
            validator: (value) => value!.isEmpty || value.length < 10
                ? 'Please enter a valid phone number'
                : null,
          ),
          const SizedBox(height: _spacingMedium),
        ],
      );

  Widget _buildPasswordSection(AppColorTheme colors) => Column(
        children: [
          _buildPasswordField(
            controller: _passwordController,
            label: 'Password',
            hint: 'Create a password',
            colors: colors,
            isVisible: _isPasswordVisible,
            toggleVisibility: () =>
                setState(() => _isPasswordVisible = !_isPasswordVisible),
          ),
          _buildPasswordRequirements(colors),
          _buildPasswordField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            hint: 'Re-enter your password',
            colors: colors,
            isVisible: _isConfirmPasswordVisible,
            toggleVisibility: () => setState(
                () => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
          ),
          if (_confirmPasswordController.text.isNotEmpty)
            _buildRequirement('Passwords match', _passwordsMatch, colors),
        ],
      );

  Widget _buildPasswordRequirements(AppColorTheme colors) => Padding(
        padding: const EdgeInsets.symmetric(vertical: _spacingSmall),
        child: Column(
          children: [
            _buildRequirement('At least $_minPasswordLength characters',
                _hasMinLength, colors),
            _buildRequirement(
                'At least one uppercase letter', _hasUpperCase, colors),
            _buildRequirement(
                'At least one lowercase letter', _hasLowerCase, colors),
            _buildRequirement('At least one number', _hasNumber, colors),
            _buildRequirement(
                'At least one special character', _hasSpecialChar, colors),
          ],
        ),
      );

  Widget _buildEmergencyContactSection(AppColorTheme colors) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: _spacingLarge),
          Text(
            'Emergency Contact',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.primary300,
            ),
          ),
          Text(
            'You can add this field later.',
            style: TextStyle(
              fontSize: 14,
              color: colors.warning,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: _spacingMedium),
          _buildTextField(
            controller: _emergencyNameController,
            label: 'Contact Name',
            hint: 'Emergency contact name',
            colors: colors,
          ),
          const SizedBox(height: _spacingMedium),
          _buildTextField(
            controller: _emergencyRelationController,
            label: 'Relationship',
            hint: 'Relationship to contact',
            colors: colors,
          ),
          const SizedBox(height: _spacingMedium),
          _buildTextField(
            controller: _emergencyPhoneController,
            label: 'Contact Phone',
            hint: 'Emergency contact phone',
            colors: colors,
            keyboardType: TextInputType.phone,
          ),
        ],
      );

  Widget _buildSubmitButton(AppColorTheme colors) => ElevatedButton(
        onPressed: _isFormValid() && !_isLoading ? _handleSubmit : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.accent200,
          minimumSize: const Size(double.infinity, 56),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          disabledBackgroundColor: colors.accent200.withOpacity(0.5),
        ),
        child: const Text(
          'Create Account',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      );

  Widget _buildSignInLink(AppColorTheme colors) => Padding(
        padding: const EdgeInsets.symmetric(vertical: _spacingLarge),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Already have an account? ',
                style: TextStyle(color: colors.text200)),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Text(
                'Sign In',
                style: TextStyle(
                  color: colors.accent200,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required AppColorTheme colors,
    TextInputType? keyboardType,
    bool isRequired = false,
    String? Function(String?)? validator,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colors.text200,
              ),
              children: isRequired
                  ? [
                      TextSpan(
                        text: ' *',
                        style: TextStyle(color: colors.warning),
                      )
                    ]
                  : null,
            ),
          ),
          const SizedBox(height: _spacingSmall),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator ??
                (isRequired
                    ? (value) => value!.isEmpty ? '$label is required' : null
                    : null),
            decoration: _textFieldDecoration(hint, colors),
          ),
        ],
      );

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required AppColorTheme colors,
    required bool isVisible,
    required VoidCallback toggleVisibility,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colors.text200,
              ),
              children: [
                TextSpan(text: ' *', style: TextStyle(color: colors.warning)),
              ],
            ),
          ),
          const SizedBox(height: _spacingSmall),
          TextFormField(
            controller: controller,
            obscureText: !isVisible,
            decoration: _textFieldDecoration(hint, colors).copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  isVisible ? Icons.visibility_off : Icons.visibility,
                  color: colors.text200,
                ),
                onPressed: toggleVisibility,
              ),
            ),
            validator: (value) => value!.isEmpty ? '$label is required' : null,
          ),
        ],
      );

  InputDecoration _textFieldDecoration(String hint, AppColorTheme colors) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: colors.text200.withOpacity(0.5)),
        filled: true,
        fillColor: colors.bg100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(16),
      );

  Widget _buildRequirement(String text, bool isMet, AppColorTheme colors) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: _spacingSmall,
              height: _spacingSmall,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isMet ? Colors.green : colors.warning,
              ),
            ),
            const SizedBox(width: _spacingSmall),
            Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: isMet ? Colors.green : colors.warning,
              ),
            ),
          ],
        ),
      );

  bool _isFormValid() =>
      _firstNameController.text.isNotEmpty &&
      _lastNameController.text.isNotEmpty &&
      _emailController.text.isNotEmpty &&
      _phoneNumberController.text.isNotEmpty &&
      _hasMinLength &&
      _hasUpperCase &&
      _hasLowerCase &&
      _hasNumber &&
      _hasSpecialChar &&
      _passwordsMatch;

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate() || !_isFormValid()) return;

    setState(() => _isLoading = true);

    try {
      final emergencyContact = _emergencyNameController.text.isNotEmpty &&
              _emergencyRelationController.text.isNotEmpty &&
              _emergencyPhoneController.text.isNotEmpty
          ? EmergencyContact(
              name: _emergencyNameController.text,
              relation: _emergencyRelationController.text,
              phone: _emergencyPhoneController.text,
            )
          : null;

      final userData = UserRegistrationData(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phoneNumber: _phoneNumberController.text.trim(),
        emergencyContact: emergencyContact,
      );

      // Log input data for debugging
      debugPrint('Registering user with email: ${userData.email}');

      // Register user with Firebase Authentication
      final UserCredential credential =
          await _auth.createUserWithEmailAndPassword(
        email: userData.email,
        password: userData.password,
      );

      debugPrint('User created with UID: ${credential.user?.uid}');

      // Store user data in Firestore
      await _firestore.collection('users').doc(credential.user!.uid).set(
            userData.toJson(),
          );

      debugPrint('User data stored in Firestore');

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'This email is already registered.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is invalid.';
          break;
        case 'weak-password':
          errorMessage = 'The password is too weak.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Email/password accounts are not enabled.';
          break;
        case 'network-request-failed':
          errorMessage = 'Network error. Please check your connection.';
          break;
        default:
          errorMessage = 'Authentication error: ${e.message} (Code: ${e.code})';
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
}
