import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mydpar/screens/profile_screen.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/screens/home_screen.dart';
import 'package:mydpar/screens/map_screen.dart';
import 'package:mydpar/theme/theme_provider.dart';

class KnowledgeBaseScreen extends StatelessWidget {
  const KnowledgeBaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.currentTheme;

    return Scaffold(
      backgroundColor: colors.primary200,
      body: SafeArea(
        child: Stack(
          children: [
            // Main Content
            SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 70), // Space for header
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        // Search Bar
                        _buildSearchBar(colors),
                        const SizedBox(height: 24),

                        // Featured Guide
                        _buildFeaturedGuide(colors),
                        const SizedBox(height: 24),

                        // Quick Access Categories
                        _buildQuickAccessCategories(colors),
                        const SizedBox(height: 32),

                        // Recent Guides
                        _buildRecentGuides(colors),
                        const SizedBox(height: 80), // Space for bottom nav
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Header
            _buildHeader(context, colors),

            // Bottom Navigation
            _buildBottomNavigation(context, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.bg100.withOpacity(0.7),
        border: Border(
          bottom: BorderSide(color: colors.bg100.withOpacity(0.2)),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: colors.primary300),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
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
  }

  Widget _buildSearchBar(dynamic colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.bg100.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.bg100.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.search, color: colors.text200),
          const SizedBox(width: 12),
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
  }

  Widget _buildFeaturedGuide(dynamic colors) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.accent200, colors.accent100],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt, color: colors.bg100),
              const SizedBox(width: 12),
              Text(
                'Featured Guide',
                style: TextStyle(
                  color: colors.bg100,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Emergency Preparedness 101',
            style: TextStyle(
              color: colors.bg100,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Essential steps to prepare for any disaster situation',
            style: TextStyle(color: colors.primary100),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // TODO: Navigate to detailed guide
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.bg100,
              foregroundColor: colors.accent200,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Learn More',
              style: TextStyle(color: colors.accent200),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessCategories(dynamic colors) {
    final categories = [
      {
        'icon': Icons.assignment_outlined,
        'title': 'Preparation Guides',
        'description': 'Step-by-step disaster guides'
      },
      {
        'icon': Icons.phone_outlined,
        'title': 'Emergency Contacts',
        'description': 'Important numbers & contacts'
      },
      {
        'icon': Icons.favorite_outline,
        'title': 'First Aid Guide',
        'description': 'Medical emergency basics'
      },
      {
        'icon': Icons.school_outlined,
        'title': 'Training',
        'description': 'Disaster response training resources'
      },
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: categories
          .map((category) => _buildCategoryCard(
                icon: category['icon'] as IconData,
                title: category['title'] as String,
                description: category['description'] as String,
                colors: colors,
              ))
          .toList(),
    );
  }

  Widget _buildCategoryCard({
    required IconData icon,
    required String title,
    required String description,
    required dynamic colors,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colors.bg100.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.bg100.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: colors.accent200, size: 28),
          const SizedBox(height: 8),
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
            style: TextStyle(
              color: colors.text200,
              fontSize: 11,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentGuides(dynamic colors) {
    return Column(
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
        const SizedBox(height: 16),
        _buildGuideCard(
          title: 'Guide Topic',
          description: 'Description',
          readTime: '5 min read',
          colors: colors,
        ),
        const SizedBox(height: 12),
        _buildGuideCard(
          title: 'Guide Topic',
          description: 'Description',
          readTime: '3 min read',
          colors: colors,
        ),
      ],
    );
  }

  Widget _buildGuideCard({
    required String title,
    required String description,
    required String readTime,
    required dynamic colors,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colors.bg100.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.bg100.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.article_outlined, color: colors.accent200),
          const SizedBox(width: 12),
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
                  style: TextStyle(
                    color: colors.text200,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: colors.text200),
                    const SizedBox(width: 4),
                    Text(
                      readTime,
                      style: TextStyle(
                        color: colors.text200,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.bookmark_border,
                        size: 16, color: colors.text200),
                    const SizedBox(width: 4),
                    Text(
                      'Save for later',
                      style: TextStyle(
                        color: colors.text200,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context, dynamic colors) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: colors.bg100.withOpacity(0.7),
          border: Border(
            top: BorderSide(color: colors.bg100.withOpacity(0.2)),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: Icon(Icons.home_outlined, color: colors.text200),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const HomeScreen()),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.map_outlined, color: colors.text200),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const MapScreen()),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.message_outlined, color: colors.text200),
                  onPressed: () {
                    // TODO: Implement messaging functionality
                  },
                ),
                IconButton(
                  icon: Icon(Icons.person_outline, color: colors.text200),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ProfileScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
