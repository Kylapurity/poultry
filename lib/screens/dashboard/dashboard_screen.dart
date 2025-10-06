import 'package:poultry_app/models/sensor_reading.dart';
import 'package:poultry_app/screens/upload_audio/upload_audio_screen.dart';
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
  // Sample data for testing
  // final Map<String, dynamic> soilMetrics = {
  //   'activity': 'High Activity',
  //   'temperature': 18,
  //   'humidity': 97,
  //   'moisture': 7.1,
  //   'pH': 7.1,
  //   'nitrogen': 7.1,
  //   'phosphorus': 7.1,
  //   'potassium': 7.1,
  //   'conductivity': 2.0,
  // };
  final ApiService _apiService = ApiService();
  final NotificationService _notificationService = NotificationService();
  bool _isLoading = true;
  String? _errorMessage;
  SensorReading? _latestReading;
  List<List<FlSpot>> _chartData = [];

  // Threshold values
  final Map<String, Map<String, double>> thresholds = {
    'temperature': {'min': 15.0, 'max': 30.0}, // Updated thresholds
    'humidity': {'min': 60.0, 'max': 90.0},
    'moisture': {'min': 20.0, 'max': 35.0},
    'nitrogen': {'min': 100.0, 'max': 200.0},
    'phosphorus': {'min': 40.0, 'max': 80.0},
    'potassium': {'min': 150.0, 'max': 250.0},
    'conductivity': {'min': 1.0, 'max': 2.5},
  };
  final Map<String, Map<String, String>> activityThreshold = {
    'activity': {'min': "Normal activity", 'max': "Optimal activity"},
  };

  // Flag for showing notifications
  bool showNotification = false;
  String notificationMessage = '';

  // Sample chart data
  final List<List<FlSpot>> chartData = [
    // Temperature data (purple)
    [
      const FlSpot(0, 20),
      const FlSpot(1, 22),
      const FlSpot(2, 24),
      const FlSpot(3, 25),
      const FlSpot(4, 26),
      const FlSpot(5, 28),
    ],
    // Moisture data (blue)
    [
      const FlSpot(0, 28),
      const FlSpot(1, 20),
      const FlSpot(2, 22),
      const FlSpot(3, 25),
      const FlSpot(4, 18),
      const FlSpot(5, 24),
    ],
    // Humidity data (orange)
    [
      const FlSpot(0, 15),
      const FlSpot(1, 22),
      const FlSpot(2, 28),
      const FlSpot(3, 20),
      const FlSpot(4, 18),
      const FlSpot(5, 20),
    ],
  ];

  // Selected time period for graph
  String selectedTimePeriod = '1D';

  Map<String, double> _getChartBoundaries() {
    if (_chartData.isEmpty) {
      return {'minX': 0, 'maxX': 5, 'minY': 0, 'maxY': 30};
    }

    double minY = double.infinity;
    double maxY = double.negativeInfinity;
    double maxX = 0;

    // Find min/max values across all data series
    for (var series in _chartData) {
      for (var spot in series) {
        if (spot.y < minY) minY = spot.y;
        if (spot.y > maxY) maxY = spot.y;
        if (spot.x > maxX) maxX = spot.x;
      }
    }

    // Add padding (10% of the range) so points don't touch edges
    double range = maxY - minY;
    double padding = range * 0.1;

    return {
      'minX': 0,
      'maxX': maxX > 0 ? maxX : 5,
      'minY': (minY - padding).clamp(0, double.infinity), // Don't go below 0
      'maxY': maxY + padding,
    };
  }

  @override
  void initState() {
    super.initState();
    // Check thresholds on init
    _notificationService.init();
    _checkThresholds();
    _loadAllData();
    ();
  }

  // Check if any metrics exceed thresholds
  void _checkThresholds() {
    if (_latestReading == null) return;

    String? alertMessage;

    final activity = _latestReading?.activity;
    final activityThreshold = thresholds['activity'];
    if (activity == activityThreshold?['max']!) {
      alertMessage = '🌱 Soil activity is optimal ($activity).';
    } else if (activity == activityThreshold?['min']) {
      alertMessage = '🌱 Soil activity is low ($activity).';
    }

    // Check Temperature
    final temp = _latestReading!.temperature;
    final tempThreshold = thresholds['temperature']!;
    if (temp > tempThreshold['max']!) {
      alertMessage =
          '🌡️ Temperature is too high ($temp°C). Consider adding shade or water.';
    } else if (temp < tempThreshold['min']!) {
      alertMessage = '🌡️ Temperature is too low ($temp°C). Protect from cold.';
    }

    // Check Humidity
    final humidity = _latestReading!.humidity;
    final humidityThreshold = thresholds['humidity']!;
    if (humidity > humidityThreshold['max']!) {
      alertMessage =
          '💧 Humidity is too high ($humidity%). Risk of fungal growth.';
    } else if (humidity < humidityThreshold['min']!) {
      alertMessage =
          '💧 Humidity is too low ($humidity%). Consider misting the plants.';
    }

    // Check Moisture
    final moisture = _latestReading!.moisture;
    final moistureThreshold = thresholds['moisture']!;
    if (moisture > moistureThreshold['max']!) {
      alertMessage = '🌱 Soil is too wet ($moisture g/m³). Risk of root rot.';
    } else if (moisture < moistureThreshold['min']!) {
      alertMessage = '🌱 Soil is too dry ($moisture g/m³). Time to water!';
    }

    // Check Nitrogen
    final nitrogen = _latestReading!.nitrogen;
    final nitrogenThreshold = thresholds['nitrogen']!;
    if (nitrogen > nitrogenThreshold['max']!) {
      alertMessage = 'N Nitrogen level is too high ($nitrogen mg/kg).';
    } else if (nitrogen < nitrogenThreshold['min']!) {
      alertMessage =
          'N Nitrogen level is too low ($nitrogen mg/kg). Consider fertilizer.';
    }

    // Check Phosphorus
    final phosphorus = _latestReading!.phosphorus;
    final phosphorusThreshold = thresholds['phosphorus']!;
    if (phosphorus > phosphorusThreshold['max']!) {
      alertMessage = 'P Phosphorus level is too high ($phosphorus mg/kg).';
    } else if (phosphorus < phosphorusThreshold['min']!) {
      alertMessage =
          'P Phosphorus level is too low ($phosphorus mg/kg). Consider fertilizer.';
    }

    // Check Potassium
    final potassium = _latestReading!.potassium;
    final potassiumThreshold = thresholds['potassium']!;
    if (potassium > potassiumThreshold['max']!) {
      alertMessage = 'K Potassium level is too high ($potassium mg/kg).';
    } else if (potassium < potassiumThreshold['min']!) {
      alertMessage =
          'K Potassium level is too low ($potassium mg/kg). Consider fertilizer.';
    }

    // If an alert was triggered, show it
    if (alertMessage != null) {
      // Show a push notification
      _notificationService.showNotification('🚨 Soil Alert', alertMessage);
      // Show an in-app banner
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
      // Fetch data and print it
      final dataMap = await _apiService.getSensorData(context: context);
      print('Raw Supabase data: $dataMap'); // Print raw data

      final reading = SensorReading.fromMap(dataMap);
      print(
        'Parsed reading: ${reading.temperature}, ${reading.humidity}, ${reading.moisture}',
      ); // Print parsed data

      final historicalData = await _apiService.getHistoricalData('1D');
      print(
        'Historical data count: ${historicalData.length}',
      ); // Print historical data

      setState(() {
        _latestReading = reading;
        _chartData = _prepareChartData(historicalData);
        _isLoading = false;
      });

      _checkThresholds();
    } catch (e) {
      print('Error loading data: $e'); // Print errors
      setState(() {
        _errorMessage = 'Failed to load data. Please pull to refresh.';
        _isLoading = false;
      });
    }
  }

  List<List<FlSpot>> _prepareChartData(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return [];

    final List<FlSpot> tempData = [];
    final List<FlSpot> moistureData = [];
    final List<FlSpot> humidityData = [];

    for (int i = 0; i < data.length; i++) {
      final record = data[i];
      final xValue = i.toDouble(); // Use the index as the X-axis value

      tempData.add(FlSpot(xValue, record['temperature']?.toDouble() ?? 0));
      moistureData.add(FlSpot(xValue, record['moisture']?.toDouble() ?? 0));
      humidityData.add(FlSpot(xValue, record['humidity']?.toDouble() ?? 0));
    }

    return [tempData, moistureData, humidityData];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/assets/images/soil_background.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.white30, BlendMode.lighten),
          ),
        ),
        child: SafeArea(
          bottom: false, // Prevents double padding with navigation bar
          child: Stack(
            children: [
              // Main content
              Column(
                children: [
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _loadAllData,
                      color: Colors.white,
                      backgroundColor: const Color(0xFF5E4935),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(
                          22.0,
                        ), // Increased padding to 22px
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Notification Banner
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
                                      'PoultryApp',
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
                                        fontFamily: 'Urbanist',
                                        fontSize: 15,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // App Logo
                            Center(
                              child: Image.asset(
                                'lib/assets/images/poultry_app_logo.png',
                                width: 100,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Dashboard Title
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

                            // Subtitle
                            const Text(
                              'Overview of the various metrics',
                              style: TextStyle(
                                fontFamily: 'Urbanist',
                                fontSize: 15,
                                color: Color(0xFF5A5A5A),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Soil Metrics Section
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
                                'Poultry Metrics',
                                style: TextStyle(
                                  fontFamily: 'Urbanist',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Soil Dynamics Card - simple card
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
                                    child: Image.asset(
                                      'lib/assets/icons/soil_dynamics_icon.png',
                                      width: 24,
                                      height: 24,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'SOIL DYNAMICS',
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
                                                'No Data'),
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

                            // Environmental Conditions Section
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
                                'Environmental conditions',
                                style: TextStyle(
                                  fontFamily: 'Urbanist',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Temperature and Humidity row - simplified cards
                            Row(
                              children: [
                                // Temperature Card
                                Expanded(
                                  child: _buildSimpleCard(
                                    iconAsset:
                                        'lib/assets/icons/temperature_icon.png',
                                    label: 'TEMPERATURE',
                                    value:
                                        _isLoading
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
                                // Humidity Card
                                Expanded(
                                  child: _buildSimpleCard(
                                    iconAsset:
                                        'lib/assets/icons/humidity_icon.png',
                                    label: 'HUMIDITY',
                                    value:
                                        _isLoading
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

                            // Moisture card - simplified
                            _buildSimpleCard(
                              iconAsset: 'lib/assets/icons/moisture_icon.png',
                              label: 'MOISTURE',
                              value:
                                  _isLoading
                                      ? '--'
                                      : (_latestReading?.moisture
                                              .toStringAsFixed(1) ??
                                          '0'),
                              unit: 'g/m³',
                              valueColor:
                                  _latestReading != null &&
                                          _latestReading!.moisture >
                                              thresholds['moisture']!['max']!
                                      ? Colors.red
                                      : const Color(0xFF4CAF50),
                            ),
                            const SizedBox(height: 20),

                            // Soil Nutrients Section
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
                                'Poultrys and Productivity',
                                style: TextStyle(
                                  fontFamily: 'Urbanist',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Nitrogen and Phosphorus row - with text icons
                            Row(
                              children: [
                                Expanded(
                                  child: _buildSimpleCard(
                                    iconText: 'N',
                                    label: 'NITROGEN',
                                    value:
                                        _isLoading
                                            ? '--'
                                            : (_latestReading?.nitrogen
                                                    .toStringAsFixed(1) ??
                                                '0'),
                                    unit: 'mg/kg',
                                    valueColor:
                                        _latestReading != null &&
                                                _latestReading!.nitrogen >
                                                    thresholds['nitrogen']!['max']!
                                            ? const Color(0xFF4CAF50)
                                            : Colors.red,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildSimpleCard(
                                    iconText: 'P',
                                    label: 'PHOSPHORUS',
                                    value:
                                        _isLoading
                                            ? '--'
                                            : (_latestReading?.phosphorus
                                                    .toStringAsFixed(1) ??
                                                '0'),
                                    unit: 'mg/kg',
                                    valueColor:
                                        _latestReading != null &&
                                                _latestReading!.phosphorus >
                                                    thresholds['phosphorus']!['max']!
                                            ? const Color(0xFF4CAF50)
                                            : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Potassium and Conductivity row - with text icons
                            Row(
                              children: [
                                Expanded(
                                  child: _buildSimpleCard(
                                    iconText: 'K',
                                    label: 'POTASSIUM',
                                    value:
                                        _isLoading
                                            ? '--'
                                            : (_latestReading?.potassium
                                                    .toStringAsFixed(1) ??
                                                '0'),
                                    unit: 'mg/kg',
                                    valueColor:
                                        _latestReading != null &&
                                                _latestReading!.potassium >
                                                    thresholds['potassium']!['max']!
                                            ? const Color(0xFF4CAF50)
                                            : Colors.red,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildSimpleCard(
                                    iconText: '⚡',
                                    label: 'ELECTRICAL CONDUCTIVITY',
                                    value:
                                        _isLoading
                                            ? '--'
                                            : (_latestReading?.conductivity
                                                    .toStringAsFixed(1) ??
                                                '0'),
                                    unit: 'dS/m',
                                    valueColor:
                                        _latestReading != null &&
                                                _latestReading!.conductivity >
                                                    thresholds['conductivity']!['max']!
                                            ? const Color(0xFF4CAF50)
                                            : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Graphs Section
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
                                'Graphs',
                                style: TextStyle(
                                  fontFamily: 'Urbanist',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Graph card
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
                                  // Graph title and time period selector
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Metrics Evolution',
                                        style: TextStyle(
                                          fontFamily: 'Urbanist',
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF3A3A3A),
                                        ),
                                      ),
                                      // Time period selector
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
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
                                                    () =>
                                                        selectedTimePeriod =
                                                            period,
                                                  );
                                                  // Refetch graph data when a new period is selected
                                                  final historicalData =
                                                      await _apiService
                                                          .getHistoricalData(
                                                            period,
                                                          );
                                                  setState(
                                                    () =>
                                                        _chartData =
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
                                                            : Colors
                                                                .transparent,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                    boxShadow:
                                                        selectedTimePeriod ==
                                                                period
                                                            ? [
                                                              BoxShadow(
                                                                color: Colors
                                                                    .grey
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
                                                      fontFamily: 'Urbanist',
                                                      fontSize: 12,
                                                      fontWeight:
                                                          selectedTimePeriod ==
                                                                  period
                                                              ? FontWeight.bold
                                                              : FontWeight
                                                                  .normal,
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

                                  // Line chart
                                  // Replace the LineChart section with this:
                                  SizedBox(
                                    height: 160,
                                    child:
                                        _chartData.isEmpty
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
                                                    lineBarsData:
                                                        _chartData.asMap().entries.map((
                                                          entry,
                                                        ) {
                                                          int index = entry.key;
                                                          List<FlSpot> spots =
                                                              entry.value;
                                                          Color color;
                                                          switch (index) {
                                                            case 0:
                                                              color =
                                                                  Colors.purple;
                                                              break;
                                                            case 1:
                                                              color =
                                                                  Colors.blue;
                                                              break;
                                                            default:
                                                              color =
                                                                  Colors.orange;
                                                          }
                                                          return LineChartBarData(
                                                            spots: spots,
                                                            color: color,
                                                            isCurved: true,
                                                            dotData: FlDotData(
                                                              show: true,
                                                            ), // Show dots so you can see all points
                                                          );
                                                        }).toList(),
                                                    lineTouchData: LineTouchData(
                                                      touchTooltipData: LineTouchTooltipData(
                                                        getTooltipColor:
                                                            (touchedSpot) =>
                                                                Colors.white,
                                                        getTooltipItems: (
                                                          List<LineBarSpot>
                                                          touchedSpots,
                                                        ) {
                                                          return touchedSpots.map((
                                                            spot,
                                                          ) {
                                                            String tooltipText =
                                                                '';
                                                            Color textColor;
                                                            switch (spot
                                                                .barIndex) {
                                                              case 0:
                                                                tooltipText =
                                                                    'Temperature: ${spot.y.toStringAsFixed(1)}°C';
                                                                textColor =
                                                                    Colors
                                                                        .purple;
                                                                break;
                                                              case 1:
                                                                tooltipText =
                                                                    'Moisture: ${spot.y.toStringAsFixed(1)}%';
                                                                textColor =
                                                                    Colors.blue;
                                                                break;
                                                              case 2:
                                                                tooltipText =
                                                                    'Humidity: ${spot.y.toStringAsFixed(1)}%';
                                                                textColor =
                                                                    Colors
                                                                        .orange;
                                                                break;
                                                              default:
                                                                tooltipText =
                                                                    'Value: ${spot.y.toStringAsFixed(1)}';
                                                                textColor =
                                                                    Colors
                                                                        .black;
                                                            }
                                                            return LineTooltipItem(
                                                              tooltipText,
                                                              TextStyle(
                                                                fontFamily:
                                                                    'Urbanist',
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
                                                      handleBuiltInTouches:
                                                          true,
                                                    ),
                                                    gridData: FlGridData(
                                                      drawHorizontalLine: true,
                                                      horizontalInterval:
                                                          (boundaries['maxY']! -
                                                              boundaries['minY']!) /
                                                          4, // Dynamic intervals
                                                      getDrawingHorizontalLine:
                                                          (value) {
                                                            return FlLine(
                                                              color:
                                                                  Colors
                                                                      .grey
                                                                      .shade200,
                                                              strokeWidth: 1,
                                                              dashArray: [5, 5],
                                                            );
                                                          },
                                                      drawVerticalLine: false,
                                                    ),
                                                    titlesData: FlTitlesData(
                                                      bottomTitles: AxisTitles(
                                                        sideTitles: SideTitles(
                                                          showTitles: true,
                                                          getTitlesWidget: (
                                                            value,
                                                            meta,
                                                          ) {
                                                            return Padding(
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
                                                                      'Urbanist',
                                                                  color:
                                                                      Colors
                                                                          .grey
                                                                          .shade500,
                                                                  fontSize: 10,
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                          reservedSize: 22,
                                                        ),
                                                      ),
                                                      leftTitles: AxisTitles(
                                                        sideTitles: SideTitles(
                                                          showTitles: true,
                                                          getTitlesWidget: (
                                                            value,
                                                            meta,
                                                          ) {
                                                            return Padding(
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
                                                                      'Urbanist',
                                                                  color:
                                                                      Colors
                                                                          .grey
                                                                          .shade500,
                                                                  fontSize: 10,
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                          reservedSize: 22,
                                                        ),
                                                      ),
                                                      topTitles:
                                                          const AxisTitles(
                                                            sideTitles:
                                                                SideTitles(
                                                                  showTitles:
                                                                      false,
                                                                ),
                                                          ),
                                                      rightTitles:
                                                          const AxisTitles(
                                                            sideTitles:
                                                                SideTitles(
                                                                  showTitles:
                                                                      false,
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

                                  // Legend
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _buildLegendItem(
                                        'Temperature',
                                        Colors.purple,
                                      ),
                                      const SizedBox(width: 16),
                                      _buildLegendItem('Moisture', Colors.blue),
                                      const SizedBox(width: 16),
                                      _buildLegendItem(
                                        'Humidity',
                                        Colors.orange,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Extra space at bottom for floating button
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Bottom Navigation
                  BottomNavigationBar(
                    currentIndex: 0, // Dashboard tab
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
                        icon: Icon(Icons.mic),
                        label: 'Audio',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.history),
                        label: 'History',
                      ),
                    ],
                    onTap: (index) {
                      if (index == 0) return; // Already on dashboard

                      if (index == 1) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AudioScreen(),
                          ),
                        );
                      } else if (index == 2) {
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

              // Chatbot button
              Positioned(
                right: 22, // Match horizontal padding
                bottom: 80, // Position above navigation bar
                child: FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChatbotScreen(),
                      ),
                    );
                  },
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
      ),
    );
  }

  // Simple metric card with better readability
  Widget _buildSimpleCard({
    String? iconAsset,
    String? iconText,
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
            // Icon Container
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child:
                    iconAsset != null
                        ? Image.asset(
                          iconAsset,
                          width: 24,
                          height: 24,
                          color: Colors.black,
                        )
                        : Text(
                          iconText ?? '',
                          style: const TextStyle(
                            fontFamily: 'Lexend',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
            ),
            const SizedBox(width: 10),

            // Label and Value
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
                              fontFamily: 'Urbanist',
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

  // Build legend item widget
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
            fontFamily: 'Urbanist',
            fontSize: 12,
            color: Color(0xFF3A3A3A),
          ),
        ),
      ],
    );
  }
}