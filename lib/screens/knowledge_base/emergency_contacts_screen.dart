import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';
import 'package:mydpar/localization/app_localizations.dart';

class EmergencyContact {
  final String titleKey; // Changed to use localization key
  final String subtitleKey; // Changed to use localization key
  final String phoneNumber;
  final String? website;
  final IconData icon;

  const EmergencyContact({
    required this.titleKey,
    required this.subtitleKey,
    required this.phoneNumber,
    this.website,
    required this.icon,
  });

  Map<String, dynamic> toJson() => {
    'titleKey': titleKey,
    'subtitleKey': subtitleKey,
    'phoneNumber': phoneNumber,
    'website': website,
    'icon': icon.codePoint,
  };
}

class EmergencyContactsScreen extends StatelessWidget {
  const EmergencyContactsScreen({super.key});

  static const double _paddingValue = 24.0;
  static const double _spacingSmall = 8.0;
  static const double _spacingMedium = 16.0;
  static const double _spacingLarge = 32.0;

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<ThemeProvider>(context).currentTheme;
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: colors.bg200,
      body: SafeArea(
        child: Column(
          children: [
            _Header(colors: colors),
            Expanded(child: _Content(colors: colors)),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final AppColorTheme colors;

  const _Header({required this.colors});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.bg100.withOpacity(0.7),
        border: Border.all(color: colors.bg300.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: EmergencyContactsScreen._paddingValue,
        vertical: EmergencyContactsScreen._paddingValue - 8,
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: colors.primary300),
            onPressed: () => Navigator.pop(context),
            tooltip: l.translate('back'),
          ),
          const SizedBox(width: EmergencyContactsScreen._spacingSmall),
          Text(
            l.translate('emergency_contacts'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.primary300,
            ),
          ),
        ],
      ),
    );
  }
}

class _Content extends StatelessWidget {
  final AppColorTheme colors;

  const _Content({required this.colors});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(EmergencyContactsScreen._paddingValue),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(titleKey: 'emergency_numbers', colors: colors),
          const SizedBox(height: EmergencyContactsScreen._spacingMedium),
          _EmergencyButton(
            number: '999',
            labelKey: 'national_emergency',
            color: colors.warning,
            isPulsing: true,
          ),
          const SizedBox(height: EmergencyContactsScreen._spacingMedium),
          _EmergencyButton(
            number: '112',
            labelKey: 'alternative_emergency',
            color: colors.accent100,
            isPulsing: false,
          ),
          const SizedBox(height: EmergencyContactsScreen._spacingLarge),
          _SectionTitle(titleKey: 'disaster_response', colors: colors),
          const SizedBox(height: EmergencyContactsScreen._spacingMedium),
          _AgencyCard(
            contact: const EmergencyContact(
              titleKey: 'nadma',
              subtitleKey: 'national_disaster_management',
              phoneNumber: '+603 8870 4800',
              website: 'https://www.nadma.gov.my/bi/',
              icon: Icons.business,
            ),
            colors: colors,
          ),
          const SizedBox(height: EmergencyContactsScreen._spacingMedium),
          _AgencyCard(
            contact: const EmergencyContact(
              titleKey: 'metmalaysia',
              subtitleKey: 'meteorological_department',
              phoneNumber: '+603 7967 8000',
              website: 'https://www.met.gov.my/?lang=en',
              icon: Icons.cloud,
            ),
            colors: colors,
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String titleKey;
  final AppColorTheme colors;

  const _SectionTitle({required this.titleKey, required this.colors});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Text(
      l.translate(titleKey),
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: colors.primary300,
      ),
    );
  }
}

class _EmergencyButton extends StatelessWidget {
  final String number;
  final String labelKey;
  final Color color;
  final bool isPulsing;

  const _EmergencyButton({
    required this.number,
    required this.labelKey,
    required this.color,
    required this.isPulsing,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<ThemeProvider>(context).currentTheme;
    final l = AppLocalizations.of(context);
    return GestureDetector(
      onTap: () => _makePhoneCall(context, number),
      child: Container(
        padding: const EdgeInsets.all(EmergencyContactsScreen._spacingMedium),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(EmergencyContactsScreen._spacingMedium),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.phone, color: colors.text200, size: 32),
            ),
            const SizedBox(width: EmergencyContactsScreen._spacingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    number,
                    style: TextStyle(
                      color: colors.text200,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    l.translate(labelKey),
                    style: TextStyle(
                      color: colors.text200.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(EmergencyContactsScreen._spacingSmall),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.phone_in_talk, color: colors.text200),
            ),
          ],
        ),
      ).animate(
        onPlay: (controller) => isPulsing ? controller.repeat(reverse: true) : null,
        effects: [
          if (isPulsing)
            ScaleEffect(
              begin: const Offset(1.0, 1.0),
              end: const Offset(1.05, 1.05),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeInOut,
            ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(BuildContext context, String phoneNumber) async {
    final l = AppLocalizations.of(context);
    final String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final Uri launchUri = Uri(scheme: 'tel', path: cleanNumber);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        _showSnackBar(context, l.translate('call_error', {'number': phoneNumber}), Colors.red);
      }
    } catch (e) {
      _showSnackBar(context, l.translate('call_error_with_exception', {'number': phoneNumber, 'error': e.toString()}), Colors.red);
    }
  }

  void _showSnackBar(BuildContext context, String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _AgencyCard extends StatelessWidget {
  final EmergencyContact contact;
  final AppColorTheme colors;

  const _AgencyCard({required this.contact, required this.colors});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(EmergencyContactsScreen._spacingMedium),
      decoration: BoxDecoration(
        color: colors.bg100.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.bg300.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(EmergencyContactsScreen._spacingMedium),
            decoration: BoxDecoration(
              color: colors.accent100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(contact.icon, color: Colors.white),
          ),
          const SizedBox(width: EmergencyContactsScreen._spacingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.translate(contact.titleKey),
                  style: TextStyle(
                    color: colors.primary300,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  l.translate(contact.subtitleKey),
                  style: TextStyle(color: colors.text200, fontSize: 14),
                ),
                const SizedBox(height: EmergencyContactsScreen._spacingSmall),
                Text(
                  contact.phoneNumber,
                  style: TextStyle(
                    color: colors.accent200,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              _ActionButton(
                icon: Icons.phone,
                color: colors.accent200,
                onTap: () => _makePhoneCall(context, contact.phoneNumber),
              ),
              if (contact.website != null) ...[
                const SizedBox(height: EmergencyContactsScreen._spacingSmall),
                _ActionButton(
                  icon: Icons.launch,
                  color: colors.accent100,
                  onTap: () => _launchURL(context, contact.website!),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(BuildContext context, String phoneNumber) async {
    final l = AppLocalizations.of(context);
    final String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final Uri launchUri = Uri(scheme: 'tel', path: cleanNumber);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        _showSnackBar(context, l.translate('call_error', {'number': phoneNumber}), Colors.red);
      }
    } catch (e) {
      _showSnackBar(context, l.translate('call_error_with_exception', {'number': phoneNumber, 'error': e.toString()}), Colors.red);
    }
  }

  Future<void> _launchURL(BuildContext context, String url) async {
    final l = AppLocalizations.of(context);
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar(context, l.translate('url_error', {'url': url}), Colors.red);
      }
    } catch (e) {
      _showSnackBar(context, l.translate('url_error_with_exception', {'url': url, 'error': e.toString()}), Colors.red);
    }
  }

  void _showSnackBar(BuildContext context, String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(EmergencyContactsScreen._spacingSmall),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}