import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const Map<String, dynamic> fallbackSensorData = {
    'id': 'fallback-id',
    'device_id': 'offline-device',
    'soil_activity': 0.0,
    'temperature': 0.0,
    'humidity': 0.0,
    'moisture': 0.0,
    'nitrogen': 0.0,
    'phosphorus': 0.0,
    'potassium': 0.0,
    'electrical_conductivity': 0.0,
    'received_at': null,
  };

  /// Sensor Data Methods

  /// Fetches data from the Supabase database.
  Future<Map<String, dynamic>> getSensorData({BuildContext? context}) async {
    try {
      // Check internet connectivity first
      final bool hasConnection = await hasInternetConnection();

      if (!hasConnection) {
        if (context != null) {
          showSnackBar(
            context,
            'No internet connection. Showing offline data.',
            isError: true,
          );
        }
        return fallbackSensorData;
      }

      // Attempt to fetch data from Supabase
      final response = await _supabase
          .from('environmental_data') // Fixed table name
          .select()
          .order('created_at', ascending: false) // Fixed column name
          .limit(1)
          .maybeSingle();

      if (response == null) {
        if (context != null) {
          showSnackBar(
            context,
            'No sensor data available. Showing default values.',
            isError: true,
          );
        }
        return fallbackSensorData;
      }

      // Success - show success message if context provided
      if (context != null) {
        showSnackBar(context, 'Sensor data updated successfully!');
      }

      return response;
    } catch (e) {
      debugPrint('Error fetching sensor data: $e');

      String errorMessage = 'Failed to fetch sensor data';

      if (e is PostgrestException) {
        errorMessage = 'Database error: ${e.message}';
      } else if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        errorMessage = 'Network error: Please check your connection';
      }

      if (context != null) {
        showSnackBar(context, errorMessage, isError: true);
      }

      // Return fallback data instead of throwing exception
      return fallbackSensorData;
    }
  }

  // Method specifically for pull-to-refresh
  Future<Map<String, dynamic>> refreshSensorData(BuildContext context) async {
    try {
      showSnackBar(context, 'Refreshing sensor data...');
      return await getSensorData(context: context);
    } catch (e) {
      showSnackBar(context, 'Failed to refresh data', isError: true);
      return fallbackSensorData;
    }
  }

  /// Chart fetch
  Future<List<Map<String, dynamic>>> getHistoricalData(
    String timePeriod,
  ) async {
    DateTime startTime;
    final now = DateTime.now();

    switch (timePeriod) {
      case '1M':
        startTime = now.subtract(const Duration(days: 30));
        break;
      case '1Y':
        startTime = now.subtract(const Duration(days: 365));
        break;
      case 'Max':
        // Fetch all data (or up to a reasonable limit)
        startTime = DateTime(2000);
        break;
      case '1D':
      default:
        startTime = now.subtract(const Duration(days: 1));
        break;
    }

    final response = await _supabase
        .from('environmental_data')
        .select()
        .gte('created_at', startTime.toIso8601String())
        .order('created_at', ascending: true);

    return response;
  }

  /// History Data Table Methods

  Future<List<Map<String, dynamic>>> getHistoryData() async {
    try {
      final response = await _supabase
          .from('history')
          .select()
          .order('timestamp', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch history data: $e');
    }
  }

  /// Utilities

  Future<bool> hasInternetConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();

      if (connectivityResult == ConnectivityResult.none) {
        return false;
      }

      // Double check with actual internet connection
      final bool hasInternet = await InternetConnectionChecker().hasConnection;
      return hasInternet;
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      return false;
    }
  }

  // Show snackbar helper method
  void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// Ensures the user is authenticated before making API calls.
  void ensureAuthenticated() {
    if (_supabase.auth.currentUser == null) {
      throw Exception('User not authenticated. Please sign in.');
    }
  }
}
