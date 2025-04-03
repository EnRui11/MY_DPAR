import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mydpar/screens/knowledge_base/emergency_contacts_screen.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';
import 'package:mydpar/screens/knowledge_base/first_aid_guide/first_aid_guide_screen.dart';
import 'package:mydpar/screens/knowledge_base/home_safety_checklist_screen.dart';
import 'package:mydpar/screens/knowledge_base/prepareration_guide/preparation_guides_screen.dart';
import 'package:mydpar/screens/knowledge_base/prepareration_guide/flood_guide_screen.dart';
import 'package:mydpar/localization/app_localizations.dart';

class Guide {
  final String titleKey; // Changed to use localization key
  final String descriptionKey; // Changed to use localization key
  final String readTime;

  const Guide({
    required this.titleKey,
    required this.descriptionKey,
    required this.readTime,
  });

  Map<String, dynamic> toJson() => {
    'titleKey': titleKey,
    'descriptionKey': descriptionKey,
    'readTime': readTime,
  };
}

class Category {
  final IconData icon;
  final String titleKey; // Changed to use localization key
  final String descriptionKey; // Changed to use localization key

  const Category({
    required this.icon,
    required this.titleKey,
    required this.descriptionKey,
  });
}

class KnowledgeBaseScreen extends StatelessWidget {
  const KnowledgeBaseScreen({super.key});

  static const double _paddingValue = 16.0;
  static const double _spacingSmall = 8.0;
  static const double _spacingMedium = 12.0;
  static const double _spacingLarge = 24.0;

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<ThemeProvider>(context).currentTheme;
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: colors.bg200,
      body: SafeArea(
        child: Stack(
          children: [
            _Content(colors: colors),
            _Header(colors: colors),
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
        border: Border.all(color: colors.bg300.withOpacity(0.7)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: KnowledgeBaseScreen._paddingValue,
        vertical: KnowledgeBaseScreen._paddingValue - 4,
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: colors.primary300),
            onPressed: () => Navigator.pop(context),
            tooltip: l.translate('back'),
          ),
          const SizedBox(width: KnowledgeBaseScreen._spacingSmall),
          Text(
            l.translate('knowledge_base'),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        KnowledgeBaseScreen._paddingValue,
        60, // Adjusted to align with header height
        KnowledgeBaseScreen._paddingValue,
        KnowledgeBaseScreen._paddingValue,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _FeaturedGuide(colors: colors),
          const SizedBox(height: KnowledgeBaseScreen._spacingLarge),
          _QuickAccessCategories(colors: colors),
        ],
      ),
    );
  }
}

class _FeaturedGuide extends StatelessWidget {
  final AppColorTheme colors;

  const _FeaturedGuide({required this.colors});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return GestureDetector(
      onTap: () => _navigateTo(context, const FloodGuideScreen()),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colors.accent200, colors.accent100],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(KnowledgeBaseScreen._paddingValue),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bolt, color: colors.bg100),
                const SizedBox(width: KnowledgeBaseScreen._spacingSmall),
                Text(
                  l.translate('featured_guide'),
                  style: TextStyle(
                    color: colors.bg100,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: KnowledgeBaseScreen._spacingMedium),
            Text(
              l.translate('emergency_preparedness_flood'),
              style: TextStyle(
                color: colors.bg100,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: KnowledgeBaseScreen._spacingSmall),
            Text(
              l.translate('flood_preparation_description'),
              style: TextStyle(color: colors.bg100.withOpacity(0.8)),
            ),
            const SizedBox(height: KnowledgeBaseScreen._spacingLarge),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _navigateTo(context, const FloodGuideScreen()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.bg100,
                  foregroundColor: colors.accent200,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: KnowledgeBaseScreen._spacingMedium),
                ),
                child: Text(l.translate('learn_more')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}

class _QuickAccessCategories extends StatelessWidget {
  final AppColorTheme colors;

  const _QuickAccessCategories({required this.colors});

  static const List<Category> _categories = [
    Category(
      icon: Icons.assignment_outlined,
      titleKey: 'preparation_guides',
      descriptionKey: 'step_by_step_disaster_guides',
    ),
    Category(
      icon: Icons.phone_outlined,
      titleKey: 'emergency_contacts',
      descriptionKey: 'important_numbers_contacts',
    ),
    Category(
      icon: Icons.favorite_outline,
      titleKey: 'first_aid_guide',
      descriptionKey: 'medical_emergency_basics',
    ),
    Category(
      icon: Icons.home_outlined,
      titleKey: 'home_safety_checklist',
      descriptionKey: 'ensure_home_safety',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.translate('quick_access'),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colors.primary300,
          ),
        ),
        const SizedBox(height: KnowledgeBaseScreen._spacingMedium),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: KnowledgeBaseScreen._spacingLarge,
          crossAxisSpacing: KnowledgeBaseScreen._spacingLarge,
          childAspectRatio: 1.1,
          children: _categories
              .map((category) => _CategoryCard(
            category: category,
            colors: colors,
          ))
              .toList(),
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final Category category;
  final AppColorTheme colors;

  const _CategoryCard({required this.category, required this.colors});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return GestureDetector(
      onTap: () => _handleCategoryTap(context, category.titleKey),
      child: Container(
        decoration: BoxDecoration(
          color: colors.bg100.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.bg300.withOpacity(0.2)),
        ),
        padding: const EdgeInsets.all(KnowledgeBaseScreen._paddingValue),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(category.icon, color: colors.accent200, size: 28),
            const SizedBox(height: KnowledgeBaseScreen._spacingSmall),
            Text(
              l.translate(category.titleKey),
              style: TextStyle(
                color: colors.primary300,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              l.translate(category.descriptionKey),
              style: TextStyle(color: colors.text200, fontSize: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _handleCategoryTap(BuildContext context, String titleKey) {
    final l = AppLocalizations.of(context);
    switch (titleKey) {
      case 'emergency_contacts':
        _navigateTo(context, const EmergencyContactsScreen());
        break;
      case 'first_aid_guide':
        _navigateTo(context, const FirstAidGuideScreen());
        break;
      case 'home_safety_checklist':
        _navigateTo(context, const HomeSafetyChecklistScreen());
        break;
      case 'preparation_guides':
        _navigateTo(context, const PreparationGuidesScreen());
        break;
      default:
        _showSnackBar(
          context,
          l.translate('not_implemented', {'title': l.translate(titleKey)}),
          Colors.orange,
        );
    }
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
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