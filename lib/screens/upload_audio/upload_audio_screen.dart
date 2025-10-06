import 'dart:io';
import 'package:fauna_pulse/screens/analysis_results/analysis_results_screen.dart';
import 'package:fauna_pulse/services/api/api_service.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fauna_pulse/screens/dashboard/dashboard_screen.dart';
import 'package:fauna_pulse/screens/history/history_screen.dart';

class AudioScreen extends StatefulWidget {
  const AudioScreen({super.key});

  @override
  State<AudioScreen> createState() => _AudioScreenState();
}

class _AudioScreenState extends State<AudioScreen> {
  File? selectedAudioFile;
  String? fileName;
  bool isUploading = false;
  String? predictionResult;
  double? confidenceScore;
  String? recordingId;
  final ApiService _apiService = ApiService();

  Future<void> pickAudioFile() async {
  try {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom, // Change from FileType.audio to FileType.custom
      allowMultiple: false,
      allowedExtensions: ['wav', 'mp3', 'm4a'], // Now this is valid
    );

    if (result != null) {
      setState(() {
        selectedAudioFile = File(result.files.single.path!);
        fileName = result.files.single.name;
      });
    }
  } catch (e) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
  }
}

  Future<void> sendForPrediction() async {
  if (selectedAudioFile == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select an audio file first')),
    );
    return;
  }

  setState(() {
    isUploading = true;
    predictionResult = null;
    confidenceScore = null;
    recordingId = null;
  });

  try {
    // 1. Send the LOCAL FILE directly to the AI model for prediction
    final Object predictionData = await _apiService.getModelPrediction(
      selectedAudioFile!.path, // Use the local file path, not URL
    );

    final Map<String, dynamic> predictionMap =
        predictionData as Map<String, dynamic>;
    
    // Check if there's an error in the prediction response
    if (predictionMap.containsKey('error')) {
      throw Exception(predictionMap['error']);
    }
    
    final String prediction = predictionMap['prediction'];
    final double confidence = predictionMap['confidence_score'];

    // 2. Upload audio to Supabase Storage and get the recording ID
    final uploadResponse = await _apiService.uploadAudioRecording(
      selectedAudioFile!,
    );
    print("we got here 1");
    final String newRecordingId = uploadResponse['id']!;
    
    setState(() {
      recordingId = newRecordingId;
    });

    // 3. Update the 'audio_recordings' table with the prediction results
    await _apiService.updateAudioRecordingPrediction(
      newRecordingId,
      prediction,
      confidence,
    );
    print("we got here 2");

    // Check if the widget is still mounted before updating UI
    if (mounted) {
      setState(() {
        isUploading = false;
        predictionResult = prediction;
        confidenceScore = confidence;
      });

      // Navigate to the ResultsScreen with the analysis results
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultsScreen(
            audioFileName: fileName ?? 'audio.mp3',
            predictionResult: predictionResult!,
            confidenceScore: confidenceScore!,
          ),
        ),
      );
    }
  } catch (e) {
    // Handle any errors during the process and show a SnackBar
    if (mounted) {
      setState(() {
        isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending for prediction: $e')),
      );
    }
  }
}
  void removeSelectedFile() {
    setState(() {
      selectedAudioFile = null;
      fileName = null;
      predictionResult = null;
      confidenceScore = null;
      recordingId = null;
    });
  }

  @override
  void initState() {
    super.initState();
    // _animationController = AnimationController(
    // vsync: this,
    // duration: const Duration(milliseconds: 1000),
    // );
    // _initializeRecorder();
  }

  // Future<void> _initializeRecorder() async {
  //   try {
  //     if (await Permission.microphone.request().isGranted) {
  //       _recorderController = RecorderController()
  //         ..androidEncoder = AndroidEncoder.aac
  //         ..androidOutputFormat = AndroidOutputFormat.mpeg4
  //         ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
  //         ..sampleRate = 44100;
  //     } else {
  //       setState(() => _error = 'Microphone permission denied');
  //     }
  //   } catch (e) {
  //     setState(() => _error = e.toString());
  //   }
  // }

  // Future<void> _startRecording() async {
  //   setState(() => _showInitialText = false);
  //   _animationController.repeat(reverse: true);

  //   try {
  //     final directory = await getTemporaryDirectory();
  //     _recordingPath = '${directory.path}/${const Uuid().v4()}.m4a';

  //     // Use consistent audio format
  //     await _audioRecorder.start(
  //       path: _recordingPath,
  //       encoder: AudioEncoder.wav, // Using AAC for better compatibility
  //       bitRate: 128000,
  //       samplingRate: 44100,
  //     );

  //     setState(() => _isRecording = true);
  //     print("Recording started at: $_recordingPath");
  //   } catch (e) {
  //     setState(() => _error = 'Error starting recording: ${e.toString()}');
  //   }
  // }

  // Future<void> _stopRecording() async {
  //   _animationController.stop();

  //   try {
  //     // Stop recording
  //     await _audioRecorder.stop();

  //     setState(() {
  //       _isRecording = false;
  //       _hasRecording = true;
  //     });

  //     print("Recording stopped. File saved at: $_recordingPath");
  //   } catch (e) {
  //     setState(() => _error = 'Error stopping recording: ${e.toString()}');
  //   }
  // }

  // Future<void> _sendRecording() async {
  //   if (_recordingPath == null) return;

  //   final connectivityResult =
  //       await ConnectivityHandler.checkConnectivity(context);
  //   if (!connectivityResult) {
  //     setState(() {
  //       _error = 'No internet connection';
  //       _isSending = false;
  //     });
  //   }

  //   setState(() => _isSending = true);

  //   try {
  //     final file = File(_recordingPath!);

  //     // Upload recording
  //     final uploadResult = await _apiService.uploadAudioRecording(file);
  //     final processedId = uploadResult['id'];
  //     final audioUrl = uploadResult['url'];

  //     // Add user message
  //     final userMessage = MessageItem(
  //       content: 'Audio recording sent',
  //       timestamp: DateTime.now(),
  //       isUser: true,
  //       isDelivered: true,
  //     );
  //     setState(() => _messages.add(userMessage));

  //     // Get AI analysis
  //     final analysis = await _apiService.getAiAnalysis(audioUrl!);

  //     // Add AI response
  //     final aiMessage = MessageItem(
  //       content: analysis,
  //       timestamp: DateTime.now(),
  //       isUser: false,
  //     );
  //     setState(() => _messages.add(aiMessage));

  //     // Save to history
  //     await _apiService.saveToHistory(processedId!, analysis);

  //     // Clean up
  //     await file.delete();
  //     setState(() {
  //       _hasRecording = false;
  //       _isSending = false;
  //       _recordingPath = null;
  //     });
  //   } catch (e) {
  //     setState(() {
  //       _error = e.toString();
  //       _isSending = false;
  //     });
  //   }
  // }

  // Future<void> _togglePlayback() async {
  //   if (_recordingPath == null) {
  //     print("No recording available to play");
  //     return;
  //   }

  //   try {
  //     if (_isPlaying) {
  //       // Stop playback
  //       await _audioPlayer.stop();
  //       setState(() => _isPlaying = false);
  //       print("Playback stopped");
  //     } else {
  //       // Start playback
  //       await _audioPlayer.setFilePath(_recordingPath!);
  //       await _audioPlayer.play();

  //       setState(() => _isPlaying = true);

  //       // Auto-update state when playback completes
  //       _audioPlayer.playerStateStream.listen((state) {
  //         if (state.processingState == ProcessingState.completed) {
  //           setState(() => _isPlaying = false);
  //           print("Playback completed");
  //         }
  //       });

  //       print("Playing recording from: $_recordingPath");
  //     }
  //   } catch (e) {
  //     setState(() => _error = 'Error playing recording: ${e.toString()}');
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/assets/images/soil_background.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.white70, BlendMode.lighten),
          ),
        ),
        child: SafeArea(
          bottom: false, // Prevents double padding with navigation bar
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(
                    22.0,
                  ), // Increased padding to 22px
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // App Logo
                      Center(
                        child: Image.asset(
                          'lib/assets/images/poultry_app_logo.png',
                          width: 70, // Increased size
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Title
                      const Text(
                        'Upload Audio',
                        style: TextStyle(
                          fontFamily: 'Lexend',
                          fontSize: 26, // Increased font size
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3A3A3A),
                        ),
                      ),

                      // Subtitle
                      const Text(
                        'Tap the button below to upload an audio to get a prediction',
                        style: TextStyle(
                          fontFamily: 'Urbanist',
                          fontSize: 15, // Increased font size
                          color: Color(0xFF5A5A5A),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Recommendations box
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18), // Increased padding
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Recommendations',
                              style: TextStyle(
                                fontFamily: 'Lexend',
                                fontSize: 18, // Increased font size
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3A3A3A),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Bullet points
                            ...[
                                  'Supported formats: .mp3, .m4a, .wav, .ogg',
                                  'Maximum file size: 4 MB',
                                  'Maximum duration: 3 minutes',
                                  'Please ensure your audio is clear and free from background noise',
                                  'Avoid silent recordings or incomplete submissions',
                                  'You can re-upload if needed',
                                  'A stable internet connection is recommended for uploading',
                                ]
                                .map(
                                  (text) => Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 10.0,
                                    ), // Increased spacing
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          '• ',
                                          style: TextStyle(
                                            fontFamily: 'Urbanist',
                                            fontSize: 15, // Increased font size
                                            color: Color(0xFF3A3A3A),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            text,
                                            style: const TextStyle(
                                              fontFamily: 'Urbanist',
                                              fontSize:
                                                  15, // Increased font size
                                              color: Color(0xFF3A3A3A),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Upload area
                      GestureDetector(
                        onTap: pickAudioFile,
                        child: Container(
                          width: double.infinity,
                          height: 120, // Keeping good height for touch target
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey,
                              width: 1,
                              style: BorderStyle.solid,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.upload_file,
                                size: 40,
                                color: Colors.grey.shade700,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Click to upload vibrations',
                                style: TextStyle(
                                  fontFamily: 'Urbanist',
                                  fontSize: 16, // Increased font size
                                  color: Color(0xFF5A5A5A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Selected file name
                      if (fileName != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.audio_file,
                                size: 20,
                                color: Colors.grey.shade700,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  fileName!,
                                  style: const TextStyle(
                                    fontFamily: 'Urbanist',
                                    fontSize: 15, // Increased font size
                                    color: Color(0xFF3A3A3A),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: removeSelectedFile,
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 30), // Extra space
                      // Send for prediction button
                      if (fileName != null)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: isUploading ? null : sendForPrediction,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon:
                                isUploading
                                    ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Icon(Icons.send),
                            label: Text(
                              isUploading
                                  ? 'Processing...'
                                  : 'Send for prediction',
                              style: const TextStyle(
                                fontFamily: 'Urbanist',
                                fontSize: 16, // Increased font size
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Bottom Navigation Bar
              BottomNavigationBar(
                currentIndex: 1, // Audio tab
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
                  if (index == 1) return; // Already on audio

                  if (index == 0) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DashboardScreen(),
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
        ),
      ),
    );
  }
}