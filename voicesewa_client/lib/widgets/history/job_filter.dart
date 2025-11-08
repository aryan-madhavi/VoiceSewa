import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

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
                labelText: 'Filter',
                labelStyle: const TextStyle(fontSize: 13),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'All', child: Text('All')),
                DropdownMenuItem(value: 'Scheduled', child: Text('Scheduled')),
                DropdownMenuItem(
                    value: 'In Progress', child: Text('In Progress')),
                DropdownMenuItem(value: 'Completed', child: Text('Completed')),
                DropdownMenuItem(value: 'Cancelled', child: Text('Cancelled')),
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
                labelText: 'Sort',
                labelStyle: const TextStyle(fontSize: 13),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'Newest First', child: Text('Newest First')),
                DropdownMenuItem(value: 'Oldest First', child: Text('Oldest First')),
                DropdownMenuItem(value: 'Amount ↑', child: Text('Amount ↑')),
                DropdownMenuItem(value: 'Amount ↓', child: Text('Amount ↓')),
                DropdownMenuItem(value: 'Rating ↑', child: Text('Rating ↑')),
                DropdownMenuItem(value: 'Rating ↓', child: Text('Rating ↓')),
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
