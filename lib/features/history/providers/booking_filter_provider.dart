import 'package:flutter_riverpod/legacy.dart';

// --- Active Jobs Filters ---
final activeStatusProvider = StateProvider<String>((ref) => 'All');
final activeSortProvider = StateProvider<String>((ref) => 'Newest First');

// --- Completed Jobs Filters ---
final completedStatusProvider = StateProvider<String>((ref) => 'All');
final completedSortProvider = StateProvider<String>((ref) => 'Newest First');