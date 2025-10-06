class AIResponse {
  final String response;
  final String advice;

   AIResponse({required this.response, required this.advice});

  factory AIResponse.fromJson(Map<String, dynamic> json) {
    return AIResponse(
      response: json['response'] ?? 'Sorry, I could not generate a response.',
      advice: json['advice'] ?? '',
    );
  }
}