import 'package:poultry_app/models/sensor_reading.dart';
import 'package:poultry_app/services/api/api_service.dart';
import 'package:poultry_app/services/notifications/notifications_service.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:poultry_app/screens/history/history_screen.dart';
import 'package:poultry_app/screens/chatbot/chatbot_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  final NotificationService _notificationService = NotificationService();
  bool _isLoading = true;
  String? _errorMessage;
  SensorReading? _latestReading;
  List<List<FlSpot>> _chartData = [];

  // Threshold values for egg production monitoring
  final Map<String, Map<String, double>> thresholds = {
    'temperature': {'min': 18.0, 'max': 30.0},
    'humidity': {'min': 50.0, 'max': 70.0},
    'ammonia': {'min': 0.0, 'max': 25.0},
    'light_intensity': {'min': 100.0, 'max': 800.0},
  };

  final Map<String, Map<String, String>> activityThreshold = {
    'activity': {'min': "Low Activity", 'max': "High Activity"},
  };

  bool showNotification = false;
  String notificationMessage = '';
  String selectedTimePeriod = '1D';

  Map<String, double> _getChartBoundaries() {
    if (_chartData.isEmpty) {
      return {'minX': 0, 'maxX': 5, 'minY': 0, 'maxY': 30};
    }

    double minY = double.infinity;
    double maxY = double.negativeInfinity;
    double maxX = 0;

    for (var series in _chartData) {
      for (var spot in series) {
        if (spot.y < minY) minY = spot.y;
        if (spot.y > maxY) maxY = spot.y;
        if (spot.x > maxX) maxX = spot.x;
      }
    }

    double range = maxY - minY;
    double padding = range * 0.1;

    return {
      'minX': 0,
      'maxX': maxX > 0 ? maxX : 5,
      'minY': (minY - padding).clamp(0, double.infinity),
      'maxY': maxY + padding,
    };
  }

  @override
  void initState() {
    super.initState();
    _notificationService.init();
    _loadAllData();
  }

  void _checkThresholds() {
    if (_latestReading == null) return;

    String? alertMessage;

    final activity = _latestReading?.activity;
    if (activity == activityThreshold['activity']?['max']) {
      alertMessage = 'Egg Production is High ($activity).';
    } else if (activity == activityThreshold['activity']?['min']) {
      alertMessage = 'Egg Production is Low ($activity).';
    }

    final temp = _latestReading!.temperature;
    final tempThreshold = thresholds['temperature']!;
    if (temp > tempThreshold['max']!) {
      alertMessage =
          'Temperature is too high (${temp.toStringAsFixed(1)}°C). Adjust ventilation.';
    } else if (temp < tempThreshold['min']!) {
      alertMessage =
          'Temperature is too low (${temp.toStringAsFixed(1)}°C). Add heating.';
    }

    final humidity = _latestReading!.humidity;
    final humidityThreshold = thresholds['humidity']!;
    if (humidity > humidityThreshold['max']!) {
      alertMessage =
          'Humidity is too high (${humidity.toStringAsFixed(1)}%). Improve ventilation.';
    } else if (humidity < humidityThreshold['min']!) {
      alertMessage =
          'Humidity is too low (${humidity.toStringAsFixed(1)}%). Add moisture.';
    }

    final ammonia = _latestReading!.ammonia;
    final ammoniaThreshold = thresholds['ammonia']!;
    if (ammonia > ammoniaThreshold['max']!) {
      alertMessage =
          'Ammonia level is too high (${ammonia.toStringAsFixed(1)} ppm). Clean coop!';
    }

    final light = _latestReading!.lightIntensity;
    final lightThreshold = thresholds['light_intensity']!;
    if (light < lightThreshold['min']!) {
      alertMessage =
          'Light intensity is too low (${light.toStringAsFixed(1)} lux). Chickens need 14-16 hours of light.';
    }

    if (alertMessage != null) {
      _notificationService.showNotification('Alert', alertMessage);
      setState(() {
        showNotification = true;
        notificationMessage = alertMessage!;
      });
    }
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dataMap = await _apiService.getSensorData(context: context);
      final reading = SensorReading.fromMap(dataMap);
      final historicalData = await _apiService.getHistoricalData('1D');

      setState(() {
        _latestReading = reading;
        _chartData = _prepareChartData(historicalData);
        _isLoading = false;
      });

      _checkThresholds();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data. Please pull to refresh.';
        _isLoading = false;
      });
    }
  }

  List<List<FlSpot>> _prepareChartData(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return [];

    final List<FlSpot> tempData = [];
    final List<FlSpot> humidityData = [];
    final List<FlSpot> ammoniaData = [];

    for (int i = 0; i < data.length; i++) {
      final record = data[i];
      final xValue = i.toDouble();

      tempData.add(FlSpot(xValue, record['temperature']?.toDouble() ?? 0));
      humidityData.add(FlSpot(xValue, record['humidity']?.toDouble() ?? 0));
      ammoniaData.add(FlSpot(xValue, record['ammonia']?.toDouble() ?? 0));
    }

    return [tempData, humidityData, ammoniaData];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadAllData,
                    color: Colors.white,
                    backgroundColor: const Color(0xFF5E4935),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(22.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showNotification)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Egg Production Alert',
                                    style: TextStyle(
                                      fontFamily: 'Lexend',
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    notificationMessage,
                                    style: const TextStyle(
                                      fontFamily: 'Lexend',
                                      fontSize: 15,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          Center(
                            child: Image.asset(
                              'lib/assets/images/Background.png',
                              width: 100,
                            ),
                          ),
                          const SizedBox(height: 16),

                          const Text(
                            'Dashboard',
                            style: TextStyle(
                              fontFamily: 'Lexend',
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3A3A3A),
                            ),
                          ),
                          const SizedBox(height: 2),

                          const Text(
                            'Total Production and Metrics',
                            style: TextStyle(
                              fontFamily: 'Lexend',
                              fontSize: 15,
                              color: Color(0xFF5A5A5A),
                            ),
                          ),
                          const SizedBox(height: 20),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5E4935),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Production Activity',
                              style: TextStyle(
                                fontFamily: 'Lexend',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.egg_outlined,
                                    size: 30,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'EGG PRODUCTION',
                                      style: TextStyle(
                                        fontFamily: 'Lexend',
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF3A3A3A),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _isLoading
                                          ? 'Loading...'
                                          : (_latestReading?.activity ??
                                                'High Activity'),
                                      style: const TextStyle(
                                        fontFamily: 'Lexend',
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF4CAF50),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE78B41),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Environmental Conditions',
                              style: TextStyle(
                                fontFamily: 'Lexend',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: _buildSimpleCard(
                                  icon: Icons.thermostat,
                                  label: 'TEMPERATURE',
                                  value: _isLoading
                                      ? '--'
                                      : (_latestReading?.temperature
                                                .toStringAsFixed(1) ??
                                            '0'),
                                  unit: '°C',
                                  valueColor:
                                      _latestReading != null &&
                                          _latestReading!.temperature >
                                              thresholds['temperature']!['max']!
                                      ? Colors.red
                                      : const Color(0xFF4CAF50),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildSimpleCard(
                                  icon: Icons.water_drop,
                                  label: 'HUMIDITY',
                                  value: _isLoading
                                      ? '--'
                                      : (_latestReading?.humidity
                                                .toStringAsFixed(1) ??
                                            '0'),
                                  unit: '%',
                                  valueColor:
                                      _latestReading != null &&
                                          _latestReading!.humidity >
                                              thresholds['humidity']!['max']!
                                      ? Colors.red
                                      : const Color(0xFF4CAF50),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: _buildSimpleCard(
                                  icon: Icons.cloud,
                                  label: 'AMMONIA/CO₂',
                                  value: _isLoading
                                      ? '--'
                                      : (_latestReading?.ammonia
                                                .toStringAsFixed(1) ??
                                            '0'),
                                  unit: 'ppm',
                                  valueColor:
                                      _latestReading != null &&
                                          _latestReading!.ammonia >
                                              thresholds['ammonia']!['max']!
                                      ? Colors.red
                                      : const Color(0xFF4CAF50),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildSimpleCard(
                                  icon: Icons.wb_sunny,
                                  label: 'LIGHT INTENSITY',
                                  value: _isLoading
                                      ? '--'
                                      : (_latestReading?.lightIntensity
                                                .toStringAsFixed(1) ??
                                            '0'),
                                  unit: 'lux',
                                  valueColor: const Color(0xFF4CAF50),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE78B41),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Metrics Over Time',
                              style: TextStyle(
                                fontFamily: 'Lexend',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Metrics Evolution',
                                      style: TextStyle(
                                        fontFamily: 'Lexend',
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF3A3A3A),
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        children: [
                                          for (String period in [
                                            '1D',
                                            '1M',
                                            '1Y',
                                            'Max',
                                          ])
                                            GestureDetector(
                                              onTap: () async {
                                                setState(
                                                  () => selectedTimePeriod =
                                                      period,
                                                );
                                                final historicalData =
                                                    await _apiService
                                                        .getHistoricalData(
                                                          period,
                                                        );
                                                setState(
                                                  () => _chartData =
                                                      _prepareChartData(
                                                        historicalData,
                                                      ),
                                                );
                                              },
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 5,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      selectedTimePeriod ==
                                                          period
                                                      ? Colors.white
                                                      : Colors.transparent,
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  boxShadow:
                                                      selectedTimePeriod ==
                                                          period
                                                      ? [
                                                          BoxShadow(
                                                            color: Colors.grey
                                                                .withOpacity(
                                                                  0.2,
                                                                ),
                                                            spreadRadius: 1,
                                                            blurRadius: 2,
                                                            offset:
                                                                const Offset(
                                                                  0,
                                                                  1,
                                                                ),
                                                          ),
                                                        ]
                                                      : null,
                                                ),
                                                child: Text(
                                                  period,
                                                  style: TextStyle(
                                                    fontFamily: 'Lexend',
                                                    fontSize: 12,
                                                    fontWeight:
                                                        selectedTimePeriod ==
                                                            period
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                                    color: const Color(
                                                      0xFF3A3A3A,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                SizedBox(
                                  height: 160,
                                  child: _chartData.isEmpty
                                      ? const Center(
                                          child: Text(
                                            'No chart data available',
                                          ),
                                        )
                                      : Builder(
                                          builder: (context) {
                                            final boundaries =
                                                _getChartBoundaries();
                                            return LineChart(
                                              LineChartData(
                                                lineBarsData: _chartData
                                                    .asMap()
                                                    .entries
                                                    .map((entry) {
                                                      int index = entry.key;
                                                      List<FlSpot> spots =
                                                          entry.value;
                                                      Color color = index == 0
                                                          ? Colors.red
                                                          : (index == 1
                                                                ? Colors.blue
                                                                : Colors
                                                                      .orange);
                                                      return LineChartBarData(
                                                        spots: spots,
                                                        color: color,
                                                        isCurved: true,
                                                        dotData: FlDotData(
                                                          show: true,
                                                        ),
                                                      );
                                                    })
                                                    .toList(),
                                                lineTouchData: LineTouchData(
                                                  touchTooltipData: LineTouchTooltipData(
                                                    getTooltipColor:
                                                        (touchedSpot) =>
                                                            Colors.white,
                                                    getTooltipItems:
                                                        (
                                                          List<LineBarSpot>
                                                          touchedSpots,
                                                        ) {
                                                          return touchedSpots.map((
                                                            spot,
                                                          ) {
                                                            String tooltipText =
                                                                '';
                                                            Color textColor;
                                                            if (spot.barIndex ==
                                                                0) {
                                                              tooltipText =
                                                                  'Temp: ${spot.y.toStringAsFixed(1)}°C';
                                                              textColor =
                                                                  Colors.red;
                                                            } else if (spot
                                                                    .barIndex ==
                                                                1) {
                                                              tooltipText =
                                                                  'Humidity: ${spot.y.toStringAsFixed(1)}%';
                                                              textColor =
                                                                  Colors.blue;
                                                            } else {
                                                              tooltipText =
                                                                  'Ammonia: ${spot.y.toStringAsFixed(1)} ppm';
                                                              textColor =
                                                                  Colors.orange;
                                                            }
                                                            return LineTooltipItem(
                                                              tooltipText,
                                                              TextStyle(
                                                                fontFamily:
                                                                    'Lexend',
                                                                color:
                                                                    textColor,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 12,
                                                              ),
                                                            );
                                                          }).toList();
                                                        },
                                                  ),
                                                  handleBuiltInTouches: true,
                                                ),
                                                gridData: FlGridData(
                                                  drawHorizontalLine: true,
                                                  horizontalInterval:
                                                      (boundaries['maxY']! -
                                                          boundaries['minY']!) /
                                                      4,
                                                  getDrawingHorizontalLine:
                                                      (value) => FlLine(
                                                        color: Colors
                                                            .grey
                                                            .shade200,
                                                        strokeWidth: 1,
                                                        dashArray: [5, 5],
                                                      ),
                                                  drawVerticalLine: false,
                                                ),
                                                titlesData: FlTitlesData(
                                                  bottomTitles: AxisTitles(
                                                    sideTitles: SideTitles(
                                                      showTitles: true,
                                                      getTitlesWidget:
                                                          (
                                                            value,
                                                            meta,
                                                          ) => Padding(
                                                            padding:
                                                                const EdgeInsets.only(
                                                                  top: 8.0,
                                                                ),
                                                            child: Text(
                                                              value
                                                                  .toInt()
                                                                  .toString(),
                                                              style: TextStyle(
                                                                fontFamily:
                                                                    'Lexend',
                                                                color: Colors
                                                                    .grey
                                                                    .shade500,
                                                                fontSize: 10,
                                                              ),
                                                            ),
                                                          ),
                                                      reservedSize: 22,
                                                    ),
                                                  ),
                                                  leftTitles: AxisTitles(
                                                    sideTitles: SideTitles(
                                                      showTitles: true,
                                                      getTitlesWidget:
                                                          (
                                                            value,
                                                            meta,
                                                          ) => Padding(
                                                            padding:
                                                                const EdgeInsets.only(
                                                                  right: 8.0,
                                                                ),
                                                            child: Text(
                                                              value
                                                                  .toStringAsFixed(
                                                                    0,
                                                                  ),
                                                              style: TextStyle(
                                                                fontFamily:
                                                                    'Lexend',
                                                                color: Colors
                                                                    .grey
                                                                    .shade500,
                                                                fontSize: 10,
                                                              ),
                                                            ),
                                                          ),
                                                      reservedSize: 22,
                                                    ),
                                                  ),
                                                  topTitles: const AxisTitles(
                                                    sideTitles: SideTitles(
                                                      showTitles: false,
                                                    ),
                                                  ),
                                                  rightTitles: const AxisTitles(
                                                    sideTitles: SideTitles(
                                                      showTitles: false,
                                                    ),
                                                  ),
                                                ),
                                                borderData: FlBorderData(
                                                  show: false,
                                                ),
                                                minX: boundaries['minX']!,
                                                maxX: boundaries['maxX']!,
                                                minY: boundaries['minY']!,
                                                maxY: boundaries['maxY']!,
                                              ),
                                            );
                                          },
                                        ),
                                ),
                                const SizedBox(height: 16),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildLegendItem('Temperature', Colors.red),
                                    const SizedBox(width: 16),
                                    _buildLegendItem('Humidity', Colors.blue),
                                    const SizedBox(width: 16),
                                    _buildLegendItem('Ammonia', Colors.orange),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ),
                BottomNavigationBar(
                  currentIndex: 0,
                  backgroundColor: Colors.white,
                  selectedItemColor: const Color(0xFF5E4935),
                  unselectedItemColor: Colors.grey,
                  selectedFontSize: 12,
                  unselectedFontSize: 12,
                  type: BottomNavigationBarType.fixed,
                  elevation: 8,
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.dashboard),
                      label: 'Dashboard',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.history),
                      label: 'History',
                    ),
                  ],
                  onTap: (index) {
                    if (index == 0) return;
                    if (index == 1) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HistoryScreen(),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),

            Positioned(
              right: 22,
              bottom: 80,
              child: FloatingActionButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChatbotScreen(),
                  ),
                ),
                backgroundColor: const Color(0xFFE78B41),
                child: const Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleCard({
    required IconData icon,
    required String label,
    required String value,
    String unit = '',
    Color valueColor = const Color(0xFF4CAF50),
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 24, color: Colors.black),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Lexend',
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3A3A3A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        value,
                        style: TextStyle(
                          fontFamily: 'Lexend',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: valueColor,
                        ),
                      ),
                      if (unit.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 2.0),
                          child: Text(
                            unit,
                            style: TextStyle(
                              fontFamily: 'Lexend',
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Lexend',
            fontSize: 12,
            color: Color(0xFF3A3A3A),
          ),
        ),
      ],
    );
  }
}
