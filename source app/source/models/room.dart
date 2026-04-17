class Room {
  String name;
  double? temp;
  double? humi;
  String light;
  String fan;
  int tempPin;
  int lightPin;
  int fanPin;

  Room({
    required this.name,
    this.temp,
    this.humi,
    this.light = 'OFF',
    this.fan = 'OFF',
    this.tempPin = -1,
    this.lightPin = -1,
    this.fanPin = -1,
  });

  factory Room.fromJson(Map<String, dynamic> j) {
    return Room(
      name: j['name'] ?? 'Room',
      temp: j['temp'] != null ? (j['temp'] as num).toDouble() : null,
      humi: j['humi'] != null ? (j['humi'] as num).toDouble() : null,
      light: (j['light'] ?? 'OFF').toString(),
      fan: (j['fan'] ?? 'OFF').toString(),
      tempPin: j['tempPin'] ?? -1,
      lightPin: j['lightPin'] ?? -1,
      fanPin: j['fanPin'] ?? -1,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'temp': temp,
        'humi': humi,
        'light': light,
        'fan': fan,
        'tempPin': tempPin,
        'lightPin': lightPin,
        'fanPin': fanPin,
      };
}