import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mydpar/screens/home_screen.dart';
import 'package:mydpar/screens/map_screen.dart';
import 'package:mydpar/screens/profile_screen.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';

// Model for feature items
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

// Model for help requests, Firebase-ready
class HelpRequest {
  final String title;
  final String description;
  final String needs;
  final String category;

  const HelpRequest({
    required this.title,
    required this.description,
    required this.needs,
    required this.category,
  });

  // Factory for Firebase data parsing (uncomment when integrating)
  // factory HelpRequest.fromJson(Map<String, dynamic> json) => HelpRequest(
  //   title: json['title'] as String,
  //   description: json['description'] as String,
  //   needs: json['needs'] as String,
  //   category: json['category'] as String,
  // );

  // Convert to JSON for Firebase writes
  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'needs': needs,
    'category': category,
  };
}

// Model for available resources, Firebase-ready
class Resource {
  final String title;
  final String description;
  final String location;
  final bool isAvailable;

  const Resource({
    required this.title,
    required this.description,
    required this.location,
    required this.isAvailable,
  });

  // Factory for Firebase data parsing (uncomment when integrating)
  // factory Resource.fromJson(Map<String, dynamic> json) => Resource(
  //   title: json['title'] as String,
  //   description: json['description'] as String,
  //   location: json['location'] as String,
  //   isAvailable: json['isAvailable'] as bool,
  // );

  // Convert to JSON for Firebase writes
  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'location': location,
    'isAvailable': isAvailable,
  };
}

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

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

  /// Builds the header with the community title
  Widget _buildHeader(BuildContext context, AppColorTheme colors) => Padding(
    padding:
    const EdgeInsets.symmetric(horizontal: _paddingValue, vertical: _paddingValue),
    child: Text(
      'Community',
      style: TextStyle(
        color: colors.primary300,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  /// Builds the scrollable content area
  Widget _buildContent(BuildContext context, AppColorTheme colors) => Expanded(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(_paddingValue),
      child: Column(
        children: [
          _buildFeatureGrid(context, colors),
          const SizedBox(height: _spacingLarge),
          _buildActiveHelpRequests(context, colors),
          const SizedBox(height: _spacingLarge),
          _buildAvailableResources(context, colors),
        ],
      ),
    ),
  );

  /// Builds the grid of feature cards
  Widget _buildFeatureGrid(BuildContext context, AppColorTheme colors) {
    const List<FeatureItem> features = [
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
      mainAxisSpacing: _spacingLarge,
      crossAxisSpacing: _spacingLarge,
      children: features.map((feature) => _buildFeatureCard(feature, colors)).toList(),
    );
  }

  /// Builds an individual feature card
  Widget _buildFeatureCard(FeatureItem feature, AppColorTheme colors) => Container(
    decoration: BoxDecoration(
      color: colors.bg100.withOpacity(0.7),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: colors.bg100.withOpacity(0.2)),
    ),
    padding: const EdgeInsets.all(_paddingValue),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(feature.icon, size: 32, color: colors.accent200),
        const SizedBox(height: _spacingSmall),
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

  /// Builds the active help requests section
  Widget _buildActiveHelpRequests(BuildContext context, AppColorTheme colors) {
    // Hardcoded help requests for now, replace with Firebase later
    const List<HelpRequest> helpRequests = [
      HelpRequest(
        title: 'Food Distribution',
        description: 'Help needed to distribute food packages to affected areas',
        needs: '200 food packages needed',
        category: 'Supplies',
      ),
      HelpRequest(
        title: 'Medical Supplies Needed',
        description: 'First aid kits and medications needed for elderly care center',
        needs: '10 first aid kits, basic medications',
        category: 'Medical',
      ),
    ];

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
              onPressed: () {
                // TODO: Navigate to full help requests screen
              },
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
        const SizedBox(height: _spacingLarge),
        SizedBox(
          height: 200,
          child: Scrollbar(
            thickness: 6,
            radius: const Radius.circular(8),
            child: ListView(
              children: helpRequests
                  .map((request) => Padding(
                padding: const EdgeInsets.only(bottom: _spacingMedium),
                child: _buildHelpRequestCard(
                  request.title,
                  request.description,
                  request.needs,
                  request.category,
                  colors,
                ),
              ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds an individual help request card
  Widget _buildHelpRequestCard(
      String title,
      String description,
      String needs,
      String category,
      AppColorTheme colors,
      ) =>
      Container(
        decoration: BoxDecoration(
          color: colors.bg100.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.bg100.withOpacity(0.2)),
        ),
        padding: const EdgeInsets.all(_paddingValue),
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
                  padding:
                  const EdgeInsets.symmetric(horizontal: _spacingSmall, vertical: 4),
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
            const SizedBox(height: _spacingMedium),
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
                  onPressed: () {
                    // TODO: Implement respond functionality
                  },
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

  /// Builds the available resources section
  Widget _buildAvailableResources(BuildContext context, AppColorTheme colors) {
    // Hardcoded resources for now, replace with Firebase later
    const List<Resource> resources = [
      Resource(
        title: 'Water Supplies',
        description: '20 boxes of bottled water available for distribution',
        location: '123 Main Street, Kuala Lumpur, 50000',
        isAvailable: true,
      ),
      Resource(
        title: 'Medical Equipment',
        description: 'Wheelchairs and basic medical supplies',
        location: '78 Hospital Street, Shah Alam, 40000',
        isAvailable: false,
      ),
    ];

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
              onPressed: () {
                // TODO: Navigate to full resources screen
              },
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
        const SizedBox(height: _spacingLarge),
        SizedBox(
          height: 200,
          child: Scrollbar(
            thickness: 6,
            radius: const Radius.circular(8),
            child: SingleChildScrollView(
              child: Column(
                children: resources
                    .map((resource) => Padding(
                  padding: const EdgeInsets.only(bottom: _spacingMedium),
                  child: _buildResourceCard(
                    resource.title,
                    resource.description,
                    resource.location,
                    resource.isAvailable,
                    colors,
                  ),
                ))
                    .toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds an individual resource card
  Widget _buildResourceCard(
      String title,
      String description,
      String location,
      bool isAvailable,
      AppColorTheme colors,
      ) =>
      Container(
        decoration: BoxDecoration(
          color: colors.bg100.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.bg100.withOpacity(0.2)),
        ),
        padding: const EdgeInsets.all(_paddingValue),
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
                  padding:
                  const EdgeInsets.symmetric(horizontal: _spacingSmall, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.bg100.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isAvailable ? 'Available' : 'Unavailable',
                    style: TextStyle(
                      color: isAvailable ? colors.accent200 : colors.warning,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: _spacingMedium),
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

  /// Builds the bottom navigation bar
  Widget _buildBottomNavigation(BuildContext context, AppColorTheme colors) =>
      Container(
        decoration: BoxDecoration(
          color: colors.bg100.withOpacity(0.7),
          border: Border(top: BorderSide(color: colors.bg100.withOpacity(0.2))),
        ),
        padding: const EdgeInsets.symmetric(vertical: _spacingSmall),
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
            _buildNavItem(
              Icons.people_outline,
              true, // Community is active
                  () {},
              colors,
            ),
            _buildNavItem(
              Icons.person_outline,
              false,
                  () => _navigateTo(context, const ProfileScreen()),
              colors,
            ),
          ],
        ),
      );

  /// Reusable navigation item widget
  Widget _buildNavItem(
      IconData icon,
      bool isActive,
      VoidCallback onPressed,
      AppColorTheme colors,
      ) =>
      IconButton(
        icon: Icon(icon),
        color: isActive ? colors.accent200 : colors.text200,
        onPressed: onPressed,
      );

  /// Navigates to a new screen, replacing the current one
  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}