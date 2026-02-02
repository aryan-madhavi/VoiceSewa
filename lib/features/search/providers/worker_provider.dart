import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:voicesewa_client/shared/data/services_data.dart';
import 'package:voicesewa_client/shared/models/worker_model.dart';
import 'dart:math' as math;

/// Filter type enum
enum WorkerFilter { distance, rating, profession }

/// State provider for selected filter
final selectedFilterProvider = StateProvider<WorkerFilter>((ref) {
  return WorkerFilter.distance;
});

/// State provider for selected profession filter (null = all)
final selectedProfessionProvider = StateProvider<Services?>((ref) {
  return null; // null means show all professions
});

/// Main worker list provider with filtering
final workerListProvider = FutureProvider<List<WorkerModel>>((ref) async {
  // Simulate network delay
  await Future.delayed(const Duration(milliseconds: 800));

  final selectedFilter = ref.watch(selectedFilterProvider);
  final selectedProfession = ref.watch(selectedProfessionProvider);

  // Get all workers
  List<WorkerModel> workers = _getDummyWorkers();

  // Filter by profession if selected
  if (selectedProfession != null) {
    workers = workers.where((w) => w.service == selectedProfession).toList();
  }

  // Sort based on selected filter
  switch (selectedFilter) {
    case WorkerFilter.distance:
      workers.sort((a, b) {
        final aKm = double.parse(a.distance.replaceAll(' km', ''));
        final bKm = double.parse(b.distance.replaceAll(' km', ''));
        return aKm.compareTo(bKm);
      });
      break;
    case WorkerFilter.rating:
      workers.sort((a, b) => b.rating.compareTo(a.rating));
      break;
    case WorkerFilter.profession:
      workers.sort((a, b) => a.serviceLabel.compareTo(b.serviceLabel));
      break;
  }

  return workers;
});

/// Helper function to create dummy workers with Ambarnath coordinates
List<WorkerModel> _getDummyWorkers() {
  // Ambarnath center coordinates: 19.1958, 73.1964
  final baseLatitude = 19.1958;
  final baseLongitude = 73.1964;

  return [
    // Worker 1 - House Cleaner
    WorkerModel(
      uid: 'worker_001',
      name: 'Anita Sharma',
      email: 'anita.sharma@example.com',
      phone: '+91 98765 43210',
      bio:
          'Hi, I\'m Anita! I specialize in deep cleaning services with 5 years of experience.',
      profileImg: '',
      avgRating: 4.8,
      reviews: List.generate(
        12,
        (i) => Review(rating: 4.5 + (i % 2 * 0.5), review: 'Great service!'),
      ),
      skillsList: [
        'Deep Cleaning',
        'Kitchen Cleaning',
        'Bathroom Sanitization',
      ],
      address: WorkerAddress(
        location: GeoPoint(baseLatitude + 0.015, baseLongitude + 0.020),
        line1: 'Shop No 12, Shivaji Nagar',
        line2: 'Near Bus Stand',
        landmark: 'Opposite HDFC Bank',
        pincode: '421501',
        city: 'Ambarnath',
      ),
      jobs: WorkerJobs(applied: [], confirmed: [], completed: [], declined: []),
      fcmToken: 'dummy_token_001',
      service: Services.houseCleaner,
      available: true,
      voiceText: 'Hi, I\'m Anita! I specialize in deep cleaning services.',
    ),

    // Worker 2 - Plumber
    WorkerModel(
      uid: 'worker_002',
      name: 'Ravi Kumar',
      email: 'ravi.kumar@example.com',
      phone: '+91 98765 43211',
      bio:
          'Hello, I\'m Ravi! I provide reliable plumbing and minor repair services.',
      profileImg: '',
      avgRating: 4.6,
      reviews: List.generate(
        8,
        (i) => Review(rating: 4.5, review: 'Professional work!'),
      ),
      skillsList: ['Pipe Fitting', 'Leak Fixing', 'Tap Installation'],
      address: WorkerAddress(
        location: GeoPoint(baseLatitude + 0.025, baseLongitude - 0.010),
        line1: 'House No 45, Ganesh Nagar',
        line2: 'First Floor',
        landmark: 'Near Railway Station',
        pincode: '421501',
        city: 'Ambarnath',
      ),
      jobs: WorkerJobs(applied: [], confirmed: [], completed: [], declined: []),
      fcmToken: 'dummy_token_002',
      service: Services.plumber,
      available: true,
      voiceText: 'Hello, I\'m Ravi! I provide reliable plumbing services.',
    ),

    // Worker 3 - Electrician
    WorkerModel(
      uid: 'worker_003',
      name: 'Priya Desai',
      email: 'priya.desai@example.com',
      phone: '+91 98765 43212',
      bio:
          'Hi there, I\'m Priya! I\'m a certified electrician offering safe electrical services.',
      profileImg: '',
      avgRating: 4.9,
      reviews: List.generate(
        15,
        (i) => Review(rating: 4.8 + (i % 2 * 0.2), review: 'Excellent!'),
      ),
      skillsList: ['Wiring', 'Switchboard Installation', 'Appliance Repair'],
      address: WorkerAddress(
        location: GeoPoint(baseLatitude - 0.012, baseLongitude + 0.018),
        line1: 'Building No 7, Krishna Park',
        line2: 'Ground Floor',
        landmark: 'Behind Post Office',
        pincode: '421501',
        city: 'Ambarnath',
      ),
      jobs: WorkerJobs(applied: [], confirmed: [], completed: [], declined: []),
      fcmToken: 'dummy_token_003',
      service: Services.electrician,
      available: false,
      voiceText: 'Hi there, I\'m Priya! Certified electrician at your service.',
    ),

    // Worker 4 - Carpenter
    WorkerModel(
      uid: 'worker_004',
      name: 'Suresh Patil',
      email: 'suresh.patil@example.com',
      phone: '+91 98765 43213',
      bio:
          'Namaste! I\'m Suresh, an experienced carpenter specializing in furniture work.',
      profileImg: '',
      avgRating: 4.7,
      reviews: List.generate(
        10,
        (i) => Review(rating: 4.6, review: 'Quality work!'),
      ),
      skillsList: ['Furniture Making', 'Door Fitting', 'Wood Polishing'],
      address: WorkerAddress(
        location: GeoPoint(baseLatitude + 0.030, baseLongitude + 0.025),
        line1: 'Workshop 3, Industrial Area',
        line2: 'Sector 5',
        landmark: 'Near Hanuman Temple',
        pincode: '421501',
        city: 'Ambarnath',
      ),
      jobs: WorkerJobs(applied: [], confirmed: [], completed: [], declined: []),
      fcmToken: 'dummy_token_004',
      service: Services.carpenter,
      available: true,
      voiceText: 'Namaste! I\'m Suresh, your trusted carpenter.',
    ),

    // Worker 5 - Painter
    WorkerModel(
      uid: 'worker_005',
      name: 'Rajesh Yadav',
      email: 'rajesh.yadav@example.com',
      phone: '+91 98765 43214',
      bio:
          'Hello! I\'m Rajesh, a professional painter with expertise in all types of painting.',
      profileImg: '',
      avgRating: 4.5,
      reviews: List.generate(
        7,
        (i) => Review(rating: 4.4, review: 'Nice finish!'),
      ),
      skillsList: ['Wall Painting', 'Texture Work', 'Waterproofing'],
      address: WorkerAddress(
        location: GeoPoint(baseLatitude - 0.020, baseLongitude - 0.015),
        line1: 'Lane 6, Ambedkar Nagar',
        line2: 'Near School',
        landmark: 'Behind Market',
        pincode: '421501',
        city: 'Ambarnath',
      ),
      jobs: WorkerJobs(applied: [], confirmed: [], completed: [], declined: []),
      fcmToken: 'dummy_token_005',
      service: Services.painter,
      available: true,
      voiceText: 'Hello! I\'m Rajesh, professional painter at your service.',
    ),

    // Worker 6 - AC Technician
    WorkerModel(
      uid: 'worker_006',
      name: 'Vikram Singh',
      email: 'vikram.singh@example.com',
      phone: '+91 98765 43215',
      bio:
          'Hi! I\'m Vikram, specialized in AC and appliance repair and maintenance.',
      profileImg: '',
      avgRating: 4.8,
      reviews: List.generate(
        14,
        (i) => Review(rating: 4.7, review: 'Quick service!'),
      ),
      skillsList: ['AC Installation', 'Gas Refilling', 'Maintenance'],
      address: WorkerAddress(
        location: GeoPoint(baseLatitude + 0.010, baseLongitude - 0.022),
        line1: 'Shop 8, MG Road',
        line2: 'Ground Floor',
        landmark: 'Near Cinema Hall',
        pincode: '421501',
        city: 'Ambarnath',
      ),
      jobs: WorkerJobs(applied: [], confirmed: [], completed: [], declined: []),
      fcmToken: 'dummy_token_006',
      service: Services.acApplianceTechnician,
      available: true,
      voiceText: 'Hi! I\'m Vikram, AC and appliance expert.',
    ),

    // Worker 7 - Cook
    WorkerModel(
      uid: 'worker_007',
      name: 'Sunita Kadam',
      email: 'sunita.kadam@example.com',
      phone: '+91 98765 43216',
      bio:
          'Namaste! I\'m Sunita, experienced cook specializing in Indian cuisine.',
      profileImg: '',
      avgRating: 4.6,
      reviews: List.generate(
        9,
        (i) => Review(rating: 4.5, review: 'Delicious food!'),
      ),
      skillsList: ['Indian Cuisine', 'Tiffin Service', 'Party Catering'],
      address: WorkerAddress(
        location: GeoPoint(baseLatitude - 0.008, baseLongitude + 0.012),
        line1: 'Flat 102, Rani Tower',
        line2: 'First Floor',
        landmark: 'Near Temple',
        pincode: '421501',
        city: 'Ambarnath',
      ),
      jobs: WorkerJobs(applied: [], confirmed: [], completed: [], declined: []),
      fcmToken: 'dummy_token_007',
      service: Services.cook,
      available: true,
      voiceText: 'Namaste! I\'m Sunita, cook with love for food.',
    ),

    // Worker 8 - Driver
    WorkerModel(
      uid: 'worker_008',
      name: 'Ramesh Bhoir',
      email: 'ramesh.bhoir@example.com',
      phone: '+91 98765 43217',
      bio:
          'Hello! I\'m Ramesh, professional driver with 10 years of experience.',
      profileImg: '',
      avgRating: 4.7,
      reviews: List.generate(
        11,
        (i) => Review(rating: 4.6, review: 'Safe driver!'),
      ),
      skillsList: ['Car Driving', 'Long Distance', 'City Tours'],
      address: WorkerAddress(
        location: GeoPoint(baseLatitude + 0.018, baseLongitude + 0.015),
        line1: 'Room 5, Driver Colony',
        line2: 'Near Taxi Stand',
        landmark: 'Behind Bus Depot',
        pincode: '421501',
        city: 'Ambarnath',
      ),
      jobs: WorkerJobs(applied: [], confirmed: [], completed: [], declined: []),
      fcmToken: 'dummy_token_008',
      service: Services.driverOnDemand,
      available: false,
      voiceText: 'Hello! I\'m Ramesh, safe and reliable driver.',
    ),

    // Worker 9 - Mechanic
    WorkerModel(
      uid: 'worker_009',
      name: 'Ashok Pawar',
      email: 'ashok.pawar@example.com',
      phone: '+91 98765 43218',
      bio: 'Hi! I\'m Ashok, mechanic for 2-wheeler and 4-wheeler vehicles.',
      profileImg: '',
      avgRating: 4.8,
      reviews: List.generate(
        13,
        (i) => Review(rating: 4.7, review: 'Fixed perfectly!'),
      ),
      skillsList: ['2W Repair', '4W Repair', 'Engine Overhauling'],
      address: WorkerAddress(
        location: GeoPoint(baseLatitude - 0.022, baseLongitude - 0.018),
        line1: 'Garage 3, Auto Market',
        line2: 'Main Road',
        landmark: 'Near Petrol Pump',
        pincode: '421501',
        city: 'Ambarnath',
      ),
      jobs: WorkerJobs(applied: [], confirmed: [], completed: [], declined: []),
      fcmToken: 'dummy_token_009',
      service: Services.mechanic,
      available: true,
      voiceText: 'Hi! I\'m Ashok, expert mechanic for all vehicles.',
    ),

    // Worker 10 - Handyman
    WorkerModel(
      uid: 'worker_010',
      name: 'Mangesh Kulkarni',
      email: 'mangesh.kulkarni@example.com',
      phone: '+91 98765 43219',
      bio: 'Namaste! I\'m Mangesh, handyman and masonry expert.',
      profileImg: '',
      avgRating: 4.7,
      reviews: List.generate(
        10,
        (i) => Review(rating: 4.6, review: 'Excellent work!'),
      ),
      skillsList: ['Masonry', 'Tile Work', 'General Repairs'],
      address: WorkerAddress(
        location: GeoPoint(baseLatitude + 0.022, baseLongitude - 0.012),
        line1: 'Workshop 7, Construction Area',
        line2: 'Near Building Site',
        landmark: 'Behind Hardware Store',
        pincode: '421501',
        city: 'Ambarnath',
      ),
      jobs: WorkerJobs(applied: [], confirmed: [], completed: [], declined: []),
      fcmToken: 'dummy_token_010',
      service: Services.handymanMasonryWork,
      available: true,
      voiceText: 'Namaste! I\'m Mangesh, your handyman for all repairs.',
    ),

    // Worker 11 - Electrician
    WorkerModel(
      uid: 'worker_011',
      name: 'Deepak Joshi',
      email: 'deepak.joshi@example.com',
      phone: '+91 98765 43220',
      bio: 'Hello! I\'m Deepak, electrician with smart home expertise.',
      profileImg: '',
      avgRating: 4.9,
      reviews: List.generate(
        16,
        (i) => Review(rating: 4.8, review: 'Modern solutions!'),
      ),
      skillsList: ['Smart Home Setup', 'LED Installation', 'Fault Diagnosis'],
      address: WorkerAddress(
        location: GeoPoint(baseLatitude - 0.015, baseLongitude + 0.025),
        line1: 'Flat 301, Vikas Tower',
        line2: 'Third Floor',
        landmark: 'Near Metro Station',
        pincode: '421501',
        city: 'Ambarnath',
      ),
      jobs: WorkerJobs(applied: [], confirmed: [], completed: [], declined: []),
      fcmToken: 'dummy_token_011',
      service: Services.electrician,
      available: true,
      voiceText: 'Hello! I\'m Deepak, modern electrical solutions provider.',
    ),

    // Worker 12 - Plumber
    WorkerModel(
      uid: 'worker_012',
      name: 'Santosh Naik',
      email: 'santosh.naik@example.com',
      phone: '+91 98765 43221',
      bio: 'Hi! I\'m Santosh, plumber for all your water-related needs.',
      profileImg: '',
      avgRating: 4.7,
      reviews: List.generate(
        10,
        (i) => Review(rating: 4.6, review: 'Quick fix!'),
      ),
      skillsList: [
        'Pipeline Work',
        'Water Tank Installation',
        'Leak Detection',
      ],
      address: WorkerAddress(
        location: GeoPoint(baseLatitude + 0.005, baseLongitude + 0.028),
        line1: 'Shop 12, Market Street',
        line2: 'Ground Floor',
        landmark: 'Near Water Pump',
        pincode: '421501',
        city: 'Ambarnath',
      ),
      jobs: WorkerJobs(applied: [], confirmed: [], completed: [], declined: []),
      fcmToken: 'dummy_token_012',
      service: Services.plumber,
      available: false,
      voiceText: 'Hi! I\'m Santosh, plumber with quick solutions.',
    ),

    // Worker 13 - House Cleaner
    WorkerModel(
      uid: 'worker_013',
      name: 'Lata Bhosale',
      email: 'lata.bhosale@example.com',
      phone: '+91 98765 43222',
      bio: 'Hello! I\'m Lata, dedicated to making your home spotless.',
      profileImg: '',
      avgRating: 4.8,
      reviews: List.generate(
        12,
        (i) => Review(rating: 4.7, review: 'Very clean!'),
      ),
      skillsList: [
        'Home Sanitization',
        'Window Cleaning',
        'Post-Construction Cleaning',
      ],
      address: WorkerAddress(
        location: GeoPoint(baseLatitude - 0.025, baseLongitude + 0.015),
        line1: 'Flat 205, Laxmi Apartments',
        line2: 'Second Floor',
        landmark: 'Near Park',
        pincode: '421501',
        city: 'Ambarnath',
      ),
      jobs: WorkerJobs(applied: [], confirmed: [], completed: [], declined: []),
      fcmToken: 'dummy_token_013',
      service: Services.houseCleaner,
      available: true,
      voiceText: 'Hello! I\'m Lata, your cleaning specialist.',
    ),

    // Worker 14 - Carpenter
    WorkerModel(
      uid: 'worker_014',
      name: 'Prakash More',
      email: 'prakash.more@example.com',
      phone: '+91 98765 43223',
      bio: 'Namaste! I\'m Prakash, carpenter with creative designs.',
      profileImg: '',
      avgRating: 4.9,
      reviews: List.generate(
        17,
        (i) => Review(rating: 4.8, review: 'Beautiful work!'),
      ),
      skillsList: ['Custom Furniture', 'Modular Kitchen', 'Interior Work'],
      address: WorkerAddress(
        location: GeoPoint(baseLatitude + 0.012, baseLongitude - 0.025),
        line1: 'Workshop A1, Furniture Lane',
        line2: 'Industrial Area',
        landmark: 'Behind Showroom',
        pincode: '421501',
        city: 'Ambarnath',
      ),
      jobs: WorkerJobs(applied: [], confirmed: [], completed: [], declined: []),
      fcmToken: 'dummy_token_014',
      service: Services.carpenter,
      available: true,
      voiceText: 'Namaste! I\'m Prakash, carpenter with eye for detail.',
    ),

    // Worker 15 - AC Technician
    WorkerModel(
      uid: 'worker_015',
      name: 'Nitin Rane',
      email: 'nitin.rane@example.com',
      phone: '+91 98765 43224',
      bio: 'Hi! I\'m Nitin, AC and appliance technician certified by brands.',
      profileImg: '',
      avgRating: 4.8,
      reviews: List.generate(
        14,
        (i) => Review(rating: 4.7, review: 'Expert service!'),
      ),
      skillsList: [
        'Split AC Service',
        'Window AC Service',
        'Refrigerator Repair',
      ],
      address: WorkerAddress(
        location: GeoPoint(baseLatitude - 0.018, baseLongitude - 0.020),
        line1: 'Service Center 2, AC Lane',
        line2: 'Main Road',
        landmark: 'Near Mall',
        pincode: '421501',
        city: 'Ambarnath',
      ),
      jobs: WorkerJobs(applied: [], confirmed: [], completed: [], declined: []),
      fcmToken: 'dummy_token_015',
      service: Services.acApplianceTechnician,
      available: true,
      voiceText: 'Hi! I\'m Nitin, AC and appliance service expert.',
    ),
  ];
}

/// Helper to calculate distance between two coordinates (Haversine formula)
double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const R = 6371; // Earth's radius in km
  final dLat = _toRadians(lat2 - lat1);
  final dLon = _toRadians(lon2 - lon1);

  final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRadians(lat1)) *
          math.cos(_toRadians(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);

  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return R * c;
}

double _toRadians(double degree) {
  return degree * math.pi / 180;
}
