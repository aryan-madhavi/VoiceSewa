import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_client/shared/data/services_data.dart';

final quickBookServicesProvider = Provider<List<Services>>((ref) {
  return [
    Services.electrician,
    Services.plumber,
    Services.carpenter,
    Services.painter,
  ];
});
