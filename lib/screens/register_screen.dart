import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mydpar/theme/theme_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
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

  static const _minPasswordLength = 8;
  static const _paddingValue = 24.0;
  static const _spacingSmall = 8.0;
  static const _spacingMedium = 16.0;
  static const _spacingLarge = 32.0;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _emergencyNameController = TextEditingController();
    _emergencyRelationController = TextEditingController();
    _emergencyPhoneController = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
    final colors = themeProvider.currentTheme; // Ensure ColorTheme is defined

    return Scaffold(
      backgroundColor: colors.bg200,
      body: SafeArea(
        child: SingleChildScrollView(
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
      ),
    );
  }

  Widget _buildHeader(dynamic colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        Text(
          'Get Started',
          style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: colors.primary300),
        ),
        const SizedBox(height: _spacingSmall),
        Text(
          'Create your account to continue',
          style: TextStyle(fontSize: 16, color: colors.text200),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoSection(dynamic colors) {
    return Column(
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
        ),
        const SizedBox(height: _spacingMedium),
      ],
    );
  }

  Widget _buildPasswordSection(dynamic colors) {
    return Column(
      children: [
        _buildPasswordField(
          controller: _passwordController,
          label: 'Password',
          hint: 'Create a password',
          colors: colors,
          isVisible: _isPasswordVisible,
          toggleVisibility: () =>
              setState(() => _isPasswordVisible = !_isPasswordVisible),
          onChanged: (value) => _updatePasswordRequirements(),
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
          onChanged: (value) => _updatePasswordRequirements(),
        ),
        if (_confirmPasswordController.text.isNotEmpty)
          _buildRequirement('Passwords match', _passwordsMatch, colors),
      ],
    );
  }

  Widget _buildPasswordRequirements(dynamic colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: _spacingSmall),
      child: Column(
        children: [
          _buildRequirement(
              'At least $_minPasswordLength characters', _hasMinLength, colors),
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
  }

  Widget _buildEmergencyContactSection(dynamic colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: _spacingLarge),
        Text(
          'Emergency Contact',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.primary300),
        ),
        Text(
          'You can add this field later.',
          style: TextStyle(
              fontSize: 14, color: colors.warning, fontStyle: FontStyle.italic),
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
  }

  Widget _buildSubmitButton(dynamic colors) {
    return ElevatedButton(
      onPressed: _isFormValid() ? _handleSubmit : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.accent200,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        disabledBackgroundColor: colors.accent200.withOpacity(0.5),
      ),
      child: const Text(
        'Create Account',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildSignInLink(dynamic colors) {
    return Padding(
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
                  color: colors.accent200, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required colors,
    TextInputType? keyboardType,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colors.text200),
            children: isRequired
                ? [
                    TextSpan(
                        text: ' *', style: TextStyle(color: colors.warning))
                  ]
                : null,
          ),
        ),
        const SizedBox(height: _spacingSmall),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: _textFieldDecoration(hint, colors),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required colors,
    required bool isVisible,
    required VoidCallback toggleVisibility,
    required ValueChanged<String> onChanged, // Changed to ValueChanged<String>
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colors.text200),
            children: [
              TextSpan(text: ' *', style: TextStyle(color: colors.warning))
            ],
          ),
        ),
        const SizedBox(height: _spacingSmall),
        TextFormField(
          controller: controller,
          obscureText: !isVisible,
          onChanged: onChanged,
          decoration: _textFieldDecoration(hint, colors).copyWith(
            suffixIcon: IconButton(
              icon: Icon(isVisible ? Icons.visibility_off : Icons.visibility,
                  color: colors.text200),
              onPressed: toggleVisibility,
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _textFieldDecoration(String hint, dynamic colors) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: colors.text200.withOpacity(0.5)),
      filled: true,
      fillColor: colors.bg100,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.all(16),
    );
  }

  Widget _buildRequirement(String text, bool isMet, dynamic colors) {
    return Padding(
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
                fontSize: 14, color: isMet ? Colors.green : colors.warning),
          ),
        ],
      ),
    );
  }

  bool _isFormValid() {
    return _firstNameController.text.isNotEmpty &&
        _lastNameController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        _hasMinLength &&
        _hasUpperCase &&
        _hasLowerCase &&
        _hasNumber &&
        _hasSpecialChar &&
        _passwordsMatch;
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      // TODO: Implement registration logic
      // Example:
      // final userData = {
      //   'firstName': _firstNameController.text,
      //   'lastName': _lastNameController.text,
      //   'email': _emailController.text,
      //   'password': _passwordController.text,
      //   'emergencyContact': {
      //     'name': _emergencyNameController.text,
      //     'relation': _emergencyRelationController.text,
      //     'phone': _emergencyPhoneController.text,
      //   }
      // };
      // Navigate to next screen or show success message
    }
  }
}
