import 'package:flutter/material.dart';

enum Services {
  electrician,
  plumber,
  carpenter,
  painter,
  acApplianceTechnician,
  houseCleaner,
  driverOnDemand,
  cook,
  mechanic,
  handymanMasonryWork,
}

class ServicesData {
  static final Map<Services, List<dynamic>> services = {
    Services.electrician: [
      Colors.amber,
      Icons.electric_bolt,
      'Electrician',
    ],
    Services.plumber: [
      Colors.blue,
      Icons.plumbing,
      'Plumber',
    ],
    Services.carpenter: [
      Colors.brown,
      Icons.handyman,
      'Carpenter',
    ],
    Services.painter: [
      Colors.purple,
      Icons.format_paint,
      'Painter',
    ],
    Services.acApplianceTechnician: [
      Colors.cyan,
      Icons.ac_unit,
      'AC / Appliance Technician',
    ],
    Services.houseCleaner: [
      Colors.teal,
      Icons.cleaning_services,
      'House Cleaner',
    ],
    Services.driverOnDemand: [
      Colors.indigo,
      Icons.drive_eta,
      'Driver on Demand',
    ],
    Services.cook: [
      Colors.redAccent,
      Icons.restaurant,
      'Cook',
    ],
    Services.mechanic: [
      Colors.grey,
      Icons.build,
      'Mechanic (2W / 4W)',
    ],
    Services.handymanMasonryWork: [
      Colors.orange,
      Icons.construction,
      'Handyman / Masonry Work',
    ],
  };

  /// All service name strings — use for dropdowns, Firestore values, etc.
  static List<String> get serviceNames =>
      services.values.map((v) => v[2] as String).toList();

  /// Display name for a given service.
  static String nameOf(Services service) => services[service]![2] as String;

  /// Icon for a given service.
  static IconData iconOf(Services service) => services[service]![1] as IconData;

  /// Color for a given service.
  static Color colorOf(Services service) => services[service]![0] as Color;
}