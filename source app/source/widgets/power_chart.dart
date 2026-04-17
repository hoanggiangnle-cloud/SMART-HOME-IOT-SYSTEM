import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/history_entry.dart';

class PowerChart extends StatelessWidget {
  final List<HistoryEntry> history;
  const PowerChart({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) return const Center(child: Text('Không có dữ liệu'));

    final reversed = history.reversed.toList();

    final spotsV = <FlSpot>[];
    final spotsA = <FlSpot>[];
    final spotsW = <FlSpot>[];
    for (var i = 0; i < reversed.length; i++) {
      final h = reversed[i];
      spotsV.add(FlSpot(i.toDouble(), h.voltage));
      spotsA.add(FlSpot(i.toDouble(), h.current));
      spotsW.add(FlSpot(i.toDouble(), h.power));
    }

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(spots: spotsV, color: Colors.amber, isCurved: true, barWidth: 2, dotData: FlDotData(show: false)),
          LineChartBarData(spots: spotsA, color: Colors.red ,isCurved: true, barWidth: 2, dotData: FlDotData(show: false)),
          LineChartBarData(spots: spotsW, color: Colors.purple ,isCurved: true, barWidth: 2, dotData: FlDotData(show: false)),
        ],
        titlesData: FlTitlesData(show: false),
        gridData: FlGridData(show: false),
      ),
    );
  }
}