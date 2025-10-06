import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:internet_connection_checker/internet_connection_checker.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

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
      final response =
          await _supabase
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

  /// Audio Recording Methods
  Future<Map<String, String>> uploadAudioRecording(File audioFile) async {
    try {
      final fileName =
          'recordings/${DateTime.now().millisecondsSinceEpoch}.wav';

      // Upload to Supabase Storage
      // await _supabase.storage
      //     .from('recordings')
      //     .upload(fileName, audioFile);
      await _supabase.storage
          .from('recordings')
          .upload(
            fileName,
            audioFile,
            fileOptions: const FileOptions(
              cacheControl: '3600', // Cache for 1 hour
              upsert: false, // Do not overwrite if file exists
              contentType: 'audio/wav', // Explicitly set content type
            ),
          );

      // Get public URL
      final String publicUrl = _supabase.storage
          .from('recordings')
          .getPublicUrl(fileName);

      // Create record in recordings table
      final response =
          await _supabase
              .from('audio_recordings')
              .insert({
                'file_url':
                    publicUrl, // Use 'file_url' as per your table schema
                'from_phone': true,
                'prediction': null, // Initialize prediction as null
                'confidence_score': null, // Initialize confidence_score as null
                'created_at': DateTime.now().toIso8601String(),
                'user_id':
                    _supabase
                        .auth
                        .currentUser
                        ?.id, // Uncomment if you have user authentication
              })
              .select()
              .single();

      return {'id': response['id'] as String, 'url': publicUrl};
    } catch (e) {
      throw Exception('Failed to upload audio: $e');
    }
  }

  Future<Map<String, dynamic>> getModelPrediction(String audioFilePath) async {
    // The API endpoint URL
    final url = Uri.parse('https://sammyg123-faunapulse.hf.space/predict');

    try {
      // Verify the file exists
      final file = File(audioFilePath);
      if (!await file.exists()) {
        throw Exception('Audio file not found at path: $audioFilePath');
      }

      // Create a multipart request for file upload
      final request = http.MultipartRequest('POST', url);

      // Attach the audio file to the request
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          audioFilePath,
          // Optional: specify content type
          // contentType: MediaType('audio', 'wav'), // Uncomment if you import 'package:http_parser/http_parser.dart'
        ),
      );

      // Send the request and wait for the response
      final streamedResponse = await request.send();

      // Read and decode the response
      final response = await http.Response.fromStream(streamedResponse);

      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to get prediction: ${response.statusCode} ${response.body}',
        );
      }

      // Decode the JSON response body
      final data = jsonDecode(response.body);

      // Validate response structure
      if (!data.containsKey('class') || !data.containsKey('confidence')) {
        throw Exception('Invalid response format from prediction API');
      }

      // Extract the prediction from the 'class' field
      final String prediction = data['class']?.toString() ?? '';

      if (prediction.isEmpty) {
        throw Exception('Empty prediction received from API');
      }

      // Extract and parse the confidence score
      final String confidenceStr = data['confidence']?.toString() ?? '0';
      final double confidenceScore =
          double.tryParse(
            confidenceStr.replaceAll('%', '').replaceAll(' ', ''),
          ) ??
          0.0;

      // Return the result in a map
      return {'prediction': prediction, 'confidence_score': confidenceScore};
    } catch (e) {
      print('Error in getModelPrediction: $e');
      // Return a map with an error message for consistent return type
      return {'error': 'Unable to analyze audio: ${e.toString()}'};
    }
  }

  Future<void> updateAudioRecordingPrediction(
    String recordingId,
    String prediction,
    double confidenceScore,
  ) async {
    try {
      await _supabase
          .from('audio_recordings')
          .update({
            'prediction': prediction,
            'confidence_score': confidenceScore,
          })
          .eq('id', recordingId); // Update the record where 'id' matches
    } catch (e) {
      throw Exception('Failed to update audio recording prediction: $e');
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