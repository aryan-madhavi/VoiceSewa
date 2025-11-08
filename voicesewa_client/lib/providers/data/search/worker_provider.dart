import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:voicesewa_client/providers/model/worker_model.dart';

final workerListProvider = FutureProvider<List<WorkerModel>>((ref) async {
  // Simulate network delay
  await Future.delayed(const Duration(milliseconds: 800));

  return [
    WorkerModel(
      name: 'Ramesh Kumar',
      rating: 4.8,
      distance: '2.1 km',
      priceRange: '₹200–₹300/hr',
      verified: true,
      photoUrl: '',
      voiceText: 'Main Ramesh, 5 saal ka experience.',
    ),
    WorkerModel(
      name: 'Sita Devi',
      rating: 4.5,
      distance: '3.4 km',
      priceRange: '₹250–₹350/hr',
      verified: false,
      photoUrl: '',
      voiceText: 'Main Sita, 3 saal ka experience.',
    ),
  ];
});

/// Filter type enum
enum WorkerFilter { distance, price, rating }

/// State provider for selected filter
final selectedFilterProvider = StateProvider<WorkerFilter>((ref) {
  return WorkerFilter.distance;
});
