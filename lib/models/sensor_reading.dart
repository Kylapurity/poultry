// models/sensor_reading.dart
class SensorReading {
  final String activity;
  final double temperature;
  final double humidity;
  final double moisture;
  /// Soil nutrient levels
  final double nitrogen;
  final double phosphorus;
  final double potassium;
  final double conductivity;

  SensorReading({
    this.activity = 'Unknown',
    this.temperature = 0.0,
    this.humidity = 0.0,
    this.moisture = 0.0,
    this.nitrogen = 0.0,
    this.phosphorus = 0.0,
    this.potassium = 0.0,
    this.conductivity = 0.0,
  });

  // A factory constructor to create a SensorReading from a Map
  factory SensorReading.fromMap(Map<String, dynamic> map) {

    return SensorReading(
      activity: map['soil_activity']?.toString() ?? 'Unknown',
      temperature: map['temperature']?.toDouble() ?? 0.0,
      humidity: map['humidity']?.toDouble() ?? 0.0,
      moisture: map['moisture']?.toDouble() ?? 0.0,
      nitrogen: map['nitrogen']?.toDouble() ?? 0.0,
      phosphorus: map['phosphorus']?.toDouble() ?? 0.0,
      potassium: map['potassium']?.toDouble() ?? 0.0,
      conductivity: map['electrical_conductivity']?.toDouble() ?? 0.0,
    );
  }
}