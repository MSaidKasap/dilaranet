class Message {
  final String? text;
  final bool isUser;
  final bool isWelcome;
  final double? similarity;
  final List<Map<String, String>>? suggestions;
  final Map<String, String>? suggestionConfirmation; // Yeni alan

  Message({
    this.text,
    required this.isUser,
    this.isWelcome = false,
    this.similarity,
    this.suggestions,
    this.suggestionConfirmation,
  });
}
