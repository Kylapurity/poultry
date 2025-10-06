
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class RecordingService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  String? recordingPath;
  bool hasRecording = false;
  
  void setRecording(String path) {
    recordingPath = path;
    hasRecording = true;
    notifyListeners();
  }
  
  void clearRecording() {
    recordingPath = null;
    hasRecording = false;
    notifyListeners();
  }
}
