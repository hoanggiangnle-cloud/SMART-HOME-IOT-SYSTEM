class HistoryEntry {
  final String room;
  final DateTime timestamp;
  final double voltage;
  final double current;
  final double power;
  final double? temp;
  final double? humi;

  HistoryEntry({
    required this.room,
    required this.timestamp,
    required this.voltage,
    required this.current,
    required this.power,
    this.temp,
    this.humi,
  });

  factory HistoryEntry.fromJson(Map<String, dynamic> j) {
    return HistoryEntry(
      room: j['room'] ?? '',
      timestamp: DateTime.parse(j['timestamp']),
      voltage: (j['voltage'] as num).toDouble(),
      current: (j['current'] as num).toDouble(),
      power: (j['power'] as num).toDouble(),
      temp: j['temp'] != null ? (j['temp'] as num).toDouble() : null,
      humi: j['humi'] != null ? (j['humi'] as num).toDouble() : null,
    );
  }
}