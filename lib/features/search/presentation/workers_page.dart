import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:voicesewa_client/core/constants/color_constants.dart';
import 'package:voicesewa_client/features/search/providers/worker_provider.dart';
import 'package:voicesewa_client/features/search/presentation/widgets/worker_card.dart';
import 'package:voicesewa_client/features/search/presentation/widgets/worker_details_sheet.dart';
import 'package:voicesewa_client/shared/data/services_data.dart';
import 'package:voicesewa_client/shared/models/worker_model.dart';
import 'package:voicesewa_client/shared/models/address_model.dart';

class SuggestedWorkersPage extends ConsumerStatefulWidget {
  const SuggestedWorkersPage({super.key});

  @override
  ConsumerState<SuggestedWorkersPage> createState() =>
      _SuggestedWorkersPageState();
}

class _SuggestedWorkersPageState extends ConsumerState<SuggestedWorkersPage> {
  // Ambarnath fallback center
  static const LatLng _fallbackCenter = LatLng(19.1958, 73.1964);

  // ── Marker color ─────────────────────────────────────────────────────────────

  Color _getMarkerColor(Services service) {
    switch (service) {
      case Services.houseCleaner:
        return Colors.teal;
      case Services.plumber:
        return Colors.blue;
      case Services.electrician:
        return Colors.amber.shade700;
      case Services.carpenter:
        return Colors.brown;
      case Services.painter:
        return Colors.purple;
      case Services.acApplianceTechnician:
        return Colors.cyan;
      case Services.mechanic:
        return Colors.grey.shade700;
      case Services.cook:
        return Colors.redAccent;
      case Services.driverOnDemand:
        return Colors.indigo;
      case Services.handymanMasonryWork:
        return Colors.deepOrange;
      default:
        return Colors.red;
    }
  }

  // ── Bottom sheets ─────────────────────────────────────────────────────────────

  void _showWorkerDetails(WorkerModel worker, GeoPoint? referenceLocation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WorkerDetailsSheet(
        worker: worker,
        distanceLabel: referenceLocation != null
            ? worker.distanceFrom(referenceLocation)
            : null,
        onBookNow: () {
          Navigator.pop(context);
          // TODO: handle booking logic
        },
      ),
    );
  }

  void _showProfessionFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final selectedProfession = ref.watch(selectedProfessionProvider);
          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter by Profession',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.select_all),
                    title: const Text('All Services'),
                    trailing: selectedProfession == null
                        ? const Icon(Icons.check, color: ColorConstants.seed)
                        : null,
                    onTap: () {
                      ref.read(selectedProfessionProvider.notifier).state =
                          null;
                      Navigator.pop(context);
                    },
                  ),
                  const Divider(),
                  ...Services.values.map((service) {
                    final isSelected = selectedProfession == service;
                    final data = ServicesData.services[service]!;
                    return ListTile(
                      leading: Icon(
                        data[1] as IconData,
                        color: data[0] as Color,
                      ),
                      title: Text(data[2] as String),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: ColorConstants.seed)
                          : null,
                      onTap: () {
                        // Toggle: tap same = clear, tap new = set
                        ref.read(selectedProfessionProvider.notifier).state =
                            isSelected ? null : service;
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final workersAsync = ref.watch(workerListProvider);
    final selectedProfession = ref.watch(selectedProfessionProvider);
    final referenceLocation = ref.watch(selectedAddressLocationProvider);
    final addresses = ref.watch(clientAddressListProvider);
    final selectedAddressIdx = ref.watch(selectedAddressIndexProvider);

    return Scaffold(
      body: Column(
        children: [
          // ── Address Picker ───────────────────────────────────────────────────
          if (addresses.isNotEmpty)
            _AddressPicker(
              addresses: addresses,
              selectedIndex: selectedAddressIdx,
              onChanged: (idx) =>
                  ref.read(selectedAddressIndexProvider.notifier).state = idx,
            ),

          // ── Flutter Map — isolated widget to prevent lag ──────────────────
          Expanded(
            flex: 2,
            child: _WorkerMap(
              workers: workersAsync.value ?? [],
              referenceLocation: referenceLocation,
              fallbackCenter: _fallbackCenter,
              getMarkerColor: _getMarkerColor,
              onMarkerTap: (worker) =>
                  _showWorkerDetails(worker, referenceLocation),
            ),
          ),

          // ── Filter Chips ─────────────────────────────────────────────────────
          _FilterBar(
            selectedProfession: selectedProfession,
            onProfessionTap: _showProfessionFilter,
          ),

          // ── Worker Cards ─────────────────────────────────────────────────────
          Expanded(
            child: workersAsync.when(
              data: (workers) {
                if (workers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No workers found nearby',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            ref
                                    .read(selectedProfessionProvider.notifier)
                                    .state =
                                null;
                            ref.read(selectedFilterProvider.notifier).state =
                                null;
                            ref.read(selectedRadiusProvider.notifier).state =
                                RadiusFilter.five;
                          },
                          child: const Text('Clear Filters'),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: workers.length,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  itemBuilder: (context, index) {
                    final worker = workers[index];
                    return WorkerCard(
                      worker: worker,
                      distanceLabel: referenceLocation != null
                          ? worker.distanceFrom(referenceLocation)
                          : null,
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: ColorConstants.seed),
              ),
              error: (err, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading workers',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      err.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Map widget — kept separate so it does NOT rebuild on filter changes ────────

class _WorkerMap extends StatefulWidget {
  final List<WorkerModel> workers;
  final GeoPoint? referenceLocation;
  final LatLng fallbackCenter;
  final Color Function(Services) getMarkerColor;
  final void Function(WorkerModel) onMarkerTap;

  const _WorkerMap({
    required this.workers,
    required this.referenceLocation,
    required this.fallbackCenter,
    required this.getMarkerColor,
    required this.onMarkerTap,
  });

  @override
  State<_WorkerMap> createState() => _WorkerMapState();
}

class _WorkerMapState extends State<_WorkerMap> {
  final MapController _mapController = MapController();
  List<Marker> _markers = [];
  // Track previous values to avoid redundant fitCamera calls
  List<String>? _prevWorkerIds;
  GeoPoint? _prevReference;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  LatLng _geo(GeoPoint g) => LatLng(g.latitude, g.longitude);

  @override
  void didUpdateWidget(_WorkerMap old) {
    super.didUpdateWidget(old);

    final newIds = widget.workers.map((w) => w.uid).toList();
    final refChanged = widget.referenceLocation != _prevReference;
    final workersChanged = newIds.toString() != (_prevWorkerIds?.toString());

    if (refChanged || workersChanged) {
      _prevWorkerIds = newIds;
      _prevReference = widget.referenceLocation;
      WidgetsBinding.instance.addPostFrameCallback((_) => _rebuild());
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _rebuild());
  }

  void _rebuild() {
    if (!mounted) return;
    final markers = <Marker>[];

    // Client pin
    if (widget.referenceLocation != null) {
      markers.add(
        Marker(
          point: _geo(widget.referenceLocation!),
          width: 44,
          height: 44,
          child: Icon(Icons.my_location, color: ColorConstants.seed, size: 36),
        ),
      );
    }

    // Worker pins
    for (final worker in widget.workers) {
      markers.add(
        Marker(
          point: _geo(worker.address.location),
          width: 36,
          height: 36,
          child: GestureDetector(
            onTap: () => widget.onMarkerTap(worker),
            child: Icon(
              Icons.location_pin,
              color: widget.getMarkerColor(worker.service),
              size: 36,
            ),
          ),
        ),
      );
    }

    setState(() => _markers = markers);

    // Fit camera
    if (widget.workers.isNotEmpty) {
      _fitCamera();
    } else if (widget.referenceLocation != null) {
      _mapController.move(_geo(widget.referenceLocation!), 13);
    }
  }

  void _fitCamera() {
    final lats = widget.workers
        .map((w) => w.address.location.latitude)
        .toList();
    final lngs = widget.workers
        .map((w) => w.address.location.longitude)
        .toList();

    if (widget.referenceLocation != null) {
      lats.add(widget.referenceLocation!.latitude);
      lngs.add(widget.referenceLocation!.longitude);
    }

    final bounds = LatLngBounds(
      LatLng(
        lats.reduce((a, b) => a < b ? a : b),
        lngs.reduce((a, b) => a < b ? a : b),
      ),
      LatLng(
        lats.reduce((a, b) => a > b ? a : b),
        lngs.reduce((a, b) => a > b ? a : b),
      ),
    );

    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: widget.referenceLocation != null
            ? _geo(widget.referenceLocation!)
            : widget.fallbackCenter,
        initialZoom: 14,
        minZoom: 10,
        maxZoom: 20,
        // All gestures enabled — no AbsorbPointer blocking them
        interactionOptions: const InteractionOptions(
          flags:
              InteractiveFlag.pinchZoom |
              InteractiveFlag.drag |
              InteractiveFlag.doubleTapZoom |
              InteractiveFlag.scrollWheelZoom |
              InteractiveFlag.pinchMove,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.voicesewa.client',
          maxZoom: 20,
          // Tile caching reduces lag significantly
          maxNativeZoom: 19,
          keepBuffer: 4, // keep 4 extra tile rows/cols in memory
          panBuffer: 2,
        ),
        MarkerLayer(
          markers: _markers,
          // Rotate markers with map for cleaner look
          rotate: false,
        ),
      ],
    );
  }
}

// ── Filter bar ────────────────────────────────────────────────────────────────

class _FilterBar extends ConsumerWidget {
  final Services? selectedProfession;
  final VoidCallback onProfessionTap;

  const _FilterBar({
    required this.selectedProfession,
    required this.onProfessionTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFilter = ref.watch(selectedFilterProvider);
    final selectedRadius = ref.watch(selectedRadiusProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Sort: Distance — toggleable
            _chip(
              label: 'Distance',
              icon: Icons.location_on,
              isSelected: selectedFilter == WorkerFilter.distance,
              onTap: () {
                ref
                    .read(selectedFilterProvider.notifier)
                    .state = selectedFilter == WorkerFilter.distance
                    ? null
                    : WorkerFilter.distance;
              },
            ),
            const SizedBox(width: 8),

            // Sort: Rating — toggleable
            _chip(
              label: 'Rating',
              icon: Icons.star,
              isSelected: selectedFilter == WorkerFilter.rating,
              onTap: () {
                ref
                    .read(selectedFilterProvider.notifier)
                    .state = selectedFilter == WorkerFilter.rating
                    ? null
                    : WorkerFilter.rating;
              },
            ),
            const SizedBox(width: 8),

            // Radius: 2 km — toggleable (tapping active = back to 5 km)
            _chip(
              label: '2 km',
              icon: Icons.radar,
              isSelected: selectedRadius == RadiusFilter.two,
              onTap: () {
                ref
                    .read(selectedRadiusProvider.notifier)
                    .state = selectedRadius == RadiusFilter.two
                    ? RadiusFilter.five
                    : RadiusFilter.two;
              },
            ),
            const SizedBox(width: 8),

            // Radius: 5 km — toggleable (tapping active = stays 5 km, it's default)
            _chip(
              label: '5 km',
              icon: Icons.radar,
              isSelected: selectedRadius == RadiusFilter.five,
              onTap: () {
                ref.read(selectedRadiusProvider.notifier).state =
                    RadiusFilter.five;
              },
            ),
            const SizedBox(width: 8),

            // Profession filter
            _ProfessionChip(
              selectedProfession: selectedProfession,
              onTap: onProfessionTap,
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? ColorConstants.seed.withOpacity(0.15)
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? ColorConstants.seed : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? ColorConstants.seed : Colors.grey.shade700,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? ColorConstants.seed : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Address Picker ────────────────────────────────────────────────────────────

class _AddressPicker extends StatelessWidget {
  final List<Address> addresses;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _AddressPicker({
    required this.addresses,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.location_on, color: ColorConstants.seed, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButton<int>(
              value: selectedIndex.clamp(0, addresses.length - 1),
              isExpanded: true,
              underline: const SizedBox(),
              isDense: true,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
              items: List.generate(addresses.length, (i) {
                final addr = addresses[i];
                return DropdownMenuItem(
                  value: i,
                  child: Text(
                    addr.shortAddress.isNotEmpty
                        ? addr.shortAddress
                        : addr.city.isNotEmpty
                        ? addr.city
                        : 'Address ${i + 1}',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }),
              onChanged: (idx) {
                if (idx != null) onChanged(idx);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Profession Chip ───────────────────────────────────────────────────────────

class _ProfessionChip extends StatelessWidget {
  final Services? selectedProfession;
  final VoidCallback onTap;

  const _ProfessionChip({
    required this.selectedProfession,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = selectedProfession != null;
    final data = isActive ? ServicesData.services[selectedProfession!]! : null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? ColorConstants.seed.withOpacity(0.15)
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? ColorConstants.seed : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? data![1] as IconData : Icons.work,
              size: 16,
              color: isActive ? ColorConstants.seed : Colors.grey.shade700,
            ),
            const SizedBox(width: 5),
            Text(
              isActive ? data![2] as String : 'Profession',
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? ColorConstants.seed : Colors.grey.shade700,
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 4),
              Icon(Icons.close, size: 14, color: ColorConstants.seed),
            ],
          ],
        ),
      ),
    );
  }
}
