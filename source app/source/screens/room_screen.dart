import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/history_entry.dart';
import '../services/api_service.dart';

class RoomScreen extends StatefulWidget {
  final String roomName;
  final Map<String, dynamic>? statusData;
  final List<HistoryEntry> history;

  const RoomScreen({
    super.key,
    required this.roomName,
    this.statusData,
    required this.history,
  });

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  String lightState = 'OFF';
  String fanState = 'OFF';

  @override
  void initState() {
    super.initState();
    _readInitial();
  }

  void _readInitial() {
    if (widget.statusData != null && widget.statusData!['rooms'] != null) {
      final arr = widget.statusData!['rooms'] as List<dynamic>;
      final found = arr.firstWhere(
            (e) => e['name'] == widget.roomName,
        orElse: () => null,
      );
      if (found != null) {
        setState(() {
          lightState = (found['light'] ?? 'OFF').toString().toUpperCase();
          fanState = (found['fan'] ?? 'OFF').toString().toUpperCase();
        });
      }
    }
  }

  Future<void> _toggleDevice(String device) async {
    if (device == 'light') {
      lightState = lightState == 'ON' ? 'OFF' : 'ON';
    } else {
      fanState = fanState == 'ON' ? 'OFF' : 'ON';
    }

    final ok = await ApiService.toggleDevice(widget.roomName, fanState, lightState);

    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi khi gửi lệnh điều khiển')),
      );
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final roomHistory = widget.history
        .where((h) => h.room == widget.roomName)
        .toList()
        .reversed
        .toList();

    final temp = roomHistory.isNotEmpty ? roomHistory.first.temp : null;
    final humi = roomHistory.isNotEmpty ? roomHistory.first.humi : null;

    return Scaffold(
      appBar: AppBar(title: Text(widget.roomName)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // --- Hàng hiển thị nhiệt độ và độ ẩm ---
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _InfoChip(
                  iconWidget: const Icon(Icons.thermostat, color: Colors.redAccent),
                  label: temp != null ? '${temp.toStringAsFixed(1)}°C' : '-',
                ),
                const SizedBox(width: 12),
                _InfoChip(
                  iconWidget: const Icon(Icons.water_drop, color: Colors.blueAccent),
                  label: humi != null ? '${humi.toStringAsFixed(1)}%' : '-',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // --- Biểu đồ ---
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    const Text(
                      'Biểu đồ nhiệt độ & độ ẩm',
                      style: TextStyle(fontWeight: FontWeight.bold,fontSize: 22),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(height: 300, child: _RoomChart(history: roomHistory)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // --- Nút bật/tắt đèn và quạt ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: lightState == 'ON' ? Colors.green : Colors.red,
                    minimumSize: Size(150, 50),
                  ),
                  onPressed: () => _toggleDevice('light'),
                  child: Text('Đèn: $lightState',style: const TextStyle(fontSize: 22,fontWeight: FontWeight.bold),),
                ),
                ElevatedButton(
                  
                  style: ElevatedButton.styleFrom(
                    backgroundColor: fanState == 'ON' ? Colors.green : Colors.red,
                    minimumSize: Size(150, 50),
                  ),
                  onPressed: () => _toggleDevice('fan'),
                  child: Text('Quạt: $fanState',style: const TextStyle(fontSize: 22,fontWeight: FontWeight.bold),),
                ),
              ],
            ),

            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: Size(150, 50),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Trở về',style: TextStyle(fontSize: 22),),
            ),
          ],
        ),
      ),
    );
  }
}
//  Widget hiển thị chip thông tin (icon + text)
class _InfoChip extends StatelessWidget {
  final Widget iconWidget;
  final String label;

  const _InfoChip({required this.iconWidget, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconWidget,
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600,fontSize: 24),
          ),
        ],
      ),
    );
  }
}

//  Widget biểu đồ nhiệt độ & độ ẩm
class _RoomChart extends StatelessWidget {
  final List<HistoryEntry> history;

  const _RoomChart({required this.history});

  @override
  Widget build(BuildContext context) {
    final spotsTemp = <FlSpot>[];
    final spotsHumi = <FlSpot>[];

    for (var i = 0; i < history.length; i++) {
      final h = history[i];
      spotsTemp.add(FlSpot(i.toDouble(), h.temp ?? 0));
      spotsHumi.add(FlSpot(i.toDouble(), h.humi ?? 0));
    }

    return SizedBox(
      height: 280,
      child: history.isEmpty
          ? const Center(child: Text('No data'))
          : LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: spotsTemp,
              isCurved: true,
              dotData: FlDotData(show: false),
              barWidth: 2,
              color: Colors.redAccent,
            ),
            LineChartBarData(
              spots: spotsHumi,
              isCurved: true,
              dotData: FlDotData(show: false),
              barWidth: 2,
              color: Colors.blueAccent,
            ),
          ],
          titlesData: FlTitlesData(show: false),
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}
