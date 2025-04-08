import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';
import 'package:mydpar/localization/app_localizations.dart';
import 'package:mydpar/services/user_information_service.dart';
import 'package:mydpar/screens/officer/widgets/officer_nav_bar.dart';

class OfficerDashboardScreen extends StatefulWidget {
  const OfficerDashboardScreen({Key? key}) : super(key: key);

  @override
  State<OfficerDashboardScreen> createState() => _OfficerDashboardScreenState();
}

class _OfficerDashboardScreenState extends State<OfficerDashboardScreen> {
  static const double _padding = 16.0;
  static const double _spacing = 24.0;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.currentTheme;

    return Scaffold(
      backgroundColor: colors.bg200,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(_padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: _spacing),
              _buildHeader(colors),
              const SizedBox(height: _spacing),
              _buildSOSSection(colors),
              const SizedBox(height: _spacing),
              _buildDisasterReportsSection(colors),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(colors),
    );
  }

  Widget _buildHeader(AppColorTheme colors) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, Officer',
            style: TextStyle(
              color: colors.primary300,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Disaster Response Control Center',
            style: TextStyle(
              color: colors.text200,
              fontSize: 16,
            ),
          ),
        ],
      );

  Widget _buildSOSSection(AppColorTheme colors) => Container(
        padding: const EdgeInsets.all(_padding),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFFF3D3D),
              const Color(0xFFFF8080),
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
                    const Icon(Icons.warning_amber_rounded,
                        color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'Active SOS',
                      style: TextStyle(
                        color: colors.bg100,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Text(
                  '2',
                  style: TextStyle(
                    color: colors.bg100,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSOSCard(
              'Medical Emergency',
              'Taman Meru, Block A',
              '2 min ago',
              colors,
            ),
            const SizedBox(height: 12),
            _buildSOSCard(
              'Trapped in Building',
              'Jalan Kebun, Shah Alam',
              '5 min ago',
              colors,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.bg100,
                  foregroundColor: const Color(0xFFFF3D3D),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('View All SOS'),
              ),
            ),
          ],
        ),
      );

  Widget _buildSOSCard(
    String title,
    String location,
    String time,
    AppColorTheme colors,
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
                Text(
                  title,
                  style: TextStyle(
                    color: colors.bg100,
                    fontWeight: FontWeight.w500,
                  ),
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
          ],
        ),
      );

  Widget _buildDisasterReportsSection(AppColorTheme colors) => Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Disaster Reports',
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
                  style: TextStyle(color: colors.accent200),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDisasterCard(
            'Flash Flood',
            'Jalan Meru, Klang',
            '5 minutes ago',
            Icons.water_drop,
            'High',
            const Color(0xFFFF3D3D),
            colors,
          ),
          const SizedBox(height: 12),
          _buildDisasterCard(
            'Landslide',
            'Bukit Antarabangsa',
            '15 minutes ago',
            Icons.landscape,
            'Medium',
            const Color(0xFFFF8C00),
            colors,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: const Text('Add New Disaster Report'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accent200,
                foregroundColor: colors.bg100,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );

  Widget _buildDisasterCard(
    String title,
    String location,
    String time,
    IconData icon,
    String severity,
    Color severityColor,
    AppColorTheme colors,
  ) =>
      Container(
        padding: const EdgeInsets.all(_padding),
        decoration: BoxDecoration(
          color: colors.bg100.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.bg300.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, color: severityColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: TextStyle(
                        color: colors.primary300,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: severityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    severity,
                    style: TextStyle(
                      color: severityColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              location,
              style: TextStyle(color: colors.text200, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  time,
                  style: TextStyle(color: colors.text200.withOpacity(0.7), fontSize: 12),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'View Details →',
                    style: TextStyle(
                      color: colors.accent200,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  // Replace the _buildBottomNavigation method with:
  Widget _buildBottomNavigation(AppColorTheme colors) => const OfficerNavBar();
}