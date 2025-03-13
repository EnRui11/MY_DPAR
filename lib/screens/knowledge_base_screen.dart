import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';

// Model for guide data, Firebase-ready
class Guide {
  final String title;
  final String description;
  final String readTime;

  const Guide({
    required this.title,
    required this.description,
    required this.readTime,
  });

  // Factory for Firebase data parsing (uncomment when integrating)
  // factory Guide.fromJson(Map<String, dynamic> json) => Guide(
  //   title: json['title'] as String,
  //   description: json['description'] as String,
  //   readTime: json['readTime'] as String,
  // );

  // Convert to JSON for Firebase writes
  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'readTime': readTime,
  };
}

// Model for category data
class Category {
  final IconData icon;
  final String title;
  final String description;

  const Category({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class KnowledgeBaseScreen extends StatelessWidget {
  const KnowledgeBaseScreen({super.key});

  // Constants for consistency and easy tweaking
  static const double _paddingValue = 16.0;
  static const double _spacingSmall = 8.0;
  static const double _spacingMedium = 12.0;
  static const double _spacingLarge = 24.0;

  @override
  Widget build(BuildContext context) {
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final AppColorTheme colors = themeProvider.currentTheme; // Updated type

    return Scaffold(
      backgroundColor: colors.bg200,
      body: SafeArea(
        child: Stack(
          children: [
            _buildContent(colors),
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
      border: Border(bottom: BorderSide(color: colors.bg100.withOpacity(0.2))),
    ),
    padding:
    const EdgeInsets.symmetric(horizontal: _paddingValue * 1.5, vertical: _paddingValue),
    child: Row(
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back, color: colors.primary300),
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: _spacingSmall),
        Text(
          'Knowledge Base',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colors.primary300,
          ),
        ),
      ],
    ),
  );

  /// Builds the scrollable content area
  Widget _buildContent(AppColorTheme colors) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(
        _paddingValue * 1.5, 70, _paddingValue * 1.5, _paddingValue),
    child: Column(
      children: [
        _buildSearchBar(colors),
        const SizedBox(height: _spacingLarge),
        _buildFeaturedGuide(colors),
        const SizedBox(height: _spacingLarge),
        _buildQuickAccessCategories(colors),
        const SizedBox(height: _spacingLarge * 1.5), // 32px
        _buildRecentGuides(colors),
      ],
    ),
  );

  /// Builds the search bar
  Widget _buildSearchBar(AppColorTheme colors) => Container(
    decoration: BoxDecoration(
      color: colors.bg100.withOpacity(0.7),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: colors.bg100.withOpacity(0.2)),
    ),
    padding: const EdgeInsets.symmetric(horizontal: _paddingValue, vertical: _spacingMedium),
    child: Row(
      children: [
        Icon(Icons.search, color: colors.text200),
        const SizedBox(width: _spacingMedium),
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search guides and resources...',
              hintStyle: TextStyle(color: colors.text200),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    ),
  );

  /// Builds the featured guide section
  Widget _buildFeaturedGuide(AppColorTheme colors) => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [colors.accent200, colors.accent100],
      ),
      borderRadius: BorderRadius.circular(16),
    ),
    padding: const EdgeInsets.all(_paddingValue * 1.5),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.bolt, color: colors.bg100),
            const SizedBox(width: _spacingMedium),
            Text(
              'Featured Guide',
              style: TextStyle(color: colors.bg100, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: _spacingMedium),
        Text(
          'Emergency Preparedness 101',
          style: TextStyle(
            color: colors.bg100,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: _spacingSmall),
        Text(
          'Essential steps to prepare for any disaster situation',
          style: TextStyle(color: colors.primary100),
        ),
        const SizedBox(height: _spacingLarge),
        ElevatedButton(
          onPressed: () {
            // TODO: Navigate to detailed guide
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.bg100,
            foregroundColor: colors.accent200,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Learn More'),
        ),
      ],
    ),
  );

  /// Builds the quick access categories grid
  Widget _buildQuickAccessCategories(AppColorTheme colors) {
    const List<Category> categories = [
      Category(
        icon: Icons.assignment_outlined,
        title: 'Preparation Guides',
        description: 'Step-by-step disaster guides',
      ),
      Category(
        icon: Icons.phone_outlined,
        title: 'Emergency Contacts',
        description: 'Important numbers & contacts',
      ),
      Category(
        icon: Icons.favorite_outline,
        title: 'First Aid Guide',
        description: 'Medical emergency basics',
      ),
      Category(
        icon: Icons.school_outlined,
        title: 'Training',
        description: 'Disaster response training resources',
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: _spacingLarge,
      crossAxisSpacing: _spacingLarge,
      childAspectRatio: 1.1,
      children: categories
          .map((category) => _buildCategoryCard(
        icon: category.icon,
        title: category.title,
        description: category.description,
        colors: colors,
      ))
          .toList(),
    );
  }

  /// Builds an individual category card
  Widget _buildCategoryCard({
    required IconData icon,
    required String title,
    required String description,
    required AppColorTheme colors,
  }) =>
      GestureDetector(
        onTap: () {
          // TODO: Navigate to category detail
        },
        child: Container(
          decoration: BoxDecoration(
            color: colors.bg100.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.bg100.withOpacity(0.2)),
          ),
          padding: const EdgeInsets.all(_paddingValue),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: colors.accent200, size: 28),
              const SizedBox(height: _spacingSmall),
              Text(
                title,
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
                description,
                style: TextStyle(color: colors.text200, fontSize: 11),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );

  /// Builds the recent guides section
  Widget _buildRecentGuides(AppColorTheme colors) {
    // Hardcoded guides for now, replace with Firebase later
    const List<Guide> guides = [
      Guide(
        title: 'Guide Topic',
        description: 'Description',
        readTime: '5 min read',
      ),
      Guide(
        title: 'Guide Topic',
        description: 'Description',
        readTime: '3 min read',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Guides',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colors.primary300,
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Navigate to all guides
              },
              child: Text(
                'View All',
                style: TextStyle(color: colors.accent200),
              ),
            ),
          ],
        ),
        const SizedBox(height: _spacingLarge),
        ...guides.map((guide) => Padding(
          padding: const EdgeInsets.only(bottom: _spacingMedium),
          child: _buildGuideCard(
            title: guide.title,
            description: guide.description,
            readTime: guide.readTime,
            colors: colors,
          ),
        )),
      ],
    );
  }

  /// Builds an individual guide card
  Widget _buildGuideCard({
    required String title,
    required String description,
    required String readTime,
    required AppColorTheme colors,
  }) =>
      GestureDetector(
        onTap: () {
          // TODO: Navigate to guide detail
        },
        child: Container(
          decoration: BoxDecoration(
            color: colors.bg100.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.bg100.withOpacity(0.2)),
          ),
          padding: const EdgeInsets.all(_paddingValue),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.article_outlined, color: colors.accent200),
              const SizedBox(width: _spacingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: colors.primary300,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(color: colors.text200, fontSize: 14),
                    ),
                    const SizedBox(height: _spacingSmall),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: colors.text200),
                        const SizedBox(width: 4),
                        Text(
                          readTime,
                          style: TextStyle(color: colors.text200, fontSize: 12),
                        ),
                        const SizedBox(width: _spacingLarge),
                        Icon(Icons.bookmark_border, size: 16, color: colors.text200),
                        const SizedBox(width: 4),
                        Text(
                          'Save for later',
                          style: TextStyle(color: colors.text200, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}