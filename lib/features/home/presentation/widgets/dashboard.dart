import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../../../core/constants/static_data.dart';
import '../../../../core/extensions/context_extensions.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(20)),
      margin: const EdgeInsetsGeometry.all(20),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.loc.yearlyEarnings, // context.loc.yearlyEarnings,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3436),
              ),
            ),
            const SizedBox(height: 24,),
            Text(
              context.loc.growthOverTheLastFiveYears, // context.loc.growthOverTheLastFiveYears,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Expanded(
              child: SfCartesianChart(

                plotAreaBorderWidth: 0,
                margin: EdgeInsets.zero,

                primaryXAxis: CategoryAxis(

                  majorGridLines: const MajorGridLines(width: 0,),
                  // axisLine: const AxisLine(width: 0,),
                  labelStyle: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600,),
                ),

                primaryYAxis: NumericAxis(
                  isVisible: false,
                  minimum: 0,
                  majorGridLines: const MajorGridLines(width: 0,),
                ),

                tooltipBehavior: TooltipBehavior(
                  enable: true,
                  header: '',
                  canShowMarker: false,
                  format: 'point.y',
                  textStyle: const TextStyle(color: Colors.white,),
                ),

                series: <CartesianSeries>[
                  ColumnSeries<ChartData, String>(
                    dataSource: chartData,
                    xValueMapper: (ChartData data, _) => data.year,
                    yValueMapper: (ChartData data, _) => data.amount,
                    width: 0.6,
                    spacing: 0.3,
                    // borderRadius: const BorderRadius.vertical(top: Radius.circular(12),),
                    pointColorMapper: (ChartData data, _)=> data.isCurrent ? const Color(0xFF00BFA5): const Color(0xFF0056D2),
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      textStyle: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      labelAlignment: ChartDataLabelAlignment.outer,
                    ),

                    animationDuration: 1500,

                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

