import 'package:flutter/material.dart';
import 'package:voicesewa_worker/core/constants/color_constants.dart';
import 'package:voicesewa_worker/shared/models/job_model.dart';

/// A horizontally scrollable row of service chips derived from the worker's
/// own `skills` array. Shows a count badge per chip based on [jobs].
///
/// [skills]          — worker.skills from Firestore (display-name strings)
/// [jobs]            — the current filtered job list to count against
/// [selectedService] — currently active service filter, null = "All"
/// [onSelected]      — called with the service name, or null to clear
class ServiceFilterRow extends StatelessWidget {
  final List<String> skills;
  final List<JobModel> jobs;
  final String? selectedService;
  final ValueChanged<String?> onSelected;

  const ServiceFilterRow({
    super.key,
    required this.skills,
    required this.jobs,
    required this.selectedService,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Only include skills that appear at least once in the job list,
    // so we never show a chip that would yield an empty filtered list.
    // Exception: if a service IS selected (even if count is 0), always show it
    // so the user can tap to deselect.
    final relevantSkills = skills.where((skill) {
      final count = jobs.where((j) => j.serviceName == skill).length;
      return count > 0 || skill == selectedService;
    }).toList();

    // Don't render the row at all if only one (or zero) services are present
    // — a single service chip adds no value.
    if (relevantSkills.length <= 1 && selectedService == null) {
      return const SizedBox.shrink();
    }

    return Container(
      color: ColorConstants.pureWhite,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // "All Services" reset chip
            _ServiceChip(
              label: 'All Services',
              count: null, // don't show a count on the All chip
              selected: selectedService == null,
              onTap: () => onSelected(null),
            ),
            ...relevantSkills.map((skill) {
              final count = jobs.where((j) => j.serviceName == skill).length;
              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _ServiceChip(
                  label: skill,
                  count: count,
                  selected: selectedService == skill,
                  onTap: () =>
                      onSelected(selectedService == skill ? null : skill),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _ServiceChip extends StatelessWidget {
  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  const _ServiceChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = ColorConstants.primaryBlue;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? activeColor.withOpacity(0.1)
              : ColorConstants.chipGreySurface2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? activeColor : ColorConstants.chipGreyBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected ? activeColor : ColorConstants.textGrey,
              ),
            ),
            if (count != null && count! > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: selected ? activeColor : ColorConstants.chipGreyBadge,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 10,
                    color: ColorConstants.pureWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
