import 'package:flutter/material.dart';
import 'package:voicesewa_worker/core/constants/color_constants.dart';

class JobFilterBar extends StatelessWidget {
  final String sort;
  final ValueChanged<String> onSortChanged;
  final List<String> sortOptions;

  const JobFilterBar({
    super.key,
    required this.sort,
    required this.onSortChanged,
    required this.sortOptions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: ColorConstants.pureWhite,
      child: Row(
        children: [
          const Icon(Icons.sort, size: 16, color: ColorConstants.textGrey),
          const SizedBox(width: 8),
          const Text(
            'Sort:',
            style: TextStyle(fontSize: 13, color: ColorConstants.textGrey),
          ),
          const SizedBox(width: 8),
          JobSortDropdown(
            value: sort,
            options: sortOptions,
            onChanged: onSortChanged,
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class JobSortDropdown extends StatelessWidget {
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const JobSortDropdown({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: ColorConstants.chipGreyBorder),
        borderRadius: BorderRadius.circular(20),
        color: ColorConstants.chipGreySurface2,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 16),
          style: const TextStyle(
            fontSize: 13,
            color: ColorConstants.textDark,
            fontWeight: FontWeight.w500,
          ),
          items: options
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}