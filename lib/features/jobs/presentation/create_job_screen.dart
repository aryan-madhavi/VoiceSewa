import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:voicesewa_client/core/constants/color_constants.dart';
import 'package:voicesewa_client/features/jobs/presentation/widgets/create_job_widgets.dart';
import 'package:voicesewa_client/shared/models/address_model.dart';
import 'package:voicesewa_client/features/jobs/providers/client_provider.dart';
import 'package:voicesewa_client/features/jobs/providers/job_provider.dart';
import 'package:voicesewa_client/shared/data/services_data.dart';
import 'package:voicesewa_client/shared/widgets/address_form.dart';

class CreateJobScreen extends ConsumerStatefulWidget {
  final Services? preselectedService;

  const CreateJobScreen({super.key, this.preselectedService});

  @override
  ConsumerState<CreateJobScreen> createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends ConsumerState<CreateJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  // Address form controllers (for new address)
  final _line1Controller = TextEditingController();
  final _line2Controller = TextEditingController();
  final _landmarkController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _cityController = TextEditingController();

  Services? _selectedService;
  Address? _selectedAddress;
  DateTime? _scheduledDate;
  bool _isLoading = false;
  bool _showAddNewAddress = false;
  GeoPoint? _newAddressLocation; // Track location for new address
  bool _hasAutoSelectedAddress = false; // Track if we've auto-selected

  @override
  void initState() {
    super.initState();
    _selectedService = widget.preselectedService;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _line1Controller.dispose();
    _line2Controller.dispose();
    _landmarkController.dispose();
    _pincodeController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  /// ✅ Auto-select first address when addresses load (only if service is preselected)
  void _autoSelectFirstAddress(List<Address> addresses) {
    if (widget.preselectedService != null &&
        !_hasAutoSelectedAddress &&
        addresses.isNotEmpty &&
        _selectedAddress == null) {
      setState(() {
        _selectedAddress = addresses.first;
        _hasAutoSelectedAddress = true;
      });
      print('✅ Auto-selected first address: ${addresses.first.shortAddress}');
    }
  }

  Future<void> _selectScheduledDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _scheduledDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'When do you want this job done?',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: ColorConstants.seed,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _scheduledDate) {
      setState(() {
        _scheduledDate = picked;
      });
    }
  }

  /// ✅ Save new address to client's Firestore collection
  Future<Address?> _saveNewAddressToClient(Address address) async {
    try {
      print('💾 Saving new address to client collection...');

      final clientActions = ref.read(clientActionsProvider);
      await clientActions.addAddress(address);

      print('✅ Address saved to client collection');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Address saved for future use'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

      return address;
    } catch (e) {
      print('❌ Error saving address to client: $e');

      // Still return the address so job creation can continue
      // Show warning but don't block the flow
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Address not saved for future: $e'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      return address;
    }
  }

  Future<void> _submitJob() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedService == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a service')));
      return;
    }

    if (_scheduledDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select when you want the job done'),
        ),
      );
      return;
    }

    // Check if address is selected or new address is filled
    Address? addressToUse = _selectedAddress;

    if (_showAddNewAddress) {
      // Validate new address fields
      if (_line1Controller.text.trim().isEmpty ||
          _cityController.text.trim().isEmpty ||
          _pincodeController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill required address fields')),
        );
        return;
      }

      // Check if location is captured for new address
      if (_newAddressLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please capture location for the address'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Create new address with captured location
      addressToUse = Address(
        location: _newAddressLocation!,
        line1: _line1Controller.text.trim(),
        line2: _line2Controller.text.trim(),
        landmark: _landmarkController.text.trim(),
        pincode: _pincodeController.text.trim(),
        city: _cityController.text.trim(),
      );

      // ✅ AUTO-SAVE: Save the new address to client collection
      // This happens before job creation
      addressToUse = await _saveNewAddressToClient(addressToUse);
    } else if (_selectedAddress == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select an address')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final actions = ref.read(jobActionsProvider);

      final jobId = await actions
          .createJob(
            serviceType: _selectedService!,
            description: _descriptionController.text.trim(),
            address: addressToUse!,
            scheduledAt: _scheduledDate!,
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('⏰ Job creation timed out - job queued locally');
              return '';
            },
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _showAddNewAddress
                  ? 'Job created and address saved!'
                  : 'Job created successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, jobId.isNotEmpty ? jobId : null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final savedAddressesAsync = ref.watch(clientAddressesProvider);

    return Scaffold(
      backgroundColor: ColorConstants.scaffold,
      appBar: AppBar(
        title: const Text('Create Job Request'),
        backgroundColor: ColorConstants.appBar,
      ),
      body: SafeArea(
        child: savedAddressesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error loading addresses: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(clientAddressesProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (savedAddresses) {
            // ✅ Auto-select first address when data loads
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _autoSelectFirstAddress(savedAddresses);
            });

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Service Selector - Dropdown
                      ServiceDropdown(
                        selectedService: _selectedService,
                        onServiceSelected: (service) {
                          setState(() => _selectedService = service);
                        },
                      ),
                      const SizedBox(height: 24),

                      // Job Description
                      JobDescriptionField(controller: _descriptionController),
                      const SizedBox(height: 24),

                      // Scheduled Date
                      ScheduledDatePicker(
                        selectedDate: _scheduledDate,
                        onTap: _selectScheduledDate,
                        onClear: () => setState(() => _scheduledDate = null),
                      ),
                      const SizedBox(height: 24),

                      // Address Selection
                      AddressSelectionSection(
                        savedAddresses: savedAddresses,
                        selectedAddress: _selectedAddress,
                        showAddNewAddress: _showAddNewAddress,
                        onAddressSelected: (address) {
                          setState(() => _selectedAddress = address);
                        },
                        onToggleAddNew: () {
                          setState(() {
                            _showAddNewAddress = !_showAddNewAddress;
                            if (_showAddNewAddress) {
                              _selectedAddress = null;
                              _newAddressLocation = null; // Reset location
                            }
                          });
                        },
                      ),

                      // New Address Form (if showing)
                      if (_showAddNewAddress) ...[
                        const SizedBox(height: 12),

                        // ✅ Info card about auto-save
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.blue.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'This address will be saved to your profile for future use',
                                  style: TextStyle(
                                    color: Colors.blue.shade900,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        AddressFormWidget(
                          line1Controller: _line1Controller,
                          line2Controller: _line2Controller,
                          landmarkController: _landmarkController,
                          cityController: _cityController,
                          pincodeController: _pincodeController,
                          location: _newAddressLocation,
                          onLocationCaptured: (location) {
                            setState(() {
                              _newAddressLocation = location;
                            });
                          },
                          showLocationCapture: true, // Enable GPS capture
                          showValidationWarnings: true, // Show warnings
                          isRequired: true,
                        ),
                      ],

                      const SizedBox(height: 32),

                      // Submit Button
                      SubmitJobButton(
                        isLoading: _isLoading,
                        onPressed: _submitJob,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}