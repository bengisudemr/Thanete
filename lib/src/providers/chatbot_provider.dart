import 'dart:convert';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:thanette/src/providers/notes_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

// Result model for smart editing
class _SmartEditResult {
  final String? editedNote;
  final List<String>? changeLog;
  const _SmartEditResult({this.editedNote, this.changeLog});
}

class ChatbotProvider extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _apiKey;
  String? _lastRemoveContent; // remembers last suggested REMOVE_CONTENT payload
  final Map<String, dynamic> _memory = {
    'pending_action': null,
    'last_intent': null,
    'topics': <String>[],
  };
  // Global kill-switch: disable all note editing (title/content). Default: disabled.
  bool noteEditingEnabled = false;

  Offset? _bubbleOffset;

  Offset? get bubbleOffset => _bubbleOffset;

  void setBubbleOffset(Offset offset) {
    if (_bubbleOffset == offset) return;
    _bubbleOffset = offset;
    notifyListeners();
  }

  // Callback functions for note editing
  Function(String)? onNoteTitleChanged;
  Function(String)? onNoteContentChanged;
  Function(String)? onNoteContentAdded;
  Function(String)? onNoteContentRemoved;
  Function(String)? onNoteContentRewritten;
  Function(String)? onNoteTitleAdded;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;

  ChatbotProvider() {
    _initializeOpenAI();
  }

  void _initializeOpenAI() {
    _apiKey = dotenv.env['OPENAI_API_KEY'];
  }

  void addMessage(String text, bool isUser) {
    _messages.add(
      ChatMessage(text: text, isUser: isUser, timestamp: DateTime.now()),
    );
    notifyListeners();
  }

  Future<void> sendMessage(String text, NotesProvider notesProvider) async {
    // Add user message
    addMessage(text, true);

    // Show loading
    _isLoading = true;
    notifyListeners();

    try {
      String response;

      if (_apiKey != null && _apiKey!.isNotEmpty) {
        try {
          // Prefer OpenAI API
          response = await _getOpenAIResponse(text, notesProvider);
        } catch (_) {
          // Network/auth error → fallback to local generation
          response = _generateResponse(text, notesProvider);
        }
      } else {
        // Fallback to rule-based responses
        response = _generateResponse(text, notesProvider);
      }

      // Add AI response
      addMessage(response, false);
    } catch (e) {
      addMessage('Üzgünüm, bir hata oluştu. Lütfen tekrar deneyin.', false);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendMessageWithNoteContext(
    String text,
    NotesProvider notesProvider, {
    required String noteId,
    String? noteTitle,
    String? noteContent,
  }) async {
    // Add user message
    addMessage(text, true);

    // Show loading
    _isLoading = true;
    notifyListeners();

    try {
      // If user says "o komutu uygula/kullan" and we have a stored command, apply immediately
      final lowerText = text.toLowerCase();
      final wantsApplyLast =
          (lowerText.contains('o komutu') ||
              lowerText.contains('komutu') ||
              lowerText.contains('onu')) &&
          (lowerText.contains('kullan') ||
              lowerText.contains('uygula') ||
              lowerText.contains('sil'));
      if (noteEditingEnabled && wantsApplyLast && _lastRemoveContent != null) {
        if (onNoteContentRemoved != null) {
          onNoteContentRemoved!(_lastRemoveContent!);
          addMessage('İstediğiniz maddeyi sildim.', false);
          _clearPendingAction();
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      // Short confirmation applies pending action
      final isAffirm = [
        'evet',
        'onayla',
        'tamam',
        'uygula',
      ].any((w) => lowerText.trim() == w || lowerText.contains(w));
      if (noteEditingEnabled && isAffirm && _memory['pending_action'] != null) {
        final pending = _memory['pending_action'] as Map<String, dynamic>;
        if (pending['type'] == 'remove' && pending['target'] is String) {
          final target = pending['target'] as String;
          if (onNoteContentRemoved != null) {
            onNoteContentRemoved!(target);
            addMessage('İstediğiniz maddeyi sildim.', false);
            _clearPendingAction();
            _isLoading = false;
            notifyListeners();
            return;
          }
        }
      }

      // Try immediate parse-and-apply from user's own cümlesi
      final didApply = noteEditingEnabled
          ? _tryApplyImmediateCommand(text, noteTitle, noteContent)
          : false;
      if (didApply) {
        addMessage('İstediğiniz değişiklikleri uyguladım.', false);
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Prefer new smart JSON-based note editor when possible
      if (_apiKey != null && _apiKey!.isNotEmpty) {
        try {
          final smart = await _getOpenAISmartNoteEdit(text, noteContent ?? '');
          final edited = (smart['EDITED_NOTE'] ?? '').toString();
          final List<dynamic> changeLogRaw = (smart['CHANGE_LOG'] is List)
              ? smart['CHANGE_LOG'] as List
              : [];
          if (noteEditingEnabled &&
              edited.isNotEmpty &&
              onNoteContentChanged != null) {
            onNoteContentChanged!(edited);
          }
          final summary = changeLogRaw
              .map((e) => e.toString())
              .take(5)
              .join('\n');
          addMessage(
            summary.isNotEmpty
                ? 'Düzenlemeler uygulandı:\n$summary'
                : 'Notunuzu güncelledim.',
            false,
          );
          _isLoading = false;
          notifyListeners();
          return;
        } catch (_) {
          // fall back to previous flow below
        }
      }

      // Smart edit detection: if the user provides the structured instruction
      final lower = text.toLowerCase();
      final wantsSmartEdit =
          text.contains('EDITED_NOTE') ||
          text.contains('CHANGE_LOG') ||
          (lower.contains('akıllı') && lower.contains('düzen')) ||
          (lower.contains('sohbet') &&
              lower.contains('notu') &&
              lower.contains('düzen'));

      if (wantsSmartEdit) {
        if (_apiKey == null || _apiKey!.isEmpty) {
          addMessage(
            'Akıllı düzenleme için bir API anahtarı gerekli. Lütfen OPENAI_API_KEY ayarlayın.',
            false,
          );
          _isLoading = false;
          notifyListeners();
          return;
        }

        try {
          final smartResult = await _runSmartEdit(text, noteContent ?? '');

          // Apply edited content
          final edited = smartResult.editedNote?.trim();
          final changes = smartResult.changeLog;
          if (edited != null && edited.isNotEmpty) {
            if (onNoteContentChanged != null) {
              onNoteContentChanged!(edited);
            }
          }

          // Show a concise confirmation message with change log summary
          final summary = (changes != null && changes.isNotEmpty)
              ? changes.take(5).join('\n')
              : 'Düzenlemeler uygulandı.';
          addMessage('Akıllı düzenleme tamamlandı.\n$summary', false);
          _isLoading = false;
          notifyListeners();
          return;
        } catch (e) {
          // If smart edit fails, inform user and continue with normal flow fallback
          addMessage('Akıllı düzenleme sırasında hata oluştu: $e', false);
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      String response;

      if (_apiKey != null && _apiKey!.isNotEmpty) {
        try {
          // Prefer OpenAI API with note context
          response = await _getOpenAIResponseWithNoteContext(
            text,
            notesProvider,
            noteId: noteId,
            noteTitle: noteTitle,
            noteContent: noteContent,
          );
        } catch (_) {
          // Network/auth error → fallback to local generation
          response = _generateResponseWithNoteContext(
            text,
            notesProvider,
            noteId: noteId,
            noteTitle: noteTitle,
            noteContent: noteContent,
          );
        }
      } else {
        // Fallback to rule-based responses
        response = _generateResponseWithNoteContext(
          text,
          notesProvider,
          noteId: noteId,
          noteTitle: noteTitle,
          noteContent: noteContent,
        );
      }

      // Check if response contains edit commands and apply them (safe)
      try {
        _processEditCommands(response, noteId, noteTitle, noteContent);
      } catch (_) {
        // Ignore parsing errors of command tags
      }

      // Add AI response
      addMessage(response, false);
    } catch (e) {
      addMessage('Üzgünüm, bir hata oluştu. Lütfen tekrar deneyin.', false);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Smart edit result holder moved to top-level

  // Build chat history string from current messages list
  String _serializeChatHistory() {
    final buffer = StringBuffer();
    for (final m in _messages) {
      final role = m.isUser ? 'user' : 'assistant';
      buffer.writeln('[$role] ${m.text}');
    }
    return buffer.toString().trim();
  }

  // Parse user's message and apply edits immediately if clearly specified
  bool _tryApplyImmediateCommand(
    String userText,
    String? noteTitle,
    String? noteContent,
  ) {
    final text = userText.trim();
    final lower = text.toLowerCase();

    // 1) İçerikten "..." sil
    final removeQuoted = RegExp(
      "içerikten\\s*(?:\\\\\"|'|“|”)(.*?)(?:\\\\\"|'|“|”)\\s*(?:sil|kaldır)",
      caseSensitive: false,
    );
    final mq = removeQuoted.firstMatch(text);
    if (mq != null) {
      final target = mq.group(1);
      if (target != null &&
          target.trim().isNotEmpty &&
          onNoteContentRemoved != null) {
        _lastRemoveContent = target;
        onNoteContentRemoved!(target);
        return true;
      }
    }

    // 2) Birinci/ikinci ... maddeyi sil
    if (noteEditingEnabled &&
        (lower.contains('madde') ||
            lower.contains('maddesini') ||
            lower.contains('maddeyi')) &&
        (lower.contains('sil') || lower.contains('kaldır'))) {
      int? idx;
      int? _ordToIdx(String t) {
        if (t.contains('ilk') ||
            t.contains('birinci') ||
            RegExp(r'\b1(\.|\s|$)').hasMatch(t))
          return 0;
        if (t.contains('ikinci') || RegExp(r'\b2(\.|\s|$)').hasMatch(t))
          return 1;
        if (t.contains('üçüncü') || RegExp(r'\b3(\.|\s|$)').hasMatch(t))
          return 2;
        if (t.contains('dördüncü') || RegExp(r'\b4(\.|\s|$)').hasMatch(t))
          return 3;
        if (t.contains('beşinci') || RegExp(r'\b5(\.|\s|$)').hasMatch(t))
          return 4;
        if (t.contains('altıncı') || RegExp(r'\b6(\.|\s|$)').hasMatch(t))
          return 5;
        if (t.contains('yedinci') || RegExp(r'\b7(\.|\s|$)').hasMatch(t))
          return 6;
        if (t.contains('sekizinci') || RegExp(r'\b8(\.|\s|$)').hasMatch(t))
          return 7;
        if (t.contains('dokuzuncu') || RegExp(r'\b9(\.|\s|$)').hasMatch(t))
          return 8;
        if (t.contains('onuncu') || RegExp(r'\b10(\.|\s|$)').hasMatch(t))
          return 9;
        return null;
      }

      idx = _ordToIdx(lower);
      if (idx != null && idx >= 0 && noteContent != null) {
        // Extract lines
        final lines = noteContent
            .split('\n')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        if (idx < lines.length) {
          final target = lines[idx];
          if (onNoteContentRemoved != null) {
            _lastRemoveContent = target;
            onNoteContentRemoved!(target);
            return true;
          }
        }
      }
    }

    // 3) İçeriği ... olarak değiştir
    if (noteEditingEnabled &&
        lower.contains('içeriği') &&
        lower.contains('olarak') &&
        lower.contains('değiştir')) {
      final after = text.split(RegExp(r'içeriği', caseSensitive: false)).last;
      final content = after
          .replaceFirst(RegExp(r'olarak', caseSensitive: false), '')
          .replaceFirst(RegExp(r'değiştir', caseSensitive: false), '')
          .trim();
      if (content.isNotEmpty && onNoteContentChanged != null) {
        onNoteContentChanged!(content);
        return true;
      }
    }

    // 4) Başlığı ... yap/değiştir
    if (noteEditingEnabled &&
        lower.contains('başlık') &&
        (lower.contains('yap') || lower.contains('değiştir'))) {
      final parts = text.split(RegExp(r'başlık', caseSensitive: false));
      if (parts.length > 1) {
        final rest = parts.last
            .replaceFirst(RegExp(r'yap|değiştir', caseSensitive: false), '')
            .trim();
        if (rest.isNotEmpty && onNoteTitleChanged != null) {
          onNoteTitleChanged!(rest);
          return true;
        }
      }
    }

    return false;
  }

  Future<_SmartEditResult> _runSmartEdit(
    String userPrompt,
    String currentNote,
  ) async {
    final chatHistory = _serializeChatHistory();

    // Replace placeholders if present, else append inputs under the prompt
    String finalUserContent;
    if (userPrompt.contains('{{chat_history}}') ||
        userPrompt.contains('{{current_note}}')) {
      finalUserContent = userPrompt
          .replaceAll('{{chat_history}}', chatHistory)
          .replaceAll('{{current_note}}', currentNote);
    } else {
      finalUserContent =
          '$userPrompt\n\nGirdi:\n- chat_history: """$chatHistory"""\n- current_note: """$currentNote"""';
    }

    final url = Uri.parse('https://api.openai.com/v1/chat/completions');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {
            'role': 'system',
            'content':
                'Sen güçlü bir not düzenleme asistanısın. Kullanıcıların notlarını sohbet geçmişine göre düzenler, özetler ve okunabilir hale getirirsin. Çıktıyı yalnızca istenen JSON formatında döndür.',
          },
          {'role': 'user', 'content': finalUserContent},
        ],
        'max_tokens': 1200,
        'temperature': 0.4,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('OpenAI API error: ${response.statusCode}');
    }
    final data = jsonDecode(response.body);
    final content = data['choices'][0]['message']['content'].toString();

    // Try to extract JSON object from content safely
    final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
    final jsonText = jsonMatch != null ? jsonMatch.group(0)! : content;

    try {
      final parsed = jsonDecode(jsonText) as Map<String, dynamic>;
      final edited = (parsed['EDITED_NOTE'] ?? '').toString();
      final rawLog = parsed['CHANGE_LOG'];
      final List<String>? changeLog = rawLog is List
          ? rawLog.map((e) => e.toString()).toList()
          : null;
      return _SmartEditResult(editedNote: edited, changeLog: changeLog);
    } catch (e) {
      // If JSON parsing fails, fallback: place all content as edited note
      return _SmartEditResult(editedNote: content, changeLog: null);
    }
  }

  // New: Smart JSON prompt returning { reply, updated_note }
  Future<Map<String, dynamic>> _getOpenAISmartNoteEdit(
    String userMessage,
    String currentNote,
  ) async {
    final chatHistory = _serializeChatHistory();
    final memoryJson = jsonEncode(_memory);

    final system =
        'Sen bir kişisel asistan ve not yöneticisisin. Kullanıcının notunu sohbet geçmişi, '
        'son kullanıcı mesajı ve kısa süreli hafızana göre düzenlersin. Cevabı YALNIZCA şu '
        'JSON formatında ver ve başka metin ekleme:\n'
        '{\n  "EDITED_NOTE": "tam güncellenmiş not",\n  "CHANGE_LOG": ["kısa açıklamalar"]\n}';

    final userPayload = jsonEncode({
      'chat_history': chatHistory,
      'user_message': userMessage,
      'current_note': currentNote,
      'memory': jsonDecode(memoryJson),
    });

    final url = Uri.parse('https://api.openai.com/v1/chat/completions');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {'role': 'system', 'content': system},
          {'role': 'user', 'content': userPayload},
        ],
        'max_tokens': 800,
        'temperature': 0.5,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('OpenAI API error: ${response.statusCode}');
    }
    final data = jsonDecode(response.body);
    final content = data['choices'][0]['message']['content'].toString();

    final match = RegExp(r'\{[\s\S]*\}').firstMatch(content);
    final jsonText = match != null ? match.group(0)! : content;
    final parsed = jsonDecode(jsonText) as Map<String, dynamic>;
    _updateMemoryFromModel(parsed);
    return parsed;
  }

  void _updateMemoryFromModel(Map<String, dynamic> modelJson) {
    final reply = (modelJson['reply'] ?? '').toString().toLowerCase();
    if (reply.contains('sildim') || reply.contains('kaldırdım')) {
      _clearPendingAction();
      _memory['last_intent'] = 'remove_item';
    }
  }

  void _clearPendingAction() {
    _memory['pending_action'] = null;
    _lastRemoveContent = null;
  }

  void _processEditCommands(
    String response,
    String noteId,
    String? noteTitle,
    String? noteContent,
  ) {
    // Look for edit commands in the response
    if (response.contains('[EDIT_TITLE:')) {
      final titleMatch = RegExp(
        r'\[EDIT_TITLE:(.*?)\]',
        dotAll: true,
      ).firstMatch(response);
      if (titleMatch != null) {
        final newTitle = titleMatch.group(1)?.trim();
        if (noteEditingEnabled &&
            newTitle != null &&
            onNoteTitleChanged != null) {
          onNoteTitleChanged!(newTitle);
        }
      }
    }

    if (response.contains('[EDIT_CONTENT:')) {
      final contentMatch = RegExp(
        r'\[EDIT_CONTENT:(.*?)\]',
        dotAll: true,
      ).firstMatch(response);
      if (contentMatch != null) {
        final newContent = contentMatch.group(1)?.trim();
        if (noteEditingEnabled &&
            newContent != null &&
            onNoteContentChanged != null) {
          onNoteContentChanged!(newContent);
        }
      }
    }

    if (response.contains('[ADD_CONTENT:')) {
      final addMatch = RegExp(
        r'\[ADD_CONTENT:(.*?)\]',
        dotAll: true,
      ).firstMatch(response);
      if (addMatch != null) {
        final addContent = addMatch.group(1)?.trim();
        if (noteEditingEnabled &&
            addContent != null &&
            onNoteContentAdded != null) {
          onNoteContentAdded!(addContent);
        }
      }
    }

    if (response.contains('[REMOVE_CONTENT:')) {
      final removeMatch = RegExp(
        r'\[REMOVE_CONTENT:(.*?)\]',
        dotAll: true,
      ).firstMatch(response);
      if (removeMatch != null) {
        final removeContent = removeMatch.group(1)?.trim();
        if (noteEditingEnabled &&
            removeContent != null &&
            onNoteContentRemoved != null) {
          _lastRemoveContent = removeContent; // remember last removal
          _memory['pending_action'] = {
            'type': 'remove',
            'target': removeContent,
          };
          onNoteContentRemoved!(removeContent);
        }
      }
    }

    if (response.contains('[REWRITE_CONTENT:')) {
      final rewriteMatch = RegExp(
        r'\[REWRITE_CONTENT:(.*?)\]',
        dotAll: true,
      ).firstMatch(response);
      if (rewriteMatch != null) {
        final rewriteContent = rewriteMatch.group(1)?.trim();
        if (noteEditingEnabled &&
            rewriteContent != null &&
            onNoteContentRewritten != null) {
          onNoteContentRewritten!(rewriteContent);
        }
      }
    }

    if (response.contains('[ADD_TITLE:')) {
      final addTitleMatch = RegExp(
        r'\[ADD_TITLE:(.*?)\]',
        dotAll: true,
      ).firstMatch(response);
      if (addTitleMatch != null) {
        final addTitle = addTitleMatch.group(1)?.trim();
        if (noteEditingEnabled &&
            addTitle != null &&
            onNoteTitleAdded != null) {
          onNoteTitleAdded!(addTitle);
        }
      }
    }
  }

  Future<String> _getOpenAIResponse(
    String userMessage,
    NotesProvider notesProvider,
  ) async {
    final notes = notesProvider.items;

    // Prepare context from notes
    final notesContext = notes.isEmpty
        ? 'Kullanıcının henüz notu yok.'
        : notes
              .map((note) {
                final title = note.title.isEmpty ? 'Başlıksız' : note.title;
                final content = note.body.isEmpty ? '(İçerik yok)' : note.body;
                return 'Not: "$title" - İçerik: $content';
              })
              .join('\n\n');

    final systemPrompt =
        '''Sen kullanıcının notlarına yardımcı olan bir AI asistanısın. 
Kullanıcının notları hakkında bilgi sahibisin ve onlara yardımcı oluyorsun.

Kullanıcının Notları:
$notesContext

Lütfen Türkçe cevap ver ve kullanıcının notları hakkında yardımcı ol.''';

    final url = Uri.parse('https://api.openai.com/v1/chat/completions');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userMessage},
        ],
        'max_tokens': 500,
        'temperature': 0.7,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'].toString();
    } else {
      throw Exception('OpenAI API error: ${response.statusCode}');
    }
  }

  String _generateResponse(String userMessage, NotesProvider notesProvider) {
    final notes = notesProvider.items;
    final lowerMessage = userMessage.toLowerCase();

    // Simple rule-based responses (replace with actual AI)
    if (lowerMessage.contains('not') || lowerMessage.contains('notlar')) {
      if (notes.isEmpty) {
        return 'Henüz hiç notunuz yok. Yeni bir not oluşturmak için sağ alttaki + butonuna tıklayabilirsiniz.';
      }

      final noteCount = notes.length;
      final pinnedCount = notes.where((n) => n.isPinned).length;

      return 'Toplam $noteCount notunuz var. Bunlardan $pinnedCount tanesi sabitlenmiş. Size nasıl yardımcı olabilirim?';
    }

    if (lowerMessage.contains('ara') || lowerMessage.contains('bul')) {
      if (notes.isEmpty) {
        return 'Notlarınız bulunmuyor. Önce bir not oluşturmanız gerekiyor.';
      }
      return 'Notlarınızda arama yapmak için üstteki arama çubuğunu kullanabilirsiniz. Belirli bir konu hakkında sorabilirsiniz.';
    }

    if (lowerMessage.contains('yardım') || lowerMessage.contains('nasıl')) {
      return '''Notlarınızı yönetmek için:

• Yeni not oluşturmak: Sağ alttaki + butonuna tıklayın
• Notları sabitlemek: Not kartının sol altındaki pin ikonuna tıklayın
• Notları yeniden sıralamak: Not kartını sürükleyip bırakın
• Notları düzenlemek: Not kartına tıklayın
• Notları silmek: Üç nokta menüsünden sil seçeneğini kullanın

Başka bir konuda yardımcı olabilir miyim?''';
    }

    if (lowerMessage.contains('merhaba') || lowerMessage.contains('selam')) {
      return 'Merhaba! Notlarınız hakkında nasıl yardımcı olabilirim?';
    }

    // Default response
    return 'Notlarınız hakkında daha fazla bilgi almak için şu soruları sorabilirsiniz:\n\n• Kaç notum var?\n• Notlarımı nasıl organize edebilirim?\n• Notları nasıl ararım?\n\nBaşka nasıl yardımcı olabilirim?';
  }

  Future<String> _getOpenAIResponseWithNoteContext(
    String userMessage,
    NotesProvider notesProvider, {
    required String noteId,
    String? noteTitle,
    String? noteContent,
  }) async {
    final notes = notesProvider.items;

    // Prepare context for the specific note
    final noteContext =
        'Şu anki Not: "$noteTitle"\nİçerik: ${noteContent ?? "(İçerik yok)"}';

    // Prepare all notes context
    final notesContext = notes.isEmpty
        ? 'Kullanıcının başka notu yok.'
        : notes
              .map((note) {
                final title = note.title.isEmpty ? 'Başlıksız' : note.title;
                final content = note.body.isEmpty ? '(İçerik yok)' : note.body;
                return 'Not: "$title" - İçerik: $content';
              })
              .join('\n\n');

    final systemPrompt =
        '''Sen kullanıcının notlarına yardımcı olan bir AI asistanısın. 
Kullanıcı şu anda bir notun detayında ve bu not hakkında sorular soruyor veya notu düzenlemek istiyor.

$noteContext

Diğer Notlar:
$notesContext

Lütfen Türkçe cevap ver ve kullanıcının notu hakkında yardımcı ol. 

EĞER kullanıcı notu düzenlemek istiyorsa, aşağıdaki formatları kullan:
- Başlık değiştirmek için: [EDIT_TITLE:Yeni Başlık]
- İçerik değiştirmek için: [EDIT_CONTENT:Yeni İçerik]
- İçeriğe ekleme yapmak için: [ADD_CONTENT:Eklenecek metin]
- İçerikten silme için: [REMOVE_CONTENT:Silinecek metin]
- İçeriği yeniden yazmak için: [REWRITE_CONTENT:Yeni içerik]
- Başlığa ekleme için: [ADD_TITLE:Eklenecek kelime]

Bu komutları kullanırken, kullanıcıya ne yaptığını da açıkla.''';

    final url = Uri.parse('https://api.openai.com/v1/chat/completions');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userMessage},
        ],
        'max_tokens': 500,
        'temperature': 0.7,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'].toString();
    } else {
      throw Exception('OpenAI API error: ${response.statusCode}');
    }
  }

  String _generateResponseWithNoteContext(
    String userMessage,
    NotesProvider notesProvider, {
    required String noteId,
    String? noteTitle,
    String? noteContent,
  }) {
    final lowerMessage = userMessage.toLowerCase();

    // Helper: map Turkish ordinals to zero-based indices
    int? _ordinalToIndex(String text) {
      final t = text.toLowerCase();
      if (t.contains('ilk') ||
          t.contains('birinci') ||
          RegExp(r'\b1(\.|\s|$)').hasMatch(t))
        return 0;
      if (t.contains('ikinci') || RegExp(r'\b2(\.|\s|$)').hasMatch(t)) return 1;
      if (t.contains('üçüncü') || RegExp(r'\b3(\.|\s|$)').hasMatch(t)) return 2;
      if (t.contains('dördüncü') || RegExp(r'\b4(\.|\s|$)').hasMatch(t))
        return 3;
      if (t.contains('beşinci') || RegExp(r'\b5(\.|\s|$)').hasMatch(t))
        return 4;
      if (t.contains('altıncı') || RegExp(r'\b6(\.|\s|$)').hasMatch(t))
        return 5;
      if (t.contains('yedinci') || RegExp(r'\b7(\.|\s|$)').hasMatch(t))
        return 6;
      if (t.contains('sekizinci') || RegExp(r'\b8(\.|\s|$)').hasMatch(t))
        return 7;
      if (t.contains('dokuzuncu') || RegExp(r'\b9(\.|\s|$)').hasMatch(t))
        return 8;
      if (t.contains('onuncu') || RegExp(r'\b10(\.|\s|$)').hasMatch(t))
        return 9;
      return null;
    }

    // Helper: extract candidate bullet/content lines from the current note
    List<String> _extractContentLines(String? content) {
      if (content == null || content.trim().isEmpty) return [];
      final allLines = content.split('\n');
      final candidates = <String>[];
      for (final raw in allLines) {
        final line = raw.trim();
        if (line.isEmpty) continue;
        // Prefer bullet/numbered items, but include any non-empty line
        final isBullet =
            line.startsWith('-') ||
            line.startsWith('•') ||
            line.startsWith('*') ||
            RegExp(r'^\d+\.|^\d+\)').hasMatch(line);
        if (isBullet) {
          candidates.add(line);
        }
      }
      // Fallback to all non-empty lines if no bullets were found
      if (candidates.isEmpty) {
        for (final raw in allLines) {
          final line = raw.trim();
          if (line.isNotEmpty) candidates.add(line);
        }
      }
      return candidates;
    }

    // New: delete Nth item (e.g., "birinci maddesini sil", "2. maddeyi kaldır")
    try {
      if ((lowerMessage.contains('madde') ||
              lowerMessage.contains('maddesini') ||
              lowerMessage.contains('maddeyi') ||
              lowerMessage.contains('satır')) &&
          (lowerMessage.contains('sil') || lowerMessage.contains('kaldır'))) {
        final idx = _ordinalToIndex(lowerMessage);
        final lines = _extractContentLines(noteContent);
        if (idx != null && idx >= 0 && idx < lines.length) {
          final target = lines[idx];
          return 'İstediğiniz maddeyi siliyorum. [REMOVE_CONTENT:$target]';
        }
        // If ordinal not found but user asked to remove an item, guide them
        if (lines.isNotEmpty) {
          return 'Hangi maddeyi silmemi istersiniz? Örneğin: "Birinci maddeyi sil"';
        } else {
          return 'Bu notta silinecek bir madde bulamadım.';
        }
      }
    } catch (_) {
      // Fall through to other rules
    }

    // Check if user wants to add content
    if (lowerMessage.contains('ekle') && lowerMessage.contains('içerik')) {
      final words = userMessage.split(' ');
      int addStartIndex = -1;
      for (int i = 0; i < words.length - 1; i++) {
        if (words[i].toLowerCase().contains('ekle') &&
            words[i + 1].toLowerCase().contains('içerik')) {
          addStartIndex = i + 2;
          break;
        }
      }

      if (addStartIndex != -1 && addStartIndex < words.length) {
        final addContent = words.sublist(addStartIndex).join(' ').trim();
        if (addContent.isNotEmpty) {
          return 'İçeriğe "$addContent" ekliyorum. [ADD_CONTENT:$addContent]';
        }
      }
      return 'İçeriğe ne eklemek istiyorsunuz?';
    }

    // Check if user wants to remove content
    if (lowerMessage.contains('sil') && lowerMessage.contains('içerik')) {
      final words = userMessage.split(' ');
      int removeStartIndex = -1;
      for (int i = 0; i < words.length - 1; i++) {
        if (words[i].toLowerCase().contains('sil') &&
            words[i + 1].toLowerCase().contains('içerik')) {
          removeStartIndex = i + 2;
          break;
        }
      }

      if (removeStartIndex != -1 && removeStartIndex < words.length) {
        final removeContent = words.sublist(removeStartIndex).join(' ').trim();
        if (removeContent.isNotEmpty) {
          return 'İçerikten "$removeContent" siliyorum. [REMOVE_CONTENT:$removeContent]';
        }
      }
      return 'İçerikten ne silmek istiyorsunuz?';
    }

    // Check if user wants to rewrite content
    if (lowerMessage.contains('yeniden yaz') ||
        lowerMessage.contains('tekrar yaz')) {
      final words = userMessage.split(' ');
      int rewriteStartIndex = -1;
      for (int i = 0; i < words.length - 1; i++) {
        if ((words[i].toLowerCase().contains('yeniden') &&
                words[i + 1].toLowerCase().contains('yaz')) ||
            (words[i].toLowerCase().contains('tekrar') &&
                words[i + 1].toLowerCase().contains('yaz'))) {
          rewriteStartIndex = i + 2;
          break;
        }
      }

      if (rewriteStartIndex != -1 && rewriteStartIndex < words.length) {
        final rewriteContent = words
            .sublist(rewriteStartIndex)
            .join(' ')
            .trim();
        if (rewriteContent.isNotEmpty) {
          return 'İçeriği yeniden yazıyorum. [REWRITE_CONTENT:$rewriteContent]';
        }
      }
      return 'İçeriği nasıl yeniden yazmak istiyorsunuz?';
    }

    // Check if user wants to add to title
    if (lowerMessage.contains('ekle') && lowerMessage.contains('başlık')) {
      final words = userMessage.split(' ');
      int addTitleStartIndex = -1;
      for (int i = 0; i < words.length - 1; i++) {
        if (words[i].toLowerCase().contains('ekle') &&
            words[i + 1].toLowerCase().contains('başlık')) {
          addTitleStartIndex = i + 2;
          break;
        }
      }

      if (addTitleStartIndex != -1 && addTitleStartIndex < words.length) {
        final addTitle = words.sublist(addTitleStartIndex).join(' ').trim();
        if (addTitle.isNotEmpty) {
          return 'Başlığa "$addTitle" ekliyorum. [ADD_TITLE:$addTitle]';
        }
      }
      return 'Başlığa ne eklemek istiyorsunuz?';
    }

    // Check if user wants to change title
    if (lowerMessage.contains('başlık') &&
        (lowerMessage.contains('değiştir') ||
            lowerMessage.contains('düzenle'))) {
      // Extract new title from message - look for text after "başlık" and "değiştir/düzenle"
      final words = userMessage.split(' ');
      int titleStartIndex = -1;
      for (int i = 0; i < words.length - 1; i++) {
        if (words[i].toLowerCase().contains('başlık') &&
            (words[i + 1].toLowerCase().contains('değiştir') ||
                words[i + 1].toLowerCase().contains('düzenle'))) {
          titleStartIndex = i + 2;
          break;
        }
      }

      if (titleStartIndex != -1 && titleStartIndex < words.length) {
        final newTitle = words.sublist(titleStartIndex).join(' ').trim();
        if (newTitle.isNotEmpty) {
          return 'Başlığı "$newTitle" olarak değiştiriyorum. [EDIT_TITLE:$newTitle]';
        }
      }
      return 'Başlığı nasıl değiştirmek istiyorsunuz? Yeni başlığı söyleyin.';
    }

    // Check if user wants to change content
    if (lowerMessage.contains('içerik') &&
        (lowerMessage.contains('değiştir') ||
            lowerMessage.contains('düzenle'))) {
      // Extract new content from message - look for text after "içerik" and "değiştir/düzenle"
      final words = userMessage.split(' ');
      int contentStartIndex = -1;
      for (int i = 0; i < words.length - 1; i++) {
        if (words[i].toLowerCase().contains('içerik') &&
            (words[i + 1].toLowerCase().contains('değiştir') ||
                words[i + 1].toLowerCase().contains('düzenle'))) {
          contentStartIndex = i + 2;
          break;
        }
      }

      if (contentStartIndex != -1 && contentStartIndex < words.length) {
        final newContent = words.sublist(contentStartIndex).join(' ').trim();
        if (newContent.isNotEmpty) {
          return 'İçeriği değiştiriyorum. [EDIT_CONTENT:$newContent]';
        }
      }
      return 'İçeriği nasıl değiştirmek istiyorsunuz? Yeni içeriği söyleyin.';
    }

    // Check if user is asking about editing/changing the note
    if (lowerMessage.contains('değiştir') ||
        lowerMessage.contains('düzenle') ||
        lowerMessage.contains('ekle') ||
        lowerMessage.contains('sil')) {
      return 'Notunuzu düzenlemek için:\n\n• Başlık değiştirmek: "Başlık değiştir [yeni başlık]"\n• İçerik değiştirmek: "İçerik değiştir [yeni içerik]"\n• İçeriğe ekleme: "İçerik ekle [eklenecek metin]"\n• İçerikten silme: "İçerik sil [silinecek metin]"\n• İçeriği yeniden yazma: "İçerik yeniden yaz [yeni içerik]"\n• Başlığa ekleme: "Başlık ekle [eklenecek kelime]"\n\nNe yapmak istiyorsunuz?';
    }

    // Check if asking about note content
    if (lowerMessage.contains('içerik') ||
        lowerMessage.contains('ne yazıyor')) {
      return 'Bu notun başlığı: "$noteTitle"\n\nİçerik: ${noteContent ?? "Henüz içerik eklenmemiş."}';
    }

    // Check if asking for suggestions
    if (lowerMessage.contains('öner') || lowerMessage.contains('nasıl')) {
      return 'Notunuzu daha iyi hale getirmek için:\n\n• Başlığı açıklayıcı bir şekilde yazın\n• İçeriği bölümler halinde organize edin\n• Önemli noktaları vurgulayın\n• Todo listesi ekleyerek görevleri takip edin';
    }

    // Default response
    return 'Bu not hakkında size nasıl yardımcı olabilirim? Notunuzu düzenlemek, içerik eklemek veya organize etmek konusunda yardımcı olabilirim.';
  }

  void clearMessages() {
    _messages.clear();
    _isLoading = false; // Reset loading state when clearing messages
    notifyListeners();
  }
}
