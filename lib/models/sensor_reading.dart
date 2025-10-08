// models/sensor_reading.dart
class SensorReading {
  final String activity;
  final double temperature;
  final double humidity;
  final double lightIntensity;
  final double ammoniacO2;

  SensorReading({
    this.activity = 'Unknown',
    this.temperature = 0.0,
    this.humidity = 0.0,
    this.lightIntensity = 0.0,
    this.ammoniacO2 = 0.0,
  });

  // A factory constructor to create a SensorReading from a Map
  factory SensorReading.fromMap(Map<String, dynamic> map) {
    return SensorReading(
      activity: map['room_activity']?.toString() ?? 'Unknown',
      temperature: map['temperature']?.toDouble() ?? 0.0,
      humidity: map['humidity']?.toDouble() ?? 0.0,
      lightIntensity: map['light intesity']?.toDouble() ?? 0.0,
      ammoniacO2: map['ammonia/cO2']?.toDouble() ?? 0.0,
    );
  }

  /// Backwards-compatible getter expected by UI code
  double get ammonia => ammoniacO2;
}
