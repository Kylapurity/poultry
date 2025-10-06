import 'package:fauna_pulse/screens/upload_audio/upload_audio_screen.dart';
import 'package:flutter/material.dart';
import 'package:fauna_pulse/screens/dashboard/dashboard_screen.dart';
import 'package:fauna_pulse/screens/history/history_screen.dart';

class ResultsScreen extends StatefulWidget {
  final String audioFileName;
  final String predictionResult;
  final double confidenceScore;

  const ResultsScreen({
    super.key,
    required this.audioFileName,
    required this.predictionResult,
    required this.confidenceScore,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  bool isPlaying = false;
  bool isPlayerInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    // In a real app, you would load the actual audio file
    // For this demo, we'll use some dummy waveform data
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        isPlayerInitialized = true;
      });
    }
  }

  void _togglePlayPause() {
    setState(() {
      isPlaying = !isPlaying;
    });
    
    // In a real app, you would actually play/pause the audio here
  }

  void _uploadNewAudio() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const AudioScreen(),
      ),
    );
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
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(22.0), // Increased padding to 22px
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // App Logo
                      Center(
                        child: Image.asset(
                          'lib/assets/images/poultry_app_logo.png',
                          width: 100, // Increased size
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Title
                      const Text(
                        'Results',
                        style: TextStyle(
                          fontFamily: 'Lexend',
                          fontSize: 26, // Increased font size
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3A3A3A),
                        ),
                      ),
                      
                      // Subtitle
                      const Text(
                        'Here you can see the prediction and confidence score of the audio',
                        style: TextStyle(
                          fontFamily: 'Urbanist',
                          fontSize: 15, // Increased font size
                          color: Color(0xFF5A5A5A),
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Audio filename
                      Center(
                        child: Text(
                          widget.audioFileName,
                          style: const TextStyle(
                            fontFamily: 'Urbanist',
                            fontSize: 16, // Increased font size
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF3A3A3A),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Audio waveform player
                      Container(
                        height: 70, // Good height for the waveform
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: isPlayerInitialized
                                    ? Image.asset(
                                        'lib/assets/images/waveform_placeholder.png',
                                        fit: BoxFit.cover,
                                      )
                                    : const Center(
                                        child: SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Color(0xFF5E4935),
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                isPlaying ? Icons.pause : Icons.play_arrow,
                                size: 32,
                                color: const Color(0xFF5E4935),
                              ),
                              onPressed: isPlayerInitialized ? _togglePlayPause : null,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Prediction results
                      Center(
                        child: Column(
                          children: [
                            const Text(
                              'Prediction:',
                              style: TextStyle(
                                fontFamily: 'Urbanist',
                                fontSize: 16, // Increased font size
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF5A5A5A),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.predictionResult,
                              style: const TextStyle(
                                fontFamily: 'Lexend',
                                fontSize: 28, // Increased font size
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF5E4935),
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                            
                            const Text(
                              'Confidence Score:',
                              style: TextStyle(
                                fontFamily: 'Urbanist',
                                fontSize: 16, // Increased font size
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF5A5A5A),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${widget.confidenceScore}%',
                              style: const TextStyle(
                                fontFamily: 'Lexend',
                                fontSize: 28, // Increased font size
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF5E4935),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      const Divider(height: 1, color: Colors.grey),
                      
                      const SizedBox(height: 30),
                      
                      // Upload another file button
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _uploadNewAudio,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.upload_file),
                          label: const Text(
                            'Upload',
                            style: TextStyle(
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
                  if (index == 1) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const AudioScreen()),
                    );
                    return;
                  }
                  
                  if (index == 0) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const DashboardScreen()),
                    );
                  } else if (index == 2) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const HistoryScreen()),
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