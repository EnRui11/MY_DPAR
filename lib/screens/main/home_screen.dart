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
import 'package:mydpar/screens/disaster_infomation/disaster_detail_screen.dart';
import 'package:mydpar/services/bottom_nav_service.dart';
import 'package:mydpar/localization/app_localizations.dart';
import 'package:mydpar/widgets/bottom_nav_bar.dart';
import 'package:mydpar/screens/main/map_screen.dart';
import 'package:mydpar/screens/main/community_screen.dart';
import 'package:mydpar/screens/main/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DisasterService>(context, listen: false)
          .fetchRecentDisasters(onlyHappening: true);
      Provider.of<NavigationService>(context, listen: false).changeIndex(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final AppColorTheme colors = themeProvider.currentTheme;
    final AppLocalizations localize = AppLocalizations.of(context)!;
    final navigationService = Provider.of<NavigationService>(context);

    return Scaffold(
      backgroundColor: colors.bg200,
      body: SafeArea(
        child: Stack(
          children: [
            _buildContent(context, colors, localize),
            _buildHeader(colors, localize),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        onTap: (index) {
          if (index != 0) { // Only navigate if not already on home screen
            navigationService.changeIndex(index);
            _navigateToScreen(index);
          }
        },
      ),
    );
  }

  /// Builds the header with gradient and welcome message
  Widget _buildHeader(AppColorTheme colors, AppLocalizations localize) =>
      Container(
        width: double.infinity,
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
                localize.translate('hello_user', {
                  'name': userService.lastName ?? localize.translate('user')
                }),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colors.bg100,
                ),
              ),
              const SizedBox(height: _spacingSmall),
              Text(
                localize.translate('welcome_to_app'),
                style: TextStyle(fontSize: 16, color: colors.primary100),
              ),
              Text(
                localize.translate('app_description'),
                style: TextStyle(fontSize: 16, color: colors.primary100),
              ),
            ],
          ),
        ),
      );

  /// Builds the scrollable main content area
  Widget _buildContent(BuildContext context, AppColorTheme colors,
          AppLocalizations localize) =>
      SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            _paddingValue, 120, _paddingValue, _paddingValue),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 64),
            _buildQuickActions(context, colors, localize),
            const SizedBox(height: _spacingLarge),
            _buildSOSButton(context, colors, localize),
            const SizedBox(height: _spacingLarge),
            _buildRecentDisastersSection(context, colors, localize),
            const SizedBox(height: 80), // Space for bottom nav
          ],
        ),
      );

  /// Builds the animated SOS emergency button
  Widget _buildSOSButton(BuildContext context, AppColorTheme colors,
          AppLocalizations localize) =>
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
                    localize.translate('sos_emergency'),
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
  Widget _buildQuickActions(BuildContext context, AppColorTheme colors,
          AppLocalizations localize) =>
      Row(
        children: [
          Expanded(
            child: _buildActionCard(
              icon: Icons.location_on_outlined,
              label: localize.translate('report_disaster'),
              colors: colors,
              onTap: () => _navigateTo(context, const ReportDisasterScreen()),
            ),
          ),
          const SizedBox(width: _spacingMedium),
          Expanded(
            child: _buildActionCard(
              icon: Icons.book_outlined,
              label: localize.translate('knowledge_base'),
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
  Widget _buildRecentDisastersSection(BuildContext context,
          AppColorTheme colors, AppLocalizations localize) =>
      Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  localize.translate('disasters_happening_now'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.primary300,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () => _navigateTo(context, const DisastersScreen()),
                child: Text(
                  localize.translate('view_all'),
                  style: TextStyle(
                    color: colors.accent200,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: _spacingMedium),
          _buildDisastersList(colors, localize),
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
    required AppLocalizations localize,
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
                        localize.translate(
                            'disaster_type_${disasterType.toLowerCase()}'),
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
                          localize
                              .translate('severity_${severity.toLowerCase()}'),
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
                        _getLocalizedTime(time, localize),
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

  /// Builds the scrollable list of disasters
  Widget _buildDisastersList(AppColorTheme colors, AppLocalizations localize) {
    return Consumer<DisasterService>(
      builder: (context, disasterService, child) {
        return RefreshIndicator(
          onRefresh: () async {
            // Show a snackbar to indicate refresh is happening
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(localize.translate('refreshing_disaster_info')),
                duration: Duration(seconds: 1),
                backgroundColor: colors.accent200,
              ),
            );
            return await disasterService.fetchRecentDisasters(
                onlyHappening: true);
          },
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
                      '${localize.translate('error')}: ${disasterService.error}',
                      style: TextStyle(color: colors.warning),
                    ),
                  )
                else if (disasterService.happeningDisasters.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(_spacingLarge),
                      child: Text(
                        localize.translate('no_active_disasters'),
                        style: TextStyle(color: colors.text200),
                      ),
                    ),
                  )
                else
                  Column(
                    children: [
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: disasterService.happeningDisasters.length > 3
                            ? 3
                            : disasterService.happeningDisasters.length,
                        itemBuilder: (context, index) {
                          final disaster =
                              disasterService.happeningDisasters[index];
                          return GestureDetector(
                            onTap: () =>
                                _navigateToDisasterDetail(context, disaster.id),
                            child: _buildDisasterCard(
                              description: disaster.description,
                              severity: disaster.severity,
                              location: disaster.location,
                              time: disaster.formattedTime,
                              disasterType: disaster.disasterType,
                              colors: colors,
                              localize: localize,
                            ),
                          );
                        },
                      ),
                      if (disasterService.happeningDisasters.length > 3)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.info_outline,
                                  size: 16, color: colors.text200),
                              const SizedBox(width: 8),
                              Text(
                                localize.translate('showing_x_of_y_disasters', {
                                  'shown': '3',
                                  'total': disasterService
                                      .happeningDisasters.length
                                      .toString()
                                }),
                                style: TextStyle(
                                  color: colors.text200,
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    localize.translate('pull_to_refresh'),
                    style: TextStyle(
                      color: colors.text200,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Navigate to disaster detail screen
  void _navigateToDisasterDetail(BuildContext context, String disasterId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DisasterDetailScreen(disasterId: disasterId),
      ),
    );
  }

  /// Helper method to navigate to a screen
  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  /// Helper method to get color based on severity
  Color _getSeverityColor(String severity, AppColorTheme colors) {
    return DisasterService.getSeverityColor(severity, colors);
  }

  /// Helper method to get icon based on disaster type
  IconData _getDisasterIcon(String type) {
    return DisasterService.getDisasterIcon(type);
  }

  /// Helper method to get localized time string
  String _getLocalizedTime(String time, AppLocalizations localize) {
    if (time.contains('just now')) {
      return localize.translate('time_just_now');
    } else if (time.contains('minute ago')) {
      return localize.translate('time_minute_ago');
    } else if (time.contains('minutes ago')) {
      final minutes = time.split(' ')[0];
      return localize.translate('time_minutes_ago', {'count': minutes});
    } else if (time.contains('hour ago')) {
      return localize.translate('time_hour_ago');
    } else if (time.contains('hours ago')) {
      final hours = time.split(' ')[0];
      return localize.translate('time_hours_ago', {'count': hours});
    } else if (time.contains('day ago')) {
      return localize.translate('time_day_ago');
    } else if (time.contains('days ago')) {
      final days = time.split(' ')[0];
      return localize.translate('time_days_ago', {'count': days});
    } else if (time.contains('month ago')) {
      return localize.translate('time_month_ago');
    } else if (time.contains('months ago')) {
      final months = time.split(' ')[0];
      return localize.translate('time_months_ago', {'count': months});
    } else if (time.contains('year ago')) {
      return localize.translate('time_year_ago');
    } else if (time.contains('years ago')) {
      final years = time.split(' ')[0];
      return localize.translate('time_years_ago', {'count': years});
    }
    return time;
  }

  void _navigateToScreen(int index) {
    Widget screen;
    switch (index) {
      case 1:
        screen = const MapScreen();
        break;
      case 2:
        screen = const CommunityScreen();
        break;
      case 3:
        screen = const ProfileScreen();
        break;
      default:
        return;
    }
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }
}
