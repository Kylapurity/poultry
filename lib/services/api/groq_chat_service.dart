import 'dart:convert';
import 'package:fauna_pulse/models/ai_response.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class GroqService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final String apiUrl =
      "https://api.groq.com/openai/v1/chat/completions"; // Replace with actual API URL
  final String apiKey =
      "your-api-key"; // Replace with your API key;

  Future<AIResponse> sendMessage(String message) async {
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };

    final body = jsonEncode({
      "model": "meta-llama/llama-4-scout-17b-16e-instruct",
      "messages": [
        {
          "role": "system",
          "content":
              "You are an AI assistant focused exclusively on agriculture and farm management. Your goal is to provide clear, friendly, and practical advice related only to agriculture or farming. Use simple language that farmers can understand. Always reply strictly in the following JSON format: {\"response\": string, \"advice\": string}. If the user asks a question outside agriculture or farming, politely redirect them to relevant agricultural topics.",
        },
        {"role": "user", "content": message},
      ],
      "temperature": 1,
      "max_tokens": 300,
      "top_p": 1,
      "response_format": {"type": "json_object"},
      "stream": false,
    });

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final content = decoded['choices'][0]['message']['content'];

      try {
        final Map<String, dynamic> jsonContent = jsonDecode(content);
        return AIResponse.fromJson(jsonContent);
      } catch (e) {
        print("❌ Error parsing Groq JSON content: $e");
        throw Exception("Error parsing Groq JSON content: $e");
      }
    } else {
      throw Exception('Failed to fetch advice: ${response.statusCode}');
    }
  }

  /// Saves a single message to the `chat_messages` table.
  Future<void> saveChatMessage({
    required String role,
    required String message,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      // It's best to prevent logged-out users from even trying to send a message.
      print('Authentication Error: User is not logged in.');
      return;
    }

    if (role != 'user' && role != 'assistant') {
      throw ArgumentError('Invalid role: Must be "user" or "assistant".');
    }

    try {
      await _supabase.from('chat_messages').insert({
        'user_id': user.id,
        'role': role,
        'message': message,
      });
    } catch (error) {
      print('Database error saving message: $error');
      // Optionally rethrow the error if you want to handle it in the UI
      rethrow;
    }
  }
}