import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:voicesewa_worker/core/constants/app_constants.dart';
import 'package:voicesewa_worker/core/providers/language_provider.dart';
import 'package:voicesewa_worker/features/auth/providers/profile_form_provider.dart';
import 'package:voicesewa_worker/features/profile/providers/worker_profile_provider.dart';
import 'package:voicesewa_worker/shared/data/service_data.dart';
import 'package:voicesewa_worker/shared/models/worker_model.dart';

class WorkerProfileFormPage extends ConsumerStatefulWidget {
  const WorkerProfileFormPage({super.key});

  @override
  ConsumerState<WorkerProfileFormPage> createState() =>
      _WorkerProfileFormPageState();
}

class _WorkerProfileFormPageState extends ConsumerState<WorkerProfileFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();

  String? _selectedLanguage;
  String? _selectedSkillCategory;
  bool _isLoading = false;

  GeoPoint? _geoPoint;
  bool _isFetchingLocation = false;
  String? _locationStatusMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  // ── Geolocation ───────────────────────────────────────────────────────────

  Future<void> _detectLocation() async {
    setState(() {
      _isFetchingLocation = true;
      _locationStatusMessage = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(
          () => _locationStatusMessage =
              'Location services are disabled. Please enable them in settings.',
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(
            () => _locationStatusMessage = 'Location permission denied.',
          );
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(
          () => _locationStatusMessage =
              'Location permission permanently denied. Please enable it in app settings.',
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        _geoPoint = GeoPoint(position.latitude, position.longitude);
        _locationStatusMessage = '✅ Location captured';
      });

      // Reverse geocode to prefill city and pincode
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty && mounted) {
          final place = placemarks.first;
          final city = place.locality?.isNotEmpty == true
              ? place.locality!
              : (place.subAdministrativeArea ?? '');
          final pincode = place.postalCode ?? '';
          setState(() {
            if (city.isNotEmpty) _cityController.text = city;
            if (pincode.isNotEmpty) _pincodeController.text = pincode;
          });
        }
      } catch (_) {
        // Reverse geocoding failed — user can still fill manually
      }
    } catch (e) {
      setState(() => _locationStatusMessage = 'Failed to get location: $e');
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      _showSnackBar(
        'Error: Not signed in. Please restart the app.',
        Colors.red,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final worker = WorkerModel(
        workerId: firebaseUser.uid,
        name: _nameController.text.trim(),
        email: firebaseUser.email ?? '',
        phone: _phoneController.text.trim(),
        bio: _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
        skills: [_selectedSkillCategory!],
        address: WorkerAddress(
          location: _geoPoint,
          city: _cityController.text.trim(),
          pincode: _pincodeController.text.trim(),
        ),
      );

      final saveProfile = ref.read(saveWorkerProfileProvider);
      final success = await saveProfile(worker);

      if (!mounted) return;

      if (success) {
        ref.read(localeProvider.notifier).changeLanguage(_selectedLanguage!);
        ref.read(profileCompletionProvider.notifier).markComplete();
        _showSnackBar('Profile created successfully! 🎉', Colors.green);
      } else {
        _showSnackBar('Failed to save profile. Please try again.', Colors.red);
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error: ${e.toString()}', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Welcome! 👋',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  "Let's set up your worker profile to get started",
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 32),

                // ── Basic Info ──────────────────────────────────────────────
                _sectionHeader('Basic Information', Icons.person_outline),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _nameController,
                  enabled: !_isLoading,
                  decoration: _inputDecoration(
                    'Full Name',
                    'Enter your full name',
                    Icons.person_outline,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Please enter your name';
                    if (v.trim().length < 2)
                      return 'Name must be at least 2 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _phoneController,
                  enabled: !_isLoading,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDecoration(
                    'Phone Number',
                    'Enter your phone number',
                    Icons.phone_outlined,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Please enter your phone number';
                    if (v.trim().length < 10)
                      return 'Please enter a valid phone number';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _selectedLanguage,
                  decoration: _inputDecoration(
                    'Preferred Language',
                    '',
                    Icons.language_outlined,
                  ),
                  items: AppConstants.supportedLanguages
                      .map(
                        (lang) => DropdownMenuItem(
                          value: lang.code,
                          child: Text(lang.displayName),
                        ),
                      )
                      .toList(),
                  onChanged: _isLoading
                      ? null
                      : (v) => setState(() => _selectedLanguage = v),
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Please select a language'
                      : null,
                ),
                const SizedBox(height: 24),

                // ── Primary Skill ────────────────────────────────────────────
                _sectionHeader('Your Skill', Icons.work_outline),
                const SizedBox(height: 8),
                Text(
                  'Select the primary service you offer',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),

                // Skill validation wrapper
                FormField<String>(
                  initialValue: _selectedSkillCategory,
                  validator: (_) =>
                      (_selectedSkillCategory == null ||
                          _selectedSkillCategory!.isEmpty)
                      ? 'Please select your primary skill'
                      : null,
                  builder: (field) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 2.8,
                        children: ServicesData.services.entries.map((entry) {
                          final color = ServicesData.colorOf(entry.key);
                          final icon = ServicesData.iconOf(entry.key);
                          final name = ServicesData.nameOf(entry.key);
                          final isSelected = _selectedSkillCategory == name;

                          return GestureDetector(
                            onTap: _isLoading
                                ? null
                                : () => setState(() {
                                    _selectedSkillCategory = name;
                                    field.didChange(name);
                                  }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? color.withOpacity(0.12)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? color
                                      : Colors.grey.shade300,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    icon,
                                    size: 18,
                                    color: isSelected ? color : Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: isSelected
                                            ? color
                                            : Colors.grey.shade700,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      if (field.hasError) ...[
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Text(
                            field.errorText!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(field.context).colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _bioController,
                  enabled: !_isLoading,
                  maxLines: 3,
                  decoration: _inputDecoration(
                    'Bio (Optional)',
                    'Tell us about your experience...',
                    Icons.description_outlined,
                    alignLabel: true,
                  ),
                ),
                const SizedBox(height: 32),

                // ── Location ────────────────────────────────────────────────
                _sectionHeader('Your Location', Icons.location_on_outlined),
                const SizedBox(height: 4),
                Text(
                  'Used to match you with nearby jobs.',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),

                OutlinedButton.icon(
                  onPressed: (_isLoading || _isFetchingLocation)
                      ? null
                      : _detectLocation,
                  icon: _isFetchingLocation
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _geoPoint != null
                              ? Icons.check_circle_outline
                              : Icons.my_location,
                          color: _geoPoint != null ? Colors.green : null,
                        ),
                  label: Text(
                    _isFetchingLocation
                        ? 'Capturing location...'
                        : _geoPoint != null
                        ? 'Location captured — tap to update'
                        : 'Capture My Location',
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    foregroundColor: _geoPoint != null ? Colors.green : null,
                    side: BorderSide(
                      color: _geoPoint != null ? Colors.green : Colors.grey,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                if (_locationStatusMessage != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        _locationStatusMessage!.startsWith('✅')
                            ? Icons.check_circle_outline
                            : Icons.info_outline,
                        size: 16,
                        color: _locationStatusMessage!.startsWith('✅')
                            ? Colors.green
                            : Colors.orange,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _locationStatusMessage!,
                          style: TextStyle(
                            fontSize: 12,
                            color: _locationStatusMessage!.startsWith('✅')
                                ? Colors.green[700]
                                : Colors.orange[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _cityController,
                        enabled: !_isLoading,
                        decoration: _inputDecoration(
                          'City',
                          'e.g. Mumbai',
                          Icons.location_city_outlined,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter your city'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _pincodeController,
                        enabled: !_isLoading,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration(
                          'Pincode',
                          '400001',
                          Icons.pin_outlined,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (v.trim().length != 6) return 'Invalid pincode';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // ── Submit ───────────────────────────────────────────────────
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.blue,
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Complete Profile',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade700,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'You can update your profile later from the settings page.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue[700]),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue[700],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Divider(color: Colors.blue[100])),
      ],
    );
  }

  InputDecoration _inputDecoration(
    String label,
    String hint,
    IconData icon, {
    bool alignLabel = false,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint.isEmpty ? null : hint,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.white,
      alignLabelWithHint: alignLabel,
    );
  }
}
