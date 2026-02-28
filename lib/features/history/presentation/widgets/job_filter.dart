import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/extensions/context_extensions.dart';

// Filter & Sort State Providers — values are always neutral English keys
final statusFilterProvider = StateProvider<String>((ref) => 'All');
final sortOptionProvider = StateProvider<String>((ref) => 'newest');

class JobFilterBar extends ConsumerWidget {
  const JobFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusFilter = ref.watch(statusFilterProvider);
    final sortOption = ref.watch(sortOptionProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ---- Filter Dropdown ----
          Expanded(
            child: DropdownButtonFormField<String>(
              // key = neutral English key; value shown = localized label
              value: statusFilter,
              icon: const Icon(Icons.filter_alt_outlined, size: 20),
              decoration: InputDecoration(
                labelText: context.loc.filter,
                labelStyle: const TextStyle(fontSize: 13),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: [
                DropdownMenuItem(value: 'All', child: Text(context.loc.all)),
                DropdownMenuItem(
                  value: 'Scheduled',
                  child: Text(context.loc.scheduled),
                ),
                DropdownMenuItem(
                  value: 'inProgress',
                  child: Text(context.loc.inProgress),
                ),
                DropdownMenuItem(
                  value: 'Completed',
                  child: Text(context.loc.completed),
                ),
                DropdownMenuItem(
                  value: 'Cancelled',
                  child: Text(context.loc.cancelled),
                ),
              ],
              onChanged: (value) =>
                  ref.read(statusFilterProvider.notifier).state = value!,
            ),
          ),
          const SizedBox(width: 8),

          // ---- Sort Dropdown ----
          Expanded(
            child: DropdownButtonFormField<String>(
              value: sortOption,
              icon: const Icon(Icons.sort_outlined, size: 20),
              decoration: InputDecoration(
                labelText: context.loc.sort,
                labelStyle: const TextStyle(fontSize: 13),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: [
                // ✅ All values are now neutral keys — never translated strings
                DropdownMenuItem(
                  value: 'newest',
                  child: Text(context.loc.newestFirst),
                ),
                DropdownMenuItem(
                  value: 'oldest',
                  child: Text(context.loc.oldestFirst),
                ),
                DropdownMenuItem(
                  value: 'amount_asc',
                  child: Text('${context.loc.amount} ↑'),
                ),
                DropdownMenuItem(
                  value: 'amount_desc',
                  child: Text('${context.loc.amount} ↓'),
                ),
                DropdownMenuItem(
                  value: 'rating_asc',
                  child: Text('${context.loc.rating} ↑'),
                ),
                DropdownMenuItem(
                  value: 'rating_desc',
                  child: Text('${context.loc.rating} ↓'),
                ),
              ],
              onChanged: (value) =>
                  ref.read(sortOptionProvider.notifier).state = value!,
            ),
          ),
        ],
      ),
    );
  }
}
