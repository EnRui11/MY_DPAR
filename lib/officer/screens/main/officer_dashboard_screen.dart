import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';
import 'package:mydpar/localization/app_localizations.dart';
import 'package:mydpar/services/user_information_service.dart';
import 'package:mydpar/services/sos_alert_service.dart';
import 'package:mydpar/services/disaster_information_service.dart';
import 'package:mydpar/officer/screens/disaster_information/officer_all_disasters_screen.dart';
import 'package:mydpar/officer/screens/disaster_information/officer_disaster_detail_screen.dart';

class OfficerDashboardScreen extends StatefulWidget {
  const OfficerDashboardScreen({Key? key}) : super(key: key);

  @override
  State<OfficerDashboardScreen> createState() => _OfficerDashboardScreenState();
}

class _OfficerDashboardScreenState extends State<OfficerDashboardScreen> {
  static const double _padding = 16.0;
  static const double _spacing = 24.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DisasterService>(context, listen: false)
          .fetchDisasters(onlyHappening: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.currentTheme;

    return Scaffold(
      backgroundColor: colors.bg200,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(_padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(colors),
                const SizedBox(height: _spacing),
                _buildSOSSection(colors),
                const SizedBox(height: _spacing),
                _buildDisasterReportsSection(colors),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppColorTheme colors) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Consumer<UserInformationService>(
            builder: (context, userService, _) => Text(
              AppLocalizations.of(context)!.translate('hello_user', {
                'name': userService.lastName ??
                    AppLocalizations.of(context)!.translate('user')
              }),
              style: TextStyle(
                color: colors.primary300,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            AppLocalizations.of(context)!
                .translate('disaster_response_control_center'), // L78
            style: TextStyle(
              color: colors.text200,
              fontSize: 16,
            ),
          ),
        ],
      );

  Widget _buildSOSSection(AppColorTheme colors) {
    final sosService = Provider.of<SOSAlertService>(context);
    final alerts = sosService.activeAlerts;
    final bool hasActiveAlerts = alerts.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(_padding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: hasActiveAlerts
              ? [
                  const Color(0xFFFF3D3D),
                  const Color(0xFFFF8080),
                ]
              : [
                  const Color(0xFF4CAF50),
                  const Color(0xFF81C784),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                      );
                    },
                    child: Icon(
                      hasActiveAlerts
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle_outline,
                      key: ValueKey<bool>(hasActiveAlerts),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context)!
                        .translate('active_sos'), // L142
                    style: TextStyle(
                      color: colors.bg100,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  '${sosService.activeAlertsCount}',
                  key: ValueKey<int>(sosService.activeAlertsCount),
                  style: TextStyle(
                    color: colors.bg100,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SizeTransition(
                  sizeFactor: animation,
                  child: child,
                ),
              );
            },
            child: alerts.isEmpty
                ? Container(
                    key: const ValueKey<bool>(false),
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: colors.bg100,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          AppLocalizations.of(context)!
                              .translate('no_active_sos_emergencies'), // L195
                          style: TextStyle(
                            color: colors.bg100,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppLocalizations.of(context)!
                              .translate('situation_under_control'), // L204
                          style: TextStyle(
                            color: colors.bg100.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    key: const ValueKey<bool>(true),
                    children: [
                      ...alerts.take(2).map((alert) => Column(
                            children: [
                              _buildSOSCard(
                                alert['emergencyType'] ?? 'Emergency',
                                alert['address'] ?? 'Location unavailable',
                                _formatTimestamp(alert['alertStartTime']),
                                colors,
                                alert,
                              ),
                              const SizedBox(height: 12),
                            ],
                          )),
                      if (alerts.length > 2)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.translate(
                                    'more_emergencies', {
                                  'count': (alerts.length - 2).toString()
                                }), // L242
                                style: TextStyle(
                                  color: colors.bg100,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final now = DateTime.now();
    final diff = now.difference(timestamp.toDate());

    if (diff.inMinutes < 60) {
      return AppLocalizations.of(context)!.translate(
          'minutes_ago', {'count': diff.inMinutes.toString()}); // L618
    } else if (diff.inHours < 24) {
      return AppLocalizations.of(context)!
          .translate('hours_ago', {'count': diff.inHours.toString()}); // L620
    } else {
      return AppLocalizations.of(context)!
          .translate('days_ago', {'count': diff.inDays.toString()}); // L622
    }
  }

  Widget _buildSOSCard(
    String title,
    String location,
    String time,
    AppColorTheme colors,
    Map<String, dynamic> alert,
  ) =>
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      color: colors.bg100,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      alert['username'] ?? 'Unknown User',
                      style: TextStyle(
                        color: colors.bg100,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Text(
                  time,
                  style: TextStyle(
                    color: colors.bg100.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              location,
              style: TextStyle(
                color: colors.bg100.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      );

  Widget _buildDisasterReportsSection(AppColorTheme colors) {
    final localize = AppLocalizations.of(context)!;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                localize.translate('disaster_reports'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.primary300,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OfficerAllDisastersScreen(),
                  ),
                );
              },
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
        const SizedBox(height: 16),
        _buildOfficerDisastersList(colors, localize),
      ],
    );
  }

  Widget _buildOfficerDisastersList(
      AppColorTheme colors, AppLocalizations localize) {
    return Consumer<DisasterService>(
      builder: (context, disasterService, child) {
        return RefreshIndicator(
          onRefresh: () async {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(localize.translate('refreshing_disaster_info')),
                duration: Duration(seconds: 1),
                backgroundColor: colors.accent200,
              ),
            );
            return await disasterService.fetchDisasters(onlyHappening: false);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                if (disasterService.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (disasterService.error != null)
                  Center(
                    child: Text(
                      '${localize.translate('error')}: ${disasterService.error}',
                      style: TextStyle(color: colors.warning),
                    ),
                  )
                else if (disasterService.disasters.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
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
                        itemCount: disasterService.disasters.length > 3
                            ? 3
                            : disasterService.disasters.length,
                        itemBuilder: (context, index) {
                          final disaster = disasterService.disasters[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => OfficerDisasterDetailScreen(
                                    disasterId: disaster.id,
                                  ),
                                ),
                              );
                            },
                            child: _buildOfficerDisasterCard(
                              severity: disaster.severity,
                              location: disaster.location,
                              timestamp: disaster.timestamp,
                              disasterType: disaster.disasterType,
                              status: disaster.status,
                              colors: colors,
                              localize: localize,
                            ),
                          );
                        },
                      ),
                      if (disasterService.disasters.length > 3)
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
                                  'total': disasterService.disasters.length
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

  Widget _buildOfficerDisasterCard({
    required String severity,
    required String location,
    required Timestamp timestamp,
    required String disasterType,
    required String? status,
    required AppColorTheme colors,
    required AppLocalizations localize,
  }) {
    final time = _formatDisasterTime(timestamp);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colors.bg100.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.bg100.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: DisasterService.getSeverityColor(severity, colors),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              DisasterService.getDisasterIcon(disasterType),
              color: colors.bg100,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: DisasterService.getSeverityColor(
                                      severity, colors)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              localize.translate(
                                  'severity_${severity.toLowerCase()}'),
                              style: TextStyle(
                                color: DisasterService.getSeverityColor(
                                    severity, colors),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (status != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              _getStatusColor(status, colors).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          localize.translate(
                              'status_${status.toLowerCase().replaceAll(' ', '_')}'),
                          style: TextStyle(
                            color: _getStatusColor(status, colors),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
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
                    _buildTimeInfo(timestamp, colors),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInfo(Timestamp timestamp, AppColorTheme colors) {
    final dateTime = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    String timeText;
    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      timeText = years == 1
          ? AppLocalizations.of(context).translate('time_year_ago')
          : AppLocalizations.of(context)
              .translate('time_years_ago')
              .replaceAll('{count}', years.toString());
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      timeText = months == 1
          ? AppLocalizations.of(context).translate('time_month_ago')
          : AppLocalizations.of(context)
              .translate('time_months_ago')
              .replaceAll('{count}', months.toString());
    } else if (difference.inDays > 0) {
      timeText = difference.inDays == 1
          ? AppLocalizations.of(context).translate('time_day_ago')
          : AppLocalizations.of(context)
              .translate('time_days_ago')
              .replaceAll('{count}', difference.inDays.toString());
    } else if (difference.inHours > 0) {
      timeText = difference.inHours == 1
          ? AppLocalizations.of(context).translate('time_hour_ago')
          : AppLocalizations.of(context)
              .translate('time_hours_ago')
              .replaceAll('{count}', difference.inHours.toString());
    } else if (difference.inMinutes > 0) {
      timeText = difference.inMinutes == 1
          ? AppLocalizations.of(context).translate('time_minute_ago')
          : AppLocalizations.of(context)
              .translate('time_minutes_ago')
              .replaceAll('{count}', difference.inMinutes.toString());
    } else {
      timeText = AppLocalizations.of(context).translate('time_just_now');
    }

    return Row(
      children: [
        Icon(Icons.access_time, color: colors.text200, size: 16),
        const SizedBox(width: 4),
        Text(timeText, style: TextStyle(color: colors.text200, fontSize: 12)),
      ],
    );
  }

  Color _getStatusColor(String status, AppColorTheme colors) {
    switch (status.toLowerCase()) {
      case 'happening':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      case 'false_alarm':
        return Colors.grey;
      default:
        return colors.accent200;
    }
  }

  String _formatDisasterTime(Timestamp timestamp) {
    try {
      final dt = timestamp.toDate();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) {
        return '${diff.inMinutes} min ago';
      } else if (diff.inHours < 24) {
        return '${diff.inHours} hours ago';
      } else {
        return '${diff.inDays} days ago';
      }
    } catch (_) {
      return timestamp.toString();
    }
  }
}
