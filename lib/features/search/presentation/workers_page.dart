import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:voicesewa_client/core/constants/color_constants.dart';
import 'package:voicesewa_client/features/search/providers/worker_provider.dart';
import 'package:voicesewa_client/features/search/presentation/widgets/worker_card.dart';
import 'package:voicesewa_client/features/search/presentation/widgets/worker_details_sheet.dart';
import 'package:voicesewa_client/shared/data/services_data.dart';
import 'package:voicesewa_client/shared/models/worker_model.dart';

class SuggestedWorkersPage extends ConsumerStatefulWidget {
  const SuggestedWorkersPage({super.key});

  @override
  ConsumerState<SuggestedWorkersPage> createState() =>
      _SuggestedWorkersPageState();
}

class _SuggestedWorkersPageState extends ConsumerState<SuggestedWorkersPage> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  // Ambarnath center coordinates
  static const LatLng _centerAmbarnath = LatLng(19.1958, 73.1964);

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _updateMarkers(List<WorkerModel> workers) {
    final markers = <Marker>{};

    for (final worker in workers) {
      final position = LatLng(
        worker.address.location.latitude,
        worker.address.location.longitude,
      );

      markers.add(
        Marker(
          markerId: MarkerId(worker.uid),
          position: position,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _getMarkerColor(worker.service),
          ),
          infoWindow: InfoWindow(
            title: worker.name,
            snippet: '${worker.serviceLabel} • ⭐ ${worker.rating}',
            onTap: () => _showWorkerDetails(worker),
          ),
          onTap: () => _showWorkerDetails(worker),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });

    // Animate camera to fit all markers
    if (workers.isNotEmpty && _mapController != null) {
      _fitMarkersInView(workers);
    }
  }

  void _fitMarkersInView(List<WorkerModel> workers) {
    if (workers.isEmpty) return;

    double minLat = workers.first.address.location.latitude;
    double maxLat = workers.first.address.location.latitude;
    double minLng = workers.first.address.location.longitude;
    double maxLng = workers.first.address.location.longitude;

    for (final worker in workers) {
      final lat = worker.address.location.latitude;
      final lng = worker.address.location.longitude;

      if (lat < minLat) minLat = lat;
      if (lat > maxLat) maxLat = lat;
      if (lng < minLng) minLng = lng;
      if (lng > maxLng) maxLng = lng;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  double _getMarkerColor(Services service) {
    switch (service) {
      case Services.houseCleaner:
        return BitmapDescriptor.hueGreen;
      case Services.plumber:
        return BitmapDescriptor.hueBlue;
      case Services.electrician:
        return BitmapDescriptor.hueYellow;
      case Services.carpenter:
        return BitmapDescriptor.hueOrange;
      case Services.painter:
        return BitmapDescriptor.hueViolet;
      case Services.acApplianceTechnician:
        return BitmapDescriptor.hueCyan;
      case Services.mechanic:
        return BitmapDescriptor.hueRose;
      case Services.cook:
        return BitmapDescriptor.hueRed;
      case Services.driverOnDemand:
        return BitmapDescriptor.hueAzure;
      case Services.handymanMasonryWork:
        return BitmapDescriptor.hueOrange;
      default:
        return BitmapDescriptor.hueRed;
    }
  }

  void _showWorkerDetails(WorkerModel worker) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WorkerDetailsSheet(
        worker: worker,
        onBookNow: () {
          Navigator.pop(context);
          // TODO: handle booking logic here
        },
        onPlayVoice: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Play voice intro: ${worker.voiceText ?? "No voice intro available"}',
              ),
            ),
          );
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
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final selectedProfession = ref.watch(selectedProfessionProvider);

            return Padding(
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
                  // All Services option
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
                  // Individual services
                  ...Services.values.map((service) {
                    final isSelected = selectedProfession == service;
                    final serviceData = ServicesData.services[service]!;
                    final color = serviceData[0] as Color;
                    final icon = serviceData[1] as IconData;
                    final label = serviceData[2] as String;

                    return ListTile(
                      leading: Icon(icon, color: color),
                      title: Text(label),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: ColorConstants.seed)
                          : null,
                      onTap: () {
                        ref.read(selectedProfessionProvider.notifier).state =
                            service;
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final workersAsync = ref.watch(workerListProvider);
    final selectedFilter = ref.watch(selectedFilterProvider);
    final selectedProfession = ref.watch(selectedProfessionProvider);

    // Update markers when workers change
    workersAsync.whenData((workers) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateMarkers(workers);
      });
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Suggested Workers'), elevation: 0),
      body: Column(
        children: [
          // 🗺️ Google Map View (Top Half)
          Expanded(
            flex: 2,
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: const CameraPosition(
                target: _centerAmbarnath,
                zoom: 13,
              ),
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,

              // ADD THESE FOR BETTER PERFORMANCE:
              liteModeEnabled: false, // Full map features
              mapToolbarEnabled: false,
              zoomControlsEnabled: false,
              buildingsEnabled: true,
              compassEnabled: true,
              rotateGesturesEnabled: true,
              scrollGesturesEnabled: true,
              tiltGesturesEnabled: true,
              zoomGesturesEnabled: true,

              // PERFORMANCE SETTINGS:
              minMaxZoomPreference: const MinMaxZoomPreference(10, 20),
              cameraTargetBounds: CameraTargetBounds.unbounded,
            ),
          ),

          // 🔽 Filter Chips (Horizontal scrollable)
          Container(
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
                  _buildFilterChip(
                    context,
                    WorkerFilter.distance,
                    'Distance',
                    Icons.location_on,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    context,
                    WorkerFilter.rating,
                    'Rating',
                    Icons.star,
                  ),
                  const SizedBox(width: 8),
                  // Profession filter with special handling
                  InkWell(
                    onTap: _showProfessionFilter,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: selectedProfession != null
                            ? ColorConstants.seed.withOpacity(0.2)
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selectedProfession != null
                              ? ColorConstants.seed
                              : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            selectedProfession != null
                                ? ServicesData.services[selectedProfession]![1]
                                      as IconData
                                : Icons.work,
                            size: 18,
                            color: selectedProfession != null
                                ? Colors.black
                                : Colors.grey.shade700,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            selectedProfession != null
                                ? ServicesData.services[selectedProfession]![2]
                                      as String
                                : 'Profession',
                            style: TextStyle(
                              color: selectedProfession != null
                                  ? Colors.black
                                  : Colors.grey.shade700,
                              fontWeight: selectedProfession != null
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                          if (selectedProfession != null) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.grey.shade700,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 📋 Worker Cards List (scrollable)
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
                          'No workers found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            // Reset filters
                            ref
                                    .read(selectedProfessionProvider.notifier)
                                    .state =
                                null;
                            ref.read(selectedFilterProvider.notifier).state =
                                WorkerFilter.distance;
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
                      onPlayVoice: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Play voice intro: ${worker.voiceText ?? "No voice intro available"}',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
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

  Widget _buildFilterChip(
    BuildContext context,
    WorkerFilter filter,
    String label,
    IconData icon,
  ) {
    final selected = ref.watch(selectedFilterProvider);
    final isSelected = selected == filter;

    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected ? Colors.black : Colors.grey.shade700,
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (_) {
        ref.read(selectedFilterProvider.notifier).state = filter;
      },
      selectedColor: ColorConstants.seed.withOpacity(0.2),
      backgroundColor: Colors.grey.shade200,
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 14,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}
