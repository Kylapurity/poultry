
import 'package:flutter/material.dart';

class MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Widget icon;

  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE0E0E0),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Icon section
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: icon),
            ),
            const SizedBox(width: 20),
            
            // Content section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Urbanist',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF666666),
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontFamily: 'Lexend',
                        fontSize: 50,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4CAF50),
                        height: 1.0,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 4.0),
                      child: Text(
                        unit,
                        style: const TextStyle(
                          fontFamily: 'Urbanist',
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class MetricCardsDemo extends StatelessWidget {
  const MetricCardsDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Temperature Card
              MetricCard(
                label: 'TEMPERATURE',
                value: '18',
                unit: '°C',
                icon: Image.asset(
                  'lib/assets/icons/temperature_icon.png',
                  width: 40,
                  height: 40,
                  color: Colors.black,
                  // If you don't have the exact asset, use an icon instead:
                  // icon: const Icon(Icons.thermostat_outlined, size: 40, color: Colors.black),
                ),
              ),
              
              // Humidity Card
              MetricCard(
                label: 'HUMIDITY',
                value: '97',
                unit: '%',
                icon: Image.asset(
                  'lib/assets/icons/humidity_icon.png',
                  width: 40,
                  height: 40,
                  color: Colors.black,
                  // Alternative:
                  // icon: const Icon(Icons.water_drop_outlined, size: 40, color: Colors.black),
                ),
              ),
              
              // Moisture Card
              MetricCard(
                label: 'MOISTURE',
                value: '7.1',
                unit: 'g/m³',
                icon: Image.asset(
                  'lib/assets/icons/moisture_icon.png',
                  width: 40,
                  height: 40,
                  color: Colors.black,
                  // Alternative:
                  // icon: const Icon(Icons.water_outlined, size: 40, color: Colors.black),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// If you need to implement this directly in your existing code, 
// you can refactor your _buildMetricCard method like this:

Widget _buildMetricCard({
  required String icon,
  required String label,
  required String value,
  required Color valueColor,
  String unit = '',
  bool fullWidth = false,
  double valueSize = 50, // Default large size
  String iconContent = '',
}) {
  return Container(
    width: fullWidth ? double.infinity : null,
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: Colors.grey.shade300,
        width: 1,
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Icon Container
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: iconContent.isEmpty
                ? Center(
                    child: Image.asset(
                      icon,
                      width: 40,
                      height: 40,
                      color: Colors.black,
                    ),
                  )
                : Center(
                    child: Text(
                      iconContent,
                      style: const TextStyle(
                        fontFamily: 'Lexend',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 20),
          
          // Label and Value
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Urbanist',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF666666),
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontFamily: 'Lexend',
                      fontSize: valueSize,
                      fontWeight: FontWeight.bold,
                      color: valueColor,
                      height: 1.0,
                    ),
                  ),
                  if (unit.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 4.0),
                      child: Text(
                        unit,
                        style: TextStyle(
                          fontFamily: 'Urbanist',
                          fontSize: valueSize * 0.4,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
