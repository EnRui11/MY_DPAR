import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mydpar/theme/theme_provider.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/localization/app_localizations.dart';
import 'package:mydpar/officer/service/emergency_team_service.dart';

/// Screen for creating a new emergency team with name, type, description, location, and specialization.
class CreateEmergencyTeamScreen extends StatefulWidget {
  const CreateEmergencyTeamScreen({super.key});

  @override
  State<CreateEmergencyTeamScreen> createState() =>
      _CreateEmergencyTeamScreenState();
}

class _CreateEmergencyTeamScreenState extends State<CreateEmergencyTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _teamNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  String _teamType = 'official';
  String _specialization = '';
  final EmergencyTeamService _teamService = EmergencyTeamService();
  bool _isLoading = false;

  // List of specializations with localized labels
  final List<Map<String, String>> _specializations = [
    {'value': '', 'label': 'select_specialization'},
    {'value': 'rescue', 'label': 'search_and_rescue'},
    {'value': 'medical', 'label': 'medical'},
    {'value': 'fire', 'label': 'fire_response'},
    {'value': 'logistics', 'label': 'logistics_and_supply'},
    {'value': 'evacuation', 'label': 'evacuation'},
    {'value': 'general', 'label': 'general_response'},
  ];

  // UI constants
  static const double _padding = 16.0;
  static const double _spacing = 16.0;
  static const double _spacingSmall = 4.0;
  static const double _cardRadius = 12.0;

  @override
  void dispose() {
    _teamNameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  /// Creates a new team and saves it to the service.
  Future<void> _createTeam() async {
    final localizations = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate() || _specialization.isEmpty) {
      if (_specialization.isEmpty) {
        _showSnackBar(localizations.translate('specialization_required'),
            backgroundColor: Colors.red);
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String locationText = _locationController.text;
      await _teamService.createTeam(
        name: _teamNameController.text,
        type: _teamType,
        description: _descriptionController.text,
        locationText: locationText,
        specialization: _specialization,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar(localizations.translate('team_created'),
          backgroundColor: Colors.green);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorSnackBar(localizations.translate('failed_to_create_team'), e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors =
        Provider.of<ThemeProvider>(context, listen: true).currentTheme;
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: colors.bg200,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.primary300),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          localizations.translate('create_team'),
          style:
              TextStyle(color: colors.primary300, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(_padding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(
                      localizations.translate('team_information'), colors),
                  const SizedBox(height: _spacing),
                  _buildTextField(
                    controller: _teamNameController,
                    label: localizations.translate('team_name'),
                    hint: localizations.translate('enter_team_name'),
                    validator: (value) => value == null || value.isEmpty
                        ? localizations.translate('team_name_required')
                        : null,
                    colors: colors,
                  ),
                  const SizedBox(height: _spacing),
                  _buildTeamTypeSelection(colors, localizations),
                  const SizedBox(height: _spacing),
                  _buildTextField(
                    controller: _descriptionController,
                    label: localizations.translate('description'),
                    hint: localizations.translate('team_description_hint'),
                    maxLines: 3,
                    colors: colors,
                  ),
                  const SizedBox(height: _spacing),
                  _buildTextField(
                    controller: _locationController,
                    label: localizations.translate('base_location'),
                    hint: localizations.translate('city_or_area'),
                    validator: (value) => value == null || value.isEmpty
                        ? localizations.translate('base_location_required')
                        : null,
                    colors: colors,
                  ),
                  const SizedBox(height: _spacing),
                  _buildSpecializationDropdown(colors, localizations),
                  const SizedBox(height: _spacing * 1.5),
                  _buildSubmitButton(colors, localizations),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a section title.
  Widget _buildSectionTitle(String title, AppColorTheme colors) => Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: colors.primary300,
        ),
      );

  /// Builds a text field with label and validation.
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
    int maxLines = 1,
    required AppColorTheme colors,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colors.text200),
          ),
          const SizedBox(height: _spacingSmall),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: colors.text200.withOpacity(0.6)),
              filled: true,
              fillColor: colors.bg100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(_cardRadius),
                borderSide: BorderSide(color: colors.bg300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(_cardRadius),
                borderSide: BorderSide(color: colors.bg300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(_cardRadius),
                borderSide: BorderSide(color: colors.accent200),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            validator: validator,
            maxLines: maxLines,
          ),
        ],
      );

  /// Builds the team type selection radio buttons.
  Widget _buildTeamTypeSelection(
          AppColorTheme colors, AppLocalizations localizations) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.translate('team_type'),
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colors.text200),
          ),
          const SizedBox(height: _spacingSmall * 2),
          Row(
            children: [
              _buildRadioOption(
                value: 'official',
                groupValue: _teamType,
                label: localizations.translate('official'),
                colors: colors,
              ),
              const SizedBox(width: _spacing),
              _buildRadioOption(
                value: 'volunteer',
                groupValue: _teamType,
                label: localizations.translate('volunteer'),
                colors: colors,
              ),
            ],
          ),
        ],
      );

  /// Builds a radio option for team type.
  Widget _buildRadioOption({
    required String value,
    required String groupValue,
    required String label,
    required AppColorTheme colors,
  }) =>
      Row(
        children: [
          Radio<String>(
            value: value,
            groupValue: groupValue,
            onChanged: (newValue) => setState(() => _teamType = newValue!),
            activeColor: colors.accent200,
          ),
          Text(label, style: TextStyle(color: colors.text200, fontSize: 14)),
        ],
      );

  /// Builds the specialization dropdown menu.
  Widget _buildSpecializationDropdown(
          AppColorTheme colors, AppLocalizations localizations) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.translate('specialization'),
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colors.text200),
          ),
          const SizedBox(height: _spacingSmall),
          Container(
            decoration: BoxDecoration(
              color: colors.bg100,
              borderRadius: BorderRadius.circular(_cardRadius),
              border: Border.all(
                  color:
                      _specialization.isEmpty ? colors.warning : colors.bg300),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _specialization,
                isExpanded: true,
                icon: Icon(Icons.arrow_drop_down, color: colors.text200),
                hint: Text(
                  localizations.translate('select_specialization'),
                  style: TextStyle(color: colors.text200.withOpacity(0.6)),
                ),
                items: _specializations
                    .map((spec) => DropdownMenuItem<String>(
                          value: spec['value'],
                          child: Text(
                            localizations.translate(spec['label']!),
                            style: TextStyle(color: colors.text200),
                          ),
                        ))
                    .toList(),
                onChanged: (newValue) =>
                    setState(() => _specialization = newValue!),
                dropdownColor: colors.bg100,
              ),
            ),
          ),
          if (_specialization.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: _spacingSmall, left: 12.0),
              child: Text(
                localizations.translate('specialization_required'),
                style: TextStyle(color: colors.warning, fontSize: 12),
              ),
            ),
        ],
      );

  /// Builds the submit button with loading state.
  Widget _buildSubmitButton(
          AppColorTheme colors, AppLocalizations localizations) =>
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _createTeam,
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.accent200,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_cardRadius)),
            elevation: 0,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  localizations.translate('create_team_button'),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                ),
        ),
      );

  /// Shows a snackbar with a message and optional background color.
  void _showSnackBar(String message, {Color? backgroundColor}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: backgroundColor),
      );
    }
  }

  /// Shows an error snackbar with a message and error details.
  void _showErrorSnackBar(String message, Object error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('$message: $error'), backgroundColor: Colors.red),
      );
    }
  }
}
