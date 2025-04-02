import 'package:flutter/material.dart';
import 'package:mydpar/services/bottom_nav_service.dart';
import 'package:provider/provider.dart';
import 'package:mydpar/screens/account/login_screen.dart';
import 'package:mydpar/services/user_information_service.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mydpar/services/language_service.dart';
import 'package:mydpar/localization/app_localizations.dart';

// Model for settings items
class SettingItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const SettingItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const double _padding = 16.0;
  static const double _spacingSmall = 8.0;
  static const double _spacingMedium = 12.0;
  static const double _spacingLarge = 24.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NavigationService>(context, listen: false).changeIndex(3);
      // Ensure user data is initialized
      Provider.of<UserInformationService>(context, listen: false)
          .initializeUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.currentTheme;
    final userInformation = Provider.of<UserInformationService>(context);
    final languageService = Provider.of<LanguageService>(context);

    return Scaffold(
      backgroundColor: colors.bg200,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(themeProvider, colors, languageService),
                _buildContent(userInformation, colors),
              ],
            ),
            if (userInformation.isLoading)
              _buildLoadingOverlay(colors), // Use service's loading state
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeProvider themeProvider, AppColorTheme colors,
          LanguageService languageService) =>
      Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: _padding, vertical: _spacingSmall),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
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
                      (Set<MaterialState> states) {
                        return Icon(
                          themeProvider.isDarkMode
                              ? Icons.dark_mode
                              : Icons.light_mode,
                          size: 16,
                          color: themeProvider.isDarkMode
                              ? colors.bg100
                              : Colors.white,
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
                          Text('EN',
                              style: TextStyle(
                                  color: colors.text100,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(width: 8),
                          Text('English',
                              style: TextStyle(color: colors.text200)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: LanguageService.malay,
                      child: Row(
                        children: [
                          Text('BM',
                              style: TextStyle(
                                  color: colors.text100,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(width: 8),
                          Text('Bahasa Melayu',
                              style: TextStyle(color: colors.text200)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: LanguageService.mandarin,
                      child: Row(
                        children: [
                          Text('ZH',
                              style: TextStyle(
                                  color: colors.text100,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(width: 8),
                          Text('中文', style: TextStyle(color: colors.text200)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: languageService.changeLanguage,
                  child: Container(
                    height: 32,
                    width: 48,
                    decoration: BoxDecoration(
                      color: colors.accent200.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: colors.accent200.withOpacity(0.3)),
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
                ),
              ],
            ),
            IconButton(
              icon: Icon(Icons.settings, color: colors.primary300),
              onPressed: () => _navigateTo(const Placeholder()),
              tooltip: AppLocalizations.of(context).translate('settings'),
            ),
          ],
        ),
      );

  Widget _buildContent(
          UserInformationService userInformation, AppColorTheme colors) =>
      Expanded(
        child: RefreshIndicator(
          onRefresh: userInformation.refreshUserData,
          color: colors.accent200,
          backgroundColor: colors.bg100,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(_padding),
            child: Column(
              children: [
                _buildProfileHeader(userInformation, colors),
                const SizedBox(height: _spacingLarge * 2),
                _buildEmergencyContactsSection(userInformation, colors),
                const SizedBox(height: _spacingLarge * 2),
                _buildSettingsSection(colors),
              ],
            ),
          ),
        ),
      );

  Widget _buildProfileHeader(
          UserInformationService userInformation, AppColorTheme colors) =>
      Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: colors.primary100,
                backgroundImage: userInformation.photoUrl != null
                    ? NetworkImage(userInformation.photoUrl!)
                    : null,
                child: userInformation.photoUrl == null
                    ? Icon(Icons.person_outline,
                        size: 48, color: colors.accent200)
                    : null,
              ),
              CircleAvatar(
                radius: 18,
                backgroundColor: colors.accent200,
                child: IconButton(
                  icon: Icon(Icons.edit, size: 18, color: colors.bg100),
                  onPressed: () =>
                      _showPhotoEditDialog(userInformation, colors),
                  padding: EdgeInsets.zero,
                  tooltip: AppLocalizations.of(context)
                      .translate('edit_profile_photo'),
                ),
              ),
            ],
          ),
          const SizedBox(height: _spacingLarge),
          Text(
            '${userInformation.firstName ?? ''} ${userInformation.lastName ?? 'User'}',
            style: TextStyle(
                color: colors.primary300,
                fontSize: 24,
                fontWeight: FontWeight.bold),
          ),
          Text(
            userInformation.email ??
                AppLocalizations.of(context).translate('loading'),
            style: TextStyle(color: colors.text200),
          ),
          Text(
            userInformation.phoneNumber ??
                AppLocalizations.of(context).translate('loading'),
            style: TextStyle(color: colors.text200),
          ),
        ],
      );

  Widget _buildEmergencyContactsSection(
          UserInformationService userInformation, AppColorTheme colors) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context).translate('emergency_contacts'),
                style: TextStyle(
                    color: colors.primary300,
                    fontSize: 18,
                    fontWeight: FontWeight.w600),
              ),
              IconButton(
                icon: Icon(Icons.add, color: colors.accent200),
                onPressed: () => _showAddContactDialog(userInformation, colors),
                tooltip: AppLocalizations.of(context).translate('add_contact'),
              ),
            ],
          ),
          const SizedBox(height: _spacingMedium),
          userInformation.contacts.isEmpty
              ? _buildEmptyContactsCard(colors)
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: userInformation.contacts.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: _spacingMedium),
                    child: _buildEmergencyContact(
                        userInformation.contacts[index],
                        index,
                        userInformation,
                        colors),
                  ),
                ),
        ],
      );

  Widget _buildEmptyContactsCard(AppColorTheme colors) => Container(
        padding: const EdgeInsets.all(_padding),
        decoration: _cardDecoration(colors),
        child: Column(
          children: [
            Icon(Icons.contact_phone_outlined, color: colors.text200, size: 48),
            const SizedBox(height: _spacingMedium),
            Text(
              AppLocalizations.of(context).translate('no_emergency_contacts'),
              style: TextStyle(
                  color: colors.primary300,
                  fontSize: 16,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: _spacingSmall),
            Text(
              AppLocalizations.of(context).translate('add_contacts_help'),
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.text200),
            ),
            const SizedBox(height: _spacingMedium),
            ElevatedButton(
              onPressed: () => _showAddContactDialog(
                  Provider.of<UserInformationService>(context, listen: false),
                  colors),
              style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accent200,
                  foregroundColor: colors.bg100),
              child:
                  Text(AppLocalizations.of(context).translate('add_contact')),
            ),
          ],
        ),
      );

  Widget _buildEmergencyContact(EmergencyContact contact, int index,
          UserInformationService userInformation, AppColorTheme colors) =>
      Container(
        decoration: _cardDecoration(colors),
        padding: const EdgeInsets.all(_padding),
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
                  icon: Icon(Icons.phone, color: colors.accent200),
                  onPressed: () => _launchPhoneCall(contact.phone, colors),
                  tooltip: AppLocalizations.of(context)
                      .translate('call_contact', {'name': contact.name}),
                ),
                IconButton(
                  icon: Icon(Icons.edit, color: colors.accent200),
                  onPressed: () => _showEditContactDialog(
                      contact, index, userInformation, colors),
                  tooltip: AppLocalizations.of(context)
                      .translate('edit_contact', {'name': contact.name}),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildSettingsSection(AppColorTheme colors) {
    final settings = [
      SettingItem(
        icon: Icons.shield_outlined,
        title: AppLocalizations.of(context).translate('privacy'),
        onTap: () => _navigateTo(const Placeholder()),
      ),
      SettingItem(
        icon: Icons.help_outline,
        title: AppLocalizations.of(context).translate('help_support'),
        onTap: () => _navigateTo(const Placeholder()),
      ),
      SettingItem(
        icon: Icons.logout,
        title: AppLocalizations.of(context).translate('logout'),
        onTap: () => _showLogoutDialog(colors),
      ),
    ];

    return Column(
      children: settings
          .map((setting) => Padding(
                padding: const EdgeInsets.only(bottom: _spacingMedium),
                child: _buildSettingItem(setting, colors),
              ))
          .toList(),
    );
  }

  Widget _buildSettingItem(SettingItem setting, AppColorTheme colors) =>
      GestureDetector(
        onTap: setting.onTap,
        child: Container(
          decoration: _cardDecoration(colors),
          padding: const EdgeInsets.all(_padding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(setting.icon, color: colors.accent200),
                  const SizedBox(width: _spacingMedium),
                  Text(
                    setting.title,
                    style: TextStyle(color: colors.primary300),
                  ),
                ],
              ),
              Icon(Icons.chevron_right, color: colors.text200),
            ],
          ),
        ),
      );

  Future<void> _launchPhoneCall(String phone, AppColorTheme colors) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final phoneUri = Uri(scheme: 'tel', path: cleanPhone);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        _showSnackBar(AppLocalizations.of(context).translate('call_failed'),
            colors.warning);
      }
    } catch (e) {
      _showSnackBar(
          AppLocalizations.of(context)
              .translate('call_error', {'phone': phone, 'error': e.toString()}),
          colors.warning);
    }
  }

  Future<void> _pickImage(ImageSource source,
      UserInformationService userInformation, AppColorTheme colors) async {
    final status = await Permission.photos.request();

    if (status.isGranted) {
      try {
        final picker = ImagePicker();
        final pickedFile = await picker.pickImage(
          source: source,
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 85,
        );

        if (pickedFile == null) return;

        if (mounted) {
          _showLoadingDialog(colors, 'uploading_photo');
        }

        await userInformation.updateProfilePhoto(pickedFile.path);
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          _showSnackBar(
              AppLocalizations.of(context).translate('profile_photo_updated'),
              colors.accent200);
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context);
          _showSnackBar(
              AppLocalizations.of(context)
                  .translate('photo_update_failed', {'error': e.toString()}),
              colors.warning);
        }
      }
    } else if (status.isDenied || status.isPermanentlyDenied) {
      if (mounted) {
        _showSnackBar(
            AppLocalizations.of(context).translate('permission_denied'),
            colors.warning);
      }
    }
  }

  void _showPhotoEditDialog(
      UserInformationService userInformation, AppColorTheme colors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            AppLocalizations.of(context).translate('change_profile_photo'),
            style: TextStyle(color: colors.primary300)),
        backgroundColor: colors.bg100,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_library, color: colors.accent200),
              title: Text(
                  AppLocalizations.of(context).translate('choose_gallery'),
                  style: TextStyle(color: colors.text100)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery, userInformation, colors);
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt, color: colors.accent200),
              title: Text(AppLocalizations.of(context).translate('take_photo'),
                  style: TextStyle(color: colors.text100)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera, userInformation, colors);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddContactDialog(
      UserInformationService userInformation, AppColorTheme colors) {
    final nameController = TextEditingController();
    final relationController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            AppLocalizations.of(context).translate('add_emergency_contact'),
            style: TextStyle(color: colors.primary300)),
        backgroundColor: colors.bg100,
        content: _buildContactForm(
            colors, nameController, relationController, phoneController),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).translate('cancel'),
                style: TextStyle(color: colors.text200)),
          ),
          ElevatedButton(
            onPressed: () => _addContact(userInformation, nameController,
                relationController, phoneController, colors),
            style: ElevatedButton.styleFrom(
                backgroundColor: colors.accent200,
                foregroundColor: colors.bg100),
            child: Text(AppLocalizations.of(context).translate('add')),
          ),
        ],
      ),
    );
  }

  Future<void> _addContact(
    UserInformationService userInformation,
    TextEditingController nameController,
    TextEditingController relationController,
    TextEditingController phoneController,
    AppColorTheme colors,
  ) async {
    if (!_validateInputs(
        nameController, relationController, phoneController, colors)) return;

    final contact = EmergencyContact(
      name: nameController.text.trim(),
      relation: relationController.text.trim(),
      phone: phoneController.text.trim(),
    );

    try {
      await userInformation.addEmergencyContact(contact);
      if (mounted) {
        Navigator.pop(context);
        _showSnackBar(AppLocalizations.of(context).translate('contact_added'),
            colors.accent200);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
            AppLocalizations.of(context)
                .translate('contact_add_failed', {'error': e.toString()}),
            colors.warning);
      }
    }
  }

  void _showEditContactDialog(EmergencyContact contact, int index,
      UserInformationService userInformation, AppColorTheme colors) {
    final nameController = TextEditingController(text: contact.name);
    final relationController = TextEditingController(text: contact.relation);
    final phoneController = TextEditingController(text: contact.phone);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            AppLocalizations.of(context).translate('edit_emergency_contact'),
            style: TextStyle(color: colors.primary300)),
        backgroundColor: colors.bg100,
        content: _buildContactForm(
            colors, nameController, relationController, phoneController),
        actions: [
          TextButton(
            onPressed: () => _showDeleteConfirmationDialog(
                contact, index, userInformation, colors),
            child: Text(AppLocalizations.of(context).translate('delete'),
                style: TextStyle(color: colors.warning)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).translate('cancel'),
                style: TextStyle(color: colors.text200)),
          ),
          ElevatedButton(
            onPressed: () => _updateContact(userInformation, nameController,
                relationController, phoneController, index, colors),
            style: ElevatedButton.styleFrom(
                backgroundColor: colors.accent200,
                foregroundColor: colors.bg100),
            child: Text(AppLocalizations.of(context).translate('save')),
          ),
        ],
      ),
    );
  }

  Future<void> _updateContact(
    UserInformationService userInformation,
    TextEditingController nameController,
    TextEditingController relationController,
    TextEditingController phoneController,
    int index,
    AppColorTheme colors,
  ) async {
    if (!_validateInputs(
        nameController, relationController, phoneController, colors)) return;

    final updatedContact = EmergencyContact(
      name: nameController.text.trim(),
      relation: relationController.text.trim(),
      phone: phoneController.text.trim(),
    );

    try {
      await userInformation.updateEmergencyContact(index, updatedContact);
      if (mounted) {
        Navigator.pop(context);
        _showSnackBar(AppLocalizations.of(context).translate('contact_updated'),
            colors.accent200);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
            AppLocalizations.of(context)
                .translate('contact_update_failed', {'error': e.toString()}),
            colors.warning);
      }
    }
  }

  void _showDeleteConfirmationDialog(EmergencyContact contact, int index,
      UserInformationService userInformation, AppColorTheme colors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).translate('delete_contact'),
            style: TextStyle(color: colors.primary300)),
        backgroundColor: colors.bg100,
        content: Text(
          AppLocalizations.of(context)
              .translate('delete_contact_confirmation', {'name': contact.name}),
          style: TextStyle(color: colors.text200),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).translate('cancel'),
                style: TextStyle(color: colors.text200)),
          ),
          ElevatedButton(
            onPressed: () => _deleteContact(index, userInformation, colors),
            style: ElevatedButton.styleFrom(
                backgroundColor: colors.warning, foregroundColor: colors.bg100),
            child: Text(AppLocalizations.of(context).translate('delete')),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteContact(int index, UserInformationService userInformation,
      AppColorTheme colors) async {
    try {
      await userInformation.deleteEmergencyContact(index);
      if (mounted) {
        Navigator.pop(context); // Close confirmation dialog
        Navigator.pop(context); // Close edit dialog
        _showSnackBar(AppLocalizations.of(context).translate('contact_deleted'),
            colors.accent200);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
            AppLocalizations.of(context)
                .translate('contact_delete_failed', {'error': e.toString()}),
            colors.warning);
      }
    }
  }

  void _showLogoutDialog(AppColorTheme colors) {
    final userInformation =
        Provider.of<UserInformationService>(context, listen: false);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context).translate('confirm_logout'),
            style: TextStyle(color: colors.primary300)),
        backgroundColor: colors.bg100,
        content: Text(
            AppLocalizations.of(context).translate('logout_confirmation'),
            style: TextStyle(color: colors.text200)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(context).translate('cancel'),
                style: TextStyle(color: colors.text200)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await userInformation.logout();
                if (mounted) {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  _showSnackBar(
                    AppLocalizations.of(context)
                        .translate('logout_failed', {'error': e.toString()}),
                    colors.warning,
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: colors.warning, foregroundColor: colors.bg100),
            child: Text(AppLocalizations.of(context).translate('logout')),
          ),
        ],
      ),
    );
  }

  Widget _buildContactForm(
    AppColorTheme colors,
    TextEditingController nameController,
    TextEditingController relationController,
    TextEditingController phoneController,
  ) =>
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).translate('name'),
              labelStyle: TextStyle(color: colors.text200),
              enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: colors.bg300)),
            ),
            style: TextStyle(color: colors.text100),
          ),
          const SizedBox(height: _spacingSmall),
          TextField(
            controller: relationController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).translate('relationship'),
              labelStyle: TextStyle(color: colors.text200),
              enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: colors.bg300)),
            ),
            style: TextStyle(color: colors.text100),
          ),
          const SizedBox(height: _spacingSmall),
          TextField(
            controller: phoneController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).translate('phone_number'),
              labelStyle: TextStyle(color: colors.text200),
              enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: colors.bg300)),
            ),
            keyboardType: TextInputType.phone,
            style: TextStyle(color: colors.text100),
          ),
        ],
      );

  bool _validateInputs(
    TextEditingController nameController,
    TextEditingController relationController,
    TextEditingController phoneController,
    AppColorTheme colors,
  ) {
    if (nameController.text.trim().isEmpty ||
        relationController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty) {
      _showSnackBar(
          AppLocalizations.of(context).translate('all_fields_required'),
          colors.warning);
      return false;
    }
    return true;
  }

  void _showLoadingDialog(AppColorTheme colors, String messageKey) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: colors.bg100,
        content: Row(
          children: [
            CircularProgressIndicator(color: colors.accent200),
            const SizedBox(width: 20),
            Text(AppLocalizations.of(context).translate(messageKey),
                style: TextStyle(color: colors.text100)),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay(AppColorTheme colors) => Container(
        color: Colors.black.withOpacity(0.5),
        child: const Center(child: CircularProgressIndicator()),
      );

  void _showSnackBar(String message, Color backgroundColor) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(_padding),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _navigateTo(Widget screen, {bool replace = false}) {
    if (replace) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => screen),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => screen),
      );
    }
  }

  BoxDecoration _cardDecoration(AppColorTheme colors, {double opacity = 0.7}) =>
      BoxDecoration(
        color: colors.bg100.withOpacity(opacity),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.bg300.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );
}
