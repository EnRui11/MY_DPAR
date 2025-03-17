import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';

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

  factory FirstAidKitItem.fromJson(Map<String, dynamic> json) =>
      FirstAidKitItem(
        name: json['name'] as String,
        checked: json['checked'] as bool,
        quantity: json['quantity'] as int,
      );
}

/// A screen displaying a first aid kit checklist with progress tracking.
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

  final Map<String, List<FirstAidKitItem>> _categories = {
    'Bandages & Dressings': [],
    'Medications': [],
    'Tools & Equipment': [],
    'Emergency Information': [],
  };

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
    _totalItems =
        _categories.values.fold(0, (sum, items) => sum + items.length);
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
              if (split[0] == 'checked')
                return MapEntry(split[0], split[1] == 'true');
              if (split[0] == 'quantity')
                return MapEntry(split[0], int.parse(split[1]));
              return MapEntry(split[0], split[1]);
            }));
            return FirstAidKitItem.fromJson(parts);
          }).toList();
          hasValidData = true;
        } catch (e) {
          print('Error parsing $category: $e');
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
          .map((item) =>
              'name:${item.name}|checked:${item.checked}|quantity:${item.quantity}')
          .toList();
      await prefs.setStringList('first_aid_kit_$category', itemsJson);
    }
  }

  /// Resets the checklist to default items with user confirmation.
  Future<void> _resetToDefaults() async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Confirmation'),
        content: const Text(
            'Are you sure you want to reset to default items? This will clear all your current changes.'),
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
      await _loadItems();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Reset to default items'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(_paddingValue),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Initializes default items for each category.
  void _initializeDefaultItems() {
    _categories['Bandages & Dressings'] = [
      FirstAidKitItem(name: 'Adhesive Bandages (various sizes)'),
      FirstAidKitItem(name: 'Sterile Gauze Pads - 4x4 inch'),
      FirstAidKitItem(name: 'Elastic Bandage - 3-inch and 4-inch rolls'),
      FirstAidKitItem(name: 'Adhesive Tape (Medical-grade)'),
      FirstAidKitItem(name: 'Triangular Bandage (For slings)'),
    ];

    _categories['Medications'] = [
      FirstAidKitItem(name: 'Pain Relievers (e.g., ibuprofen, paracetamol)'),
      FirstAidKitItem(name: 'Antibiotic Ointment'),
      FirstAidKitItem(name: 'Antiseptic Solution'),
      FirstAidKitItem(name: 'Antihistamines'),
      FirstAidKitItem(name: 'Anti-diarrheal Medication'),
      FirstAidKitItem(name: 'Hydrocortisone Cream'),
    ];

    _categories['Tools & Equipment'] = [
      FirstAidKitItem(name: 'Medical-grade Scissors'),
      FirstAidKitItem(name: 'Tweezers'),
      FirstAidKitItem(name: 'Digital Thermometer'),
      FirstAidKitItem(name: 'Disposable Gloves (Latex-free)'),
      FirstAidKitItem(name: 'CPR Face Mask'),
      FirstAidKitItem(name: 'Cold Compress'),
      FirstAidKitItem(name: 'Cotton Balls & Swabs'),
      FirstAidKitItem(name: 'Emergency Blanket'),
    ];

    _categories['Emergency Information'] = [
      FirstAidKitItem(name: 'First Aid Manual'),
      FirstAidKitItem(name: 'Emergency Contact List'),
      FirstAidKitItem(name: 'Medical History & Allergy Information'),
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
            _buildContent(colors),
            _buildHeader(context, colors),
          ],
        ),
      ),
    );
  }

  /// Builds the header with back button, title, and reset button.
  Widget _buildHeader(BuildContext context, AppColorTheme colors) => Container(
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
                'First Aid Kit Checklist',
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

  /// Builds the main content area with progress and categories.
  Widget _buildContent(AppColorTheme colors) => _isLoading
      ? Center(child: CircularProgressIndicator(color: colors.accent200))
      : SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
              _paddingValue, 70, _paddingValue, _paddingValue),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: _spacingLarge),
              _buildMaintenanceCard(colors),
              const SizedBox(height: _spacingLarge),
              _buildProgressBar(colors),
              const SizedBox(height: _spacingLarge),
              ..._categories.entries.map(
                (entry) => Column(
                  children: [
                    _buildCategoryCard(colors, entry.key,
                        _getCategoryIcon(entry.key), entry.value),
                    const SizedBox(height: _spacingLarge),
                  ],
                ),
              ),
            ],
          ),
        );

  /// Builds the overall progress bar for the kit.
  Widget _buildProgressBar(AppColorTheme colors) => Container(
        padding: const EdgeInsets.all(_paddingValue),
        decoration: _buildCardDecoration(colors),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Kit Completion',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colors.primary300),
                ),
                Text(
                  '$_completedItems/$_totalItems Items',
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

  /// Builds a category card with items and progress indicator.
  Widget _buildCategoryCard(AppColorTheme colors, String title, IconData icon,
      List<FirstAidKitItem> items) {
    final itemCount = items.length;
    final completedCount = items.where((item) => item.checked).length;
    final progress =
        itemCount > 0 ? (completedCount / itemCount).toDouble() : 0.0;

    return Container(
      decoration: _buildCardDecoration(colors),
      padding: const EdgeInsets.all(_paddingValue),
      child: Column(
        children: [
          ExpansionTile(
            leading: Icon(icon, color: colors.accent200),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                      color: colors.primary300,
                      fontSize: 18,
                      fontWeight: FontWeight.w600),
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
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(top: _spacingMedium),
            children: items.isEmpty
                ? [
                    Text('No items available',
                        style: TextStyle(color: colors.text200))
                  ]
                : items
                    .asMap()
                    .entries
                    .map((entry) => _buildChecklistItem(
                        colors, title, entry.key, entry.value))
                    .toList(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                _paddingValue, 0, _paddingValue, _spacingSmall),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '$completedCount/$itemCount items completed',
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

  /// Builds a checklist item with a tappable checkbox and description.
  Widget _buildChecklistItem(
      AppColorTheme colors, String category, int index, FirstAidKitItem item) {
    final controller = TextEditingController(
        text: item.quantity > 0 ? item.quantity.toString() : '');
    return InkWell(
      onTap: () {
        setState(() {
          item.checked = !item.checked; // Toggle the state
          if (!item.checked) {
            item.quantity = 0;
            controller.text = '';
          }
          _updateProgress();
          _saveItems();
        });
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: _spacingSmall),
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
                onChanged: (value) {
                  setState(() {
                    item.checked = value ?? false;
                    if (!item.checked) {
                      item.quantity = 0;
                      controller.text = '';
                    }
                    _updateProgress();
                    _saveItems();
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
                    _saveItems();
                  });
                },
                onTap: () {
                  if (!item.checked) {
                    setState(() {
                      item.checked = true;
                      _updateProgress();
                      _saveItems();
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

  /// Builds the maintenance tips card.
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
                  _buildMaintenanceItem(colors, Icons.inventory_2,
                      'Check items you have and enter quantities'),
                  _buildMaintenanceItem(colors, Icons.event,
                      'Regularly check expiration dates and replace items'),
                  _buildMaintenanceItem(colors, Icons.wb_sunny,
                      'Store in a cool, dry place away from sunlight'),
                ],
              ),
            ),
          ],
        ),
      );

  /// Builds a maintenance tip item.
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
