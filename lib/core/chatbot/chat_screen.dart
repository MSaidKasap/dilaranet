import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'message_model.dart';
import 'package:flutter_tts/flutter_tts.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final FlutterTts _flutterTts = FlutterTts();

  final List<Message> _messages = [];
  bool _isTyping = false;
  bool _isDataLoaded = false;
  Map<String, String> _knownQuestions = {};
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadQuestionsFromAPI();
    _messages.add(Message(
      text:
          "Merhaba! Size nasıl yardımcı olabilirim? Sorularınızı sorabilirsiniz.",
      isUser: false,
      isWelcome: true,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _loadQuestionsFromAPI() async {
    try {
      setState(() {
        _isTyping = true;
      });

      final response = await http.get(
        Uri.parse('https://dilara.net/chatbot/get_questions.php'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _knownQuestions = Map<String, String>.from(data['questions']);
            _isDataLoaded = true;
          });
        } else {
          throw Exception('API başarısız yanıt verdi');
        }
      } else {
        throw Exception('API isteği başarısız: ${response.statusCode}');
      }
    } catch (error) {
      setState(() {
        _messages.add(Message(
          text:
              "Üzgünüm, sorular yüklenirken bir hata oluştu. Lütfen daha sonra tekrar deneyin.",
          isUser: false,
        ));
      });
    } finally {
      setState(() {
        _isTyping = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty || !_isDataLoaded) return;
    _textController.clear();
    setState(() {
      _messages.add(Message(text: text, isUser: true));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    setState(() {
      _isTyping = true;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      _loadQuestionsFromAPI();
      _getBotResponse(text);
    });
  }

  void _getBotResponse(String userMessage) {
    final lowerMsg = userMessage.toLowerCase();
    final exactMatch = _knownQuestions.containsKey(lowerMsg);
    final bestMatch = _findBestMatch(lowerMsg);
    final suggestions = _findTopSuggestions(userMessage, count: 3);

    setState(() {
      _isTyping = false;
      _messages.removeWhere((msg) =>
          msg.isUser == false &&
          (msg.text?.contains("Bunu mu demek istediniz") == true ||
              msg.text?.contains("Veya belki bunlardan birini") == true ||
              msg.text?.contains("Tam olarak anlayamadım") == true));

      if (exactMatch) {
        final response = _knownQuestions[lowerMsg]!;
        _messages.add(Message(
          text: response,
          isUser: false,
        ));
      } else if (bestMatch != null) {
        final similarity = bestMatch['similarity'];
        if (similarity >= 0.9) {
          _messages.add(Message(
            text: bestMatch['answer']!,
            isUser: false,
          ));
        } else if (similarity <= 0.6) {
          _saveUnknownQuestionToAPI(userMessage);

          _messages.add(Message(
            text: "Bunu mu demek istediniz?",
            isUser: false,
          ));
          _messages.add(Message(
            isUser: false,
            suggestionConfirmation: {
              'question': bestMatch['question']!,
              'answer': bestMatch['answer']!,
            },
          ));
          final otherSuggestions = suggestions
              .where((s) => s['question'] != bestMatch['question'])
              .toList();

          if (otherSuggestions.isNotEmpty) {
            _messages.add(Message(
              text: "Veya belki bunlardan birini:",
              isUser: false,
            ));
            _messages.add(Message(
              isUser: false,
              suggestions: otherSuggestions,
            ));
          }
        } else if (suggestions.isNotEmpty) {
          _messages.add(Message(
            text:
                "Tam olarak anlayamadım, belki bunlardan birini sormak istediniz?",
            isUser: false,
          ));
          _messages.add(Message(
            isUser: false,
            suggestions: suggestions,
          ));
        } else {
          _messages.add(Message(
            text:
                "Üzgünüm, bu konuda bir bilgim yok. Daha detaylı sorabilir misiniz?",
            isUser: false,
          ));
          _saveUnknownQuestionToAPI(userMessage);
        }
      } else {
        // bestMatch null ise
        if (suggestions.isNotEmpty) {
          _messages.add(Message(
            text:
                "Tam olarak anlayamadım, belki bunlardan birini sormak istediniz?",
            isUser: false,
          ));
          _messages.add(Message(
            isUser: false,
            suggestions: suggestions,
          ));
        } else {
          _messages.add(Message(
            text:
                "Üzgünüm, bu konuda bir bilgim yok. Daha detaylı sorabilir misiniz?",
            isUser: false,
          ));
          _saveUnknownQuestionToAPI(userMessage);
          _loadQuestionsFromAPI();
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Map<String, dynamic>? _findBestMatch(String userMessage) {
    if (_knownQuestions.isEmpty) return null;

    final List<Map<String, dynamic>> matches = [];

    for (final entry in _knownQuestions.entries) {
      final similarity =
          _calculateSimilarity(userMessage, entry.key.toLowerCase());
      if (similarity > 0.3) {
        // Benzerlik eşiği
        matches.add({
          'question': entry.key,
          'answer': entry.value,
          'similarity': similarity,
        });
      }
    }
    if (matches.isEmpty) return null;
    matches.sort((a, b) => b['similarity'].compareTo(a['similarity']));
    return matches.first;
  }

  double _calculateSimilarity(String str1, String str2) {
    if (str1.isEmpty || str2.isEmpty) return 0.0;
    if (str1 == str2) return 1.0;
    if (str1.contains(str2) || str2.contains(str1)) {
      return 0.8;
    }
    final words1 = str1.split(' ');
    final words2 = str2.split(' ');
    final commonWords = words1.where((word) => words2.contains(word)).length;
    final union = words1.toSet()..addAll(words2.toSet());
    final jaccard = union.isEmpty ? 0.0 : commonWords / union.length;
    final maxLength = str1.length > str2.length ? str1.length : str2.length;
    final levenshtein = maxLength > 0
        ? 1 - (_levenshteinDistance(str1, str2) / maxLength)
        : 0.0;
    return (jaccard * 0.6) + (levenshtein * 0.4);
  }

  int _levenshteinDistance(String a, String b) {
    final matrix = List.generate(
      a.length + 1,
      (i) => List.filled(b.length + 1, 0),
    );

    for (var i = 0; i <= a.length; i++) {
      matrix[i][0] = i;
    }
    for (var j = 0; j <= b.length; j++) {
      matrix[0][j] = j;
    }

    for (var i = 1; i <= a.length; i++) {
      for (var j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1, // deletion
          matrix[i][j - 1] + 1, // insertion
          matrix[i - 1][j - 1] + cost, // substitution
        ].reduce((value, element) => value < element ? value : element);
      }
    }

    return matrix[a.length][b.length];
  }

  List<Map<String, String>> _findTopSuggestions(String userMessage,
      {int count = 3}) {
    if (_knownQuestions.isEmpty) return [];
    final List<Map<String, dynamic>> suggestions = [];
    for (final entry in _knownQuestions.entries) {
      final similarity = _calculateSimilarity(
          userMessage.toLowerCase(), entry.key.toLowerCase());
      if (similarity > 0.3) {
        suggestions.add({
          'question': entry.key,
          'answer': entry.value,
          'similarity': similarity,
        });
      }
    }
    suggestions.sort((a, b) => b['similarity'].compareTo(a['similarity']));
    return suggestions
        .take(count)
        .map((e) => {
              'question': e['question'] as String,
              'answer': e['answer'] as String
            })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  // ignore: deprecated_member_use
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      ' Chatbot ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.white,
              child: ListView.builder(
                controller: _scrollController,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < _messages.length) {
                    return _buildMessage(_messages[index]);
                  } else {
                    return _buildTypingIndicator();
                  }
                },
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Sorunuzu buraya yazın...',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    onSubmitted: _handleSubmitted,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        // ignore: deprecated_member_use
                        color: const Color(0xFF667EEA).withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () => _handleSubmitted(_textController.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(Message message) {
    if (message.suggestions != null) {
      return _buildSuggestionMessage(message);
    }
    if (message.suggestionConfirmation != null) {
      return _buildConfirmationMessage(message);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Align(
        alignment:
            message.isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: message.isWelcome
                  ? const LinearGradient(
                      colors: [Color(0xFF28A745), Color(0xFF20C997)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : message.isUser
                      ? const LinearGradient(
                          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
              color:
                  message.isUser || message.isWelcome ? null : Colors.grey[100],
              border: message.isUser || message.isWelcome
                  ? null
                  : Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.text ?? '',
                  style: TextStyle(
                    color: message.isUser || message.isWelcome
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionMessage(Message message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Belki bunları sormak istediniz:',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF856404),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: message.suggestions!.map((suggestion) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _messages.add(Message(
                            text: suggestion['question']!,
                            isUser: true,
                          ));
                        });
                        _getBotResponse(suggestion['question']!);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFEAA7), Color(0xFFFAB1A0)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          suggestion['question']!,
                          style: const TextStyle(
                            color: Color(0xFF2D3436),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmationMessage(Message message) {
    final question = message.suggestionConfirmation!['question']!;
    final answer = message.suggestionConfirmation!['answer']!;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          child: GestureDetector(
            onTap: () {
              setState(() {
                _messages.add(Message(
                  text: answer,
                  isUser: false,
                ));
              });
              WidgetsBinding.instance
                  .addPostFrameCallback((_) => _scrollToBottom());
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    question,
                    style: TextStyle(
                      color: Colors.blue[900],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bu soruyu sormak istediyseniz dokunun',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 40,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTypingDot(0),
                    _buildTypingDot(1),
                    _buildTypingDot(2),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Text('Yazıyor...'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 600 + (index * 200)),
      height: 8,
      width: 8,
      decoration: BoxDecoration(
        color: const Color(0xFF667EEA),
        shape: BoxShape.circle,
      ),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 2),
    );
  }

  Future<void> _saveUnknownQuestionToAPI(String question) async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      // ignore: avoid_print
      print("Firebase Cihaz Tokeni: $token");
      final response = await http.post(
        Uri.parse('https://dilara.net/chatbot/save_question.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'soru': question,
          'token': token ?? '',
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        debugPrint("Soru başarıyla kaydedildi: $question");
      } else {
        debugPrint(
            "Soru kaydedilemedi (API hatası): ${data['message'] ?? 'Bilinmeyen hata'}");
      }
    } catch (e) {
      debugPrint("Soru kaydedilemedi (istemci hatası): $e");
    }
  }
}
