import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/history_entry.dart';

class TempHumChart extends StatelessWidget {
  final List<HistoryEntry> entries;

  const TempHumChart({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 2,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
              ),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < entries.length) {
                    return RotatedBox(
                      quarterTurns: 1,
                      child: Text(
                        '${entries[value.toInt()].timestamp.hour}:${entries[value.toInt()].timestamp.minute}',
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            // Temperature line
            LineChartBarData(
              spots: List.generate(entries.length, (index) {
                return entries[index].temp != null
                    ? FlSpot(index.toDouble(), entries[index].temp!)
                    : FlSpot.nullSpot;
              }),
              isCurved: true,
              color: Colors.red,
              barWidth: 2,
              dotData: FlDotData(show: false),
            ),
            // Humidity line
            LineChartBarData(
              spots: List.generate(entries.length, (index) {
                return entries[index].humi != null
                    ? FlSpot(index.toDouble(), entries[index].humi!)
                    : FlSpot.nullSpot;
              }),
              isCurved: true,
              color: Colors.blue,
              barWidth: 2,
              dotData: FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}