import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mydpar/screens/main/home_screen.dart';
import 'package:mydpar/screens/main/map_screen.dart';
import 'package:mydpar/screens/main/community_screen.dart';
import 'package:mydpar/screens/account/login_screen.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

// Model for emergency contact data, Firebase-ready
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
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const double _padding = 16.0;
  static const double _spacingSmall = 8.0;
  static const double _spacingMedium = 12.0;
  static const double _spacingLarge = 24.0;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.currentTheme;

    return Scaffold(
      backgroundColor: colors.bg200,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, themeProvider, colors),
            _buildContent(context, colors),
            _buildBottomNavigation(context, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeProvider themeProvider,
      AppColorTheme colors) =>
      Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: _padding, vertical: _spacingSmall),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(
                themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                color: colors.accent200,
              ),
              onPressed: themeProvider.toggleTheme,
              tooltip: 'Toggle theme',
            ),
            IconButton(
              icon: Icon(Icons.settings, color: colors.primary300),
              onPressed: () => _navigateTo(context, const Placeholder()),
              tooltip: 'Settings',
            ),
          ],
        ),
      );

  Widget _buildContent(BuildContext context, AppColorTheme colors) => Expanded(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(_padding),
      child: Column(
        children: [
          _buildProfileHeader(colors),
          const SizedBox(height: _spacingLarge * 2),
          _buildEmergencyContactsSection(context, colors),
          const SizedBox(height: _spacingLarge * 2),
          _buildSettingsSection(context, colors),
        ],
      ),
    ),
  );

  Widget _buildProfileHeader(AppColorTheme colors) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'email@example.com';

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user?.uid)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final userData = snapshot.data?.data() as Map<String, dynamic>?;
            final lastName = userData?['lastName'] ?? 'User';
            final photoUrl = user?.photoURL;

            return Stack(
              children: [
                Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: colors.primary100,
                          backgroundImage:
                          photoUrl != null ? NetworkImage(photoUrl) : null,
                          child: photoUrl == null
                              ? Icon(Icons.person_outline,
                              size: 48, color: colors.accent200)
                              : null,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: colors.accent200,
                            child: IconButton(
                              icon: Icon(Icons.edit,
                                  size: 18, color: colors.bg100),
                              onPressed: () => _showPhotoEditDialog(colors),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: _spacingLarge),
                    Text(
                      lastName,
                      style: TextStyle(
                        color: colors.primary300,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      email,
                      style: TextStyle(color: colors.text200),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildEmergencyContactsSection(
      BuildContext context, AppColorTheme colors) {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final userData = snapshot.data?.data() as Map<String, dynamic>?;
        final emergencyContactsData =
            userData?['emergencyContacts'] as List<dynamic>? ?? [];

        final contacts = emergencyContactsData
            .map((contact) =>
            EmergencyContact.fromJson(contact as Map<String, dynamic>))
            .toList();

        return Column(
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add, color: colors.accent200),
                  onPressed: () => _showAddContactDialog(colors),
                  tooltip: 'Add contact',
                ),
              ],
            ),
            const SizedBox(height: _spacingMedium),
            if (contacts.isEmpty)
              Container(
                padding: const EdgeInsets.all(_padding),
                decoration: _cardDecoration(colors),
                child: Column(
                  children: [
                    Icon(Icons.contact_phone_outlined,
                        color: colors.text200, size: 48),
                    const SizedBox(height: _spacingMedium),
                    Text(
                      'No Emergency Contact',
                      style: TextStyle(
                        color: colors.primary300,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: _spacingSmall),
                    Text(
                      'Add emergency contact to get help quickly in case of emergency',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.text200),
                    ),
                    const SizedBox(height: _spacingMedium),
                    ElevatedButton(
                      onPressed: () => _showAddContactDialog(colors),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.accent200,
                        foregroundColor: colors.bg100,
                      ),
                      child: const Text('Add Emergency Contact'),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: contacts.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: _spacingMedium),
                  child: _buildEmergencyContact(contacts[index], index, colors),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildEmergencyContact(
      EmergencyContact contact, int index, AppColorTheme colors) =>
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
                    color: colors.primary300,
                    fontWeight: FontWeight.w500,
                  ),
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
                  onPressed: () =>
                      _showEditContactDialog(contact, index, colors),
                  tooltip: 'Edit ${contact.name}',
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildSettingsSection(BuildContext context, AppColorTheme colors) {
    final settings = [
      SettingItem(
        icon: Icons.shield_outlined,
        title: 'Privacy',
        onTap: () => _navigateTo(context, const Placeholder()),
      ),
      SettingItem(
        icon: Icons.help_outline,
        title: 'Help & Support',
        onTap: () => _navigateTo(context, const Placeholder()),
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

  void _showLogoutDialog(AppColorTheme colors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:
        Text('Confirm Logout', style: TextStyle(color: colors.primary300)),
        backgroundColor: colors.bg100,
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: colors.text200),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: colors.text200)),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.warning,
              foregroundColor: colors.bg100,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
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

  Widget _buildBottomNavigation(BuildContext context, AppColorTheme colors) =>
      Container(
        decoration: BoxDecoration(
          color: colors.bg100,
          border: Border(top: BorderSide(color: colors.bg300.withOpacity(0.2))),
        ),
        padding: const EdgeInsets.symmetric(vertical: _spacingSmall),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
                Icons.home_outlined,
                false,
                    () => _navigateTo(context, const HomeScreen(), replace: true),
                colors),
            _buildNavItem(
                Icons.map_outlined,
                false,
                    () => _navigateTo(context, const MapScreen(), replace: true),
                colors),
            _buildNavItem(Icons.people_outline, false,
                    () => _navigateTo(context, const CommunityScreen()), colors),
            _buildNavItem(Icons.person, true, () {}, colors),
          ],
        ),
      );

  Widget _buildNavItem(IconData icon, bool isActive, VoidCallback onPressed,
      AppColorTheme colors) =>
      IconButton(
        icon: Icon(icon),
        color: isActive ? colors.accent200 : colors.text200,
        onPressed: onPressed,
        tooltip: isActive ? 'Profile (current)' : null,
      );

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

  Future<void> _uploadProfilePhoto(String filePath, AppColorTheme colors) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnackBar('No user signed in', colors.warning);
        return;
      }

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: colors.bg100,
          content: Row(
            children: [
              CircularProgressIndicator(color: colors.accent200),
              const SizedBox(width: 20),
              Text('Uploading...', style: TextStyle(color: colors.text100)),
            ],
          ),
        ),
      );

      // Upload to Firebase Storage
      final ref = FirebaseStorage.instance
          .ref()
          .child('user_photos')
          .child('${user.uid}.jpg');
      final uploadTask = ref.putFile(File(filePath));

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        debugPrint(
            'Upload progress: ${(snapshot.bytesTransferred / snapshot.totalBytes) * 100}%');
      });

      final snapshot = await uploadTask;
      final photoUrl = await snapshot.ref.getDownloadURL();

      // Update Firebase Auth profile
      await user.updatePhotoURL(photoUrl);

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'photoUrl': photoUrl});

      if (mounted) {
        Navigator.pop(context); // Dismiss loading dialog
        _showSnackBar('Profile photo updated successfully', colors.accent200);
        setState(() {}); // Refresh UI
      }
    } catch (e, stackTrace) {
      debugPrint('Error uploading photo: $e\nStack trace: $stackTrace');
      if (mounted) {
        Navigator.pop(context); // Dismiss loading dialog
        _showSnackBar('Failed to update profile photo: $e', colors.warning);
      }
    }
  }

  Future<void> _requestPermissionAndPickImage(
      ImageSource source, AppColorTheme colors) async {
    PermissionStatus permissionStatus;
    if (source == ImageSource.camera) {
      permissionStatus = await Permission.camera.request();
    } else {
      permissionStatus = await Permission.photos.request();
    }

    if (permissionStatus.isGranted) {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null && mounted) {
        await _uploadProfilePhoto(pickedFile.path, colors);
      } else if (mounted) {
        _showSnackBar('No image selected', colors.warning);
      }
    } else if (permissionStatus.isDenied || permissionStatus.isPermanentlyDenied) {
      if (mounted) {
        _showSnackBar(
            'Permission denied. Please allow access in settings.', colors.warning);
      }
    }
  }

  Future<void> _showPhotoEditDialog(AppColorTheme colors) async {
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
              onTap: () async {
                Navigator.pop(context);
                await _requestPermissionAndPickImage(ImageSource.gallery, colors);
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt, color: colors.accent200),
              title: Text('Take a Photo',
                  style: TextStyle(color: colors.text100)),
              onTap: () async {
                Navigator.pop(context);
                await _requestPermissionAndPickImage(ImageSource.camera, colors);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddContactDialog(AppColorTheme colors) {
    final nameController = TextEditingController();
    final relationController = TextEditingController();
    final phoneController = TextEditingController();
    final user = FirebaseAuth.instance.currentUser;

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
            onPressed: () async {
              if (nameController.text.isEmpty ||
                  relationController.text.isEmpty ||
                  phoneController.text.isEmpty) {
                _showSnackBar('All fields are required', colors.warning);
                return;
              }

              final contact = EmergencyContact(
                name: nameController.text.trim(),
                relation: relationController.text.trim(),
                phone: phoneController.text.trim(),
              );

              final docRef =
              FirebaseFirestore.instance.collection('users').doc(user?.uid);

              final docSnapshot = await docRef.get();
              final currentContacts = List<Map<String, dynamic>>.from(
                  docSnapshot.data()?['emergencyContacts'] ?? []);

              currentContacts.add(contact.toJson());
              await docRef.update({'emergencyContacts': currentContacts});

              if (mounted) {
                Navigator.pop(context);
                _showSnackBar('Contact added', colors.accent200);
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: colors.accent200,
                foregroundColor: colors.bg100),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(
      EmergencyContact contact, int index, AppColorTheme colors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:
        Text('Delete Contact', style: TextStyle(color: colors.primary300)),
        backgroundColor: colors.bg100,
        content: Text(
          'Are you sure you want to delete ${contact.name} from your emergency contacts?',
          style: TextStyle(color: colors.text200),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: colors.text200)),
          ),
          ElevatedButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              final docRef =
              FirebaseFirestore.instance.collection('users').doc(user?.uid);

              final docSnapshot = await docRef.get();
              final currentContacts = List<Map<String, dynamic>>.from(
                  docSnapshot.data()?['emergencyContacts'] ?? []);

              currentContacts.removeAt(index);
              await docRef.update({'emergencyContacts': currentContacts});

              if (mounted) {
                Navigator.pop(context); // Close confirmation dialog
                Navigator.pop(context); // Close edit dialog
                _showSnackBar('Contact deleted', colors.accent200);
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: colors.warning, foregroundColor: colors.bg100),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showEditContactDialog(
      EmergencyContact contact, int index, AppColorTheme colors) {
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
            onPressed: () =>
                _showDeleteConfirmationDialog(contact, index, colors),
            child: Text('Delete', style: TextStyle(color: colors.warning)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: colors.text200)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty ||
                  relationController.text.isEmpty ||
                  phoneController.text.isEmpty) {
                _showSnackBar('All fields are required', colors.warning);
                return;
              }

              final updatedContact = EmergencyContact(
                name: nameController.text.trim(),
                relation: relationController.text.trim(),
                phone: phoneController.text.trim(),
              );

              final user = FirebaseAuth.instance.currentUser;
              final docRef =
              FirebaseFirestore.instance.collection('users').doc(user?.uid);

              final docSnapshot = await docRef.get();
              final currentContacts = List<Map<String, dynamic>>.from(
                  docSnapshot.data()?['emergencyContacts'] ?? []);

              currentContacts[index] = updatedContact.toJson();
              await docRef.update({'emergencyContacts': currentContacts});

              if (mounted) {
                Navigator.pop(context);
                _showSnackBar('Contact updated', colors.accent200);
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: colors.accent200,
                foregroundColor: colors.bg100),
            child: const Text('Save'),
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

  void _navigateTo(BuildContext context, Widget screen,
      {bool replace = false}) {
    final route = MaterialPageRoute(builder: (_) => screen);
    if (replace) {
      Navigator.pushReplacement(context, route);
    } else {
      Navigator.push(context, route);
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