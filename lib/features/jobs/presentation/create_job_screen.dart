import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:voicesewa_client/core/constants/color_constants.dart';
import 'package:voicesewa_client/shared/models/address_model.dart';
import 'package:voicesewa_client/features/jobs/providers/client_provider.dart';
import 'package:voicesewa_client/features/jobs/providers/job_provider.dart';
import 'package:voicesewa_client/shared/data/services_data.dart';

class CreateJobScreen extends ConsumerStatefulWidget {
  final Services? preselectedService;

  const CreateJobScreen({super.key, this.preselectedService});

  @override
  ConsumerState<CreateJobScreen> createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends ConsumerState<CreateJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  // For new address
  final _line1Controller = TextEditingController();
  final _line2Controller = TextEditingController();
  final _landmarkController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _cityController = TextEditingController();

  Services? _selectedService;
  Address? _selectedAddress;
  bool _isLoading = false;
  bool _showAddNewAddress = false;

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

  Future<void> _submitJob() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedService == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a service')));
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

      // Create new address
      addressToUse = Address(
        location: const GeoPoint(0, 0), // TODO: Get actual location
        line1: _line1Controller.text.trim(),
        line2: _line2Controller.text.trim(),
        landmark: _landmarkController.text.trim(),
        pincode: _pincodeController.text.trim(),
        city: _cityController.text.trim(),
      );
    } else if (_selectedAddress == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select an address')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final actions = ref.read(jobActionsProvider);
      final jobId = await actions.createJob(
        serviceType: _selectedService!,
        description: _descriptionController.text.trim(),
        address: addressToUse!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, jobId);
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
    // Watch the async provider properly
    final savedAddressesAsync = ref.watch(clientAddressesProvider);

    return Scaffold(
      backgroundColor: ColorConstants.scaffold,
      appBar: AppBar(
        title: const Text('Create Job Request'),
        backgroundColor: ColorConstants.appBar,
      ),
      body: SafeArea(
        child: savedAddressesAsync.when(
          // Loading state
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          // Error state
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error loading addresses: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(clientAddressesProvider);
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          // Data loaded successfully
          data: (savedAddresses) => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Service Selection
                  Text(
                    'Select Service',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<Services>(
                    isExpanded: true,
                    value: _selectedService,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.business_center),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: Services.values.map((service) {
                      final data = ServicesData.services[service]!;
                      return DropdownMenuItem(
                        value: service,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(data[1] as IconData, color: data[0] as Color),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                data[2] as String,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedService = value);
                    },
                    validator: (value) =>
                        value == null ? 'Please select a service' : null,
                  ),
                  const SizedBox(height: 16),

                  // Description
                  Text(
                    'Job Description',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Describe what needs to be done...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a description';
                      }
                      if (value.trim().length < 10) {
                        return 'Description must be at least 10 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Address Section Header with Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Job Address',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      if (savedAddresses.isNotEmpty)
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(
                              value: false,
                              label: Text('Saved'),
                              icon: Icon(Icons.bookmark, size: 16),
                            ),
                            ButtonSegment(
                              value: true,
                              label: Text('New'),
                              icon: Icon(Icons.add, size: 16),
                            ),
                          ],
                          selected: {_showAddNewAddress},
                          onSelectionChanged: (Set<bool> selected) {
                            setState(() {
                              _showAddNewAddress = selected.first;
                              if (_showAddNewAddress) {
                                _selectedAddress = null;
                              }
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Show saved addresses dropdown OR new address form
                  if (!_showAddNewAddress && savedAddresses.isNotEmpty) ...[
                    // Dropdown for saved addresses
                    DropdownButtonFormField<Address>(
                      isExpanded: true,
                      value: _selectedAddress,
                      isDense: true,
                      menuMaxHeight: 300,
                      decoration: InputDecoration(
                        labelText: 'Select Address',
                        prefixIcon: const Icon(Icons.location_on),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: savedAddresses.map((address) {
                        return DropdownMenuItem(
                          value: address,
                          child: Row(
                            children: [
                              const Icon(Icons.location_on, size: 18, color: Colors.grey),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${address.line1}, ${address.city}',
                                  style: const TextStyle(fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedAddress = value);
                      },
                    ),

                    // Show selected address details
                    if (_selectedAddress != null) ...[
                      const SizedBox(height: 12),
                      Card(
                        color: Colors.green.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 16,
                                    color: Colors.green.shade700,
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Selected Address',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _selectedAddress!.fullAddress,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ] else ...[
                    // New address form
                    if (savedAddresses.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text(
                          'No saved addresses. Please add one below.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),

                    TextFormField(
                      controller: _line1Controller,
                      decoration: InputDecoration(
                        labelText: 'Address Line 1 *',
                        prefixIcon: const Icon(Icons.home),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _line2Controller,
                      decoration: InputDecoration(
                        labelText: 'Address Line 2',
                        prefixIcon: const Icon(Icons.home_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _landmarkController,
                      decoration: InputDecoration(
                        labelText: 'Landmark',
                        prefixIcon: const Icon(Icons.place),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _pincodeController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Pincode *',
                              prefixIcon: const Icon(Icons.pin_drop),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _cityController,
                            decoration: InputDecoration(
                              labelText: 'City *',
                              prefixIcon: const Icon(Icons.location_city),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Submit Button
                  FilledButton(
                    onPressed: _isLoading ? null : _submitJob,
                    style: FilledButton.styleFrom(
                      backgroundColor: ColorConstants.seed,
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
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Submit Job Request',
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
    );
  }
}