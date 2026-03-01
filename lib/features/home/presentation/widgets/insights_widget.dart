import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../../core/constants/color_constants.dart';

// ── Models ─────────────────────────────────────────────────────────────────

class _ForecastItem {
  final String district;
  final String job;
  final double demandProbability;

  const _ForecastItem({
    required this.district,
    required this.job,
    required this.demandProbability,
  });

  factory _ForecastItem.fromJson(Map<String, dynamic> json) => _ForecastItem(
    district: json['district'] as String,
    job: json['job'] as String,
    demandProbability: (json['demandProbability'] as num).toDouble(),
  );
}

class _ForecastData {
  final int month;
  final String season;
  final List<_ForecastItem> top5;
  final List<_ForecastItem> fullForecast;

  const _ForecastData({
    required this.month,
    required this.season,
    required this.top5,
    required this.fullForecast,
  });

  factory _ForecastData.fromJson(Map<String, dynamic> json) => _ForecastData(
    month: json['month'] as int,
    season: json['season'] as String,
    top5: (json['top5'] as List)
        .map((e) => _ForecastItem.fromJson(e as Map<String, dynamic>))
        .toList(),
    fullForecast: (json['fullForecast'] as List)
        .map((e) => _ForecastItem.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

// ── Color palettes ──────────────────────────────────────────────────────────

const _jobColors = <String, Color>{
  'Electrician': Color(0xFFFFB300),
  'Plumber': Color(0xFF1E88E5),
  'Carpenter': Color(0xFF6D4C41),
  'Painter': Color(0xFFE53935),
  'Appliance Technician': Color(0xFF8E24AA),
  'House Cleaner': Color(0xFF00ACC1),
  'Driver': Color(0xFF43A047),
  'Cook': Color(0xFFF4511E),
  'Mechanic': Color(0xFF546E7A),
  'Masonry': Color(0xFF7CB342),
};

const _areaColors = <String, Color>{
  'Panvel': Color(0xFF00BFA5),
  'Andheri': Color(0xFF3949AB),
  'Borivali': Color(0xFFD81B60),
  'Ghodbunder': Color(0xFFFF8F00),
  'Kalyan': Color(0xFF00897B),
  'Vashi': Color(0xFF8E24AA),
};

Color _jobColor(String job) => _jobColors[job] ?? const Color(0xFF607D8B);

Color _areaColor(String district) {
  for (final entry in _areaColors.entries) {
    if (district.contains(entry.key)) return entry.value;
  }
  return const Color(0xFF546E7A);
}

IconData _jobIcon(String job) {
  final j = job.toLowerCase();
  if (j.contains('electric')) return Icons.bolt_rounded;
  if (j.contains('plumb')) return Icons.water_rounded;
  if (j.contains('carpen')) return Icons.handyman_rounded;
  if (j.contains('paint')) return Icons.format_paint_rounded;
  if (j.contains('appliance')) return Icons.kitchen_rounded;
  if (j.contains('clean')) return Icons.cleaning_services_rounded;
  if (j.contains('driver')) return Icons.directions_car_rounded;
  if (j.contains('cook')) return Icons.restaurant_rounded;
  if (j.contains('mechanic')) return Icons.build_rounded;
  if (j.contains('mason')) return Icons.domain_rounded;
  return Icons.work_rounded;
}

// ── Main widget ─────────────────────────────────────────────────────────────

class InsightsWidget extends StatefulWidget {
  const InsightsWidget({super.key});

  @override
  State<InsightsWidget> createState() => _InsightsWidgetState();
}

class _InsightsWidgetState extends State<InsightsWidget> {
  _ForecastData? _data;
  bool _loading = true;
  String? _error;

  static const _baseUrl = 'https://voicesewa-3.onrender.com';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await http.get(Uri.parse('$_baseUrl/current-forecast'));
      if (res.statusCode == 200) {
        setState(() {
          _data = _ForecastData.fromJson(
            jsonDecode(res.body) as Map<String, dynamic>,
          );
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load (${res.statusCode})';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error. Tap to retry.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF48CAE4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Market Insights',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  Text(
                    'Job demand by area & trade',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
              const Spacer(),
              if (!_loading)
                GestureDetector(
                  onTap: _fetchData,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.refresh_rounded,
                      color: Colors.grey,
                      size: 18,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 20),

          // ── States ──────────────────────────────────────────────────────
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: CircularProgressIndicator(
                  color: Color(0xFF6C63FF),
                  strokeWidth: 2.5,
                ),
              ),
            )
          else if (_error != null)
            GestureDetector(
              onTap: _fetchData,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.wifi_off_rounded,
                        color: Colors.grey,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tap to retry',
                        style: TextStyle(
                          color: Color(0xFF6C63FF),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (_data != null)
            _InsightsBody(data: _data!),
        ],
      ),
    );
  }
}

// ── Body ────────────────────────────────────────────────────────────────────

class _InsightsBody extends StatelessWidget {
  final _ForecastData data;
  const _InsightsBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final uniqueJobs = data.fullForecast.map((e) => e.job).toSet().toList();

    // Build area → {job → probability}
    final areaMap = <String, Map<String, double>>{};
    for (final item in data.fullForecast) {
      areaMap.putIfAbsent(item.district, () => {});
      areaMap[item.district]![item.job] = item.demandProbability;
    }

    final sortedAreas = areaMap.entries.toList()
      ..sort((a, b) {
        final aAvg = a.value.values.reduce((x, y) => x + y) / a.value.length;
        final bAvg = b.value.values.reduce((x, y) => x + y) / b.value.length;
        return bAvg.compareTo(aAvg);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Season banner
        _SeasonBanner(season: data.season),
        const SizedBox(height: 20),

        // Job legend
        const Text(
          'Job Types',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: uniqueJobs.map((job) => _JobChip(job: job)).toList(),
        ),

        const SizedBox(height: 24),

        // Area cards
        const Text(
          'Demand by Area',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 10),
        ...sortedAreas.map(
          (e) => _AreaCard(district: e.key, jobDemand: e.value),
        ),
      ],
    );
  }
}

// ── Season banner ────────────────────────────────────────────────────────────

class _SeasonBanner extends StatelessWidget {
  final String season;
  const _SeasonBanner({required this.season});

  @override
  Widget build(BuildContext context) {
    final sl = season.toLowerCase();
    final gradient = sl == 'summer'
        ? const LinearGradient(colors: [Color(0xFFFFB300), Color(0xFFFF7043)])
        : sl == 'monsoon'
        ? const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF00ACC1)])
        : sl == 'winter'
        ? const LinearGradient(colors: [Color(0xFF37474F), Color(0xFF546E7A)])
        : const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)]);

    final icon = sl == 'summer'
        ? Icons.wb_sunny_rounded
        : sl == 'monsoon'
        ? Icons.water_drop_rounded
        : sl == 'winter'
        ? Icons.ac_unit_rounded
        : Icons.eco_rounded;

    final label = sl == 'summer'
        ? 'Summer Season — High demand expected across all trades'
        : sl == 'monsoon'
        ? 'Monsoon Season — Surge in plumbing & repair work'
        : sl == 'winter'
        ? 'Winter Season — Indoor jobs at peak'
        : '$season Season';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Job chip ─────────────────────────────────────────────────────────────────

class _JobChip extends StatelessWidget {
  final String job;
  const _JobChip({required this.job});

  @override
  Widget build(BuildContext context) {
    final color = _jobColor(job);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Icon(_jobIcon(job), size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            job,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Area card ─────────────────────────────────────────────────────────────────

class _AreaCard extends StatelessWidget {
  final String district;
  final Map<String, double> jobDemand;
  const _AreaCard({required this.district, required this.jobDemand});

  @override
  Widget build(BuildContext context) {
    final areaColor = _areaColor(district);
    final avg = jobDemand.values.reduce((a, b) => a + b) / jobDemand.length;
    final pct = (avg * 100).round();

    final sortedJobs = jobDemand.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: areaColor.withOpacity(0.22)),
        boxShadow: [
          BoxShadow(
            color: areaColor.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Area header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: areaColor.withOpacity(0.09),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: areaColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    district,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: areaColor,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: areaColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Avg $pct%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Job bars
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: sortedJobs.map((entry) {
                final jColor = _jobColor(entry.key);
                final jPct = (entry.value * 100).round();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Row(
                    children: [
                      Icon(_jobIcon(entry.key), size: 13, color: jColor),
                      const SizedBox(width: 5),
                      SizedBox(
                        width: 112,
                        child: Text(
                          entry.key,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: jColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: entry.value,
                            backgroundColor: jColor.withOpacity(0.10),
                            valueColor: AlwaysStoppedAnimation<Color>(jColor),
                            minHeight: 7,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 30,
                        child: Text(
                          '$jPct%',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: jColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
