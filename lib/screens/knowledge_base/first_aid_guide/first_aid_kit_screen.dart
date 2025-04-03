import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';
import 'package:mydpar/localization/app_localizations.dart';

/// Represents an item in the first aid kit with a name, checked status, and quantity.
class FirstAidKitItem {
  final String name;
  bool checked;
  int quantity;

  FirstAidKitItem({
    required this.name,
    this.checked = false,
    this.quantity = 0,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'checked': checked,
    'quantity': quantity,
  };

  factory FirstAidKitItem.fromJson(Map<String, dynamic> json) => FirstAidKitItem(
    name: json['name'] as String,
    checked: json['checked'] as bool,
    quantity: json['quantity'] as int,
  );
}

/// A screen displaying a first aid kit checklist with progress tracking and multi-language support.
class FirstAidKitScreen extends StatefulWidget {
  const FirstAidKitScreen({super.key});

  @override
  State<FirstAidKitScreen> createState() => _FirstAidKitScreenState();
}

class _FirstAidKitScreenState extends State<FirstAidKitScreen> {
  // Constants for consistent spacing and padding
  static const double _paddingValue = 16.0;
  static const double _spacingSmall = 8.0;
  static const double _spacingMedium = 12.0;
  static const double _spacingLarge = 24.0;

  // In the _FirstAidKitScreenState class
  final Map<String, List<FirstAidKitItem>> _categories = {};

  bool _isLoading = false;
  int _totalItems = 0;
  int _completedItems = 0;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  /// Updates the total and completed item counts for progress tracking.
  void _updateProgress() {
    _totalItems = _categories.values.fold(0, (sum, items) => sum + items.length);
    _completedItems = _categories.values.fold(
        0, (sum, items) => sum + items.where((item) => item.checked).length);
  }

  /// Loads items from SharedPreferences and initializes progress.
  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();

    bool hasValidData = false;

    for (final category in _categories.keys) {
      final itemsJson = prefs.getStringList('first_aid_kit_$category');
      if (itemsJson != null && itemsJson.isNotEmpty) {
        try {
          _categories[category] = itemsJson.map((item) {
            final parts = Map.fromEntries(item.split('|').map((e) {
              final split = e.split(':');
              if (split[0] == 'checked') return MapEntry(split[0], split[1] == 'true');
              if (split[0] == 'quantity') return MapEntry(split[0], int.parse(split[1]));
              return MapEntry(split[0], split[1]);
            }));
            return FirstAidKitItem.fromJson(parts);
          }).toList();
          hasValidData = true;
        } catch (e) {
          debugPrint('Error parsing $category: $e');
          hasValidData = false;
          break;
        }
      }
    }

    if (!hasValidData) {
      _initializeDefaultItems();
      await _saveItems();
      await prefs.setBool('first_aid_kit_initialized', true);
    }

    _updateProgress();

    if (mounted) setState(() => _isLoading = false);
  }

  /// Saves all items to SharedPreferences.
  Future<void> _saveItems() async {
    final prefs = await SharedPreferences.getInstance();
    for (final category in _categories.keys) {
      final itemsJson = _categories[category]!
          .map((item) => 'name:${item.name}|checked:${item.checked}|quantity:${item.quantity}')
          .toList();
      await prefs.setStringList('first_aid_kit_$category', itemsJson);
    }
  }

  /// Resets the checklist to default items with user confirmation.
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
      await _loadItems();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.translate('reset_success')),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(_paddingValue),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Initializes default items for each category with localized names.
  void _initializeDefaultItems() {
    final l = AppLocalizations.of(context);
    
    // Use translated category names
    _categories[l.translate('bandages_dressings')] = [
      FirstAidKitItem(name: l.translate('adhesive_bandages')),
      FirstAidKitItem(name: l.translate('sterile_gauze_pads')),
      FirstAidKitItem(name: l.translate('elastic_bandage')),
      FirstAidKitItem(name: l.translate('adhesive_tape')),
      FirstAidKitItem(name: l.translate('triangular_bandage')),
    ];

    _categories[l.translate('medications')] = [
      FirstAidKitItem(name: l.translate('pain_relievers')),
      FirstAidKitItem(name: l.translate('antibiotic_ointment')),
      FirstAidKitItem(name: l.translate('antiseptic_solution')),
      FirstAidKitItem(name: l.translate('antihistamines')),
      FirstAidKitItem(name: l.translate('anti_diarrheal')),
      FirstAidKitItem(name: l.translate('hydrocortisone_cream')),
    ];

    _categories[l.translate('tools_equipment')] = [
      FirstAidKitItem(name: l.translate('medical_scissors')),
      FirstAidKitItem(name: l.translate('tweezers')),
      FirstAidKitItem(name: l.translate('digital_thermometer')),
      FirstAidKitItem(name: l.translate('disposable_gloves')),
      FirstAidKitItem(name: l.translate('cpr_face_mask')),
      FirstAidKitItem(name: l.translate('cold_compress')),
      FirstAidKitItem(name: l.translate('cotton_balls_swabs')),
      FirstAidKitItem(name: l.translate('emergency_blanket')),
    ];

    _categories[l.translate('emergency_information')] = [
      FirstAidKitItem(name: l.translate('first_aid_manual')),
      FirstAidKitItem(name: l.translate('emergency_contact_list')),
      FirstAidKitItem(name: l.translate('medical_history_allergy')),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.currentTheme;

    return Scaffold(
      backgroundColor: colors.bg200,
      body: SafeArea(
        child: Stack(
          children: [
            _Content(colors: colors, isLoading: _isLoading, categories: _categories),
            _Header(colors: colors, onReset: _resetToDefaults),
          ],
        ),
      ),
    );
  }
}

/// Encapsulates the scrollable content of the screen.
class _Content extends StatelessWidget {
  final AppColorTheme colors;
  final bool isLoading;
  final Map<String, List<FirstAidKitItem>> categories;

  const _Content({
    required this.colors,
    required this.isLoading,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Center(child: CircularProgressIndicator(color: colors.accent200))
        : SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        _FirstAidKitScreenState._paddingValue,
        70,
        _FirstAidKitScreenState._paddingValue,
        _FirstAidKitScreenState._paddingValue,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: _FirstAidKitScreenState._spacingLarge),
          _MaintenanceCard(colors: colors),
          const SizedBox(height: _FirstAidKitScreenState._spacingLarge),
          _ProgressBar(colors: colors, categories: categories),
          const SizedBox(height: _FirstAidKitScreenState._spacingLarge),
          ...categories.entries.map(
                (entry) => Padding(
              padding: const EdgeInsets.only(bottom: _FirstAidKitScreenState._spacingLarge),
              child: _CategoryCard(
                colors: colors,
                title: entry.key,
                items: entry.value,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Displays the header with back button, title, and reset button.
class _Header extends StatelessWidget {
  final AppColorTheme colors;
  final VoidCallback onReset;

  const _Header({required this.colors, required this.onReset});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.bg100.withOpacity(0.7),
        border: Border.all(color: colors.bg300.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: _FirstAidKitScreenState._paddingValue,
        vertical: _FirstAidKitScreenState._paddingValue - 4,
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: colors.primary300),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: _FirstAidKitScreenState._spacingSmall),
          Expanded(
            child: Text(
              l.translate('first_aid_kit_checklist'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.primary300,
              ),
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

/// Displays the maintenance tips card.
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
      padding: const EdgeInsets.all(_FirstAidKitScreenState._paddingValue),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: colors.bg100, size: 28),
              const SizedBox(width: _FirstAidKitScreenState._spacingMedium),
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
          const SizedBox(height: _FirstAidKitScreenState._spacingLarge),
          Container(
            padding: const EdgeInsets.all(_FirstAidKitScreenState._paddingValue),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _MaintenanceItem(
                  icon: Icons.inventory_2,
                  textKey: 'check_items_quantity',
                  colors: colors,
                ),
                _MaintenanceItem(
                  icon: Icons.event,
                  textKey: 'check_expiration',
                  colors: colors,
                ),
                _MaintenanceItem(
                  icon: Icons.wb_sunny,
                  textKey: 'store_cool_dry',
                  colors: colors,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A single maintenance tip item with localized text.
class _MaintenanceItem extends StatelessWidget {
  final IconData icon;
  final String textKey;
  final AppColorTheme colors;

  const _MaintenanceItem({
    required this.icon,
    required this.textKey,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: _FirstAidKitScreenState._spacingSmall),
      child: Row(
        children: [
          Icon(icon, color: colors.bg100, size: 20),
          const SizedBox(width: _FirstAidKitScreenState._spacingMedium),
          Expanded(
            child: Text(
              AppLocalizations.of(context).translate(textKey),
              style: TextStyle(color: colors.bg100),
            ),
          ),
        ],
      ),
    );
  }
}

/// Displays the overall progress bar for the kit.
class _ProgressBar extends StatelessWidget {
  final AppColorTheme colors;
  final Map<String, List<FirstAidKitItem>> categories;

  const _ProgressBar({required this.colors, required this.categories});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final totalItems = categories.values.fold(0, (sum, items) => sum + items.length);
    final completedItems =
    categories.values.fold(0, (sum, items) => sum + items.where((item) => item.checked).length);

    return Container(
      padding: const EdgeInsets.all(_FirstAidKitScreenState._paddingValue),
      decoration: _buildCardDecoration(colors),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l.translate('kit_completion'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.primary300,
                ),
              ),
              Text(
                l.translate('items_completed', {'completed': completedItems, 'total': totalItems}),
                style: TextStyle(color: colors.accent200, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: _FirstAidKitScreenState._spacingMedium),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: totalItems > 0 ? (completedItems / totalItems).toDouble() : 0.0,
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

/// Displays a category card with items and progress indicator.
class _CategoryCard extends StatefulWidget {
  final AppColorTheme colors;
  final String title;
  final List<FirstAidKitItem> items;

  const _CategoryCard({
    required this.colors,
    required this.title,
    required this.items,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final itemCount = widget.items.length;
    final completedCount = widget.items.where((item) => item.checked).length;
    final progress = itemCount > 0 ? (completedCount / itemCount).toDouble() : 0.0;

    return Container(
      decoration: _buildCardDecoration(widget.colors),
      padding: const EdgeInsets.all(_FirstAidKitScreenState._paddingValue),
      child: Column(
        children: [
          ExpansionTile(
            leading: Icon(_getCategoryIcon(widget.title), color: widget.colors.accent200),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    color: widget.colors.primary300,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: _FirstAidKitScreenState._spacingSmall),
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
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(top: _FirstAidKitScreenState._spacingMedium),
            children: widget.items.isEmpty
                ? [
              Text(
                l.translate('no_items_available'),
                style: TextStyle(color: widget.colors.text200),
              ),
            ]
                : widget.items
                .asMap()
                .entries
                .map((entry) => _ChecklistItem(
              colors: widget.colors,
              item: entry.value,
              onUpdate: () => setState(() {
                _updateParentProgress(context);
                _saveParentItems(context);
              }),
            ))
                .toList(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              _FirstAidKitScreenState._paddingValue,
              0,
              _FirstAidKitScreenState._paddingValue,
              _FirstAidKitScreenState._spacingSmall,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  l.translate('items_completed', {'completed': completedCount, 'total': itemCount}),
                  style: TextStyle(
                    color: widget.colors.text200.withOpacity(0.7),
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

  /// Maps category names to icons.
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Bandages & Dressings':
        return Icons.medical_services;
      case 'Medications':
        return Icons.medication;
      case 'Tools & Equipment':
        return Icons.build;
      case 'Emergency Information':
        return Icons.info_outline;
      default:
        return Icons.category;
    }
  }

  void _updateParentProgress(BuildContext context) {
    final state = context.findAncestorStateOfType<_FirstAidKitScreenState>();
    state?._updateProgress();
  }

  void _saveParentItems(BuildContext context) async {
    final state = context.findAncestorStateOfType<_FirstAidKitScreenState>();
    await state?._saveItems();
  }
}

/// A single checklist item with a checkbox and quantity input.
class _ChecklistItem extends StatelessWidget {
  final AppColorTheme colors;
  final FirstAidKitItem item;
  final VoidCallback onUpdate;

  const _ChecklistItem({
    required this.colors,
    required this.item,
    required this.onUpdate,
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
        onUpdate();
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: _FirstAidKitScreenState._spacingSmall),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: item.checked,
                activeColor: colors.accent200,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                onChanged: (value) {
                  item.checked = value ?? false;
                  if (!item.checked) {
                    item.quantity = 0;
                    controller.text = '';
                  }
                  onUpdate();
                },
              ),
            ),
            const SizedBox(width: _FirstAidKitScreenState._spacingMedium),
            Expanded(
              child: Text(
                item.name,
                style: TextStyle(
                  color: colors.text200,
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
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  hintText: l.translate('quantity_hint'),
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
                    borderSide: BorderSide(color: colors.bg300.withOpacity(0.5)),
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
                  onUpdate();
                },
                onTap: () {
                  if (!item.checked) {
                    item.checked = true;
                    onUpdate();
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