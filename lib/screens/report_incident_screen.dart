import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mydpar/theme/theme_provider.dart';

class ReportIncidentScreen extends StatefulWidget {
  const ReportIncidentScreen({super.key});

  @override
  State<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen> {
  String? _selectedIncidentType;
  String? _otherIncidentType;
  String? _selectedSeverity;
  String? _selectedLocation;
  final _descriptionController = TextEditingController();

  bool get _isFormValid {
    if (_selectedIncidentType == null) return false;
    if (_selectedIncidentType == 'Other' && (_otherIncidentType?.isEmpty ?? true)) return false;
    if (_selectedSeverity == null) return false;
    if (_selectedLocation == null) return false;
    return true;
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
            // Status Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colors.bg100.withOpacity(0.7),
                border: Border(
                  bottom: BorderSide(color: colors.bg300.withOpacity(0.2)),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    color: colors.primary300,
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    'Report Incident',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: colors.primary300,
                    ),
                  ),
                ],
              ),
            ),
            // Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Incident Type', colors, isRequired: true),
                    const SizedBox(height: 8),
                    _buildIncidentTypeDropdown(colors),
                    if (_selectedIncidentType == 'Other') ...[
                      const SizedBox(height: 16),
                      _buildLabel('Specify Incident Type', colors, isRequired: true),
                      const SizedBox(height: 8),
                      _buildOtherIncidentField(colors),
                    ],
                    const SizedBox(height: 24),
                    _buildLabel('Severity Level', colors, isRequired: true),
                    const SizedBox(height: 8),
                    _buildSeverityButtons(colors),
                    const SizedBox(height: 24),
                    _buildLabel('Location', colors, isRequired: true),
                    const SizedBox(height: 8),
                    _buildLocationSelector(colors),
                    const SizedBox(height: 24),
                    _buildLabel('Description', colors),
                    const SizedBox(height: 8),
                    _buildDescriptionField(colors),
                    const SizedBox(height: 24),
                    _buildLabel('Add Photos', colors),
                    const SizedBox(height: 8),
                    _buildPhotoUploader(colors),
                    const SizedBox(height: 32),
                    _buildSubmitButton(colors),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, dynamic colors, {bool isRequired = false}) {
    return Row(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colors.primary300,
          ),
        ),
        if (isRequired)
          Text(
            ' *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colors.warning,
            ),
          ),
      ],
    );
  }

  Widget _buildIncidentTypeDropdown(dynamic colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.bg100.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.bg300.withOpacity(0.2)),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedIncidentType,
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: InputBorder.none,
        ),
        dropdownColor: colors.bg100,
        style: TextStyle(color: colors.text200, fontSize: 16),
        hint: Text('Select incident type', style: TextStyle(color: colors.text200)),
        items: [
          'Flood',
          'Fire',
          'Earthquake',
          'Landslide',
          'Tsunami',
          'Haze',
          'Typhoon',
          'Other',
        ].map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (newValue) {
          setState(() {
            _selectedIncidentType = newValue;
          });
        },
      ),
    );
  }

  Widget _buildOtherIncidentField(dynamic colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.bg100.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.bg300.withOpacity(0.2)),
      ),
      child: TextField(
        onChanged: (value) => _otherIncidentType = value,
        style: TextStyle(color: colors.text200),
        decoration: InputDecoration(
          hintText: 'Please specify the incident type',
          hintStyle: TextStyle(color: colors.text200.withOpacity(0.7)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildSeverityButtons(dynamic colors) {
    return Row(
      children: ['Low', 'Medium', 'High'].map((severity) {
        final isSelected = _selectedSeverity == severity;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 4,
            ),
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedSeverity = severity;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected
                    ? colors.accent200
                    : colors.bg100.withOpacity(0.7),
                foregroundColor: isSelected ? colors.bg100 : colors.text200,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: colors.bg300.withOpacity(0.2),
                  ),
                ),
              ),
              child: Text(severity),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLocationSelector(dynamic colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.bg100.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _selectedLocation == null
              ? colors.warning
              : colors.bg300.withOpacity(0.2),
        ),
      ),
      child: MaterialButton(
        onPressed: () {
          // Temporary simulation of location selection
          setState(() {
            _selectedLocation = "Selected Location";
          });
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(Icons.location_on_outlined, color: colors.accent200),
              const SizedBox(width: 8),
              Text(
                _selectedLocation ?? 'Select location on map',
                style: TextStyle(color: colors.text200),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionField(dynamic colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.bg100.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.bg300.withOpacity(0.2)),
      ),
      child: TextField(
        controller: _descriptionController,
        style: TextStyle(color: colors.text200),
        maxLines: 4,
        decoration: InputDecoration(
          hintText: 'Describe the incident...',
          hintStyle: TextStyle(color: colors.text200.withOpacity(0.7)),
          contentPadding: const EdgeInsets.all(16),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildPhotoUploader(dynamic colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.bg100.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.bg300.withOpacity(0.2),
          style: BorderStyle.solid,
          width: 2,
        ),
      ),
      child: MaterialButton(
        onPressed: () {
          // TODO: Implement photo upload
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              Icon(Icons.upload_outlined, color: colors.accent200, size: 32),
              const SizedBox(height: 8),
              Text(
                'Tap to upload photo',
                style: TextStyle(color: colors.text200),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(dynamic colors) {
    void _showValidationErrors() {
      List<String> missingFields = [];

      if (_selectedIncidentType == null) {
        missingFields.add('Incident Type');
      } else if (_selectedIncidentType == 'Other' &&
          (_otherIncidentType?.isEmpty ?? true)) {
        missingFields.add('Other Incident Type specification');
      }

      if (_selectedSeverity == null) {
        missingFields.add('Severity Level');
      }

      if (_selectedLocation == null) {
        missingFields.add('Location');
      }

      if (missingFields.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please fill in the required fields: ${missingFields.join(", ")}',
              style: TextStyle(color: colors.bg100),
            ),
            backgroundColor: colors.warning,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          if (_isFormValid) {
            // TODO: Implement report submission
            print('Form is valid, submitting...');
          } else {
            _showValidationErrors();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.accent200,
          foregroundColor: colors.bg100,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Submit Report',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
