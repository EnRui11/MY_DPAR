import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mydpar/theme/theme_provider.dart';
import 'package:mydpar/screens/home_screen.dart';
import 'package:mydpar/screens/map_screen.dart';
import 'package:mydpar/screens/profile_screen.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.currentTheme;

    return Scaffold(
      backgroundColor: colors.primary200,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, colors),
            _buildContent(context, colors),
            _buildBottomNavigation(context, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Text(
        'Community',
        style: TextStyle(
          color: colors.primary300,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, dynamic colors) {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildFeatureGrid(context, colors),
            const SizedBox(height: 24),
            _buildActiveHelpRequests(context, colors),
            const SizedBox(height: 24),
            _buildAvailableResources(context, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureGrid(BuildContext context, dynamic colors) {
    final features = [
      FeatureItem(
        icon: Icons.group_outlined,
        title: 'Volunteer',
        description: 'Join our volunteer network',
      ),
      FeatureItem(
        icon: Icons.inventory_2_outlined,
        title: 'Resources',
        description: 'Share or request resources',
      ),
      FeatureItem(
        icon: Icons.people_outline,
        title: 'Groups',
        description: 'Join community groups',
      ),
      FeatureItem(
        icon: Icons.help_outline,
        title: 'Help & Support',
        description: 'Request assistance',
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: features
          .map((feature) => _buildFeatureCard(feature, colors))
          .toList(),
    );
  }

  Widget _buildFeatureCard(FeatureItem feature, dynamic colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.bg100.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.bg100.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(feature.icon, size: 32, color: colors.accent200),
          const SizedBox(height: 8),
          Text(
            feature.title,
            style: TextStyle(
              color: colors.primary300,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            feature.description,
            style: TextStyle(
              color: colors.text200,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveHelpRequests(BuildContext context, dynamic colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Active Help Requests',
              style: TextStyle(
                color: colors.primary300,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'View All',
                style: TextStyle(
                  color: colors.accent200,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: Scrollbar(
            thickness: 6,
            radius: const Radius.circular(8),
            child: ListView(
              children: [
                _buildHelpRequestCard(
                  'Food Distribution',
                  'Help needed to distribute food packages to affected areas',
                  '200 food packages needed',
                  'Supplies',
                  colors,
                ),
                const SizedBox(height: 12),
                _buildHelpRequestCard(
                  'Medical Supplies Needed',
                  'First aid kits and medications needed for elderly care center',
                  '10 first aid kits, basic medications',
                  'Medical',
                  colors,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvailableResources(BuildContext context, dynamic colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Available Resources',
              style: TextStyle(
                color: colors.primary300,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'View All',
                style: TextStyle(
                  color: colors.accent200,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: Scrollbar(
            thickness: 6,
            radius: const Radius.circular(8),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildResourceCard(
                    'Water Supplies',
                    '20 boxes of bottled water available for distribution',
                    '123 Main Street, Kuala Lumpur, 50000',
                    true,
                    colors,
                  ),
                  const SizedBox(height: 12),
                  _buildResourceCard(
                    'Medical Equipment',
                    'Wheelchairs and basic medical supplies',
                    '78 Hospital Street, Shah Alam, 40000',
                    false,
                    colors,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHelpRequestCard(String title, String description, String needs,
      String category, dynamic colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.bg100.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.bg100.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.bg100.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    color: colors.accent200,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  needs,
                  style: TextStyle(
                    color: colors.text200,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Respond',
                  style: TextStyle(
                    color: colors.accent200,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResourceCard(String title, String description, String location,
      bool isAvailable, dynamic colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.bg100.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.bg100.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.bg100.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isAvailable ? 'Available' : 'Unavailable',
                  style: TextStyle(
                    color: isAvailable ? colors.accent200 : Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 16, color: colors.text200),
              const SizedBox(width: 4),
              Text(
                location,
                style: TextStyle(
                  color: colors.text200,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context, dynamic colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.bg100.withOpacity(0.7),
        border: Border(top: BorderSide(color: colors.bg100.withOpacity(0.2))),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            Icons.home_outlined,
            false,
            () => _navigateTo(context, const HomeScreen()),
            colors,
          ),
          _buildNavItem(
            Icons.map_outlined,
            false,
            () => _navigateTo(context, const MapScreen()),
            colors,
          ),
          _buildNavItem(Icons.people_outline, true, () {}, colors),
          _buildNavItem(
            Icons.person_outline,
            false,
            () => _navigateTo(context, const ProfileScreen()),
            colors,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
      IconData icon, bool isActive, VoidCallback onPressed, dynamic colors) {
    return IconButton(
      icon: Icon(icon),
      color: isActive ? colors.accent200 : colors.text200,
      onPressed: onPressed,
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}

class FeatureItem {
  final IconData icon;
  final String title;
  final String description;

  const FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });
}
