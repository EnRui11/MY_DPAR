import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';

class BitesStingsGuideScreen extends StatefulWidget {
  const BitesStingsGuideScreen({super.key});

  @override
  State<BitesStingsGuideScreen> createState() => _BitesStingsGuideScreenState();
}

class _BitesStingsGuideScreenState extends State<BitesStingsGuideScreen> {
  static const double _paddingValue = 16.0;
  static const double _spacingSmall = 8.0;
  static const double _spacingMedium = 12.0;
  static const double _spacingLarge = 24.0;

  String _selectedCategory = 'insect'; // Default selected category

  @override
  Widget build(BuildContext context) {
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final AppColorTheme colors = themeProvider.currentTheme;

    return Scaffold(
      backgroundColor: colors.bg200,
      body: SafeArea(
        child: Stack(
          children: [
            _buildContent(context, colors),
            _buildHeader(context, colors),
          ],
        ),
      ),
    );
  }

  /// Builds the header with back button and title
  Widget _buildHeader(BuildContext context, AppColorTheme colors) => Container(
    decoration: BoxDecoration(
      color: colors.bg100.withOpacity(0.7),
      border: Border(bottom: BorderSide(color: colors.bg300.withOpacity(0.2))),
    ),
    padding: const EdgeInsets.symmetric(
      horizontal: _paddingValue,
      vertical: _paddingValue - 4,
    ),
    child: Row(
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back, color: colors.primary300),
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: _spacingSmall),
        Expanded(
          child: Text(
            'Bites & Stings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.primary300,
            ),
          ),
        ),
      ],
    ),
  );

  /// Builds the main content area
  Widget _buildContent(BuildContext context, AppColorTheme colors) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(
      _paddingValue,
      70, // Adjusted for header height
      _paddingValue,
      _paddingValue,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: _spacingLarge),
        _buildEmergencyWarning(context, colors),
        const SizedBox(height: _spacingLarge),
        _buildCategoryTabs(colors),
      ],
    ),
  );

  /// Builds the emergency warning section
  Widget _buildEmergencyWarning(BuildContext context, AppColorTheme colors) => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [colors.warning, colors.warning.withOpacity(0.8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(12),
    ),
    padding: const EdgeInsets.all(_paddingValue),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: colors.bg100, size: 28),
            const SizedBox(width: _spacingMedium),
            Text(
              'Emergency Warning',
              style: TextStyle(
                color: colors.bg100,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: _spacingLarge),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(_paddingValue),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Seek Immediate Help If:',
                style: TextStyle(
                  color: colors.bg100,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: _spacingMedium),
              _buildWarningItem('Difficulty breathing or swallowing'),
              _buildWarningItem('Severe swelling or rash'),
              _buildWarningItem('Signs of anaphylaxis (e.g., dizziness, rapid pulse)'),
              _buildWarningItem('Known poisonous bite/sting'),
            ],
          ),
        ),
        const SizedBox(height: _spacingLarge),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _makeEmergencyCall(context),
            icon: Icon(Icons.phone, color: colors.warning),
            label: Text(
              'Call 999',
              style: TextStyle(color: colors.warning, fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.bg100,
              padding: const EdgeInsets.symmetric(vertical: _spacingMedium),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    ),
  ).animate().fadeIn(duration: 300.ms);

  /// Builds a warning item for emergency conditions
  Widget _buildWarningItem(String text) => Padding(
    padding: const EdgeInsets.only(bottom: _spacingSmall),
    child: Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: const BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
          margin: const EdgeInsets.only(right: _spacingSmall, top: 4),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );

  /// Builds the category tabs section
  Widget _buildCategoryTabs(AppColorTheme colors) => Container(
    decoration: _buildCardDecoration(colors),
    padding: const EdgeInsets.all(_paddingValue),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.medical_information, color: colors.accent200),
            const SizedBox(width: _spacingMedium),
            Text(
              'Treatment Guide',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.primary300,
              ),
            ),
          ],
        ),
        const SizedBox(height: _spacingLarge),
        _buildCategoryOption(
          colors,
          'insect',
          'Insect Bites & Stings',
          Icons.bug_report,
          colors.accent100,
        ),
        const SizedBox(height: _spacingSmall),
        _buildCategoryOption(
          colors,
          'animal',
          'Animal Bites',
          Icons.pets,
          colors.warning,
        ),
        const SizedBox(height: _spacingSmall),
        _buildCategoryOption(
          colors,
          'snake',
          'Snake Bites',
          Icons.warning_rounded,
          Colors.red,
        ),
        const SizedBox(height: _spacingLarge),
        _buildCategoryContent(colors),
      ],
    ),
  ).animate().fadeIn(duration: 400.ms);

  /// Builds a category option button
  Widget _buildCategoryOption(
      AppColorTheme colors,
      String category,
      String text,
      IconData icon,
      Color indicatorColor,
      ) =>
      InkWell(
        onTap: () => setState(() => _selectedCategory = category),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: _selectedCategory == category
                ? indicatorColor.withOpacity(0.1)
                : colors.bg100.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _selectedCategory == category ? indicatorColor : colors.bg300.withOpacity(0.2),
              width: _selectedCategory == category ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.all(_spacingMedium),
          transform: _selectedCategory == category ? Matrix4.identity().scaled(1.02) : Matrix4.identity(),
          child: Row(
            children: [
              Icon(icon, color: indicatorColor),
              const SizedBox(width: _spacingMedium),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: colors.text200,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  /// Builds the content for the selected category
  Widget _buildCategoryContent(AppColorTheme colors) {
    final Map<String, Widget> categories = {
      'insect': _buildInsectBitesSection(colors),
      'animal': _buildAnimalBitesSection(colors),
      'snake': _buildSnakeBitesSection(colors),
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
      child: categories[_selectedCategory] ?? const SizedBox.shrink(key: ValueKey('empty')),
    );
  }

  /// Builds the insect bites section
  Widget _buildInsectBitesSection(AppColorTheme colors) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        decoration: BoxDecoration(
          color: colors.accent100.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(_spacingMedium),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: colors.accent100, size: 20),
            const SizedBox(width: _spacingSmall),
            Expanded(
              child: Text(
                'Usually mild - Monitor for allergic reactions',
                style: TextStyle(color: colors.accent100, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: _spacingLarge),
      Text(
        'Bee/Wasp Stings',
        style: TextStyle(fontWeight: FontWeight.w600, color: colors.primary300),
      ),
      const SizedBox(height: _spacingMedium),
      ...[
        _buildStep(colors, '1', 'Remove Stinger', 'Scrape with a credit card or fingernail (don’t squeeze)'),
        _buildStep(colors, '2', 'Clean Wound', 'Wash area thoroughly with soap and water'),
        _buildStep(colors, '3', 'Reduce Swelling', 'Apply cold compress for 10-15 minutes'),
        _buildStep(colors, '4', 'Manage Symptoms', 'Take antihistamine if needed for itching/swelling'),
      ].asMap().entries.map((entry) => entry.value.animate().fadeIn(duration: 400.ms, delay: (entry.key * 100).ms)).toList(),
    ],
  );

  /// Builds the animal bites section
  Widget _buildAnimalBitesSection(AppColorTheme colors) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        decoration: BoxDecoration(
          color: colors.warning.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(_spacingMedium),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: colors.warning, size: 20),
            const SizedBox(width: _spacingSmall),
            Expanded(
              child: Text(
                'Moderate to severe - Medical attention recommended',
                style: TextStyle(color: colors.warning, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: _spacingLarge),
      ...[
        _buildStep(colors, '1', 'Control Bleeding', 'Apply gentle pressure with a clean cloth'),
        _buildStep(colors, '2', 'Clean Wound', 'Wash thoroughly with soap and water (5+ minutes)'),
        _buildStep(colors, '3', 'Apply First Aid', 'Use antibiotic ointment and sterile bandage'),
      ].asMap().entries.map((entry) => entry.value.animate().fadeIn(duration: 400.ms, delay: (entry.key * 100).ms)).toList(),
      const SizedBox(height: _spacingMedium),
      _buildTipCard(
        colors,
        'Medical Attention Required',
        Icons.local_hospital,
        ['Deep wounds', 'Wild/stray animal bites', 'Potential rabies exposure'],
        false,
      ).animate().fadeIn(duration: 400.ms),
    ],
  );

  /// Builds the snake bites section
  Widget _buildSnakeBitesSection(AppColorTheme colors) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(_spacingMedium),
        child: Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.red, size: 20),
            const SizedBox(width: _spacingSmall),
            Expanded(
              child: Text(
                'Critical Emergency - Immediate medical care required!',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: _spacingLarge),
      ...[
        _buildStep(colors, '1', 'Stay Calm', 'Remain still to slow venom spread'),
        _buildStep(colors, '2', 'Call Emergency', 'Contact emergency services immediately'),
        _buildStep(colors, '3', 'Immobilize', 'Keep affected area below heart level'),
      ].asMap().entries.map((entry) => entry.value.animate().fadeIn(duration: 400.ms, delay: (entry.key * 100).ms)).toList(),
      const SizedBox(height: _spacingMedium),
      _buildTipCard(
        colors,
        'Important Safety Warnings',
        Icons.warning_rounded,
        ['Never attempt to suck out venom', 'Do not apply a tourniquet', 'Avoid applying ice to the bite area'],
        true,
      ).animate().fadeIn(duration: 400.ms),
    ],
  );

  /// Builds a treatment step
  Widget _buildStep(AppColorTheme colors, String step, String title, String description) => Container(
    margin: const EdgeInsets.only(bottom: _spacingLarge),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _getSeverityColor(colors),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  step,
                  style: TextStyle(
                    color: colors.bg100,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: _spacingMedium),
            Icon(_getStepIcon(title), color: _getSeverityColor(colors)),
            const SizedBox(width: _spacingSmall),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colors.primary300,
                ),
              ),
            ),
          ],
        ),
        Container(
          margin: const EdgeInsets.only(left: 16),
          padding: const EdgeInsets.only(left: 24, top: _spacingMedium, bottom: _spacingMedium),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: _getSeverityColor(colors).withOpacity(0.3),
                width: 2,
              ),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(_paddingValue),
            decoration: BoxDecoration(
              color: colors.bg100.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(description, style: TextStyle(color: colors.text200)),
          ),
        ),
      ],
    ),
  );

  /// Builds a tip card for additional information
  Widget _buildTipCard(
      AppColorTheme colors,
      String title,
      IconData icon,
      List<String> items,
      bool isWarning,
      ) =>
      Container(
        padding: const EdgeInsets.all(_paddingValue),
        decoration: BoxDecoration(
          color: isWarning ? colors.warning.withOpacity(0.15) : colors.bg100.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isWarning ? colors.warning.withOpacity(0.3) : colors.accent200.withOpacity(0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: isWarning ? colors.warning : colors.accent200, size: 24),
                const SizedBox(width: _spacingMedium),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isWarning ? colors.warning : colors.accent200,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: _spacingMedium),
            ...items.map(
                  (item) => Padding(
                padding: const EdgeInsets.only(bottom: _spacingSmall),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(right: 8, top: 6),
                      decoration: BoxDecoration(
                        color: isWarning ? colors.warning : colors.text200,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(child: Text(item, style: TextStyle(color: colors.text200, fontSize: 14))),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  /// Determines severity color based on category
  Color _getSeverityColor(AppColorTheme colors) {
    switch (_selectedCategory) {
      case 'insect':
        return colors.accent100;
      case 'animal':
        return colors.warning;
      case 'snake':
        return Colors.red;
      default:
        return colors.accent200;
    }
  }

  /// Maps step titles to appropriate icons
  IconData _getStepIcon(String title) {
    switch (title.toLowerCase()) {
      case 'remove stinger':
        return Icons.content_cut;
      case 'clean wound':
        return Icons.water_drop;
      case 'reduce swelling':
        return Icons.ac_unit; // Changed to align with FracturesGuideScreen
      case 'manage symptoms':
        return Icons.medical_services;
      case 'control bleeding':
        return Icons.favorite;
      case 'apply first aid':
        return Icons.medical_information;
      case 'stay calm':
        return Icons.psychology;
      case 'call emergency':
        return Icons.phone;
      case 'immobilize':
        return Icons.do_not_step;
      default:
        return Icons.check_circle;
    }
  }

  /// Initiates an emergency phone call
  Future<void> _makeEmergencyCall(BuildContext context) async {
    final Uri url = Uri.parse('tel:999');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        _showSnackBar(context, 'Could not launch emergency call', Colors.red);
      }
    } catch (e) {
      _showSnackBar(context, 'Failed to make call: $e', Colors.red);
    }
  }

  /// Displays a snackbar with a message
  void _showSnackBar(BuildContext context, String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(_paddingValue),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Returns a reusable card decoration
  BoxDecoration _buildCardDecoration(AppColorTheme colors) => BoxDecoration(
    color: colors.bg100.withOpacity(0.85),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: colors.accent200.withOpacity(0.1)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );
}