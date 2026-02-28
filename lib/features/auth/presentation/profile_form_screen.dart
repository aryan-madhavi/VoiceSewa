import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:voicesewa_client/core/constants/color_constants.dart';
import 'package:voicesewa_client/shared/models/address_model.dart';
import 'package:voicesewa_client/shared/models/client_model.dart';
import 'package:voicesewa_client/features/auth/providers/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:voicesewa_client/features/auth/providers/profile_form_provider.dart';
import 'package:voicesewa_client/features/auth/services/fcm_service.dart';
import 'package:voicesewa_client/shared/widgets/address_form.dart';

/// Profile setup screen — creates Firestore profile and saves FCM token.
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _landmarkController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();

  GeoPoint? _location;
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

  void _onLocationCaptured(GeoPoint location) {
    setState(() => _location = location);
  }

  Future<void> _submitProfile() async {
    if (!_skipAddress) {
      if (!_formKey.currentState!.validate()) return;
    } else {
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
      if (user == null) throw Exception('No user logged in');

      print('💾 Creating profile for UID: ${user.uid}');

      // ── Build addresses ────────────────────────────────────────────────────
      final List<Address> addresses = [];
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

      // ── Save profile WITHOUT fcm_token first ───────────────────────────────
      // requestPermissionAndSave does an update(), which requires the doc to exist.
      // So we upsert the profile first, then save the token.
      final repo = ref.read(clientFirebaseRepositoryProvider);
      await repo.upsertProfile(
        ClientProfile(
          uid: user.uid,
          name: _nameController.text.trim(),
          email: user.email!,
          phone: _phoneController.text.trim(),
          addresses: addresses,
          fcmToken: null,
        ),
      );

      print('✅ Profile saved to Firestore');

      // ── Now save FCM token (doc exists, update() is safe) ──────────────────
      await ref.read(fcmServiceProvider).requestPermissionAndSave(user.uid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile created successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        ref.invalidate(userHasProfileProvider);

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
      if (mounted) setState(() => _isLoading = false);
    }
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
                      _buildSectionHeader(
                        icon: Icons.person,
                        title: 'Personal Information',
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _nameController,
                        label: 'Full Name *',
                        hint: 'Enter your full name',
                        icon: Icons.person_outline,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter your name'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _phoneController,
                        label: 'Phone Number *',
                        hint: '10-digit mobile number',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Please enter phone number';
                          }
                          if (v.trim().length != 10) {
                            return 'Phone number must be 10 digits';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      _buildSectionHeader(
                        icon: Icons.location_on,
                        title: 'Service Address',
                      ),
                      const SizedBox(height: 8),

                      CheckboxListTile(
                        value: _skipAddress,
                        onChanged: (v) => setState(() {
                          _skipAddress = v ?? false;
                          if (_skipAddress) _location = null;
                        }),
                        title: const Text('Skip address (add later)'),
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: ColorConstants.seed,
                      ),
                      const SizedBox(height: 16),

                      if (!_skipAddress)
                        AddressFormWidget(
                          line1Controller: _addressLine1Controller,
                          line2Controller: _addressLine2Controller,
                          landmarkController: _landmarkController,
                          cityController: _cityController,
                          pincodeController: _pincodeController,
                          location: _location,
                          onLocationCaptured: _onLocationCaptured,
                          showLocationCapture: true,
                          showValidationWarnings: true,
                          isRequired: true,
                        ),

                      const SizedBox(height: 32),

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
