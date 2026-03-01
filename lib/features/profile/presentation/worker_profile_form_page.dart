import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:voicesewa_worker/core/constants/app_constants.dart';
import 'package:voicesewa_worker/core/constants/color_constants.dart';
import 'package:voicesewa_worker/core/providers/language_provider.dart';
import 'package:voicesewa_worker/core/providers/session_provider.dart';
import 'package:voicesewa_worker/features/auth/presentation/widgets/aadhaar_verification_section.dart';
import 'package:voicesewa_worker/features/auth/providers/profile_form_provider.dart';
import 'package:voicesewa_worker/features/auth/providers/aadhaar_verification_provider.dart';
import 'package:voicesewa_worker/features/profile/data/services/profile_image_service.dart';
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
  final Set<String> _selectedSkills = {};
  bool _isLoading = false;

  GeoPoint? _geoPoint;
  bool _isFetchingLocation = false;
  String? _locationStatusMessage;

  // ── Image state ───────────────────────────────────────────────────────────
  File? _pickedImageFile; // locally picked/captured file (not yet uploaded)
  String? _existingImageUrl; // already-uploaded URL from Firestore
  bool _isUploadingImage = false;
  double _uploadProgress = 0.0;

  // ── Edit-mode state ───────────────────────────────────────────────────────
  bool _prefilled = false;
  // Key changes after prefill so FormField rebuilds with correct initialValue
  Key _skillsFieldKey = const ValueKey('skills_empty');
  WorkerModel? _originalWorker;

  // Whether this page was opened from the profile page (edit) vs first-time setup
  bool get _isEditMode => _originalWorker != null;

  // The image to show in the avatar preview:
  // 1. Locally picked file (highest priority)
  // 2. Existing URL from Firestore
  // 3. null -> show placeholder
  ImageProvider? get _previewImage {
    if (_pickedImageFile != null) return FileImage(_pickedImageFile!);
    if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
      return NetworkImage(_existingImageUrl!);
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    // Attempt to prefill on next frame (stream may already have data)
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryPrefill());
  }

  void _tryPrefill() {
    final uid = ref.read(currentUserProvider)?.uid ?? '';
    if (uid.isEmpty) return;
    final profileAsync = ref.read(workerProfileStreamProvider(uid));
    profileAsync.whenData((worker) {
      if (worker != null && mounted) _prefillFromWorker(worker);
    });
  }

  void _prefillFromWorker(WorkerModel worker) {
    if (_prefilled) return;
    _prefilled = true;
    _originalWorker = worker;

    _nameController.text = worker.name;
    _phoneController.text = worker.phone;
    _bioController.text = worker.bio ?? '';
    _cityController.text = worker.address?.city ?? '';
    _existingImageUrl = worker.profileImg;
    _pincodeController.text = worker.address?.pincode ?? '';

    // Prefill GeoPoint so it's preserved even if user doesn't re-detect
    _geoPoint = worker.address?.location;
    if (_geoPoint != null) {
      _locationStatusMessage = '✅ Location captured';
    }

    // Prefill skills grid
    _selectedSkills
      ..clear()
      ..addAll(worker.skills);

    // Prefill language — match stored locale or fall back to current app locale
    final currentLocale = ref.read(localeProvider);
    _selectedLanguage =
        AppConstants.supportedLanguages.any(
          (l) => l.code == currentLocale.languageCode,
        )
        ? currentLocale.languageCode
        : null;

    _skillsFieldKey = ValueKey('skills_${_selectedSkills.join('_')}');
    if (mounted) setState(() {});
  }

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
        ColorConstants.errorRed,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ── Step 1: Upload new image if one was picked ─────────────────────
      String? finalImageUrl = _existingImageUrl;

      if (_pickedImageFile != null) {
        setState(() {
          _isUploadingImage = true;
          _uploadProgress = 0.0;
        });

        // Delete old image from Storage to avoid orphaned files
        if (_existingImageUrl != null) {
          await ProfileImageService.deleteByUrl(_existingImageUrl!);
        }

        finalImageUrl = await ProfileImageService.uploadProfileImage(
          uid: firebaseUser.uid,
          file: _pickedImageFile!,
          onProgress: (p) {
            if (mounted) setState(() => _uploadProgress = p);
          },
        );

        if (mounted) setState(() => _isUploadingImage = false);
      }

      // ── Step 2: Save profile to Firestore ──────────────────────────────
      // Build updated address — keep existing geohash if GeoPoint unchanged
      final existingAddress = _originalWorker?.address;
      final geoPointChanged = _geoPoint != existingAddress?.location;

      final worker = WorkerModel(
        workerId: firebaseUser.uid,
        name: _nameController.text.trim(),
        email: _isEditMode
            ? (_originalWorker!.email) // email not editable in edit mode
            : (firebaseUser.email ?? ''),
        phone: _phoneController.text.trim(),
        bio: _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
        profileImg: finalImageUrl,
        skills: _selectedSkills.toList(),
        // Preserve existing fields that aren't edited in this form
        avgRating: _originalWorker?.avgRating ?? 0.0,
        reviews: _originalWorker?.reviews ?? [],
        fcmToken: _originalWorker?.fcmToken,
        jobs: _originalWorker?.jobs,
        address: WorkerAddress(
          location: _geoPoint,
          city: _cityController.text.trim(),
          pincode: _pincodeController.text.trim(),
          // If GeoPoint didn't change, reuse stored geohash to avoid recompute
          geohash: geoPointChanged ? null : existingAddress?.geohash,
        ),
      );

      final saveProfile = ref.read(saveWorkerProfileProvider);
      final success = await saveProfile(worker);

      // ── Step 3: Merge Aadhaar verification data if verified ────────────
      final aadhaarState = ref.read(aadhaarVerificationProvider);
      if (success && aadhaarState.isVerified && aadhaarState.data != null) {
        final repo = ref.read(workerProfileRepositoryProvider);
        await repo.updateFields(
          firebaseUser.uid,
          aadhaarState.data!.toFirestoreMap(),
        );
        print('✅ Aadhaar verification saved to Firestore');
      }

      if (!mounted) return;

      if (success) {
        // Only change language if a new one was selected
        if (_selectedLanguage != null) {
          ref.read(localeProvider.notifier).changeLanguage(_selectedLanguage!);
        }

        if (!_isEditMode) {
          // First-time setup — mark profile complete
          ref.read(profileCompletionProvider.notifier).markComplete();
        }

        _showSnackBar(
          _isEditMode
              ? 'Profile updated successfully! ✅'
              : 'Profile created successfully! 🎉',
          ColorConstants.successGreen,
        );

        if (_isEditMode && mounted) Navigator.of(context).pop();
      } else {
        _showSnackBar(
          'Failed to save profile. Please try again.',
          ColorConstants.errorRed,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingImage = false);
        _showSnackBar('Error: ${e.toString()}', ColorConstants.errorRed);
      }
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
    // Watch stream so if data arrives after initState, we still prefill
    final uid = ref.watch(currentUserProvider)?.uid ?? '';
    ref.watch(workerProfileStreamProvider(uid)).whenData((worker) {
      if (worker != null) _prefillFromWorker(worker);
    });

    return Scaffold(
      backgroundColor: ColorConstants.backgroundColor,
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Profile' : 'Complete Your Profile'),
        // Show back button in edit mode, hide in first-time setup
        automaticallyImplyLeading: _isEditMode,
        backgroundColor: ColorConstants.pureWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Show welcome header only on first-time setup, not in edit mode
                if (!_isEditMode) ...[
                  const Text(
                    'Welcome! 👋',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Let's set up your worker profile to get started",
                    style: TextStyle(
                      fontSize: 16,
                      color: ColorConstants.subtitleGrey,
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                // ── Profile Photo ──────────────────────────────────────────
                _sectionHeader('Profile Photo', Icons.photo_camera_outlined),
                const SizedBox(height: 16),
                _buildPhotoSection(),
                const SizedBox(height: 28),

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

                // ── Skills ───────────────────────────────────────────────────
                _sectionHeader('Your Skills', Icons.work_outline),
                const SizedBox(height: 8),
                Text(
                  'Select all services you offer',
                  style: TextStyle(
                    fontSize: 13,
                    color: ColorConstants.subtitleGrey,
                  ),
                ),
                const SizedBox(height: 12),

                FormField<String>(
                  key: _skillsFieldKey,
                  initialValue: _selectedSkills.isEmpty ? null : 'selected',
                  validator: (_) => (_selectedSkills.isEmpty)
                      ? 'Please select at least one skill'
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
                          final enumName = entry.key.name;
                          final isSelected = _selectedSkills.contains(enumName);

                          return GestureDetector(
                            onTap: _isLoading
                                ? null
                                : () => setState(() {
                                    if (_selectedSkills.contains(enumName)) {
                                      _selectedSkills.remove(enumName);
                                    } else {
                                      _selectedSkills.add(enumName);
                                    }
                                    field.didChange(
                                      _selectedSkills.isEmpty
                                          ? null
                                          : 'selected',
                                    );
                                  }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? color.withOpacity(0.12)
                                    : ColorConstants.pureWhite,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? color
                                      : ColorConstants.dividerGrey,
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
                                    color: isSelected
                                        ? color
                                        : ColorConstants.unselectedGrey,
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
                                            : ColorConstants.unselectedGreyDark,
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

                // ── Aadhaar Verification ──────────────────────────────────────
                _sectionHeader(
                  'Aadhaar Verification',
                  Icons.verified_user_outlined,
                ),
                const SizedBox(height: 12),
                AadhaarVerificationSection(
                  onVerified: (data) {
                    // Prefill name only if user hasn't typed anything yet
                    if (data.name != null &&
                        _nameController.text.trim().isEmpty) {
                      _nameController.text = data.name!;
                    }
                    // Prefill pincode from Aadhaar if empty
                    if (data.pincode != null &&
                        _pincodeController.text.trim().isEmpty) {
                      _pincodeController.text = data.pincode!;
                    }
                    // Prefill city (district) from Aadhaar if empty
                    if (data.district != null &&
                        _cityController.text.trim().isEmpty) {
                      _cityController.text = data.district!;
                    }
                    _showSnackBar(
                      '✅ Aadhaar verified! Fields pre-filled for you.',
                      ColorConstants.successGreen,
                    );
                  },
                ),
                const SizedBox(height: 32),

                // ── Location ─────────────────────────────────────────────────
                _sectionHeader('Your Location', Icons.location_on_outlined),
                const SizedBox(height: 4),
                Text(
                  'Used to match you with nearby jobs.',
                  style: TextStyle(
                    fontSize: 13,
                    color: ColorConstants.subtitleGrey,
                  ),
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
                          color: _geoPoint != null
                              ? ColorConstants.successGreen
                              : null,
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
                    foregroundColor: _geoPoint != null
                        ? ColorConstants.successGreen
                        : null,
                    side: BorderSide(
                      color: _geoPoint != null
                          ? ColorConstants.successGreen
                          : ColorConstants.unselectedGrey,
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
                            ? ColorConstants.successGreen
                            : ColorConstants.warningOrange,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _locationStatusMessage!,
                          style: TextStyle(
                            fontSize: 12,
                            color: _locationStatusMessage!.startsWith('✅')
                                ? ColorConstants.successGreenDark
                                : ColorConstants.warningOrangeDark,
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
                // Show upload progress bar while image is uploading
                if (_isUploadingImage) ...[
                  Row(
                    children: [
                      const Icon(
                        Icons.cloud_upload_outlined,
                        size: 16,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Uploading photo... ${(_uploadProgress * 100).toInt()}%',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: _uploadProgress,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                ElevatedButton(
                  onPressed: (_isLoading || _isUploadingImage)
                      ? null
                      : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: ColorConstants.infoBlue,
                    foregroundColor: ColorConstants.pureWhite,
                    disabledBackgroundColor: ColorConstants.disabledGrey,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              ColorConstants.pureWhite,
                            ),
                          ),
                        )
                      : Text(
                          _isEditMode ? 'Save Changes' : 'Complete Profile',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: ColorConstants.pureWhite,
                          ),
                        ),
                ),
                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ColorConstants.infoBlueSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ColorConstants.infoBlueBorder),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: ColorConstants.infoBlueDark,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _isEditMode
                              ? 'Re-capture your location if you have moved to a new area.'
                              : 'You can update your profile later from the settings page.',
                          style: TextStyle(
                            fontSize: 13,
                            color: ColorConstants.infoBlueDeep,
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

  // ── Image source bottom sheet ─────────────────────────────────────────────

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Profile Photo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.photo_library_outlined,
                    color: Colors.blue,
                  ),
                ),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Pick an existing photo'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final file = await ProfileImageService.pickFromGallery();
                  if (file != null && mounted)
                    setState(() => _pickedImageFile = file);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.green,
                  ),
                ),
                title: const Text('Take a Photo'),
                subtitle: const Text('Use your camera'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final file = await ProfileImageService.captureFromCamera();
                  if (file != null && mounted)
                    setState(() => _pickedImageFile = file);
                },
              ),
              if (_pickedImageFile != null || _existingImageUrl != null)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                  title: const Text(
                    'Remove Photo',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _pickedImageFile = null;
                      _existingImageUrl = null;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Profile photo avatar widget ───────────────────────────────────────────

  Widget _buildPhotoSection() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _isLoading ? null : _showImageSourceSheet,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _pickedImageFile != null
                          ? ColorConstants.infoBlue
                          : Colors.grey[300]!,
                      width: _pickedImageFile != null ? 3 : 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 55,
                    backgroundColor: Colors.grey[100],
                    backgroundImage: _previewImage,
                    child: _previewImage == null
                        ? Icon(
                            Icons.person_outline,
                            size: 50,
                            color: Colors.grey[400],
                          )
                        : null,
                  ),
                ),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: ColorConstants.infoBlue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _pickedImageFile != null
                ? 'New photo selected — will upload on save'
                : _existingImageUrl != null
                ? 'Tap to change photo'
                : 'Tap to add a profile photo',
            style: TextStyle(
              fontSize: 12,
              color: _pickedImageFile != null
                  ? Colors.blue[700]
                  : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: ColorConstants.infoBlueDark),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: ColorConstants.infoBlueDark,
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(child: Divider(color: ColorConstants.infoBlueDivider)),
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
      fillColor: ColorConstants.pureWhite,
      alignLabelWithHint: alignLabel,
    );
  }
}
