import 'package:flutter/material.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/screens/home_screen.dart';
import 'package:mydpar/screens/map_screen.dart';

class KnowledgeBaseScreen extends StatelessWidget {
  const KnowledgeBaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary200,
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
                        _buildSearchBar(),
                        const SizedBox(height: 24),

                        // Featured Guide
                        _buildFeaturedGuide(),
                        const SizedBox(height: 24),

                        // Quick Access Categories
                        _buildQuickAccessCategories(),
                        const SizedBox(height: 32),

                        // Recent Guides
                        _buildRecentGuides(),
                        const SizedBox(height: 80), // Space for bottom nav
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Header
            _buildHeader(context),

            // Bottom Navigation
            _buildBottomNavigation(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg100.withOpacity(0.7),
        border: Border(
          bottom: BorderSide(color: AppColors.bg100.withOpacity(0.2)),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            color: AppColors.primary300,
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Text(
            'Knowledge Base',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.primary300,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg100.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.bg100.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.search, color: AppColors.text200),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search guides and resources...',
                hintStyle: TextStyle(color: AppColors.text200),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedGuide() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.accent200, AppColors.accent100],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt, color: AppColors.bg100),
              const SizedBox(width: 12),
              Text(
                'Featured Guide',
                style: TextStyle(
                  color: AppColors.bg100,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Emergency Preparedness 101',
            style: TextStyle(
              color: AppColors.bg100,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Essential steps to prepare for any disaster situation',
            style: TextStyle(color: AppColors.primary100),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.bg100,
              foregroundColor: AppColors.accent200,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Learn More'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessCategories() {
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
      children: categories.map((category) => _buildCategoryCard(
        icon: category['icon'] as IconData,
        title: category['title'] as String,
        description: category['description'] as String,
      )).toList(),
    );
  }

  Widget _buildCategoryCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg100.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.bg100.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.accent200, size: 32),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: AppColors.primary300,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              color: AppColors.text200,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentGuides() {
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
                color: AppColors.primary300,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'View All',
                style: TextStyle(color: AppColors.accent200),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildGuideCard(
          title: 'Guide Topic',
          description: 'Description',
          readTime: '5 min read',
        ),
        const SizedBox(height: 12),
        _buildGuideCard(
          title: 'Guide Topic',
          description: 'Description',
          readTime: '3 min read',
        ),
      ],
    );
  }

  Widget _buildGuideCard({
    required String title,
    required String description,
    required String readTime,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg100.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.bg100.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.article_outlined, color: AppColors.accent200),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.primary300,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: AppColors.text200,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: AppColors.text200),
                    const SizedBox(width: 4),
                    Text(
                      readTime,
                      style: TextStyle(
                        color: AppColors.text200,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.bookmark_border, size: 16, color: AppColors.text200),
                    const SizedBox(width: 4),
                    Text(
                      'Save for later',
                      style: TextStyle(
                        color: AppColors.text200,
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

  Widget _buildBottomNavigation(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bg100.withOpacity(0.7),
          border: Border(
            top: BorderSide(color: AppColors.bg100.withOpacity(0.2)),
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
                  icon: const Icon(Icons.home_outlined),
                  color: AppColors.text200,
                  onPressed: () {
                    // Navigate to home screen and remove all previous routes
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const HomeScreen()),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.map_outlined),
                  color: AppColors.text200,
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const MapScreen()),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.message_outlined),
                  color: AppColors.text200,
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.person_outline),
                  color: AppColors.text200,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}