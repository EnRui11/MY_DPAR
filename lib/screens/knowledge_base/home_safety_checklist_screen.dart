import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';

/// Represents a single checklist item with a title and completion status.
class ChecklistItem {
  final String title;
  bool isChecked;

  ChecklistItem({required this.title, this.isChecked = false});
}

/// Represents a section of the checklist with a title, icon, and items.
class ChecklistSection {
  final String title;
  final IconData icon;
  final List<ChecklistItem> items;
  bool isExpanded;

  ChecklistSection({
    required this.title,
    required this.icon,
    required this.items,
    this.isExpanded = false,
  });
}

/// A screen displaying a home safety checklist tailored for Malaysia.
class HomeSafetyChecklistScreen extends StatefulWidget {
  const HomeSafetyChecklistScreen({super.key});

  @override
  State<HomeSafetyChecklistScreen> createState() => _HomeSafetyChecklistScreenState();
}

class _HomeSafetyChecklistScreenState extends State<HomeSafetyChecklistScreen> {
  // Constants for consistent spacing and padding
  static const double _paddingValue = 16.0;
  static const double _spacingSmall = 8.0;
  static const double _spacingMedium = 12.0;
  static const double _spacingLarge = 24.0;

  late List<ChecklistSection> _sections;
  int _totalItems = 0;
  int _completedItems = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeSections();
    _loadProgress();
  }

  /// Initializes checklist sections with items tailored for Malaysia.
  void _initializeSections() {
    _sections = [
      ChecklistSection(
        title: 'Fire Prevention',
        icon: Icons.local_fire_department,
        items: [
          ChecklistItem(title: 'Avoid overloading electrical circuits with multiple devices'),
          ChecklistItem(title: 'Install and test smoke alarms monthly'),
          ChecklistItem(title: 'Keep Class B or K fire extinguishers in kitchen and living areas'),
          ChecklistItem(title: 'Plan and practice a fire escape route with family'),
          ChecklistItem(title: 'Store flammable items (e.g., gas cylinders) safely away from heat'),
          // Removed smoking-related items as smoking indoors is less common in Malaysia
          ChecklistItem(title: 'Never smoke in bed or when drowsy'),
          ChecklistItem(title: 'Use stable ashtrays and douse cigarettes with water'),
        ],
      ),
      ChecklistSection(
        title: 'Carbon Monoxide & Gas Safety',
        icon: Icons.gas_meter_outlined,
        items: [
          ChecklistItem(title: 'Install carbon monoxide and gas leak detectors'),
          ChecklistItem(title: 'Inspect gas stoves and heaters annually'),
          ChecklistItem(title: 'Never use gas stoves for heating during power outages'),
          ChecklistItem(title: 'Ventilate kitchens when using gas appliances'),
          // Adjusted for Malaysia where gas leaks from LPG are a bigger concern than CO from cars
          ChecklistItem(title: 'Never run vehicles with fueled engines in closed spaces'),
        ],
      ),
      ChecklistSection(
        title: 'Kitchen Safety',
        icon: Icons.kitchen,
        items: [
          ChecklistItem(title: 'Never leave cooking unattended, especially with oil'),
          ChecklistItem(title: 'Turn pot handles inward to prevent spills'),
          ChecklistItem(title: 'Keep sharp knives in a rack or guarded separately'),
          ChecklistItem(title: 'Use non-slip mats near the sink and stove'),
          ChecklistItem(title: 'Check gas hoses and regulators regularly'),
        ],
      ),
      ChecklistSection(
        title: 'Bathroom Safety',
        icon: Icons.bathroom,
        items: [
          ChecklistItem(title: 'Use non-slip mats or decals in wet areas'),
          ChecklistItem(title: 'Keep floors dry and clean spills immediately'),
          ChecklistItem(title: 'Install GFCI outlets near water sources'),
          ChecklistItem(title: 'Set water heater to 48°C (120°F) to prevent burns'),
          ChecklistItem(title: 'Ensure proper ventilation to reduce mould growth'),
        ],
      ),
      ChecklistSection(
        title: 'Burglar-Proofing',
        icon: Icons.security,
        items: [
          ChecklistItem(title: 'Install ANSI Grade 1 deadbolts on all doors'),
          ChecklistItem(title: 'Secure windows with locks and grilles'),
          ChecklistItem(title: 'Use motion sensor lights around the perimeter'),
          ChecklistItem(title: 'Join a local "Rukun Tetangga" or neighborhood watch'),
          ChecklistItem(title: 'Install CCTV or a video doorbell'),
        ],
      ),
      ChecklistSection(
        title: 'Monsoon & Flood Safety',
        icon: Icons.water,
        items: [
          ChecklistItem(title: 'Elevate electrical appliances above flood levels'),
          ChecklistItem(title: 'Clear drains and gutters before monsoon season'),
          ChecklistItem(title: 'Prepare an emergency kit with food and water'),
          ChecklistItem(title: 'Know your local flood evacuation route'),
        ],
      ),
    ];

    _totalItems = _sections.fold(0, (sum, section) => sum + section.items.length);
  }

  /// Loads saved progress from SharedPreferences and updates counts.
  Future<void> _loadProgress() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      _completedItems = 0;
      for (var section in _sections) {
        for (var item in section.items) {
          final key = '${section.title}_${item.title}';
          item.isChecked = prefs.getBool(key) ?? false;
          if (item.isChecked) _completedItems++;
        }
      }
      _isLoading = false;
    });
  }

  /// Saves the progress of a checklist item to SharedPreferences.
  Future<void> _saveProgress(ChecklistItem item, ChecklistSection section) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${section.title}_${item.title}';
    await prefs.setBool(key, item.isChecked);
  }

  /// Resets all checklist items to their default unchecked state with confirmation.
  Future<void> _resetToDefaults() async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Confirmation'),
        content: const Text('Are you sure you want to reset all progress? This will clear all your checked items.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (shouldReset == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await _loadProgress();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Reset all progress'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(_paddingValue),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.currentTheme;

    return Scaffold(
      backgroundColor: colors.bg200,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(colors),
            if (!_isLoading) _buildProgressBar(colors),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: colors.accent200))
                  : ListView.builder(
                padding: const EdgeInsets.all(_paddingValue),
                itemCount: _sections.length,
                itemBuilder: (context, index) => _buildSection(_sections[index], colors),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the header with back button, title, and reset button.
  Widget _buildHeader(AppColorTheme colors) => Container(
    padding: const EdgeInsets.symmetric(horizontal: _paddingValue, vertical: _paddingValue - 4),
    decoration: BoxDecoration(
      color: colors.bg100.withOpacity(0.7),
      border: Border(bottom: BorderSide(color: colors.bg300.withOpacity(0.2))),
    ),
    child: Row(
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back, color: colors.primary300),
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: _spacingSmall),
        Expanded(
          child: Text(
            'Home Safety Checklist',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colors.primary300),
          ),
        ),
        IconButton(
          icon: Icon(Icons.restore, color: colors.primary300),
          onPressed: _resetToDefaults,
          tooltip: 'Reset to defaults',
        ),
      ],
    ),
  );

  /// Builds the progress bar showing overall completion status.
  Widget _buildProgressBar(AppColorTheme colors) => Container(
    margin: const EdgeInsets.all(_paddingValue),
    padding: const EdgeInsets.all(_paddingValue),
    decoration: _buildCardDecoration(colors),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your Progress',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.primary300),
            ),
            Text(
              '$_completedItems/$_totalItems Complete',
              style: TextStyle(color: colors.accent200, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: _spacingMedium),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _totalItems > 0 ? (_completedItems / _totalItems).toDouble() : 0.0,
            backgroundColor: colors.primary100,
            valueColor: AlwaysStoppedAnimation<Color>(colors.accent200),
            minHeight: 8,
          ),
        ),
      ],
    ),
  );

  /// Builds a collapsible section with checklist items and progress.
  Widget _buildSection(ChecklistSection section, AppColorTheme colors) {
    final sectionTotal = section.items.length;
    final sectionCompleted = section.items.where((item) => item.isChecked).length;
    final progress = sectionTotal > 0 ? (sectionCompleted / sectionTotal).toDouble() : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: _spacingMedium),
      decoration: _buildCardDecoration(colors),
      child: Column(
        children: [
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              leading: Icon(section.icon, color: colors.accent200),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.title,
                    style: TextStyle(color: colors.primary300, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: _spacingSmall),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: colors.bg300.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress == 1.0 ? colors.accent200 : colors.accent200.withOpacity(0.5),
                      ),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
              children: section.items.map((item) => _buildChecklistItem(item, section, colors)).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(_paddingValue, 0, _paddingValue, _spacingSmall),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '$sectionCompleted/$sectionTotal items completed',
                  style: TextStyle(color: colors.text200.withOpacity(0.7), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a single checklist item with a tappable checkbox and description.
  Widget _buildChecklistItem(ChecklistItem item, ChecklistSection section, AppColorTheme colors) => InkWell(
    onTap: () {
      setState(() {
        item.isChecked = !item.isChecked; // Toggle the state
        _completedItems += item.isChecked ? 1 : -1; // Update count in memory
        _saveProgress(item, section);
      });
    },
    child: Padding(
      padding: const EdgeInsets.fromLTRB(_paddingValue, 0, _paddingValue, _spacingMedium),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: item.isChecked,
              activeColor: colors.accent200,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              onChanged: (bool? value) {
                setState(() {
                  item.isChecked = value ?? false;
                  _completedItems += item.isChecked ? 1 : -1; // Update count in memory
                  _saveProgress(item, section);
                });
              },
            ),
          ),
          const SizedBox(width: _spacingMedium),
          Expanded(
            child: Text(
              item.title,
              style: TextStyle(color: colors.text200, fontSize: 14),
            ),
          ),
        ],
      ),
    ),
  );

  /// Returns a reusable card decoration for consistent styling.
  BoxDecoration _buildCardDecoration(AppColorTheme colors) => BoxDecoration(
    color: colors.bg100.withOpacity(0.85),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: colors.accent200.withOpacity(0.1)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );
}