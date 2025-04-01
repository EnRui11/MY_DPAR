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

// Model for emergency contact data
class EmergencyContact {
  final String name;
  final String relation;
  final String phone;

  const EmergencyContact({
    required this.name,
    required this.relation,
    required this.phone,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) =>
      EmergencyContact(
        name: json['name'] as String? ?? 'Unknown',
        relation: json['relation'] as String? ?? 'Not specified',
        phone: json['phone'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'relation': relation,
        'phone': phone,
      };
}

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
    // Set current index in navigation service
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NavigationService>(context, listen: false).changeIndex(3);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final AppColorTheme colors = themeProvider.currentTheme;
    final userInfomation = Provider.of<UserInformationService>(context);

    return Scaffold(
      backgroundColor: colors.bg200,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(themeProvider, colors),
                _buildContent(userInfomation, colors),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the header with theme toggle and settings icon.
  Widget _buildHeader(ThemeProvider themeProvider, AppColorTheme colors) =>
      Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: _padding, vertical: _spacingSmall),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                      size: 16,
                      color: themeProvider.isDarkMode ? colors.bg100 : Colors.white,
                    );
                  },
                ),
                trackOutlineColor: MaterialStateProperty.resolveWith(
                  (states) => themeProvider.isDarkMode ? colors.bg300.withOpacity(0.2) : Colors.transparent,
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.settings, color: colors.primary300),
              onPressed: () =>
                  _navigateTo(const Placeholder()), // Placeholder for settings
              tooltip: 'Settings',
            ),
          ],
        ),
      );

  /// Builds the scrollable content area with refresh functionality.
  Widget _buildContent(
          UserInformationService userInfomation, AppColorTheme colors) =>
      Expanded(
        child: RefreshIndicator(
          onRefresh: userInfomation.refreshUserData,
          color: colors.accent200,
          backgroundColor: colors.bg100,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(_padding),
            child: Column(
              children: [
                _buildProfileHeader(userInfomation, colors),
                const SizedBox(height: _spacingLarge * 2),
                _buildEmergencyContactsSection(userInfomation, colors),
                const SizedBox(height: _spacingLarge * 2),
                _buildSettingsSection(colors),
              ],
            ),
          ),
        ),
      );

  /// Builds the profile header with avatar, name, and email.
  Widget _buildProfileHeader(
          UserInformationService userInfomation, AppColorTheme colors) =>
      Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: colors.primary100,
                backgroundImage: userInfomation.photoUrl != null
                    ? NetworkImage(userInfomation.photoUrl!)
                    : null,
                child: userInfomation.photoUrl == null
                    ? Icon(Icons.person_outline,
                        size: 48, color: colors.accent200)
                    : null,
              ),
              CircleAvatar(
                radius: 18,
                backgroundColor: colors.accent200,
                child: IconButton(
                  icon: Icon(Icons.edit, size: 18, color: colors.bg100),
                  onPressed: () => _showPhotoEditDialog(userInfomation, colors),
                  padding: EdgeInsets.zero,
                  tooltip: 'Edit profile photo',
                ),
              ),
            ],
          ),
          const SizedBox(height: _spacingLarge),
          Text(
            userInfomation.lastName ?? 'Loading...',
            style: TextStyle(
                color: colors.primary300,
                fontSize: 24,
                fontWeight: FontWeight.bold),
          ),
          Text(
            userInfomation.email ?? 'Loading...',
            style: TextStyle(color: colors.text200),
          ),
          Text(
            userInfomation.phoneNumber ?? 'Loading...',
            style: TextStyle(color: colors.text200),
          ),
        ],
      );

  /// Builds the emergency contacts section.
  Widget _buildEmergencyContactsSection(
          UserInformationService userInfomation, AppColorTheme colors) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Emergency Contacts',
                style: TextStyle(
                    color: colors.primary300,
                    fontSize: 18,
                    fontWeight: FontWeight.w600),
              ),
              IconButton(
                icon: Icon(Icons.add, color: colors.accent200),
                onPressed: () => _showAddContactDialog(userInfomation, colors),
                tooltip: 'Add contact',
              ),
            ],
          ),
          const SizedBox(height: _spacingMedium),
          userInfomation.contacts.isEmpty
              ? _buildEmptyContactsCard(colors)
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: userInfomation.contacts.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: _spacingMedium),
                    child: _buildEmergencyContact(
                        userInfomation.contacts[index],
                        index,
                        userInfomation,
                        colors),
                  ),
                ),
        ],
      );

  /// Builds a card for when no contacts are available.
  Widget _buildEmptyContactsCard(AppColorTheme colors) => Container(
        padding: const EdgeInsets.all(_padding),
        decoration: _cardDecoration(colors),
        child: Column(
          children: [
            Icon(Icons.contact_phone_outlined, color: colors.text200, size: 48),
            const SizedBox(height: _spacingMedium),
            Text(
              'No Emergency Contacts',
              style: TextStyle(
                  color: colors.primary300,
                  fontSize: 16,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: _spacingSmall),
            Text(
              'Add contacts for quick help during emergencies',
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
              child: const Text('Add Contact'),
            ),
          ],
        ),
      );

  /// Builds an individual emergency contact card.
  Widget _buildEmergencyContact(EmergencyContact contact, int index,
          UserInformationService userInfomation, AppColorTheme colors) =>
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
                  tooltip: 'Call ${contact.name}',
                ),
                IconButton(
                  icon: Icon(Icons.edit, color: colors.accent200),
                  onPressed: () => _showEditContactDialog(
                      contact, index, userInfomation, colors),
                  tooltip: 'Edit ${contact.name}',
                ),
              ],
            ),
          ],
        ),
      );

  /// Builds the settings section.
  Widget _buildSettingsSection(AppColorTheme colors) {
    final settings = [
      SettingItem(
        icon: Icons.shield_outlined,
        title: 'Privacy',
        onTap: () => _navigateTo(const Placeholder()),
      ),
      SettingItem(
        icon: Icons.help_outline,
        title: 'Help & Support',
        onTap: () => _navigateTo(const Placeholder()),
      ),
      SettingItem(
        icon: Icons.logout,
        title: 'Logout',
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

  /// Builds an individual setting item.
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

  /// Launches a phone call with error handling.
  Future<void> _launchPhoneCall(String phone, AppColorTheme colors) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final phoneUri = Uri(scheme: 'tel', path: cleanPhone);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        _showSnackBar('Could not launch phone call', colors.warning);
      }
    } catch (e) {
      _showSnackBar('Error calling $phone: $e', colors.warning);
    }
  }

  /// Requests permission and picks an image, then updates via userInfomation.
  Future<void> _pickImage(ImageSource source,
      UserInformationService userInfomation, AppColorTheme colors) async {
    final permission =
        source == ImageSource.camera ? Permission.camera : Permission.photos;
    final status = await permission.request();

    if (status.isGranted) {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null && mounted) {
        _showLoadingDialog(colors, 'Uploading photo...');
        try {
          await userInfomation.updateProfilePhoto(pickedFile.path);
          if (mounted) {
            Navigator.pop(context); // Close loading dialog
            _showSnackBar('Profile photo updated', colors.accent200);
          }
        } catch (e) {
          if (mounted) {
            Navigator.pop(context);
            _showSnackBar('Failed to update photo: $e', colors.warning);
          }
        }
      }
    } else if (status.isDenied || status.isPermanentlyDenied) {
      if (mounted) {
        _showSnackBar(
            'Permission denied. Enable it in settings.', colors.warning);
      }
    }
  }

  /// Shows a dialog to edit the profile photo.
  void _showPhotoEditDialog(
      UserInformationService userInfomation, AppColorTheme colors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change Profile Photo',
            style: TextStyle(color: colors.primary300)),
        backgroundColor: colors.bg100,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_library, color: colors.accent200),
              title: Text('Choose from Gallery',
                  style: TextStyle(color: colors.text100)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery, userInfomation, colors);
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt, color: colors.accent200),
              title:
                  Text('Take a Photo', style: TextStyle(color: colors.text100)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera, userInfomation, colors);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Shows a dialog to add a new emergency contact.
  void _showAddContactDialog(
      UserInformationService userInfomation, AppColorTheme colors) {
    final nameController = TextEditingController();
    final relationController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Emergency Contact',
            style: TextStyle(color: colors.primary300)),
        backgroundColor: colors.bg100,
        content: _buildContactForm(
            colors, nameController, relationController, phoneController),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: colors.text200)),
          ),
          ElevatedButton(
            onPressed: () => _addContact(userInfomation, nameController,
                relationController, phoneController, colors),
            style: ElevatedButton.styleFrom(
                backgroundColor: colors.accent200,
                foregroundColor: colors.bg100),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  /// Adds a new contact via userInfomation.
  Future<void> _addContact(
    UserInformationService userInfomation,
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
      await userInfomation.addEmergencyContact(contact);
      if (mounted) {
        Navigator.pop(context);
        _showSnackBar('Contact added', colors.accent200);
      }
    } catch (e) {
      _showSnackBar('Error adding contact: $e', colors.warning);
    }
  }

  /// Shows a dialog to edit an existing emergency contact.
  void _showEditContactDialog(EmergencyContact contact, int index,
      UserInformationService userInfomation, AppColorTheme colors) {
    final nameController = TextEditingController(text: contact.name);
    final relationController = TextEditingController(text: contact.relation);
    final phoneController = TextEditingController(text: contact.phone);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Emergency Contact',
            style: TextStyle(color: colors.primary300)),
        backgroundColor: colors.bg100,
        content: _buildContactForm(
            colors, nameController, relationController, phoneController),
        actions: [
          TextButton(
            onPressed: () => _showDeleteConfirmationDialog(
                contact, index, userInfomation, colors),
            child: Text('Delete', style: TextStyle(color: colors.warning)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: colors.text200)),
          ),
          ElevatedButton(
            onPressed: () => _updateContact(userInfomation, nameController,
                relationController, phoneController, index, colors),
            style: ElevatedButton.styleFrom(
                backgroundColor: colors.accent200,
                foregroundColor: colors.bg100),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  /// Updates an existing contact via userInfomation.
  Future<void> _updateContact(
    UserInformationService userInfomation,
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
      await userInfomation.updateEmergencyContact(index, updatedContact);
      if (mounted) {
        Navigator.pop(context);
        _showSnackBar('Contact updated', colors.accent200);
      }
    } catch (e) {
      _showSnackBar('Error updating contact: $e', colors.warning);
    }
  }

  /// Shows a confirmation dialog to delete a contact.
  void _showDeleteConfirmationDialog(EmergencyContact contact, int index,
      UserInformationService userInfomation, AppColorTheme colors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:
            Text('Delete Contact', style: TextStyle(color: colors.primary300)),
        backgroundColor: colors.bg100,
        content: Text(
          'Are you sure you want to delete ${contact.name}?',
          style: TextStyle(color: colors.text200),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: colors.text200)),
          ),
          ElevatedButton(
            onPressed: () => _deleteContact(index, userInfomation, colors),
            style: ElevatedButton.styleFrom(
                backgroundColor: colors.warning, foregroundColor: colors.bg100),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Deletes a contact via userInfomation.
  Future<void> _deleteContact(int index, UserInformationService userInfomation,
      AppColorTheme colors) async {
    try {
      await userInfomation.deleteEmergencyContact(index);
      if (mounted) {
        Navigator.pop(context); // Close confirmation dialog
        Navigator.pop(context); // Close edit dialog
        _showSnackBar('Contact deleted', colors.accent200);
      }
    } catch (e) {
      _showSnackBar('Error deleting contact: $e', colors.warning);
    }
  }

  /// Shows a logout confirmation dialog.
  void _showLogoutDialog(AppColorTheme colors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:
            Text('Confirm Logout', style: TextStyle(color: colors.primary300)),
        backgroundColor: colors.bg100,
        content: Text('Are you sure you want to logout?',
            style: TextStyle(color: colors.text200)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: colors.text200)),
          ),
          ElevatedButton(
            onPressed: () async {
              await Provider.of<UserInformationService>(context, listen: false)
                  .logout();
              if (mounted) {
                Navigator.pop(context);
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()));
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: colors.warning, foregroundColor: colors.bg100),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  /// Reusable contact form widget for add/edit dialogs.
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
              labelText: 'Name',
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
              labelText: 'Relationship',
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
              labelText: 'Phone Number',
              labelStyle: TextStyle(color: colors.text200),
              enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: colors.bg300)),
            ),
            keyboardType: TextInputType.phone,
            style: TextStyle(color: colors.text100),
          ),
        ],
      );

  /// Validates input fields and shows error if invalid.
  bool _validateInputs(
    TextEditingController nameController,
    TextEditingController relationController,
    TextEditingController phoneController,
    AppColorTheme colors,
  ) {
    if (nameController.text.trim().isEmpty ||
        relationController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty) {
      _showSnackBar('All fields are required', colors.warning);
      return false;
    }
    return true;
  }

  /// Shows a loading dialog with a custom message.
  void _showLoadingDialog(AppColorTheme colors, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: colors.bg100,
        content: Row(
          children: [
            CircularProgressIndicator(color: colors.accent200),
            const SizedBox(width: 20),
            Text(message, style: TextStyle(color: colors.text100)),
          ],
        ),
      ),
    );
  }

  /// Displays a snackbar with a custom message and color.
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

  /// Navigates to a new screen, optionally replacing the current one.
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

  /// Provides a reusable card decoration with a subtle shadow.
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
