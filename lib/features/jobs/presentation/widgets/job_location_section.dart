import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:voicesewa_worker/core/constants/color_constants.dart';
import 'package:voicesewa_worker/shared/models/job_model.dart';
import 'job_section_card.dart';
import 'package:voicesewa_worker/core/extensions/context_extensions.dart';

class JobLocationSection extends StatelessWidget {
  final JobModel job;

  const JobLocationSection({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    final location = job.address.location;
    final hasLocation = location != null;

    return JobSectionCard(
      title: context.loc.clientLocation,
      icon: Icons.location_on_outlined,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (job.address.displayAddress.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.place_outlined,
                    size: 15,
                    color: ColorConstants.textGrey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      job.address.displayAddress,
                      style: const TextStyle(
                        fontSize: 13,
                        color: ColorConstants.textDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            if (hasLocation) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 200,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(
                        location!.latitude,
                        location.longitude,
                      ),
                      initialZoom: 15,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.voicesewa.worker',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(
                              location.latitude,
                              location.longitude,
                            ),
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_pin,
                              color: ColorConstants.errorRed,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.open_in_new, size: 16),
                  onPressed: () => _openInMaps(location),
                  label: Text(context.loc.openInMaps),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ColorConstants.primaryBlue,
                    side: BorderSide(
                      color: ColorConstants.primaryBlue.withOpacity(0.5),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ] else
              const Text(
                'Location not provided',
                style: TextStyle(fontSize: 13, color: ColorConstants.textGrey),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _openInMaps(GeoPoint location) async {
    final lat = location.latitude;
    final lng = location.longitude;

    // Try native maps app first (geo: URI) — works on Android & iOS
    final geoUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng');
    if (await canLaunchUrl(geoUri)) {
      await launchUrl(geoUri, mode: LaunchMode.externalApplication);
      return;
    }

    // Fallback: open Google Maps in browser
    final webUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    await launchUrl(webUri, mode: LaunchMode.externalApplication);
  }
}
