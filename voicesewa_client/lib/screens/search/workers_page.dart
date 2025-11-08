import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_client/constants/core/color_constants.dart';
import 'package:voicesewa_client/providers/data/search/worker_provider.dart';
import 'package:voicesewa_client/widgets/search/worker_card.dart';

class SuggestedWorkersPage extends ConsumerStatefulWidget {
  const SuggestedWorkersPage({super.key});

  @override
  ConsumerState<SuggestedWorkersPage> createState() =>
      _SuggestedWorkersPageState();
}

class _SuggestedWorkersPageState
    extends ConsumerState<SuggestedWorkersPage> {
  @override
  Widget build(BuildContext context) {
    final workersAsync = ref.watch(workerListProvider);
    final selectedFilter = ref.watch(selectedFilterProvider);

    return Scaffold(
      body: Column(
        children: [
          // 🔹 Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFilterChip(context, WorkerFilter.distance, 'Distance'),
                _buildFilterChip(context, WorkerFilter.price, 'Price'),
                _buildFilterChip(context, WorkerFilter.rating, 'Rating'),
              ],
            ),
          ),

          // 🔹 Worker Cards List
          Expanded(
            child: workersAsync.when(
              data: (workers) {
                return ListView.builder(
                  itemCount: workers.length,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemBuilder: (context, index) {
                    final worker = workers[index];
                    return WorkerCard(
                      worker: worker,
                      onPlayVoice: () {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Playing intro: ${worker.voiceText}'),
                        ));
                      },
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: ColorConstants.seed),
              ),
              error: (err, _) => Center(
                child: Text('Error: $err'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
      BuildContext context, WorkerFilter filter, String label) {
    final selected = ref.watch(selectedFilterProvider);
    final isSelected = selected == filter;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        ref.read(selectedFilterProvider.notifier).state = filter;
      },
      selectedColor: ColorConstants.seed.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}
