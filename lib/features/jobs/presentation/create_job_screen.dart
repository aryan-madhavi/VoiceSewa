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
  DateTime? _scheduledDate; // ✅ When client wants the job done
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

  // ✅ Date picker for when client wants the job done
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
        scheduledAt: _scheduledDate!, // ✅ Client sets scheduled date
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
                    onChanged: (value) =>
                        setState(() => _selectedService = value),
                    validator: (value) =>
                        value == null ? 'Please select a service' : null,
                  ),
                  const SizedBox(height: 24),

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
                      hintText:
                          'Describe your job requirements in detail... (min 10 characters)',
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

                  // ✅ Scheduled Date Selection (REQUIRED)
                  Text(
                    'When do you want this job done? *',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _selectScheduledDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _scheduledDate != null
                              ? ColorConstants.seed
                              : Colors.grey.shade400,
                          width: _scheduledDate != null ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: _scheduledDate != null
                            ? ColorConstants.seed.withOpacity(0.05)
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: _scheduledDate != null
                                ? ColorConstants.seed
                                : Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _scheduledDate != null
                                  ? '${_scheduledDate!.day}/${_scheduledDate!.month}/${_scheduledDate!.year}'
                                  : 'Tap to select date',
                              style: TextStyle(
                                color: _scheduledDate != null
                                    ? Colors.black87
                                    : Colors.grey,
                                fontWeight: _scheduledDate != null
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (_scheduledDate != null)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () =>
                                  setState(() => _scheduledDate = null),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Workers will see this date and confirm availability in their quotations.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Address Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Job Location',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (savedAddresses.isNotEmpty)
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _showAddNewAddress = !_showAddNewAddress;
                              if (_showAddNewAddress) _selectedAddress = null;
                            });
                          },
                          icon: Icon(
                            _showAddNewAddress ? Icons.list : Icons.add,
                            size: 18,
                          ),
                          label: Text(
                            _showAddNewAddress ? 'Select Saved' : 'Add New',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (!_showAddNewAddress && savedAddresses.isNotEmpty) ...[
                    // Saved addresses dropdown
                    DropdownButtonFormField<Address>(
                      isExpanded: true,
                      value: _selectedAddress,
                      decoration: InputDecoration(
                        labelText: 'Select Address',
                        prefixIcon: const Icon(Icons.location_on),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: savedAddresses.map((address) {
                        return DropdownMenuItem(
                          value: address,
                          child: Text(
                            '${address.line1}, ${address.city}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => _selectedAddress = value),
                    ),
                    if (_selectedAddress != null) ...[
                      const SizedBox(height: 12),
                      Card(
                        color: Colors.green.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(_selectedAddress!.fullAddress),
                        ),
                      ),
                    ],
                  ] else ...[
                    // New address form
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