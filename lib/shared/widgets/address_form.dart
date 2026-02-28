import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:voicesewa_client/core/constants/color_constants.dart';
import 'package:voicesewa_client/shared/models/address_model.dart';
import 'package:voicesewa_client/core/extensions/context_extensions.dart';
import 'package:voicesewa_client/core/extensions/context_extensions.dart';

/// Reusable address form widget
/// Can be used in profile setup, job creation, and anywhere else addresses are needed
class AddressFormWidget extends StatefulWidget {
  final TextEditingController line1Controller;
  final TextEditingController line2Controller;
  final TextEditingController landmarkController;
  final TextEditingController cityController;
  final TextEditingController pincodeController;

  /// Current location (optional - used for GPS-based addresses)
  final GeoPoint? location;

  /// Callback when location is captured
  final Function(GeoPoint)? onLocationCaptured;

  /// Whether to show the location capture button
  final bool showLocationCapture;

  /// Whether to show validation warnings
  final bool showValidationWarnings;

  /// Whether the form is required or can be skipped
  final bool isRequired;

  const AddressFormWidget({
    super.key,
    required this.line1Controller,
    required this.line2Controller,
    required this.landmarkController,
    required this.cityController,
    required this.pincodeController,
    this.location,
    this.onLocationCaptured,
    this.showLocationCapture = false,
    this.showValidationWarnings = false,
    this.isRequired = true,
  });

  @override
  State<AddressFormWidget> createState() => _AddressFormWidgetState();
}

class _AddressFormWidgetState extends State<AddressFormWidget> {
  bool _isLoadingLocation = false;

  /// Get current location using GPS, then reverse-geocode to auto-fill fields
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

      final geoPoint = GeoPoint(position.latitude, position.longitude);

      // Reverse geocode and auto-fill fields (non-blocking on failure)
      await _reverseGeocode(position.latitude, position.longitude);

      if (mounted) {
        widget.onLocationCaptured?.call(geoPoint);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.loc.locationCapturedAddressAutofilled),
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
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  /// Reverse geocode [lat]/[lng] and auto-fill any currently empty fields.
  /// Only fills a field if the user has not typed anything yet,
  /// so manual edits are never overwritten.
  Future<void> _reverseGeocode(double lat, double lng) async {
    try {
      print('🗺️ Reverse geocoding: $lat, $lng');

      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) {
        print('⚠️ No placemarks returned');
        return;
      }

      final p = placemarks.first;
      print('📍 Placemark: ${p.toJson()}');

      // Line 1: street number + street name
      if (widget.line1Controller.text.trim().isEmpty) {
        final line1 = [
          p.subThoroughfare,
          p.thoroughfare,
        ].where((s) => s != null && s.isNotEmpty).join(' ');
        if (line1.isNotEmpty) widget.line1Controller.text = line1;
      }

      // Line 2: sub-locality / neighbourhood
      if (widget.line2Controller.text.trim().isEmpty) {
        final line2 = p.subLocality ?? '';
        if (line2.isNotEmpty) widget.line2Controller.text = line2;
      }

      // Landmark: locality as a familiar nearby area name
      if (widget.landmarkController.text.trim().isEmpty) {
        final landmark = p.locality ?? '';
        if (landmark.isNotEmpty) widget.landmarkController.text = landmark;
      }

      // City: locality -> subAdministrativeArea -> administrativeArea
      if (widget.cityController.text.trim().isEmpty) {
        final city =
            [
              p.locality,
              p.subAdministrativeArea,
              p.administrativeArea,
            ].firstWhere(
              (s) => s != null && s.isNotEmpty,
              orElse: () => null,
            ) ??
            '';
        if (city.isNotEmpty) widget.cityController.text = city;
      }

      // Pincode: postalCode
      if (widget.pincodeController.text.trim().isEmpty) {
        final pincode = p.postalCode ?? '';
        if (pincode.isNotEmpty) widget.pincodeController.text = pincode;
      }

      print('✅ Fields auto-filled from geocoding');
    } catch (e) {
      // Non-critical: location already captured, just log and continue
      print('⚠️ Reverse geocoding failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Location Capture Button (optional)
        if (widget.showLocationCapture) ...[
          OutlinedButton.icon(
            onPressed: _isLoadingLocation ? null : _getCurrentLocation,
            icon: _isLoadingLocation
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    widget.location != null
                        ? Icons.location_on
                        : Icons.location_off,
                    color: widget.location != null ? Colors.green : Colors.grey,
                  ),
            label: Text(
              widget.location != null
                  ? 'Location Captured ✓'
                  : 'Use Current Location & Auto-fill',
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(
                color: widget.location != null
                    ? Colors.green
                    : ColorConstants.seed,
                width: 2,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Address Line 1
        TextFormField(
          controller: widget.line1Controller,
          decoration: InputDecoration(
            labelText:
                'Address Line 1 (Street) ${widget.isRequired ? '*' : ''}',
            hintText: context.loc.houseFlatNoStreetName,
            prefixIcon: const Icon(Icons.home),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: ColorConstants.seed,
                width: 2,
              ),
            ),
          ),
          validator: widget.isRequired
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter street address';
                  }
                  return null;
                }
              : null,
        ),
        const SizedBox(height: 12),

        // Address Line 2
        TextFormField(
          controller: widget.line2Controller,
          decoration: InputDecoration(
            labelText: context.loc.addressLine2,
            hintText: context.loc.apartmentSuiteBuildingOptional,
            prefixIcon: const Icon(Icons.apartment),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: ColorConstants.seed,
                width: 2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Landmark
        TextFormField(
          controller: widget.landmarkController,
          decoration: InputDecoration(
            labelText: context.loc.landmark,
            hintText: context.loc.nearbyLandmarkOptional,
            prefixIcon: const Icon(Icons.place),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: ColorConstants.seed,
                width: 2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // City and Pincode in a row
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: widget.cityController,
                decoration: InputDecoration(
                  labelText: 'City ${widget.isRequired ? '*' : ''}',
                  hintText: context.loc.cityName,
                  prefixIcon: const Icon(Icons.location_city),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: ColorConstants.seed,
                      width: 2,
                    ),
                  ),
                ),
                validator: widget.isRequired
                    ? (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter city';
                        }
                        return null;
                      }
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: widget.pincodeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Pincode ${widget.isRequired ? '*' : ''}',
                  hintText: context.loc.sixDigits,
                  prefixIcon: const Icon(Icons.pin_drop),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: ColorConstants.seed,
                      width: 2,
                    ),
                  ),
                ),
                validator: widget.isRequired
                    ? (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        if (value.trim().length < 5) {
                          return 'Invalid';
                        }
                        return null;
                      }
                    : null,
              ),
            ),
          ],
        ),

        // Validation Warning (optional)
        if (widget.showValidationWarnings &&
            widget.showLocationCapture &&
            widget.location == null) ...[
          const SizedBox(height: 12),
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
      ],
    );
  }

  /// Helper to create an Address object from the form data
  /// Call this method to get the Address when submitting
  Address? getAddress() {
    // Check if any required fields are empty
    if (widget.isRequired) {
      if (widget.line1Controller.text.trim().isEmpty ||
          widget.cityController.text.trim().isEmpty ||
          widget.pincodeController.text.trim().isEmpty) {
        return null;
      }
    }

    return Address(
      location: widget.location ?? const GeoPoint(0, 0),
      line1: widget.line1Controller.text.trim(),
      line2: widget.line2Controller.text.trim(),
      landmark: widget.landmarkController.text.trim(),
      pincode: widget.pincodeController.text.trim(),
      city: widget.cityController.text.trim(),
    );
  }
}
