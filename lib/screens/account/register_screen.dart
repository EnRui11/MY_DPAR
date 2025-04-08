import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mydpar/screens/account/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:mydpar/localization/app_localizations.dart';
import 'package:mydpar/services/language_service.dart';
import 'package:mydpar/services/user_information_service.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';

/// Data model for user registration, Firebase-ready.
class UserRegistrationData {
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String phoneNumber;
  final List<EmergencyContact> emergencyContacts;
  final String role;

  const UserRegistrationData({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.phoneNumber,
    this.emergencyContacts = const [],
    this.role = 'normal',
  });

  /// Converts the user data to a JSON map for Firestore.
  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phoneNumber': phoneNumber,
        'emergencyContacts': emergencyContacts.map((e) => e.toJson()).toList(),
        'role': role,
      };
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  late final TextEditingController _phoneNumberController;
  List<EmergencyContact> _emergencyContacts = [];

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _hasMinLength = false;
  bool _hasUpperCase = false;
  bool _hasLowerCase = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;
  bool _passwordsMatch = false;
  bool _isLoading = false;

  static const _minPasswordLength = 8;
  static const _padding = 24.0;
  static const _spacingSmall = 8.0;
  static const _spacingMedium = 16.0;
  static const _spacingLarge = 32.0;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _passwordController.addListener(_updatePasswordRequirements);
    _confirmPasswordController.addListener(_updatePasswordRequirements);
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _initializeControllers() {
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _phoneNumberController = TextEditingController();
  }

  void _disposeControllers() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneNumberController.dispose();
  }

  void _updatePasswordRequirements() {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    setState(() {
      _hasMinLength = password.length >= _minPasswordLength;
      _hasUpperCase = RegExp(r'[A-Z]').hasMatch(password);
      _hasLowerCase = RegExp(r'[a-z]').hasMatch(password);
      _hasNumber = RegExp(r'[0-9]').hasMatch(password);
      _hasSpecialChar = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
      _passwordsMatch =
          password == confirmPassword && confirmPassword.isNotEmpty;
    });
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
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(themeProvider, colors, languageService),
                _buildContent(colors, localizations),
              ],
            ),
            if (_isLoading) _buildLoadingOverlay(colors),
          ],
        ),
      ),
    );
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
      SizedBox(
        width: 80,
        child: Switch(
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

  /// Builds the main content area with the registration form.
  Widget _buildContent(AppColorTheme colors, AppLocalizations localizations) =>
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(_padding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAppTitle(colors, localizations),
                const SizedBox(height: _spacingLarge),
                _buildPersonalInfoSection(colors, localizations),
                _buildPasswordSection(colors, localizations),
                _buildEmergencyContactSection(colors, localizations),
                const SizedBox(height: _spacingLarge),
                _buildSubmitButton(colors, localizations),
                _buildSignInLink(colors, localizations),
              ],
            ),
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
            localizations.translate('get_started'),
            style: TextStyle(fontSize: 16, color: colors.text200),
          ),
          const SizedBox(height: _spacingSmall),
          Text(
            localizations.translate('create_account_to_continue'),
            style: TextStyle(fontSize: 16, color: colors.text200),
          ),
        ],
      );

  /// Builds the personal information input section.
  Widget _buildPersonalInfoSection(
          AppColorTheme colors, AppLocalizations localizations) =>
      Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _firstNameController,
                  label: localizations.translate('first_name'),
                  hint: localizations.translate('first_name_hint'),
                  colors: colors,
                  isRequired: true,
                ),
              ),
              const SizedBox(width: _spacingMedium),
              Expanded(
                child: _buildTextField(
                  controller: _lastNameController,
                  label: localizations.translate('last_name'),
                  hint: localizations.translate('last_name_hint'),
                  colors: colors,
                  isRequired: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: _spacingMedium),
          _buildTextField(
            controller: _emailController,
            label: localizations.translate('email'),
            hint: localizations.translate('enter_your_email'),
            colors: colors,
            keyboardType: TextInputType.emailAddress,
            isRequired: true,
            validator: (value) => value!.isEmpty || !value.contains('@')
                ? localizations.translate('invalid_email')
                : null,
          ),
          const SizedBox(height: _spacingMedium),
          _buildTextField(
            controller: _phoneNumberController,
            label: localizations.translate('phone_number'),
            hint: localizations.translate('enter_phone_number'),
            colors: colors,
            keyboardType: TextInputType.phone,
            isRequired: true,
            validator: (value) => value!.isEmpty || value.length < 10
                ? localizations.translate('invalid_phone_number')
                : null,
          ),
          const SizedBox(height: _spacingMedium),
        ],
      );

  /// Builds the password input section with requirements.
  Widget _buildPasswordSection(
          AppColorTheme colors, AppLocalizations localizations) =>
      Column(
        children: [
          _buildPasswordField(
            controller: _passwordController,
            label: localizations.translate('password'),
            hint: localizations.translate('create_password'),
            colors: colors,
            isVisible: _isPasswordVisible,
            toggleVisibility: () =>
                setState(() => _isPasswordVisible = !_isPasswordVisible),
          ),
          _buildPasswordRequirements(colors, localizations),
          _buildPasswordField(
            controller: _confirmPasswordController,
            label: localizations.translate('confirm_password'),
            hint: localizations.translate('reenter_password'),
            colors: colors,
            isVisible: _isConfirmPasswordVisible,
            toggleVisibility: () => setState(
                () => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
          ),
          if (_confirmPasswordController.text.isNotEmpty)
            _buildRequirement(localizations.translate('passwords_match'),
                _passwordsMatch, colors),
        ],
      );

  /// Builds the password requirements display.
  Widget _buildPasswordRequirements(
          AppColorTheme colors, AppLocalizations localizations) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: _spacingSmall),
        child: Column(
          children: [
            _buildRequirement(
              localizations.translate(
                  'min_characters', {'count': _minPasswordLength.toString()}),
              _hasMinLength,
              colors,
            ),
            _buildRequirement(localizations.translate('one_uppercase'),
                _hasUpperCase, colors),
            _buildRequirement(localizations.translate('one_lowercase'),
                _hasLowerCase, colors),
            _buildRequirement(
                localizations.translate('one_number'), _hasNumber, colors),
            _buildRequirement(localizations.translate('one_special_char'),
                _hasSpecialChar, colors),
          ],
        ),
      );

  /// Builds the emergency contact input section.
  Widget _buildEmergencyContactSection(
          AppColorTheme colors, AppLocalizations localizations) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: _spacingLarge),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                localizations.translate('emergency_contact'),
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colors.primary300),
              ),
              TextButton.icon(
                icon: Icon(Icons.add, color: colors.accent200, size: 18),
                label: Text(
                  localizations.translate('add'),
                  style: TextStyle(color: colors.accent200),
                ),
                onPressed: () => _showAddContactDialog(colors, localizations),
              ),
            ],
          ),
          Text(
            localizations.translate('add_later'),
            style: TextStyle(
                fontSize: 14,
                color: colors.warning,
                fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: _spacingMedium),
          if (_emergencyContacts.isNotEmpty)
            Column(
              children: _emergencyContacts
                  .asMap()
                  .entries
                  .map((entry) => _buildEmergencyContactCard(
                      colors, localizations, entry.key, entry.value))
                  .toList(),
            )
          else
            _buildEmptyContactCard(colors, localizations),
        ],
      );

  /// Builds a card showing the emergency contact information
  Widget _buildEmergencyContactCard(
          AppColorTheme colors,
          AppLocalizations localizations,
          int index,
          EmergencyContact contact) =>
      Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: colors.bg100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.bg300.withOpacity(0.2)),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  style: TextStyle(
                      color: colors.primary300, fontWeight: FontWeight.w500),
                ),
                Text(
                  contact.relation,
                  style: TextStyle(color: colors.text200, fontSize: 14),
                ),
                Text(
                  contact.phone,
                  style: TextStyle(color: colors.text200, fontSize: 14),
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: colors.accent200),
                  onPressed: () => _showAddContactDialog(colors, localizations,
                      index: index, contact: contact),
                  tooltip: localizations.translate('edit_contact'),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: colors.warning),
                  onPressed: () => _deleteContact(index),
                  tooltip: localizations.translate('delete_contact'),
                ),
              ],
            ),
          ],
        ),
      );

  /// Shows a dialog to add or edit emergency contact
  void _showAddContactDialog(
      AppColorTheme colors, AppLocalizations localizations,
      {int? index, EmergencyContact? contact}) {
    final isEditing = index != null;
    final nameController = TextEditingController(text: contact?.name ?? '');
    final relationController =
        TextEditingController(text: contact?.relation ?? '');
    final phoneController = TextEditingController(text: contact?.phone ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            isEditing
                ? localizations.translate('edit_emergency_contact')
                : localizations.translate('add_emergency_contact'),
            style: TextStyle(color: colors.primary300)),
        backgroundColor: colors.bg100,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: localizations.translate('name'),
                labelStyle: TextStyle(color: colors.text200),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: colors.bg300)),
              ),
              style: TextStyle(color: colors.text100),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: relationController,
              decoration: InputDecoration(
                labelText: localizations.translate('relationship'),
                labelStyle: TextStyle(color: colors.text200),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: colors.bg300)),
              ),
              style: TextStyle(color: colors.text100),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(
                labelText: localizations.translate('phone_number'),
                labelStyle: TextStyle(color: colors.text200),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: colors.bg300)),
              ),
              keyboardType: TextInputType.phone,
              style: TextStyle(color: colors.text100),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.translate('cancel'),
                style: TextStyle(color: colors.text200)),
          ),
          ElevatedButton(
            onPressed: () {
              if (_validateContactInputs(
                  nameController.text,
                  relationController.text,
                  phoneController.text,
                  colors,
                  localizations)) {
                setState(() {
                  final newContact = EmergencyContact(
                    name: nameController.text.trim(),
                    relation: relationController.text.trim(),
                    phone: phoneController.text.trim(),
                  );
                  if (isEditing) {
                    _emergencyContacts[index!] = newContact;
                  } else {
                    _emergencyContacts.add(newContact);
                  }
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: colors.accent200,
                foregroundColor: colors.bg100),
            child: Text(localizations.translate('save')),
          ),
        ],
      ),
    );
  }

  /// Deletes a contact at the specified index
  void _deleteContact(int index) {
    setState(() {
      _emergencyContacts.removeAt(index);
    });
  }

  /// Builds a card for when no emergency contact is added
  Widget _buildEmptyContactCard(
          AppColorTheme colors, AppLocalizations localizations) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.bg100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.bg300.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.contact_phone_outlined, color: colors.text200, size: 48),
            const SizedBox(height: 12),
            Text(
              localizations.translate('no_emergency_contacts'),
              style: TextStyle(
                  color: colors.primary300,
                  fontSize: 16,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              localizations.translate('add_contacts_help'),
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.text200),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showAddContactDialog(colors, localizations),
              style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accent200,
                  foregroundColor: colors.bg100),
              child: Text(localizations.translate('add_contact')),
            ),
          ],
        ),
      );

  /// Validates the emergency contact inputs
  bool _validateContactInputs(String name, String relation, String phone,
      AppColorTheme colors, AppLocalizations localizations) {
    if (name.trim().isEmpty ||
        relation.trim().isEmpty ||
        phone.trim().isEmpty) {
      _showErrorSnackBar(
          context, localizations.translate('all_fields_required'));
      return false;
    }
    if (phone.trim().length < 8) {
      _showErrorSnackBar(
          context, localizations.translate('invalid_phone_number'));
      return false;
    }
    return true;
  }

  Widget _buildSubmitButton(
          AppColorTheme colors, AppLocalizations localizations) =>
      ElevatedButton(
        onPressed:
            _isFormValid() && !_isLoading ? () => _submit(context) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.accent200,
          minimumSize: const Size(double.infinity, 56),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          disabledBackgroundColor: colors.accent200.withOpacity(0.5),
        ),
        child: Text(
          localizations.translate('create_account'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      );

  /// Builds the sign-in link for existing users.
  Widget _buildSignInLink(
          AppColorTheme colors, AppLocalizations localizations) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: _spacingLarge),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              localizations.translate('already_have_account'),
              style: TextStyle(color: colors.text200),
            ),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Text(
                localizations.translate('sign_in'),
                style: TextStyle(
                    color: colors.accent200, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );

  /// Builds a generic text field with label and validation.
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
          _buildFieldLabel(label, colors, isRequired: isRequired),
          const SizedBox(height: _spacingSmall),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: _buildTextFieldDecoration(hint, colors),
            validator: validator ??
                (isRequired
                    ? (value) => value!.isEmpty ? '$label is required' : null
                    : null),
          ),
        ],
      );

  /// Builds a password field with visibility toggle.
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
          _buildFieldLabel(label, colors, isRequired: true),
          const SizedBox(height: _spacingSmall),
          TextFormField(
            controller: controller,
            obscureText: !isVisible,
            decoration: _buildTextFieldDecoration(hint, colors).copyWith(
                suffixIcon: _buildVisibilityToggle(
                    colors, isVisible, toggleVisibility)),
            validator: (value) => value!.isEmpty ? '$label is required' : null,
          ),
        ],
      );

  /// Builds the visibility toggle icon for password fields.
  Widget _buildVisibilityToggle(AppColorTheme colors, bool isVisible,
          VoidCallback toggleVisibility) =>
      IconButton(
        icon: Icon(isVisible ? Icons.visibility_off : Icons.visibility,
            color: colors.text200),
        onPressed: toggleVisibility,
      );

  /// Builds a field label with an optional required indicator.
  Widget _buildFieldLabel(String text, AppColorTheme colors,
          {bool isRequired = false}) =>
      RichText(
        text: TextSpan(
          text: text,
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w500, color: colors.text200),
          children: isRequired
              ? [TextSpan(text: ' *', style: TextStyle(color: colors.warning))]
              : null,
        ),
      );

  /// Builds the text field decoration.
  InputDecoration _buildTextFieldDecoration(
          String hint, AppColorTheme colors) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: colors.text200.withOpacity(0.5)),
        filled: true,
        fillColor: colors.bg100,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.all(16),
      );

  /// Builds a password requirement indicator.
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
                  fontSize: 14, color: isMet ? Colors.green : colors.warning),
            ),
          ],
        ),
      );

  /// Builds the loading overlay for async operations.
  Widget _buildLoadingOverlay(AppColorTheme colors) => Container(
        color: Colors.black.withOpacity(0.5),
        child: const Center(child: CircularProgressIndicator()),
      );

  /// Validates the form data.
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

  /// Handles the registration submission process.
  Future<void> _submit(BuildContext context) async {
    final localizations = AppLocalizations.of(context);
    final userService =
        Provider.of<UserInformationService>(context, listen: false);

    if (!_formKey.currentState!.validate() || !_isFormValid()) return;

    setState(() => _isLoading = true);
    try {
      final userData = UserRegistrationData(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phoneNumber: _phoneNumberController.text.trim(),
        emergencyContacts: _emergencyContacts,
        role: 'normal',
      );

      debugPrint('Registering user with email: ${userData.email}');
      final credential = await userService.registerUser(
        firstName: userData.firstName,
        lastName: userData.lastName,
        email: userData.email,
        password: userData.password,
        phoneNumber: userData.phoneNumber,
        emergencyContacts: userData.emergencyContacts,
        role: userData.role,
      );
      debugPrint('User created with UID: ${credential.user?.uid}');

      if (mounted) {
        _showSuccessSnackBar(
            context, localizations.translate('account_created_successfully'));
        _navigateTo(context, const LoginScreen(), replace: true);
      }
    } catch (e) {
      _showErrorSnackBar(context, _mapErrorToMessage(e, localizations));
      debugPrint('Registration error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Shows a success snackbar with a message.
  void _showSuccessSnackBar(BuildContext context, String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
    }
  }

  /// Maps FirebaseAuthException codes to user-friendly messages.
  String _mapErrorToMessage(dynamic e, AppLocalizations localizations) {
    if (e is FirebaseAuthException) {
      const errorMap = {
        'email-already-in-use': 'email_already_registered',
        'invalid-email': 'invalid_email_address',
        'weak-password': 'password_too_weak',
        'operation-not-allowed': 'email_password_not_enabled',
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

  /// Navigates to a new screen, optionally replacing the current one.
  void _navigateTo(BuildContext context, Widget screen,
      {bool replace = false}) {
    final route = MaterialPageRoute(builder: (_) => screen);
    if (replace) {
      Navigator.pushReplacement(context, route);
    } else {
      Navigator.push(context, route);
    }
  }

  /// Shows an error snackbar with a message.
  void _showErrorSnackBar(BuildContext context, String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }
}
