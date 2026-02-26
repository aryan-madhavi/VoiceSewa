import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:voicesewa_client/features/jobs/providers/client_provider.dart';
import 'package:voicesewa_client/shared/data/services_data.dart';
import 'package:voicesewa_client/shared/models/worker_model.dart';
import 'package:voicesewa_client/shared/models/address_model.dart';

// ── Enums ────────────────────────────────────────────────────────────────────

enum WorkerFilter { distance, rating }

/// Radius filter options in km. Defaults to 5 km (base fetch limit).
/// Workers beyond 5 km are never fetched.
enum RadiusFilter {
  two(2.0),
  five(5.0);

  final double km;
  const RadiusFilter(this.km);

  String get label => '${km.toStringAsFixed(0)} km';
}

// ── UI State Providers ───────────────────────────────────────────────────────

/// Currently selected sort filter (null = none active)
final selectedFilterProvider = StateProvider<WorkerFilter?>((_) => null);

/// Currently selected profession filter (null = all)
final selectedProfessionProvider = StateProvider<Services?>((_) => null);

/// Currently selected radius filter — defaults to 5 km (max fetch radius)
final selectedRadiusProvider = StateProvider<RadiusFilter>(
  (_) => RadiusFilter.five,
);

/// Index of the client address the user has selected for distance calculation.
final selectedAddressIndexProvider = StateProvider<int>((_) => 0);

// ── Selected reference GeoPoint ──────────────────────────────────────────────

/// The GeoPoint of the client's currently selected address.
/// Returns null if the client has no addresses yet.
final selectedAddressLocationProvider = Provider<GeoPoint?>((ref) {
  final clientAsync = ref.watch(currentClientProvider);
  return clientAsync.when(
    data: (client) {
      if (client == null || client.addresses.isEmpty) return null;
      final idx = ref.watch(selectedAddressIndexProvider);
      final safeIdx = idx.clamp(0, client.addresses.length - 1);
      return client.addresses[safeIdx].location;
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

/// All addresses of the current client (for the address picker dropdown).
final clientAddressListProvider = Provider<List<Address>>((ref) {
  final clientAsync = ref.watch(currentClientProvider);
  return clientAsync.when(
    data: (client) => client?.addresses ?? [],
    loading: () => [],
    error: (_, __) => [],
  );
});

// ── Firestore Worker Stream ──────────────────────────────────────────────────

/// Raw stream of ALL workers from Firestore.
/// Client-side radius filtering is applied in [workerListProvider].
/// Firestore does not support geospatial range queries natively without
/// GeoFlutterFire, so we fetch all and filter by Haversine distance.
final _allWorkersStreamProvider = StreamProvider<List<WorkerModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('workers')
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map((doc) => WorkerModel.fromFirestore(doc)).toList(),
      );
});

// ── Filtered & Sorted Worker List ────────────────────────────────────────────

/// Final list of workers after applying 5 km base filter + optional filters.
final workerListProvider = Provider<AsyncValue<List<WorkerModel>>>((ref) {
  final workersAsync = ref.watch(_allWorkersStreamProvider);
  final selectedFilter = ref.watch(selectedFilterProvider);
  final selectedProfession = ref.watch(selectedProfessionProvider);
  final selectedRadius = ref.watch(selectedRadiusProvider);
  final referenceLocation = ref.watch(selectedAddressLocationProvider);

  return workersAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
    data: (workers) {
      var filtered = [...workers];

      // 1. Always filter to selected radius (default 5 km).
      //    No referenceLocation = show nothing (can't compute distance).
      if (referenceLocation == null) return const AsyncValue.data([]);

      filtered = filtered
          .where(
            (w) => w.distanceKmFrom(referenceLocation) <= selectedRadius.km,
          )
          .toList();

      // 2. Filter by profession if selected
      if (selectedProfession != null) {
        filtered = filtered
            .where((w) => w.service == selectedProfession)
            .toList();
      }

      // 3. Sort
      switch (selectedFilter) {
        case WorkerFilter.distance:
          filtered.sort(
            (a, b) => a
                .distanceKmFrom(referenceLocation)
                .compareTo(b.distanceKmFrom(referenceLocation)),
          );
          break;
        case WorkerFilter.rating:
          filtered.sort((a, b) => b.avgRating.compareTo(a.avgRating));
          break;
        case null:
          // Default: sort by distance
          filtered.sort(
            (a, b) => a
                .distanceKmFrom(referenceLocation)
                .compareTo(b.distanceKmFrom(referenceLocation)),
          );
          break;
      }

      return AsyncValue.data(filtered);
    },
  );
});
