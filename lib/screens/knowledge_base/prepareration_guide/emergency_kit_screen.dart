import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';
import 'package:mydpar/localization/app_localizations.dart';

class EmergencyKitItem {
  final String nameKey; // Changed to use localization key
  bool checked;
  int quantity;

  EmergencyKitItem({
    required this.nameKey,
    this.checked = false,
    this.quantity = 0,
  });

  Map<String, dynamic> toJson() => {
        'nameKey': nameKey,
        'checked': checked,
        'quantity': quantity,
      };

  factory EmergencyKitItem.fromJson(Map<String, dynamic> json) =>
      EmergencyKitItem(
        nameKey: json['nameKey'] as String,
        checked: json['checked'] as bool,
        quantity: json['quantity'] as int,
      );
}

class EmergencyKitSection {
  final String titleKey; // Changed to use localization key
  final IconData icon;
  final List<EmergencyKitItem> items;

  EmergencyKitSection({
    required this.titleKey,
    required this.icon,
    required this.items,
  });
}

class EmergencyKitScreen extends StatefulWidget {
  const EmergencyKitScreen({super.key});

  static const double paddingValue = 16.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 12.0;
  static const double spacingLarge = 24.0;

  @override
  State<EmergencyKitScreen> createState() => _EmergencyKitScreenState();
}

class _EmergencyKitScreenState extends State<EmergencyKitScreen> {
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
        titleKey: 'basic_emergency_supply_kit',
        icon: Icons.backpack_outlined,
        items: [
          EmergencyKitItem(nameKey: 'water_food'),
          EmergencyKitItem(nameKey: 'phone_battery'),
          EmergencyKitItem(nameKey: 'radio'),
          EmergencyKitItem(nameKey: 'flashlight'),
          EmergencyKitItem(nameKey: 'first_aid_kit'),
          EmergencyKitItem(nameKey: 'n95_masks'),
          EmergencyKitItem(nameKey: 'whistle'),
          EmergencyKitItem(nameKey: 'towelettes_garbage'),
          EmergencyKitItem(nameKey: 'multipurpose_tool'),
          EmergencyKitItem(nameKey: 'can_opener'),
          EmergencyKitItem(nameKey: 'local_maps'),
        ],
      ),
      EmergencyKitSection(
        titleKey: 'additional_items',
        icon: Icons.add_circle_outline,
        items: [
          EmergencyKitItem(nameKey: 'medications_glasses'),
          EmergencyKitItem(nameKey: 'infant_supplies'),
          EmergencyKitItem(nameKey: 'pet_supplies'),
          EmergencyKitItem(nameKey: 'family_documents'),
          EmergencyKitItem(nameKey: 'cash'),
          EmergencyKitItem(nameKey: 'contact_list'),
          EmergencyKitItem(nameKey: 'sleeping_bag'),
          EmergencyKitItem(nameKey: 'clothing'),
          EmergencyKitItem(nameKey: 'fire_extinguisher'),
          EmergencyKitItem(nameKey: 'matches_lighter'),
          EmergencyKitItem(nameKey: 'hygiene_items'),
          EmergencyKitItem(nameKey: 'utensils'),
          EmergencyKitItem(nameKey: 'rain_gear'),
          EmergencyKitItem(nameKey: 'mosquito_repellent'),
          EmergencyKitItem(nameKey: 'waterproof_container'),
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
        final key = '${section.titleKey}_${item.nameKey}';
        item.checked = prefs.getBool(key) ?? false;
        item.quantity = prefs.getInt('${key}_quantity') ?? 0;
      }
    }

    _updateProgress();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    for (final section in _sections) {
      for (final item in section.items) {
        final key = '${section.titleKey}_${item.nameKey}';
        await prefs.setBool(key, item.checked);
        await prefs.setInt('${key}_quantity', item.quantity);
      }
    }
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
            content: Text(l.translate('reset_success')),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(EmergencyKitScreen.paddingValue),
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
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.currentTheme;
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: colors.bg200,
      body: SafeArea(
        child: Column(
          children: [
            _Header(colors: colors),
            if (_isLoading)
              Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: colors.accent200),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(EmergencyKitScreen.paddingValue),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _MaintenanceCard(colors: colors),
                      const SizedBox(height: EmergencyKitScreen.spacingLarge),
                      _ProgressCard(
                        colors: colors,
                        completedItems: _completedItems,
                        totalItems: _totalItems,
                      ),
                      const SizedBox(height: EmergencyKitScreen.spacingLarge),
                      ..._sections.map(
                        (section) => Column(
                          children: [
                            _SectionCard(
                              colors: colors,
                              section: section,
                              onItemChanged: () {
                                _updateProgress();
                                _saveProgress();
                              },
                            ),
                            const SizedBox(height: EmergencyKitScreen.spacingLarge),
                          ],
                        ),
                      ),
                    ],
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

  const _Header({required this.colors});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.bg100.withOpacity(0.7),
        border: Border.all(color: colors.bg300.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: EmergencyKitScreen.paddingValue,
        vertical: EmergencyKitScreen.paddingValue - 4,
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: colors.primary300),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: EmergencyKitScreen.spacingSmall),
          Expanded(
            child: Text(
              l.translate('emergency_kit_checklist'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.primary300,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.restore, color: colors.primary300),
            onPressed: () => context
                .findAncestorStateOfType<_EmergencyKitScreenState>()
                ?._resetToDefaults(),
            tooltip: l.translate('reset_to_defaults'),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final AppColorTheme colors;
  final int completedItems;
  final int totalItems;

  const _ProgressCard({
    required this.colors,
    required this.completedItems,
    required this.totalItems,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(EmergencyKitScreen.paddingValue),
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
                  color: colors.primary300,
                ),
              ),
              Text(
                l.translate('progress_complete',
                    {'completed': completedItems, 'total': totalItems}),
                style: TextStyle(
                  color: colors.accent200,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: EmergencyKitScreen.spacingMedium),
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

class _SectionCard extends StatelessWidget {
  final AppColorTheme colors;
  final EmergencyKitSection section;
  final VoidCallback onItemChanged;

  const _SectionCard({
    required this.colors,
    required this.section,
    required this.onItemChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final sectionTotal = section.items.length;
    final sectionCompleted = section.items.where((item) => item.checked).length;
    final progress =
        sectionTotal > 0 ? (sectionCompleted / sectionTotal).toDouble() : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: EmergencyKitScreen.spacingMedium),
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
                    l.translate(section.titleKey),
                    style: TextStyle(
                      color: colors.primary300,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: EmergencyKitScreen.spacingSmall),
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
                  .map((item) => _ChecklistItem(
                        colors: colors,
                        item: item,
                        sectionTitleKey: section.titleKey,
                        onChanged: onItemChanged,
                      ))
                  .toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              EmergencyKitScreen.paddingValue,
              0,
              EmergencyKitScreen.paddingValue,
              EmergencyKitScreen.spacingSmall,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  l.translate('items_completed',
                      {'completed': sectionCompleted, 'total': sectionTotal}),
                  style: TextStyle(
                    color: colors.text200.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MaintenanceCard extends StatelessWidget {
  final AppColorTheme colors;

  const _MaintenanceCard({required this.colors});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.accent200, colors.accent100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(EmergencyKitScreen.paddingValue),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: colors.bg100, size: 28),
              const SizedBox(width: EmergencyKitScreen.spacingMedium),
              Text(
                l.translate('essential_kit_maintenance'),
                style: TextStyle(
                  color: colors.bg100,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: EmergencyKitScreen.spacingLarge),
          Container(
            padding: const EdgeInsets.all(EmergencyKitScreen.paddingValue),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildMaintenanceItem(colors, Icons.calendar_today,
                    l.translate('check_replace_6_months')),
                _buildMaintenanceItem(
                    colors, Icons.battery_alert, l.translate('test_batteries')),
                _buildMaintenanceItem(
                    colors, Icons.water_drop, l.translate('store_waterproof')),
                _buildMaintenanceItem(
                    colors, Icons.location_on, l.translate('keep_accessible')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceItem(
          AppColorTheme colors, IconData icon, String text) =>
      Padding(
        padding:
            const EdgeInsets.only(bottom: EmergencyKitScreen.spacingSmall),
        child: Row(
          children: [
            Icon(icon, color: colors.bg100, size: 20),
            const SizedBox(width: EmergencyKitScreen.spacingMedium),
            Expanded(
              child: Text(
                text,
                style: TextStyle(color: colors.bg100),
              ),
            ),
          ],
        ),
      );
}

class _ChecklistItem extends StatelessWidget {
  final AppColorTheme colors;
  final EmergencyKitItem item;
  final String sectionTitleKey;
  final VoidCallback onChanged;

  const _ChecklistItem({
    required this.colors,
    required this.item,
    required this.sectionTitleKey,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final controller = TextEditingController(
      text: item.quantity > 0 ? item.quantity.toString() : '',
    );

    return InkWell(
      onTap: () {
        item.checked = !item.checked;
        if (!item.checked) {
          item.quantity = 0;
          controller.text = '';
        }
        onChanged();
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          EmergencyKitScreen.paddingValue,
          EmergencyKitScreen.spacingSmall,
          EmergencyKitScreen.paddingValue,
          EmergencyKitScreen.spacingSmall,
        ),
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
                  item.checked = value ?? false;
                  if (!item.checked) {
                    item.quantity = 0;
                    controller.text = '';
                  }
                  onChanged();
                },
              ),
            ),
            const SizedBox(width: EmergencyKitScreen.spacingMedium),
            Expanded(
              child: Text(
                l.translate(item.nameKey),
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
                  hintText: l.translate('quantity'),
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
                  item.quantity = (int.tryParse(value) ?? 0).clamp(0, 999);
                  controller.text = item.quantity.toString();
                  onChanged();
                },
                onTap: () {
                  if (!item.checked) {
                    item.checked = true;
                    onChanged();
                  }
                },
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
