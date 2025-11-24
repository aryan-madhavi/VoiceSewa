import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final List<ChartData> chartData = [
    ChartData("2025", 10000),
    ChartData("2024", 5000),
    ChartData("2023", 3000),
  ];
  @override
  Widget build(BuildContext context) {
    return Card(
      child: SfCartesianChart(
        primaryXAxis: CategoryAxis(),
        series: <CartesianSeries>[
          BarSeries<ChartData, String>(
            dataSource: chartData,
            xValueMapper: (ChartData data, _) => data.year,
            yValueMapper: (ChartData data, _) => data.amount,
            width: 0.5,
            spacing: 0.3,
          ),
        ],
      ),
    );
  }
}

class ChartData {
  final String year;
  final double amount;
  ChartData(this.year, this.amount);
}
