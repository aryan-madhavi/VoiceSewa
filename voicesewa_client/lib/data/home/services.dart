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

class ServiceData {
  static final List<Services> quickServices = [
    Services.electrician,
    Services.plumber,
    Services.carpenter,
    Services.painter,
  ];
  static final Map<Services, List<dynamic>> services = {
    Services.electrician: [
      Colors.amber,
      Icons.electrical_services,
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
}