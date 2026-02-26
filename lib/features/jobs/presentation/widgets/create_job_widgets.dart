import 'package:flutter/material.dart';
import 'package:voicesewa_client/core/constants/color_constants.dart';
import 'package:voicesewa_client/shared/data/services_data.dart';
import 'package:voicesewa_client/shared/models/address_model.dart';

/// Service selector dropdown widget
class ServiceDropdown extends StatelessWidget {
  final Services? selectedService;
  final ValueChanged<Services?> onServiceSelected;

  const ServiceDropdown({
    super.key,
    required this.selectedService,
    required this.onServiceSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Service *',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<Services>(
          isExpanded: true,
          value: selectedService,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.business_center),
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
          items: Services.values.map((service) {
            final data = ServicesData.services[service]!;
            final color = data[0] as Color;
            final icon = data[1] as IconData;
            final label = data[2] as String;

            return DropdownMenuItem(
              value: service,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 12),
                  Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
                ],
              ),
            );
          }).toList(),
          onChanged: onServiceSelected,
          validator: (value) =>
              value == null ? 'Please select a service' : null,
        ),
      ],
    );
  }
}

/// Service selector grid widget
class ServiceSelectorGrid extends StatelessWidget {
  final Services? selectedService;
  final ValueChanged<Services?> onServiceSelected;

  const ServiceSelectorGrid({
    super.key,
    required this.selectedService,
    required this.onServiceSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Service *',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: Services.values.length,
          itemBuilder: (context, index) {
            final service = Services.values[index];
            final isSelected = selectedService == service;

            return ServiceCard(
              service: service,
              isSelected: isSelected,
              onTap: () => onServiceSelected(service),
            );
          },
        ),
      ],
    );
  }
}

/// Individual service card widget
class ServiceCard extends StatelessWidget {
  final Services service;
  final bool isSelected;
  final VoidCallback onTap;

  const ServiceCard({
    super.key,
    required this.service,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Get service data from ServicesData
    final data = ServicesData.services[service]!;
    final color = data[0] as Color;
    final icon = data[1] as IconData;
    final label = data[2] as String;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected ? color : Colors.grey.shade600,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? color : Colors.black87,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Job description text field widget
class JobDescriptionField extends StatelessWidget {
  final TextEditingController controller;

  const JobDescriptionField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Job Description *',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Describe what you need done...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
      ],
    );
  }
}

/// Scheduled date picker widget
class ScheduledDatePicker extends StatelessWidget {
  final DateTime? selectedDate;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const ScheduledDatePicker({
    super.key,
    required this.selectedDate,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'When do you want this job done? *',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: selectedDate != null
                    ? ColorConstants.seed
                    : Colors.grey.shade400,
                width: selectedDate != null ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
              color: selectedDate != null
                  ? ColorConstants.seed.withOpacity(0.05)
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: selectedDate != null
                      ? ColorConstants.seed
                      : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selectedDate != null
                        ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                        : 'Tap to select date',
                    style: TextStyle(
                      color: selectedDate != null
                          ? Colors.black87
                          : Colors.grey,
                      fontWeight: selectedDate != null
                          ? FontWeight.w600
                          : FontWeight.normal,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (selectedDate != null && onClear != null)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: onClear,
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
      ],
    );
  }
}

/// Address selection section widget
class AddressSelectionSection extends StatelessWidget {
  final List<Address> savedAddresses;
  final Address? selectedAddress;
  final bool showAddNewAddress;
  final ValueChanged<Address?> onAddressSelected;
  final VoidCallback onToggleAddNew;

  const AddressSelectionSection({
    super.key,
    required this.savedAddresses,
    required this.selectedAddress,
    required this.showAddNewAddress,
    required this.onAddressSelected,
    required this.onToggleAddNew,
  });

  @override
  Widget build(BuildContext context) {
    final hasAddresses = savedAddresses.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Job Location',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            // Show "Add New" when there are saved addresses and not already adding
            // Show "Select Saved" when currently adding and saved addresses exist
            if (hasAddresses)
              TextButton.icon(
                onPressed: onToggleAddNew,
                icon: Icon(
                  showAddNewAddress ? Icons.list : Icons.add,
                  size: 18,
                ),
                label: Text(
                  showAddNewAddress ? 'Select Saved' : 'Add New',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // No saved addresses: always show a prompt to add one
        if (!hasAddresses && !showAddNewAddress)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.location_off, color: Colors.orange.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No saved addresses. Please add one below.',
                    style: TextStyle(
                      color: Colors.orange.shade900,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Dropdown only when there are saved addresses and not adding new
        if (!showAddNewAddress && hasAddresses)
          SavedAddressDropdown(
            addresses: savedAddresses,
            selectedAddress: selectedAddress,
            onChanged: onAddressSelected,
          ),
      ],
    );
  }
}

/// Saved address dropdown widget
class SavedAddressDropdown extends StatelessWidget {
  final List<Address> addresses;
  final Address? selectedAddress;
  final ValueChanged<Address?> onChanged;

  const SavedAddressDropdown({
    super.key,
    required this.addresses,
    required this.selectedAddress,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DropdownButtonFormField<Address>(
          isExpanded: true,
          value: selectedAddress,
          decoration: InputDecoration(
            labelText: 'Select Address',
            prefixIcon: const Icon(Icons.location_on),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: addresses.map((address) {
            return DropdownMenuItem(
              value: address,
              child: Text(
                '${address.line1}, ${address.city}',
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
        if (selectedAddress != null) ...[
          const SizedBox(height: 12),
          Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(selectedAddress!.fullAddress),
            ),
          ),
        ],
      ],
    );
  }
}

/// Submit job button widget
class SubmitJobButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;

  const SubmitJobButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: ColorConstants.seed,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: isLoading
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
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
    );
  }
}
