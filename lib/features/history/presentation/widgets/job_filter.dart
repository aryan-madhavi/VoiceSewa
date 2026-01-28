import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/extensions/context_extensions.dart';

// Filter & Sort State Providers
final statusFilterProvider = StateProvider<String>((ref) => 'All');
final sortOptionProvider = StateProvider<String>((ref) => 'Newest First');

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
              value: statusFilter,
              icon: const Icon(Icons.filter_alt_outlined, size: 20),
              decoration: InputDecoration(
                labelText: context.loc.filter,  //'Filter',
                labelStyle: const TextStyle(fontSize: 13),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: [
                DropdownMenuItem(value: 'All', child: Text(
                  context.loc.all, //'All'
                )),
                DropdownMenuItem(value: 'Scheduled', child: Text(
                  context.loc.scheduled, //'Scheduled'
                )),
                DropdownMenuItem(
                    value: 'In Progress', child: Text(
                  context.loc.inProgress, //'In Progress'
                )),
                DropdownMenuItem(value: 'Completed', child: Text(
                  context.loc.completed, //'Completed'
                )),
                DropdownMenuItem(value: 'Cancelled', child: Text(
                  context.loc.cancelled, //'Cancelled'
                )),
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
                labelText: context.loc.sort,  //'Sort',
                labelStyle: const TextStyle(fontSize: 13),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: [
                DropdownMenuItem(value: 'Newest First', child: Text(
                  context.loc.newestFirst, //'Newest First'
                )),
                DropdownMenuItem(value: 'Oldest First', child: Text(
                  context.loc.oldestFirst, //'Oldest First'
                )),
                DropdownMenuItem(value: 'Amount ↑', child: Text(
                    '${context.loc.amount} ↑'
                )),
                DropdownMenuItem(value: 'Amount ↓', child: Text('${context.loc.amount} ↓')),
                DropdownMenuItem(value: 'Rating ↑', child: Text('${context.loc.rating} ↑')),
                DropdownMenuItem(value: 'Rating ↓', child: Text('${context.loc.rating} ↓')),
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
