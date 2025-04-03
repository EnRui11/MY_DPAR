import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';
import 'package:mydpar/localization/app_localizations.dart';

// Move constants to file level so they can be accessed by all classes
const double _paddingValue = 16.0;
const double _spacingSmall = 8.0;
const double _spacingMedium = 12.0;
const double _spacingLarge = 24.0;

class ChecklistItem {
  final String titleKey; // Changed to use localization key
  bool isChecked;

  ChecklistItem({required this.titleKey, this.isChecked = false});
}

class ChecklistSection {
  final String titleKey; // Changed to use localization key
  final IconData icon;
  final List<ChecklistItem> items;
  bool isExpanded;

  ChecklistSection({
    required this.titleKey,
    required this.icon,
    required this.items,
    this.isExpanded = false,
  });
}

class HomeSafetyChecklistScreen extends StatefulWidget {
  const HomeSafetyChecklistScreen({super.key});

  @override
  State<HomeSafetyChecklistScreen> createState() =>
      _HomeSafetyChecklistScreenState();
}

class _HomeSafetyChecklistScreenState extends State<HomeSafetyChecklistScreen> {
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

  void _initializeSections() {
    _sections = [
      ChecklistSection(
        titleKey: 'fire_prevention',
        icon: Icons.local_fire_department,
        items: [
          ChecklistItem(titleKey: 'avoid_overloading_circuits'),
          ChecklistItem(titleKey: 'install_smoke_alarms'),
          ChecklistItem(titleKey: 'keep_fire_extinguishers'),
          ChecklistItem(titleKey: 'plan_fire_escape'),
          ChecklistItem(titleKey: 'store_flammable_items'),
          ChecklistItem(titleKey: 'never_smoke_in_bed'),
          ChecklistItem(titleKey: 'use_stable_ashtrays'),
        ],
      ),
      ChecklistSection(
        titleKey: 'carbon_monoxide_gas_safety',
        icon: Icons.gas_meter_outlined,
        items: [
          ChecklistItem(titleKey: 'install_co_detectors'),
          ChecklistItem(titleKey: 'inspect_gas_appliances'),
          ChecklistItem(titleKey: 'no_gas_stoves_for_heating'),
          ChecklistItem(titleKey: 'ventilate_kitchens'),
          ChecklistItem(titleKey: 'no_vehicles_in_closed_spaces'),
        ],
      ),
      ChecklistSection(
        titleKey: 'kitchen_safety',
        icon: Icons.kitchen,
        items: [
          ChecklistItem(titleKey: 'never_leave_cooking'),
          ChecklistItem(titleKey: 'turn_pot_handles'),
          ChecklistItem(titleKey: 'keep_knives_safe'),
          ChecklistItem(titleKey: 'use_non_slip_mats'),
          ChecklistItem(titleKey: 'check_gas_hoses'),
        ],
      ),
      ChecklistSection(
        titleKey: 'bathroom_safety',
        icon: Icons.bathroom,
        items: [
          ChecklistItem(titleKey: 'use_non_slip_mats_bathroom'),
          ChecklistItem(titleKey: 'keep_floors_dry'),
          ChecklistItem(titleKey: 'install_gfci_outlets'),
          ChecklistItem(titleKey: 'set_water_heater'),
          ChecklistItem(titleKey: 'ensure_ventilation'),
        ],
      ),
      ChecklistSection(
        titleKey: 'burglar_proofing',
        icon: Icons.security,
        items: [
          ChecklistItem(titleKey: 'install_deadbolts'),
          ChecklistItem(titleKey: 'secure_windows'),
          ChecklistItem(titleKey: 'use_motion_lights'),
          ChecklistItem(titleKey: 'join_neighborhood_watch'),
          ChecklistItem(titleKey: 'install_cctv'),
        ],
      ),
      ChecklistSection(
        titleKey: 'monsoon_flood_safety',
        icon: Icons.water,
        items: [
          ChecklistItem(titleKey: 'elevate_appliances'),
          ChecklistItem(titleKey: 'clear_drains'),
          ChecklistItem(titleKey: 'prepare_emergency_kit'),
          ChecklistItem(titleKey: 'know_evacuation_route'),
        ],
      ),
    ];

    _totalItems =
        _sections.fold(0, (sum, section) => sum + section.items.length);
  }

  Future<void> _loadProgress() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      _completedItems = 0;
      for (var section in _sections) {
        for (var item in section.items) {
          final key = '${section.titleKey}_${item.titleKey}';
          item.isChecked = prefs.getBool(key) ?? false;
          if (item.isChecked) _completedItems++;
        }
      }
      _isLoading = false;
    });
  }

  Future<void> _saveProgress(
      ChecklistItem item, ChecklistSection section) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${section.titleKey}_${item.titleKey}';
    await prefs.setBool(key, item.isChecked);
  }

  Future<void> _resetToDefaults() async {
    final l = AppLocalizations.of(context);
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.translate('reset_confirmation')),
        content: Text(l.translate('reset_confirmation_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.translate('reset')),
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
            content: Text(l.translate('reset_progress_message')),
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
    final colors = Provider.of<ThemeProvider>(context).currentTheme;
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: colors.bg200,
      body: SafeArea(
        child: Column(
          children: [
            _Header(colors: colors, onReset: _resetToDefaults),
            if (!_isLoading)
              _ProgressBar(
                  colors: colors,
                  completedItems: _completedItems,
                  totalItems: _totalItems),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: colors.accent200))
                  : ListView.builder(
                      padding: const EdgeInsets.all(_paddingValue),
                      itemCount: _sections.length,
                      itemBuilder: (context, index) => _Section(
                        section: _sections[index],
                        colors: colors,
                        onItemChanged: (item) =>
                            _saveProgress(item, _sections[index]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final AppColorTheme colors;
  final VoidCallback onReset;

  const _Header({required this.colors, required this.onReset});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: _paddingValue, vertical: _paddingValue - 4),
      decoration: _buildCardDecoration(colors),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: colors.primary300),
            onPressed: () => Navigator.pop(context),
            tooltip: l.translate('back'),
          ),
          const SizedBox(width: _spacingSmall),
          Expanded(
            child: Text(
              l.translate('home_safety_checklist'),
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colors.primary300),
            ),
          ),
          IconButton(
            icon: Icon(Icons.restore, color: colors.primary300),
            onPressed: onReset,
            tooltip: l.translate('reset_to_defaults'),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final AppColorTheme colors;
  final int completedItems;
  final int totalItems;

  const _ProgressBar(
      {required this.colors,
      required this.completedItems,
      required this.totalItems});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
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
                l.translate('your_progress'),
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.primary300),
              ),
              Text(
                l.translate('progress_status', {
                  'completed': completedItems.toString(),
                  'total': totalItems.toString()
                }),
                style: TextStyle(
                    color: colors.accent200, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: _spacingMedium),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: totalItems > 0
                  ? (completedItems / totalItems).toDouble()
                  : 0.0,
              backgroundColor: colors.primary100,
              valueColor: AlwaysStoppedAnimation<Color>(colors.accent200),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatefulWidget {
  final ChecklistSection section;
  final AppColorTheme colors;
  final Function(ChecklistItem) onItemChanged;

  const _Section(
      {required this.section,
      required this.colors,
      required this.onItemChanged});

  @override
  State<_Section> createState() => _SectionState();
}

class _SectionState extends State<_Section> {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final sectionTotal = widget.section.items.length;
    final sectionCompleted =
        widget.section.items.where((item) => item.isChecked).length;
    final progress =
        sectionTotal > 0 ? (sectionCompleted / sectionTotal).toDouble() : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: _spacingMedium),
      decoration: _buildCardDecoration(widget.colors),
      child: Column(
        children: [
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              leading:
                  Icon(widget.section.icon, color: widget.colors.accent200),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.translate(widget.section.titleKey),
                    style: TextStyle(
                        color: widget.colors.primary300,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: _spacingSmall),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: widget.colors.bg300.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress == 1.0
                            ? widget.colors.accent200
                            : widget.colors.accent200.withOpacity(0.5),
                      ),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
              children: widget.section.items
                  .map((item) => _ChecklistItem(
                        item: item,
                        colors: widget.colors,
                        onChanged: (value) {
                          setState(() {
                            item.isChecked = value;
                            widget.onItemChanged(item);
                          });
                        },
                      ))
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
                  l.translate('section_progress', {
                    'completed': sectionCompleted.toString(),
                    'total': sectionTotal.toString(),
                  }),
                  style: TextStyle(
                      color: widget.colors.text200.withOpacity(0.7),
                      fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  final ChecklistItem item;
  final AppColorTheme colors;
  final ValueChanged<bool> onChanged;

  const _ChecklistItem(
      {required this.item, required this.colors, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return InkWell(
      onTap: () => onChanged(!item.isChecked),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            _paddingValue, 0, _paddingValue, _spacingMedium),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: item.isChecked,
                activeColor: colors.accent200,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
                onChanged: (bool? value) => onChanged(value ?? false),
              ),
            ),
            const SizedBox(width: _spacingMedium),
            Expanded(
              child: Text(
                l.translate(item.titleKey),
                style: TextStyle(color: colors.text200, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
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
