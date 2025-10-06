import 'package:poultry_app/screens/upload_audio/upload_audio_screen.dart';
import 'package:flutter/material.dart';
import 'package:poultry_app/screens/dashboard/dashboard_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  // Track which sections are expanded
  bool isNotificationsExpanded = false;
  bool isPreviousChatsExpanded = false;
  bool isPastReadingsExpanded = true;

  // Sample data
  // final List<String> notifications = [
  //   'Temperature was abnormally high',
  //   'Moisture levels dropped below threshold',
  //   'Soil activity increased significantly',
  // ];

  // final List<String> previousChats = [
  //   'What is agriculture?',
  //   'How to improve soil health?',
  //   'What plants grow best in alkaline soil?',
  // ];

  // final List<Map<String, dynamic>> pastReadings = [
  //   {'temperature': 34, 'humidity': 98, 'timestamp': '2023-05-15 14:30'},
  //   {'temperature': 32, 'humidity': 95, 'timestamp': '2023-05-15 10:15'},
  //   {'temperature': 28, 'humidity': 92, 'timestamp': '2023-05-14 16:45'},
  //   {'temperature': 26, 'humidity': 90, 'timestamp': '2023-05-14 12:30'},
  //   {'temperature': 23, 'humidity': 99, 'timestamp': '2023-05-13 18:20'},
  //   {'temperature': 22, 'humidity': 98, 'timestamp': '2023-05-13 14:10'},
  // ];
  List<Map<String, dynamic>> notifications = [];
  List<Map<String, dynamic>> previousChats = [];
  List<Map<String, dynamic>> pastReadings = [];

  bool isLoading = true;
  String? error;
  @override
  void initState() {
    super.initState();
    _loadHistoryData();
  }

  Future<void> _loadHistoryData() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      // Get all history data
      final response = await _supabase
          .from('history')
          .select()
          .eq('user_id', _supabase.auth.currentUser?.id as Object )
          .order('created_at', ascending: false); // Fixed: was 'timestamp'

      final List<Map<String, dynamic>> historyData =
          List<Map<String, dynamic>>.from(response);

      // Group data by type
      setState(() {
        notifications =
            historyData
                .where(
                  (item) =>
                      item['type'] == 'notification' ||
                      item['type'] == 'sensor_alert',
                )
                .toList();

        previousChats =
            historyData.where((item) => item['type'] == 'chat').toList();

        pastReadings =
            historyData.where((item) => item['type'] == 'recording').toList();

        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  // Helper method to format timestamp
  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return 'Unknown time';
    try {
      final DateTime dateTime = DateTime.parse(timestamp);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid date';
    }
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
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // App Logo
                      Center(
                        child: Image.asset(
                          'lib/assets/images/poultry_app_logo.png',
                          width: 100,
                        ),
                      ),
                      const SizedBox(height: 25),
                      
                      // History Title
                      const Text(
                        'History',
                        style: TextStyle(
                          fontFamily: 'Lexend',
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3A3A3A),
                        ),
                      ),
                      
                      // Subtitle with refresh option
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'You can find all your past suggestions here.',
                              style: TextStyle(
                                fontFamily: 'Urbanist',
                                fontSize: 15,
                                color: Color(0xFF5A5A5A),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: _loadHistoryData,
                            color: const Color(0xFF5E4935),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Loading indicator
                      if (isLoading)
                        const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF5E4935),
                          ),
                        )
                      else if (error != null)
                        Center(
                          child: Column(
                            children: [
                              Text('Error: $error'),
                              ElevatedButton(
                                onPressed: _loadHistoryData,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      else ...[
                        // Notifications Section
                        _buildSection(
                          title: 'NOTIFICATIONS',
                          items: notifications,
                          isExpanded: isNotificationsExpanded,
                          onToggle: () {
                            setState(() {
                              isNotificationsExpanded = !isNotificationsExpanded;
                            });
                          },
                          itemBuilder: (item) => '${item['title'] ?? 'Notification'}: ${item['description'] ?? 'No description'}',
                        ),
                        
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Divider(height: 1, color: Colors.grey),
                        ),
                        
                        // Previous Chats Section
                        _buildSection(
                          title: 'PREVIOUS CHATS',
                          items: previousChats,
                          isExpanded: isPreviousChatsExpanded,
                          onToggle: () {
                            setState(() {
                              isPreviousChatsExpanded = !isPreviousChatsExpanded;
                            });
                          },
                          itemBuilder: (item) => item['description'] ?? item['title'] ?? 'Chat message',
                        ),
                        
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Divider(height: 1, color: Colors.grey),
                        ),
                        
                        // Past Readings Section
                        _buildSection(
                          title: 'PAST READINGS',
                          items: pastReadings,
                          isExpanded: isPastReadingsExpanded,
                          onToggle: () {
                            setState(() {
                              isPastReadingsExpanded = !isPastReadingsExpanded;
                            });
                          },
                          itemBuilder: (item) => '${item['title'] ?? 'Recording'}: ${item['description'] ?? 'Audio recording'} - ${_formatTimestamp(item['created_at'])}',
                        ),
                      ],
                      
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              
              // Bottom Navigation
              BottomNavigationBar(
                currentIndex: 2,
                backgroundColor: Colors.white,
                selectedItemColor: const Color(0xFF5E4935),
                unselectedItemColor: Colors.grey,
                selectedFontSize: 12,
                unselectedFontSize: 12,
                type: BottomNavigationBarType.fixed,
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
                  if (index == 2) return; // Already on history
                  
                  if (index == 0) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const DashboardScreen()),
                    );
                  } else if (index == 1) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const AudioScreen()),
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

  // Reusable section builder
  Widget _buildSection({
    required String title,
    required List<Map<String, dynamic>> items,
    required bool isExpanded,
    required VoidCallback onToggle,
    required String Function(Map<String, dynamic>) itemBuilder,
  }) {
    if (items.isEmpty) {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Urbanist',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3A3A3A),
                  letterSpacing: 1.0,
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down,
                size: 20,
                color: Colors.grey.shade400,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'No data available',
                      style: TextStyle(
                        fontFamily: 'Urbanist',
                        fontSize: 14,
                        color: Color(0xFF8A8A8A),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$title (${items.length})',
              style: const TextStyle(
                fontFamily: 'Urbanist',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3A3A3A),
                letterSpacing: 1.0,
              ),
            ),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(
                isExpanded 
                    ? Icons.keyboard_arrow_up 
                    : Icons.keyboard_arrow_down,
                size: 20,
                color: const Color(0xFF5E4935),
              ),
              onPressed: onToggle,
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // First item (always visible)
        _buildHistoryItem(
          text: itemBuilder(items[0]),
          isExpanded: false,
          onToggle: onToggle,
        ),
        
        // Expanded items
        if (isExpanded && items.length > 1)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF5E4935),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items.skip(1).map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 6.0),
                        child: Icon(
                          Icons.circle,
                          size: 6,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          itemBuilder(item),
                          style: const TextStyle(
                            fontFamily: 'Urbanist',
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  // Build history item widget
  Widget _buildHistoryItem({
    required String text,
    required bool isExpanded,
    required VoidCallback onToggle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontFamily: 'Urbanist',
                      fontSize: 14,
                      color: Color(0xFF3A3A3A),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 18,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}