import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';

class EmergencyKitItem {
  final String name;
  bool checked;
  int quantity;

  EmergencyKitItem({
    required this.name,
    this.checked = false,
    this.quantity = 0,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'checked': checked,
        'quantity': quantity,
      };

  factory EmergencyKitItem.fromJson(Map<String, dynamic> json) =>
      EmergencyKitItem(
        name: json['name'] as String,
        checked: json['checked'] as bool,
        quantity: json['quantity'] as int,
      );
}

class EmergencyKitSection {
  final String title;
  final IconData icon;
  final List<EmergencyKitItem> items;

  EmergencyKitSection({
    required this.title,
    required this.icon,
    required this.items,
  });
}

class EmergencyKitScreen extends StatefulWidget {
  const EmergencyKitScreen({super.key});

  @override
  State<EmergencyKitScreen> createState() => _EmergencyKitScreenState();
}

class _EmergencyKitScreenState extends State<EmergencyKitScreen> {
  static const double _paddingValue = 16.0;
  static const double _spacingSmall = 8.0;
  static const double _spacingMedium = 12.0;
  static const double _spacingLarge = 24.0;

  late List<EmergencyKitSection> _sections;
  int _totalItems = 0;
  int _completedItems = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeSections();
    _loadProgress();
  }

  void _initializeSections() {
    _sections = [
      EmergencyKitSection(
        title: 'Basic Emergency Supply Kit',
        icon: Icons.backpack_outlined,
        items: [
          EmergencyKitItem(
              name: 'Water and non-perishable food for several days'),
          EmergencyKitItem(name: 'Extra cell phone battery or charger'),
          EmergencyKitItem(name: 'Battery-powered or hand crank radio'),
          EmergencyKitItem(name: 'Flashlight and extra batteries'),
          EmergencyKitItem(name: 'First aid kit'),
          EmergencyKitItem(name: 'N95 masks (for haze or dust)'),
          EmergencyKitItem(name: 'Whistle to signal for help'),
          EmergencyKitItem(name: 'Moist towelettes and garbage bags'),
          EmergencyKitItem(name: 'Multipurpose tool or wrench'),
          EmergencyKitItem(name: 'Can opener for food'),
          EmergencyKitItem(name: 'Local maps'),
        ],
      ),
      EmergencyKitSection(
        title: 'Additional Items to Consider',
        icon: Icons.add_circle_outline,
        items: [
          EmergencyKitItem(name: 'Prescription medications and glasses'),
          EmergencyKitItem(name: 'Infant formula and diapers'),
          EmergencyKitItem(name: 'Pet food and supplies'),
          EmergencyKitItem(
              name: 'Important family documents (in waterproof bag)'),
          EmergencyKitItem(name: 'Cash and change'),
          EmergencyKitItem(name: 'Emergency contact list and evacuation plan'),
          EmergencyKitItem(name: 'Sleeping bag or warm blanket'),
          EmergencyKitItem(name: 'Complete change of clothing'),
          EmergencyKitItem(name: 'Small fire extinguisher'),
          EmergencyKitItem(name: 'Matches and lighter in waterproof container'),
          EmergencyKitItem(name: 'Personal hygiene items'),
          EmergencyKitItem(name: 'Paper and plastic utensils'),
          EmergencyKitItem(name: 'Rain gear (poncho or umbrella)'),
          EmergencyKitItem(name: 'Mosquito repellent'),
          EmergencyKitItem(name: 'Waterproof bag or container'),
        ],
      ),
    ];

    _updateProgress();
  }

  Future<void> _loadProgress() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();

    for (final section in _sections) {
      for (final item in section.items) {
        final key = '${section.title}_${item.name}';
        item.checked = prefs.getBool(key) ?? false;
        item.quantity = prefs.getInt('${key}_quantity') ?? 0; // Load quantity
      }
    }

    _updateProgress();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    for (final section in _sections) {
      for (final item in section.items) {
        final key = '${section.title}_${item.name}';
        await prefs.setBool(key, item.checked);
        await prefs.setInt('${key}_quantity', item.quantity); // Save quantity
      }
    }
  }

  Future<void> _resetToDefaults() async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Confirmation'),
        content: const Text(
            'Are you sure you want to reset all progress? This will clear all your checked items and quantities.'),
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

  void _updateProgress() {
    _totalItems =
        _sections.fold(0, (sum, section) => sum + section.items.length);
    _completedItems = _sections.fold(
        0,
        (sum, section) =>
            sum + section.items.where((item) => item.checked).length);
    setState(() {});
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
            if (_isLoading)
              Expanded(
                  child: Center(
                      child:
                          CircularProgressIndicator(color: colors.accent200)))
            else
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(_paddingValue),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMaintenanceCard(colors),
                      const SizedBox(height: _spacingLarge),
                      _buildProgressCard(colors),
                      const SizedBox(height: _spacingLarge),
                      ..._sections.map((section) => Column(
                            children: [
                              _buildSectionCard(colors, section),
                              const SizedBox(height: _spacingLarge),
                            ],
                          )),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppColorTheme colors) => Container(
        decoration: BoxDecoration(
          color: colors.bg100.withOpacity(0.7),
          border:
              Border(bottom: BorderSide(color: colors.bg300.withOpacity(0.2))),
        ),
        padding: const EdgeInsets.symmetric(
            horizontal: _paddingValue, vertical: _paddingValue - 4),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: colors.primary300),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: _spacingSmall),
            Expanded(
              child: Text(
                'Emergency Kit Checklist',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colors.primary300),
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

  Widget _buildProgressCard(AppColorTheme colors) => Container(
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
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colors.primary300),
                ),
                Text(
                  '$_completedItems/$_totalItems Complete',
                  style: TextStyle(
                      color: colors.accent200, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: _spacingMedium),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _totalItems > 0
                    ? (_completedItems / _totalItems).toDouble()
                    : 0.0,
                backgroundColor: colors.primary100,
                valueColor: AlwaysStoppedAnimation<Color>(colors.accent200),
                minHeight: 8,
              ),
            ),
          ],
        ),
      );

  Widget _buildSectionCard(AppColorTheme colors, EmergencyKitSection section) {
    final sectionTotal = section.items.length;
    final sectionCompleted = section.items.where((item) => item.checked).length;
    final progress =
        sectionTotal > 0 ? (sectionCompleted / sectionTotal).toDouble() : 0.0;

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
                    style: TextStyle(
                        color: colors.primary300, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: _spacingSmall),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: colors.bg300.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress == 1.0
                            ? colors.accent200
                            : colors.accent200.withOpacity(0.5),
                      ),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
              children: section.items
                  .map((item) => _buildChecklistItem(colors, item, section))
                  .toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                _paddingValue, 0, _paddingValue, _spacingSmall),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '$sectionCompleted/$sectionTotal items completed',
                  style: TextStyle(
                      color: colors.text200.withOpacity(0.7), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceCard(AppColorTheme colors) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colors.accent200, colors.accent100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(_paddingValue),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: colors.bg100, size: 28),
                const SizedBox(width: _spacingMedium),
                Text(
                  'Essential Kit Maintenance',
                  style: TextStyle(
                      color: colors.bg100,
                      fontSize: 18,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: _spacingLarge),
            Container(
              padding: const EdgeInsets.all(_paddingValue),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildMaintenanceItem(colors, Icons.calendar_today,
                      'Check and replace items every 6 months'),
                  _buildMaintenanceItem(colors, Icons.battery_alert,
                      'Test all battery-powered devices regularly'),
                  _buildMaintenanceItem(colors, Icons.water_drop,
                      'Store in waterproof containers in a dry place'),
                  _buildMaintenanceItem(colors, Icons.location_on,
                      'Keep in an easily accessible location'),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildMaintenanceItem(
          AppColorTheme colors, IconData icon, String text) =>
      Padding(
        padding: const EdgeInsets.only(bottom: _spacingSmall),
        child: Row(
          children: [
            Icon(icon, color: colors.bg100, size: 20),
            const SizedBox(width: _spacingMedium),
            Expanded(child: Text(text, style: TextStyle(color: colors.bg100))),
          ],
        ),
      );

  Widget _buildChecklistItem(AppColorTheme colors, EmergencyKitItem item,
      EmergencyKitSection section) {
    final controller = TextEditingController(
        text: item.quantity > 0 ? item.quantity.toString() : '');
    return InkWell(
      onTap: () {
        setState(() {
          item.checked = !item.checked;
          if (!item.checked) {
            item.quantity = 0;
            controller.text = '';
          }
          _updateProgress();
          _saveProgress();
        });
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            _paddingValue, _spacingSmall, _paddingValue, _spacingSmall),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: item.checked,
                activeColor: colors.accent200,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
                onChanged: (bool? value) {
                  setState(() {
                    item.checked = value ?? false;
                    if (!item.checked) {
                      item.quantity = 0;
                      controller.text = '';
                    }
                    _updateProgress();
                    _saveProgress();
                  });
                },
              ),
            ),
            const SizedBox(width: _spacingMedium),
            Expanded(
              child: Text(
                item.name,
                style: TextStyle(
                  color: colors.text200,
                  fontSize: 14,
                  decoration: item.checked ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            SizedBox(
              width: 60,
              child: TextField(
                enabled: item.checked,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  hintText: 'Qty',
                  hintStyle: TextStyle(color: colors.bg300),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colors.bg300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colors.bg300),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: colors.bg300.withOpacity(0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colors.accent200),
                  ),
                ),
                controller: controller,
                onChanged: (value) {
                  setState(() {
                    item.quantity = (int.tryParse(value) ?? 0).clamp(0, 999);
                    controller.text = item.quantity.toString();
                    _saveProgress();
                  });
                },
                onTap: () {
                  if (!item.checked) {
                    setState(() {
                      item.checked = true;
                      _updateProgress();
                      _saveProgress();
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

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
