import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mydpar/screens/knowledge_base/knowledge_base_screen.dart';
import 'package:mydpar/screens/report_disaster/report_disaster_screen.dart';
import 'package:mydpar/screens/sos_emergency/sos_emergency_screen.dart';
import 'package:mydpar/screens/disaster_infomation/all_disasters_screen.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';
import 'package:mydpar/services/user_information_service.dart';
import 'package:mydpar/services/disaster_information_service.dart';
import 'package:mydpar/screens/disaster_infomation/alert_detail_screen.dart';
import 'package:mydpar/services/bottom_nav_service.dart';

class HomeScreen extends StatefulWidget {
  final bool showNavBar;

  const HomeScreen({Key? key, this.showNavBar = true}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Constants for consistency and easy tweaking
  static const double _paddingValue = 24.0;
  static const double _spacingSmall = 8.0;
  static const double _spacingMedium = 16.0;
  static const double _spacingLarge = 24.0;

  @override
  void initState() {
    super.initState();
    // Fetch disasters when the screen loads, only get happening disasters
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Set current index in navigation service
      Provider.of<NavigationService>(context, listen: false).changeIndex(0);
      Provider.of<DisasterService>(context, listen: false)
          .fetchRecentDisasters(onlyHappening: true);
    });
  }

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
            _buildHeader(colors),
          ],
        ),
      ),
    );
  }

  /// Builds the header with gradient and welcome message
  Widget _buildHeader(AppColorTheme colors) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colors.accent200, colors.accent100],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(_paddingValue),
        child: Consumer<UserInformationService>(
          builder: (context, userService, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Hello, ${userService.lastName ?? 'User'}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colors.bg100,
                ),
              ),
              const SizedBox(height: _spacingSmall),
              Text(
                'Welcome to MY_DPAR',
                style: TextStyle(fontSize: 16, color: colors.primary100),
              ),
              Text(
                'Your Disaster Preparedness and Response Assistant',
                style: TextStyle(fontSize: 16, color: colors.primary100),
              ),
            ],
          ),
        ),
      );

  /// Builds the scrollable main content area
  Widget _buildContent(BuildContext context, AppColorTheme colors) =>
      SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            _paddingValue, 120, _paddingValue, _paddingValue),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 64),
            _buildQuickActions(context, colors),
            const SizedBox(height: _spacingLarge),
            _buildSOSButton(context, colors),
            const SizedBox(height: _spacingLarge),
            _buildRecentDisastersSection(context, colors),
            const SizedBox(height: 80), // Space for bottom nav
          ],
        ),
      );

  /// Builds the animated SOS emergency button
  Widget _buildSOSButton(BuildContext context, AppColorTheme colors) =>
      TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.95, end: 1.0),
        duration: const Duration(seconds: 2),
        curve: Curves.easeInOut,
        builder: (context, scale, child) => Transform.scale(
          scale: scale,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: colors.warning,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: colors.warning.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: MaterialButton(
              onPressed: () => _navigateTo(context, const SOSEmergencyScreen()),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: colors.bg100, size: 24),
                  const SizedBox(width: _spacingSmall),
                  Text(
                    'SOS Emergency',
                    style: TextStyle(
                      color: colors.bg100,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  /// Builds the quick action cards (Report Disaster, Knowledge Base)
  Widget _buildQuickActions(BuildContext context, AppColorTheme colors) => Row(
        children: [
          Expanded(
            child: _buildActionCard(
              icon: Icons.location_on_outlined,
              label: 'Report Disaster',
              colors: colors,
              onTap: () => _navigateTo(context, const ReportDisasterScreen()),
            ),
          ),
          const SizedBox(width: _spacingMedium),
          Expanded(
            child: _buildActionCard(
              icon: Icons.book_outlined,
              label: 'Knowledge Base',
              colors: colors,
              onTap: () => _navigateTo(context, const KnowledgeBaseScreen()),
            ),
          ),
        ],
      );

  /// Reusable action card widget
  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required AppColorTheme colors,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: colors.bg100.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.bg100.withOpacity(0.2)),
          ),
          padding: const EdgeInsets.all(_spacingMedium),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: colors.accent200, size: 32),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  color: colors.primary300,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

  /// Builds the recent disasters section with a header and list
  Widget _buildRecentDisastersSection(
          BuildContext context, AppColorTheme colors) =>
      Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Disasters Happening Now',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.primary300,
                ),
              ),
              TextButton(
                onPressed: () => _navigateTo(context, const DisastersScreen()),
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
          const SizedBox(height: _spacingMedium),
          _buildDisastersList(colors),
        ],
      );

  /// Builds an individual disaster card
  Widget _buildDisasterCard({
    required String description,
    required String severity,
    required String location,
    required String time,
    required String disasterType,
    required AppColorTheme colors,
  }) =>
      Container(
        margin: const EdgeInsets.only(bottom: _spacingMedium),
        decoration: BoxDecoration(
          color: colors.bg100.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.bg100.withOpacity(0.2)),
        ),
        padding: const EdgeInsets.all(_spacingMedium),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getSeverityColor(severity, colors),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_getDisasterIcon(disasterType),
                  color: colors.bg100, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        disasterType,
                        style: TextStyle(
                          color: colors.primary300,
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getSeverityColor(severity, colors)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          severity,
                          style: TextStyle(
                            color: _getSeverityColor(severity, colors),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(color: colors.text200, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          color: colors.text200, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: TextStyle(
                            color: colors.text200,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.access_time, color: colors.text200, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        time,
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

  /// Helper method to get color based on severity
  Color _getSeverityColor(String severity, AppColorTheme colors) {
    switch (severity.toLowerCase()) {
      case 'high':
        return colors.warning;
      case 'medium':
        return Color(0xFFFF8C00);
      case 'low':
        return Color(0xFF71C4EF);
      default:
        return colors.text200;
    }
  }

  /// Helper method to get icon based on disaster type
  IconData _getDisasterIcon(String type) {
    const IconData flood = IconData(0xf07a3, fontFamily: 'MaterialIcons');
    const IconData tsunami = IconData(0xf07cf, fontFamily: 'MaterialIcons');

    switch (type.toLowerCase()) {
      case 'heavy rain':
        return Icons.thunderstorm_outlined;
      case 'flood':
        return flood;
      case 'fire':
        return Icons.local_fire_department;
      case 'earthquake':
        return Icons.terrain;
      case 'landslide':
        return Icons.landslide;
      case 'tsunami':
        return tsunami;
      case 'haze':
        return Icons.air;
      case 'typhoon':
        return Icons.cyclone;
      case 'weather':
        return Icons.thunderstorm;
      default:
        return Icons.warning_amber_rounded;
    }
  }

  /// Builds the scrollable list of disasters
  Widget _buildDisastersList(AppColorTheme colors) {
    return Consumer<DisasterService>(
      builder: (context, disasterService, child) {
        return RefreshIndicator(
          onRefresh: () =>
              disasterService.fetchRecentDisasters(onlyHappening: true),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                if (disasterService.isLoading)
                  const Center(
                    child: CircularProgressIndicator(),
                  )
                else if (disasterService.error != null)
                  Center(
                    child: Text(
                      'Error: ${disasterService.error}',
                      style: TextStyle(color: colors.warning),
                    ),
                  )
                else if (disasterService.happeningDisasters.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(_spacingMedium),
                      child: Text(
                        'No active disasters at the moment',
                        style: TextStyle(color: colors.text200),
                      ),
                    ),
                  )
                else
                  // Inside _buildDisastersList method, update the ListView.builder
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    // Limit to maximum 3 items
                    itemCount: disasterService.happeningDisasters.length > 3
                        ? 3
                        : disasterService.happeningDisasters.length,
                    itemBuilder: (context, index) {
                      final disaster =
                          disasterService.happeningDisasters[index];
                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                AlertDetailScreen(disasterId: disaster.id),
                          ),
                        ),
                        child: _buildDisasterCard(
                          description: disaster.description,
                          severity: disaster.severity,
                          location: disaster.location,
                          time: disaster.formattedTime,
                          disasterType: disaster.disasterType,
                          colors: colors,
                        ),
                      );
                    },
                  ),
                // Pull to refresh hint text
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.arrow_downward,
                        size: 16,
                        color: colors.text200,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Pull down to refresh',
                        style: TextStyle(
                          color: colors.text200,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Navigates to a new screen
  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}
