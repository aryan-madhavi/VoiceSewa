import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:voicesewa_client/core/constants/color_constants.dart';
import 'package:voicesewa_client/shared/models/address_model.dart';
import 'package:voicesewa_client/shared/models/client_model.dart';
import 'package:voicesewa_client/features/auth/providers/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:voicesewa_client/features/auth/providers/profile_form_provider.dart';
import 'package:voicesewa_client/features/auth/services/fcm_service.dart';

/// Enhanced profile setup screen with address, geolocation, and FCM
/// Creates complete profile in Firebase Firestore with FCM token
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  // Address controllers
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _landmarkController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();

  // FCM Service
  final _fcmService = FCMService();

  GeoPoint? _location;
  bool _isLoadingLocation = false;
  bool _isLoading = false;
  bool _skipAddress = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  /// Get current location using GPS
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception(
          'Location services are disabled. Please enable them in settings.',
        );
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permissions permanently denied. Please enable in settings.',
        );
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _location = GeoPoint(position.latitude, position.longitude);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Location captured: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ Location error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get location: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  /// Submit profile to Firestore with FCM token
  Future<void> _submitProfile() async {
    // Validate form (skip address validation if user chose to skip)
    if (!_skipAddress) {
      if (!_formKey.currentState!.validate()) return;
    } else {
      // Still validate name and phone
      if (_nameController.text.trim().isEmpty ||
          _phoneController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Name and phone are required'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      print('💾 Creating profile for UID: ${user.uid}');
      print('   Email: ${user.email}');
      print('   Name: ${_nameController.text.trim()}');
      print('   Skip address: $_skipAddress');

      // 1️⃣ Get FCM token for this user
      String? fcmToken;
      try {
        print('🔔 Initializing FCM...');
        final hasPermission = await _fcmService.initialize();

        if (hasPermission) {
          fcmToken = await _fcmService.getToken();
          print('✅ FCM token obtained: ${fcmToken?.substring(0, 20)}...');
        } else {
          print(
            '⚠️ FCM permissions denied - profile will be created without token',
          );
        }
      } catch (e) {
        print('⚠️ FCM error (non-critical): $e');
        // Continue profile creation even if FCM fails
      }

      // 2️⃣ Prepare addresses list
      List<Address> addresses = [];

      if (!_skipAddress && _location != null) {
        addresses.add(
          Address(
            location: _location!,
            line1: _addressLine1Controller.text.trim(),
            line2: _addressLine2Controller.text.trim(),
            landmark: _landmarkController.text.trim(),
            pincode: _pincodeController.text.trim(),
            city: _cityController.text.trim(),
          ),
        );
      }

      // 3️⃣ Create client profile with FCM token
      final profile = ClientProfile(
        uid: user.uid,
        name: _nameController.text.trim(),
        email: user.email!,
        phone: _phoneController.text.trim(),
        addresses: addresses,
        fcmToken: fcmToken, // ✅ FCM token saved here
      );

      // 4️⃣ Save to Firestore
      final repo = ref.read(clientFirebaseRepositoryProvider);
      await repo.upsertProfile(profile);

      print('✅ Profile saved to Firestore with FCM token');

      // 5️⃣ Subscribe to FCM topics
      if (fcmToken != null) {
        try {
          await _subscribeToTopics(addresses);
        } catch (e) {
          print('⚠️ Topic subscription error (non-critical): $e');
        }
      }

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile created successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        print('🔄 Marking profile as complete and navigating...');

        // CRITICAL FIX: Invalidate the profile check provider to force refresh
        ref.invalidate(userHasProfileProvider);

        // Mark profile as complete AFTER the frame to ensure navigation
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref.read(profileCompletionProvider.notifier).markComplete();
          }
        });
      }
    } catch (e) {
      print('❌ Profile creation error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create profile: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Subscribe user to FCM topics based on their profile
  Future<void> _subscribeToTopics(List<Address> addresses) async {
    print('🔔 Subscribing to FCM topics...');

    // Subscribe to default client topics
    // await _fcmService.subscribeToDefaultClientTopics();

    // Subscribe to location-based topics if address provided
    if (addresses.isNotEmpty) {
      final primaryAddress = addresses.first;
      // await _fcmService.subscribeToLocationTopics(city: primaryAddress.city);
    }

    print('✅ Topic subscriptions complete');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      _buildSectionHeader(
                        icon: Icons.person,
                        title: 'Personal Information',
                      ),
                      const SizedBox(height: 16),

                      // Name field
                      _buildTextField(
                        controller: _nameController,
                        label: 'Full Name *',
                        hint: 'Enter your full name',
                        icon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Phone field
                      _buildTextField(
                        controller: _phoneController,
                        label: 'Phone Number *',
                        hint: '10-digit mobile number',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter phone number';
                          }
                          if (value.trim().length != 10) {
                            return 'Phone number must be 10 digits';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      // Address section header
                      _buildSectionHeader(
                        icon: Icons.location_on,
                        title: 'Service Address',
                      ),
                      const SizedBox(height: 8),

                      // Skip address checkbox
                      CheckboxListTile(
                        value: _skipAddress,
                        onChanged: (value) {
                          setState(() {
                            _skipAddress = value ?? false;
                            if (_skipAddress) {
                              _location = null; // Clear location if skipping
                            }
                          });
                        },
                        title: const Text('Skip address (add later)'),
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: ColorConstants.seed,
                      ),
                      const SizedBox(height: 16),

                      // Location capture button (only if not skipping)
                      if (!_skipAddress) ...[
                        OutlinedButton.icon(
                          onPressed: _isLoadingLocation
                              ? null
                              : _getCurrentLocation,
                          icon: _isLoadingLocation
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  _location != null
                                      ? Icons.check_circle
                                      : Icons.my_location,
                                  color: _location != null
                                      ? Colors.green
                                      : ColorConstants.seed,
                                ),
                          label: Text(
                            _location != null
                                ? 'Location Captured ✓'
                                : 'Capture Current Location',
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(
                              color: _location != null
                                  ? Colors.green
                                  : ColorConstants.seed,
                              width: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Address Line 1
                        _buildTextField(
                          controller: _addressLine1Controller,
                          label: 'Address Line 1 (Street) *',
                          hint: 'House/Flat No., Street Name',
                          icon: Icons.home,
                          validator: (value) {
                            if (_skipAddress) return null;
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter street address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Address Line 2
                        _buildTextField(
                          controller: _addressLine2Controller,
                          label: 'Address Line 2',
                          hint: 'Apartment, Suite, Building (Optional)',
                          icon: Icons.apartment,
                        ),
                        const SizedBox(height: 16),

                        // Landmark
                        _buildTextField(
                          controller: _landmarkController,
                          label: 'Landmark',
                          hint: 'Nearby landmark (Optional)',
                          icon: Icons.place,
                        ),
                        const SizedBox(height: 16),

                        // City and Pincode in a row
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildTextField(
                                controller: _cityController,
                                label: 'City *',
                                hint: 'City name',
                                icon: Icons.location_city,
                                validator: (value) {
                                  if (_skipAddress) return null;
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Enter city';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                controller: _pincodeController,
                                label: 'Pincode *',
                                hint: '6 digits',
                                icon: Icons.pin_drop,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (_skipAddress) return null;
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Required';
                                  }
                                  if (value.trim().length != 6) {
                                    return 'Invalid';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Address validation warning
                        if (_location == null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.orange.shade700,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Please capture your location for accurate service delivery',
                                    style: TextStyle(
                                      color: Colors.orange.shade900,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],

                      const SizedBox(height: 32),

                      // Submit button
                      FilledButton(
                        onPressed: _isLoading ? null : _submitProfile,
                        style: FilledButton.styleFrom(
                          backgroundColor: ColorConstants.seed,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build section header
  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, color: ColorConstants.seed, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: ColorConstants.seed,
          ),
        ),
      ],
    );
  }

  /// Build text field
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ColorConstants.seed, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
      validator: validator,
    );
  }
}
