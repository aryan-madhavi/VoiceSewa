import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:voicesewa_client/core/extensions/context_extensions.dart';

class DynamicJobFilterBar extends ConsumerWidget {
  final Map<String, String> statusOptions;
  final Map<String, String> sortOptions;

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
          Expanded(
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              value: statusOptions.containsKey(selectedStatus)
                  ? selectedStatus
                  : statusOptions.keys.first,
              icon: const Icon(Icons.filter_alt_outlined, size: 20),
              decoration: InputDecoration(
                labelText: context.loc.filter,
                labelStyle: const TextStyle(fontSize: 13),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: statusOptions.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(
                    entry.value,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) ref.read(statusProvider.notifier).state = value;
              },
            ),
          ),
          const SizedBox(width: 8),

          Expanded(
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              value: sortOptions.containsKey(selectedSort)
                  ? selectedSort
                  : sortOptions.keys.first,
              icon: const Icon(Icons.sort_outlined, size: 20),
              decoration: InputDecoration(
                labelText: context.loc.sort,
                labelStyle: const TextStyle(fontSize: 13),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: sortOptions.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(
                    entry.value,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
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