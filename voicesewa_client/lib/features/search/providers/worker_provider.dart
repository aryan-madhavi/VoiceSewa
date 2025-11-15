import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:voicesewa_client/features/home/data/services_data.dart';
import 'package:voicesewa_client/features/search/model/worker_model.dart';

final workerListProvider = FutureProvider<List<WorkerModel>>((ref) async {
  // Simulate network delay
  await Future.delayed(const Duration(milliseconds: 800));

  return [
    WorkerModel(
      name: 'Anita S.',
      rating: 4.8,
      distance: '2.4 km',
      priceRange: '₹400 - ₹700',
      verified: true,
      photoUrl: '',
      voiceText: 'Hi, I’m Anita! I specialize in deep cleaning services.',
      service: Services.houseCleaner,
      experience: 5,
      skills: ['Deep Cleaning', 'Kitchen Cleaning', 'Bathroom Sanitization'],
      available: true,
    ),
    WorkerModel(
      name: 'Ravi K.',
      rating: 4.6,
      distance: '3.1 km',
      priceRange: '₹350 - ₹600',
      verified: true,
      photoUrl: '',
      voiceText: 'Hello, I’m Ravi! I provide reliable plumbing and minor repair services.',
      service: Services.plumber,
      experience: 7,
      skills: ['Pipe Fitting', 'Leak Fixing', 'Tap Installation'],
      available: true,
    ),
    WorkerModel(
      name: 'Priya D.',
      rating: 4.9,
      distance: '1.8 km',
      priceRange: '₹500 - ₹900',
      verified: true,
      photoUrl: '',
      voiceText: 'Hi there, I’m Priya! I’m a certified electrician offering safe and efficient electrical services.',
      service: Services.electrician,
      experience: 6,
      skills: ['Wiring', 'Switchboard Installation', 'Appliance Repair'],
      available: false,
    ),
  ];
});

/// Filter type enum
enum WorkerFilter { distance, price, rating }

/// State provider for selected filter
final selectedFilterProvider = StateProvider<WorkerFilter>((ref) {
  return WorkerFilter.distance;
});
