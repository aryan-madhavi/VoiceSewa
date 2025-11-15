import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

// --- Active Jobs Filters ---
final activeStatusProvider = StateProvider<String>((ref) => 'All');
final activeSortProvider = StateProvider<String>((ref) => 'Newest First');

// --- Completed Jobs Filters ---
final completedStatusProvider = StateProvider<String>((ref) => 'All');
final completedSortProvider = StateProvider<String>((ref) => 'Newest First');

// --- Active Jobs Data ---
final activeJobsProvider = Provider<List<Map<String, dynamic>>>(
  (ref) => [
    {
      'service': 'Plumbing Repair',
      'description': 'Fixing kitchen sink leakage',
      'worker': 'Rajesh K.',
      'rating': '4.7',
      'date': 'Nov 5, 2025',
      'amount': '₹450',
      'status': 'In Progress',
      'userRating': '-',
    },
    {
      'service': 'Home Cleaning',
      'description': 'Full 2BHK deep cleaning service',
      'worker': 'Anita S.',
      'rating': '4.8',
      'date': 'Nov 7, 2025',
      'amount': '₹1200',
      'status': 'Scheduled',
      'userRating': '-',
    },
    {
      'service': 'AC Installation',
      'description': 'Split AC setup and testing',
      'worker': 'Vivek T.',
      'rating': '4.6',
      'date': 'Nov 9, 2025',
      'amount': '₹1500',
      'status': 'In Progress',
      'userRating': '-',
    },
    {
      'service': 'Pest Control',
      'description': 'Cockroach and ant treatment for 3BHK',
      'worker': 'Deepa R.',
      'rating': '4.9',
      'date': 'Nov 10, 2025',
      'amount': '₹800',
      'status': 'Scheduled',
      'userRating': '-',
    },
    {
      'service': 'Carpet Cleaning',
      'description': 'Dry wash and shampooing of carpets',
      'worker': 'Arun P.',
      'rating': '4.5',
      'date': 'Nov 11, 2025',
      'amount': '₹1000',
      'status': 'Scheduled',
      'userRating': '-',
    },
    {
      'service': 'Refrigerator Repair',
      'description': 'Cooling issue inspection and fix',
      'worker': 'Sanjay L.',
      'rating': '4.8',
      'date': 'Nov 8, 2025',
      'amount': '₹700',
      'status': 'In Progress',
      'userRating': '-',
    },
  ],
);

// --- Completed Jobs Data ---
final completedJobsProvider = Provider<List<Map<String, dynamic>>>(
  (ref) => [
    {
      'service': 'Wall Painting',
      'description': 'Living room painting',
      'worker': 'Ajay Singh',
      'rating': '4.9',
      'date': 'Nov 28, 2024',
      'amount': '₹2500',
      'status': 'Completed',
      'userRating': '5/5',
    },
    {
      'service': 'Car Wash',
      'description': 'Exterior and interior cleaning',
      'worker': 'Vikas G.',
      'rating': '4.8',
      'date': 'Nov 3, 2025',
      'amount': '₹600',
      'status': 'Completed',
      'userRating': '4.9/5',
    },
    {
      'service': 'Gardening',
      'description': 'Lawn trimming and plant maintenance',
      'worker': 'Rohit M.',
      'rating': '4.7',
      'date': 'Nov 1, 2025',
      'amount': '₹800',
      'status': 'Completed',
      'userRating': '4.8/5',
    },
    {
      'service': 'Furniture Assembly',
      'description': 'Bed and wardrobe installation',
      'worker': 'Nikhil D.',
      'rating': '4.6',
      'date': 'Oct 30, 2025',
      'amount': '₹500',
      'status': 'Completed',
      'userRating': '4.7/5',
    },
    {
      'service': 'AC Maintenance',
      'description': 'Filter cleaning and gas refill',
      'worker': 'Kumar P.',
      'rating': '4.9',
      'date': 'Oct 22, 2025',
      'amount': '₹900',
      'status': 'Completed',
      'userRating': '5/5',
    },
    {
      'service': 'Electrician Visit',
      'description': 'Fan wiring and socket repair',
      'worker': 'Sunil T.',
      'rating': '4.4',
      'date': 'Oct 10, 2025',
      'amount': '₹650',
      'status': 'Cancelled',
      'userRating': '-',
    },
  ],
);
