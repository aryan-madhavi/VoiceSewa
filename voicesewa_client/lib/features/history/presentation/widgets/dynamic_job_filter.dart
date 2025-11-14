import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

class DynamicJobFilterBar extends ConsumerWidget {
  final List<String> statusOptions;
  final List<String> sortOptions;
  final StateProvider<String> statusProvider;
  final StateProvider<String> sortProvider;

  const DynamicJobFilterBar({
    super.key,
    required this.statusOptions,
    required this.sortOptions,
    required this.statusProvider,
    required this.sortProvider,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedStatus = ref.watch(statusProvider);
    final selectedSort = ref.watch(sortProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Filter
          Expanded(
            child: DropdownButtonFormField<String>(
              value: selectedStatus,
              icon: const Icon(Icons.filter_alt_outlined, size: 20),
              decoration: InputDecoration(
                labelText: 'Filter',
                labelStyle: const TextStyle(fontSize: 13),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: statusOptions
                  .map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) ref.read(statusProvider.notifier).state = value;
              },
            ),
          ),
          const SizedBox(width: 8),

          // Sort
          Expanded(
            child: DropdownButtonFormField<String>(
              value: selectedSort,
              icon: const Icon(Icons.sort_outlined, size: 20),
              decoration: InputDecoration(
                labelText: 'Sort',
                labelStyle: const TextStyle(fontSize: 13),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: sortOptions
                  .map((sort) => DropdownMenuItem(
                        value: sort,
                        child: Text(sort),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) ref.read(sortProvider.notifier).state = value;
              },
            ),
          ),
        ],
      ),
    );
  }
}
