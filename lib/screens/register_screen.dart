import 'package:flutter/material.dart';
import 'package:mydpar/theme/color_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyRelationController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  bool _hasMinLength = false;
  bool _hasUpperCase = false;
  bool _hasLowerCase = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;
  bool _passwordsMatch = false;

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

  void _updatePasswordStatus() {
    final password = _passwordController.text;
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasUpperCase = password.contains(RegExp(r'[A-Z]'));
      _hasLowerCase = password.contains(RegExp(r'[a-z]'));
      _hasNumber = password.contains(RegExp(r'[0-9]'));
      _hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
      _passwordsMatch = password == _confirmPasswordController.text &&
          _confirmPasswordController.text.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg200,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  Text(
                    'Get Started',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary300,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your account to continue',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.text200,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Personal Information
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _firstNameController,
                          label: 'First Name',
                          hint: 'First name',
                          required: true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _lastNameController,
                          label: 'Last Name',
                          hint: 'Last name',
                          required: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _emailController,
                    label: 'Email',
                    hint: 'Enter your email',
                    keyboardType: TextInputType.emailAddress,
                    required: true,
                  ),
                  const SizedBox(height: 16),

                  // Password Fields
                  _buildPasswordField(
                    controller: _passwordController,
                    label: 'Password',
                    hint: 'Create a password',
                    isVisible: _isPasswordVisible,
                    onVisibilityChanged: (value) =>
                        setState(() => _isPasswordVisible = value),
                    onChanged: (value) => _updatePasswordStatus(),
                  ),
                  
                  // Password Requirements
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        _buildRequirement('At least 8 characters', _hasMinLength),
                        _buildRequirement('At least one uppercase letter', _hasUpperCase),
                        _buildRequirement('At least one lowercase letter', _hasLowerCase),
                        _buildRequirement('At least one number', _hasNumber),
                        _buildRequirement('At least one special character', _hasSpecialChar),
                      ],
                    ),
                  ),

                  _buildPasswordField(
                    controller: _confirmPasswordController,
                    label: 'Confirm Password',
                    hint: 'Re-enter your password',
                    isVisible: _isConfirmPasswordVisible,
                    onVisibilityChanged: (value) =>
                        setState(() => _isConfirmPasswordVisible = value),
                    onChanged: (value) => _updatePasswordStatus(),
                  ),

                  if (_confirmPasswordController.text.isNotEmpty)
                    _buildRequirement(
                      'Passwords match',
                      _passwordsMatch,
                    ),

                  // Emergency Contact Section
                  const SizedBox(height: 32),
                  Text(
                    'Emergency Contact',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary300,
                    ),
                  ),
                  Text(
                    'You can add this field later.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.warning,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _emergencyNameController,
                    label: 'Contact Name',
                    hint: 'Emergency contact name',
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _emergencyRelationController,
                    label: 'Relationship',
                    hint: 'Relationship to contact',
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _emergencyPhoneController,
                    label: 'Contact Phone',
                    hint: 'Emergency contact phone',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  ElevatedButton(
                    onPressed: _canSubmit() ? _handleSubmit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent200,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      disabledBackgroundColor: AppColors.accent200.withOpacity(0.5),
                    ),
                    child: const Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  // Sign In Link
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: TextStyle(color: AppColors.text200),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Text(
                            'Sign In',
                            style: TextStyle(
                              color: AppColors.accent200,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    bool required = false,
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
              color: AppColors.text200,
            ),
            children: required
                ? [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(color: AppColors.warning),
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.text200.withOpacity(0.5)),
            filled: true,
            fillColor: AppColors.bg100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isVisible,
    required Function(bool) onVisibilityChanged,
    required Function(String) onChanged,
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
              color: AppColors.text200,
            ),
            children: [
              TextSpan(
                text: ' *',
                style: TextStyle(color: AppColors.warning),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: !isVisible,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.text200.withOpacity(0.5)),
            filled: true,
            fillColor: AppColors.bg100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
            suffixIcon: IconButton(
              icon: Icon(
                isVisible ? Icons.visibility_off : Icons.visibility,
                color: AppColors.text200,
              ),
              onPressed: () => onVisibilityChanged(!isVisible),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRequirement(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isMet ? Colors.green : AppColors.warning,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: isMet ? Colors.green : AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }

  bool _canSubmit() {
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
    }
  }
}