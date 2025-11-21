import 'dart:math';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:thanette/src/models/note.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thanette/src/models/drawing.dart';
import 'package:thanette/src/providers/supabase_service.dart';
import 'package:thanette/src/widgets/todo_list_widget.dart';

class NotesProvider extends ChangeNotifier {
  final List<NoteModel> _all = [];
  final List<NoteModel> _visible = [];
  static const int _pageSize = 8;
  bool _isLoading = false;
  bool _hasMore = true;
  String _searchQuery = '';
  String _activeCategory = 'all';
  final Set<String> _knownCategories = {
    'general',
    'personal',
    'ideas',
    'study',
  };
  RealtimeChannel? _notesChannel;

  String _normalizeCategory(String? value) {
    final raw = (value ?? '').trim().toLowerCase();
    if (raw.isEmpty) return 'general';
    final collapsed = raw.replaceAll(RegExp(r'\s+'), '_');
    switch (collapsed) {
      case 'all':
        return 'all';
      case 'kişisel':
      case 'kisisel':
      case 'personal':
        return 'personal';
      case 'iş':
      case 'is':
      case 'work':
        return 'iş';
      case 'genel':
      case 'general':
        return 'general';
      case 'fikir':
      case 'ideas':
        return 'ideas';
      case 'çalışma':
      case 'calisma':
      case 'study':
        return 'study';
      default:
        return collapsed;
    }
  }

  String canonicalizeCategory(String value) => _normalizeCategory(value);

  List<NoteModel> get items => List.unmodifiable(_visible);
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String get searchQuery => _searchQuery;
  String get activeCategory => _activeCategory;
  List<String> get categories {
    final sorted =
        _knownCategories.where((c) => c != 'all' && c.isNotEmpty).toList()
          ..sort();
    sorted.removeWhere((c) => c == 'personal' || c == 'general');
    final result = <String>['all'];
    if (_knownCategories.contains('personal')) {
      result.add('personal');
    }
    if (_knownCategories.contains('general')) {
      result.add('general');
    }
    result.addAll(sorted);
    return result;
  }

  String categoryLabel(String value) {
    switch (value) {
      case 'all':
        return 'Tümü';
      case 'general':
        return 'Genel';
      case 'personal':
        return 'Kişisel';
      case 'iş':
        return 'İş';
      case 'ideas':
        return 'Fikir';
      case 'study':
        return 'Çalışma';
      default:
        final sanitized = value.replaceAll('_', ' ').trim();
        if (sanitized.isEmpty) return 'Genel';
        final words = sanitized.split(' ').where((word) => word.isNotEmpty);
        return words
            .map(
              (word) =>
                  word[0].toUpperCase() +
                  (word.length > 1 ? word.substring(1) : ''),
            )
            .join(' ');
    }
  }

  Future<void> bootstrap() async {
    await loadFromSupabase();

    // Refresh on auth state changes (login/logout)
    Supabase.instance.client.auth.onAuthStateChange.listen((event) async {
      await loadFromSupabase();
    });

    // Subscribe to realtime changes for current user notes
    _subscribeRealtime();
  }

  void _subscribeRealtime() {
    try {
      _notesChannel?.unsubscribe();
      _notesChannel = SupabaseService.instance.subscribeToNotes((
        payload,
      ) async {
        // Any insert/update/delete → refresh list
        await loadFromSupabase();
      });
    } catch (_) {}
  }

  Future<void> loadFromSupabase() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      // Check authentication first
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        // User not authenticated, clear notes and return
        _all.clear();
        _visible.clear();
        _hasMore = false;
        _isLoading = false;
        notifyListeners();
        return;
      }

      final notes = await SupabaseService.instance.getNotes();

      _all.clear();
      _knownCategories
        ..clear()
        ..addAll({'general', 'personal', 'ideas', 'study'});
      // deterministic color pool
      final seedColors = const [
        Color(0xFF7B61FF),
        Color(0xFFFFD166),
        Color(0xFF6EE7B7),
        Color(0xFF111827),
      ];

      for (int i = 0; i < notes.length; i++) {
        final n = notes[i];
        // Get color from database or use default
        Color noteColor = seedColors[i % seedColors.length];
        if (n.containsKey('color') && n['color'] != null) {
          try {
            noteColor = Color(n['color'] as int);
          } catch (e) {
            // If color parsing fails, use default
            noteColor = seedColors[i % seedColors.length];
          }
        }

        final category = _normalizeCategory(
          (n['category'] ?? 'general').toString(),
        );
        if (category != 'all') {
          _knownCategories.add(category);
        }

        // Parse attachments if they exist
        List<NoteAttachment> attachments = [];
        if (n['attachments'] != null &&
            n['attachments'].toString().isNotEmpty) {
          try {
            print(
              'Parsing attachments for note ${n['id']}: ${n['attachments']}',
            );
            final attachmentsJson =
                jsonDecode(n['attachments'].toString()) as List;
            attachments = attachmentsJson
                .map(
                  (attJson) => NoteAttachment(
                    id: attJson['id'],
                    name: attJson['name'],
                    path: attJson['path'],
                    type: AttachmentType.values[attJson['type']],
                    size: attJson['size'],
                    createdAt: DateTime.parse(attJson['createdAt']),
                  ),
                )
                .toList();
            print('Successfully parsed ${attachments.length} attachments');
          } catch (e) {
            print('Attachment parsing error for note ${n['id']}: $e');
            // Attachment parsing error - continue without attachments
          }
        } else {
          print('No attachments found for note ${n['id']}');
        }

        // Parse drawing data if it exists
        DrawingData? drawingData;
        if (n['drawing_data'] != null &&
            n['drawing_data'].toString().isNotEmpty) {
          try {
            drawingData = DrawingData.fromJson(
              jsonDecode(n['drawing_data'].toString()),
            );
          } catch (e) {
            // Drawing data parsing error - continue without drawing
          }
        }

        // Parse todos if they exist
        List<TodoItem> todos = [];
        if (n['todos'] != null && n['todos'].toString().isNotEmpty) {
          try {
            final todosJson = jsonDecode(n['todos'].toString()) as List;
            todos = todosJson
                .map(
                  (todoJson) => TodoItem(
                    id: todoJson['id'],
                    text: todoJson['text'],
                    isCompleted: todoJson['isCompleted'] ?? false,
                    createdAt: DateTime.parse(todoJson['createdAt']),
                  ),
                )
                .toList();
          } catch (e) {
            // Todo parsing error - continue without todos
          }
        }

        final note = NoteModel(
          id: (n['id'] ?? '').toString(),
          title: (n['title'] ?? 'untitled').toString(),
          body: (n['content'] ?? '').toString(),
          color: noteColor,
          isPinned: n['is_pinned'] == true,
          category: category,
          attachments: attachments,
          drawingData: drawingData,
          todos: todos,
        );

        // Set apple drawing data if it exists
        if (n['apple_drawing_data'] != null &&
            n['apple_drawing_data'].toString().isNotEmpty) {
          note.appleDrawingData = n['apple_drawing_data'].toString();
        }

        _all.add(note);
      }

      _sortPinnedFirst(_all);
      _applyFilters();
    } catch (_) {
      // On error, avoid stuck loader
      _visible.clear();
      _hasMore = false;
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void loadNextPage() {
    if (_isLoading || !_hasMore) return;
    if (_searchQuery.isNotEmpty || _activeCategory != 'all') return;
    _isLoading = true;
    final start = _visible.length;
    final end = min(start + _pageSize, _all.length);
    final additional = _all.sublist(start, end);
    _visible.addAll(additional);
    _hasMore = end < _all.length;
    _isLoading = false;
    notifyListeners();
  }

  // Legacy local create (kept if UI calls it). Does NOT persist.
  String createNote({String category = 'general'}) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final colorPool = const [
      Color(0xFF7B61FF),
      Color(0xFFFFD166),
      Color(0xFF6EE7B7),
      Color(0xFF111827),
    ];
    final normalizedCategory = _normalizeCategory(category);

    final note = NoteModel(
      id: id,
      title: '',
      body: '',
      color: colorPool[DateTime.now().millisecond % colorPool.length],
      category: normalizedCategory,
    );
    _all.insert(0, note);
    if (normalizedCategory != 'all') {
      _knownCategories.add(normalizedCategory);
    }
    _applyFilters();
    return id;
  }

  // New: Persisted create that inserts to Supabase and returns new id.
  Future<String> createNoteRemote({
    String title = '',
    String body = '',
    String category = 'general',
  }) async {
    final colorPool = const [
      Color(0xFF7B61FF),
      Color(0xFFFFD166),
      Color(0xFF6EE7B7),
      Color(0xFF111827),
    ];

    // Don't save if both title and body are empty
    if (title.trim().isEmpty && body.trim().isEmpty) {
      throw Exception('Cannot create empty note');
    }

    // Ensure we don't save empty titles to database
    final finalTitle = title.trim().isEmpty ? 'Başlıksız Not' : title.trim();
    final normalizedCategory = _normalizeCategory(category);

    final inserted = await SupabaseService.instance.addNote(
      finalTitle,
      body,
      category: normalizedCategory,
    );
    final id = (inserted['id'] ?? '').toString();

    final note = NoteModel(
      id: id,
      title: finalTitle,
      body: body,
      color: colorPool[DateTime.now().millisecond % colorPool.length],
      category: normalizedCategory,
    );

    _all.insert(0, note);
    if (note.category != 'all') {
      _knownCategories.add(note.category);
    }
    _applyFilters();
    return id;
  }

  NoteModel? getById(String id) {
    try {
      return _all.firstWhere((n) => n.id == id);
    } catch (_) {
      return null;
    }
  }

  void updateNote({
    required String id,
    required String title,
    required String body,
    List<TodoItem>? todos,
  }) {
    final index = _all.indexWhere((n) => n.id == id);
    if (index == -1) return;
    _all[index].title = title.isEmpty ? 'untitled' : title;
    _all[index].body = body;
    if (todos != null) {
      _all[index].todos = todos;
    }
    final vIndex = _visible.indexWhere((n) => n.id == id);
    if (vIndex != -1) {
      _visible[vIndex] = _all[index];
    }
    notifyListeners();
  }

  Future<void> updateNoteRemote({
    required String id,
    required String title,
    required String body,
    List<TodoItem>? todos,
    String? category,
  }) async {
    // Ensure we don't save empty titles to database
    final finalTitle = title.trim().isEmpty ? 'untitled' : title.trim();
    final normalizedCategory = category != null
        ? _normalizeCategory(category)
        : null;

    await SupabaseService.instance.updateNote(
      id,
      finalTitle,
      body,
      category: normalizedCategory,
    );
    if (todos != null) {
      try {
        final todosJson = todos
            .map(
              (todo) => {
                'id': todo.id,
                'text': todo.text,
                'isCompleted': todo.isCompleted,
                'createdAt': todo.createdAt.toIso8601String(),
              },
            )
            .toList();
        await SupabaseService.instance.updateNoteTodos(
          id,
          jsonEncode(todosJson),
        );
      } catch (e) {
        // ignore
      }
    }
    if (normalizedCategory != null) {
      setNoteCategoryLocal(id, normalizedCategory, notify: false);
    }
    updateNote(id: id, title: finalTitle, body: body, todos: todos);
  }

  void updateNoteColor({required String id, required Color color}) {
    final index = _all.indexWhere((n) => n.id == id);
    if (index == -1) return;
    _all[index].color = color;
    final vIndex = _visible.indexWhere((n) => n.id == id);
    if (vIndex != -1) {
      _visible[vIndex] = _all[index];
    }
    notifyListeners();
  }

  Future<void> updateNoteColorRemote({
    required String id,
    required Color color,
  }) async {
    try {
      await SupabaseService.instance.updateNoteColor(id, color);
      updateNoteColor(id: id, color: color);
    } catch (e) {
      // If database update fails (e.g., column doesn't exist), still update locally
      print('Warning: Could not save color to database: $e');
      updateNoteColor(id: id, color: color);
    }
  }

  void togglePin(String id) {
    final index = _all.indexWhere((n) => n.id == id);
    if (index == -1) return;
    _all[index].isPinned = !_all[index].isPinned;

    _sortPinnedFirst(_all);
    _applyFilters();
  }

  Future<void> togglePinRemote(String id) async {
    final index = _all.indexWhere((n) => n.id == id);
    if (index == -1) return;

    final newPinState = !_all[index].isPinned;

    try {
      await SupabaseService.instance.updateNotePin(id, newPinState);
      _all[index].isPinned = newPinState;
      _sortPinnedFirst(_all);
      _applyFilters();
    } catch (e) {
      // If database update fails, still update locally
      print('Warning: Could not save pin state to database: $e');
      togglePin(id);
    }
  }

  void reorderNotes(int oldIndex, int newIndex) {
    // Pinlenmiş notlar sıralanamaz
    if (_all[oldIndex].isPinned) return;

    // Yeni index'i pinlenmiş notların sayısına göre ayarla
    final pinnedCount = _all.where((note) => note.isPinned).length;
    if (newIndex < pinnedCount) {
      newIndex = pinnedCount;
    }

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    // Move in all list
    final item = _all.removeAt(oldIndex);
    _all.insert(newIndex, item);

    _applyFilters();
  }

  void reorderNotesLocally(int oldIndex, int newIndex) {
    // Reorder without database update for immediate feedback
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final item = _all.removeAt(oldIndex);
    _all.insert(newIndex, item);

    _applyFilters();
  }

  Future<void> addAttachmentToNote(
    String noteId,
    NoteAttachment attachment,
  ) async {
    print('NotesProvider: Adding attachment to note $noteId');
    final index = _all.indexWhere((n) => n.id == noteId);
    if (index != -1) {
      print('NotesProvider: Found note at index $index');
      _all[index].addAttachment(attachment);
      print(
        'NotesProvider: Attachment added to note. Total attachments: ${_all[index].attachments.length}',
      );

      final vIndex = _visible.indexWhere((n) => n.id == noteId);
      if (vIndex != -1) {
        _visible[vIndex] = _all[index];
        print('NotesProvider: Updated visible note at index $vIndex');
      }

      // Save attachments to Supabase
      try {
        final attachmentsJson = _all[index].attachments
            .map(
              (att) => {
                'id': att.id,
                'name': att.name,
                'path': att.path,
                'type': att.type.index,
                'size': att.size,
                'createdAt': att.createdAt.toIso8601String(),
              },
            )
            .toList();
        final attachmentsString = jsonEncode(attachmentsJson);
        print(
          'NotesProvider: Saving attachments to Supabase: $attachmentsString',
        );

        await SupabaseService.instance.updateNoteAttachments(
          noteId,
          attachmentsString,
        );
        print('NotesProvider: Attachments saved to Supabase successfully');
      } catch (e) {
        print('NotesProvider: Error saving attachments to Supabase: $e');
        // Attachment save error - continue
      }

      notifyListeners();
      print('NotesProvider: Notified listeners');
    } else {
      print('NotesProvider: Note not found with ID: $noteId');
    }
  }

  Future<void> removeAttachmentFromNote(
    String noteId,
    String attachmentId,
  ) async {
    final index = _all.indexWhere((n) => n.id == noteId);
    if (index != -1) {
      _all[index].removeAttachment(attachmentId);
      final vIndex = _visible.indexWhere((n) => n.id == noteId);
      if (vIndex != -1) {
        _visible[vIndex] = _all[index];
      }

      // Update attachments in Supabase
      try {
        final attachmentsJson = _all[index].attachments
            .map(
              (att) => {
                'id': att.id,
                'name': att.name,
                'path': att.path,
                'type': att.type.index,
                'size': att.size,
                'createdAt': att.createdAt.toIso8601String(),
              },
            )
            .toList();
        final attachmentsString = jsonEncode(attachmentsJson);
        await SupabaseService.instance.updateNoteAttachments(
          noteId,
          attachmentsString,
        );
      } catch (e) {
        // Attachment delete error - continue
      }

      notifyListeners();
    }
  }

  Future<void> updateNoteDrawing(
    String noteId,
    DrawingData? drawingData,
  ) async {
    final index = _all.indexWhere((n) => n.id == noteId);
    if (index != -1) {
      _all[index].updateDrawing(drawingData);
      final vIndex = _visible.indexWhere((n) => n.id == noteId);
      if (vIndex != -1) {
        _visible[vIndex] = _all[index];
      }

      // Save drawing data to Supabase
      try {
        final drawingString = drawingData != null
            ? jsonEncode(drawingData.toJson())
            : '';
        print('Updating note drawing in Supabase for note: $noteId');
        print('Drawing data string length: ${drawingString.length}');
        await SupabaseService.instance.updateNoteDrawing(noteId, drawingString);
        print('Drawing data updated successfully in Supabase');
      } catch (e) {
        print('Drawing save error: $e');
        // Drawing save error - continue
      }

      notifyListeners();
    }
  }

  Future<void> updateNoteTodos(String noteId, List<TodoItem> todos) async {
    final index = _all.indexWhere((n) => n.id == noteId);
    if (index != -1) {
      _all[index].todos = todos;
      final vIndex = _visible.indexWhere((n) => n.id == noteId);
      if (vIndex != -1) {
        _visible[vIndex] = _all[index];
      }

      // Save todos to Supabase
      try {
        final todosJson = todos
            .map(
              (todo) => {
                'id': todo.id,
                'text': todo.text,
                'isCompleted': todo.isCompleted,
                'createdAt': todo.createdAt.toIso8601String(),
              },
            )
            .toList();
        await SupabaseService.instance.updateNoteTodos(
          noteId,
          jsonEncode(todosJson),
        );
        print('Todos updated successfully in Supabase');
      } catch (e) {
        print('Todos save error: $e');
        // Todos save error - continue
      }

      notifyListeners();
    }
  }

  Future<void> updateNoteAppleDrawing(
    String noteId,
    String appleDrawingData,
  ) async {
    final index = _all.indexWhere((n) => n.id == noteId);
    if (index != -1) {
      _all[index].updateAppleDrawing(appleDrawingData);
      final vIndex = _visible.indexWhere((n) => n.id == noteId);
      if (vIndex != -1) {
        _visible[vIndex] = _all[index];
      }

      // Save apple drawing data to Supabase
      try {
        await SupabaseService.instance.updateNoteAppleDrawing(
          noteId,
          appleDrawingData,
        );
      } catch (e) {
        // Apple drawing save error - continue
      }

      notifyListeners();
    }
  }

  void deleteNote(String id) {
    _all.removeWhere((n) => n.id == id);
    _visible.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  Future<void> deleteNoteRemote(String id) async {
    await SupabaseService.instance.deleteNote(id);
    deleteNote(id);
    // optional: refetch to ensure pagination counts
    await loadFromSupabase();
  }

  void searchNotes(String query) {
    _searchQuery = query.toLowerCase().trim();
    _applyFilters();
  }

  void clearSearch() {
    _searchQuery = '';
    _applyFilters();
  }

  void setCategoryFilter(String category) {
    final normalized = _normalizeCategory(category);
    if (_activeCategory == normalized) return;
    _activeCategory = normalized;
    _applyFilters();
  }

  void setNoteCategoryLocal(String id, String category, {bool notify = true}) {
    final normalized = _normalizeCategory(category);
    if (normalized == 'all') return;
    final index = _all.indexWhere((n) => n.id == id);
    if (index == -1) return;
    _all[index].category = normalized;
    _knownCategories.add(normalized);
    final vIndex = _visible.indexWhere((n) => n.id == id);
    if (vIndex != -1) {
      _visible[vIndex] = _all[index];
    }
    if (notify) {
      _applyFilters();
    }
  }

  Future<void> setNoteCategoryRemote(String id, String category) async {
    final note = getById(id);
    if (note == null) return;
    final previous = note.category;
    final normalized = _normalizeCategory(category);
    setNoteCategoryLocal(id, normalized, notify: false);
    try {
      await SupabaseService.instance.updateNoteCategory(id, normalized);
      _applyFilters();
    } catch (e) {
      setNoteCategoryLocal(id, previous, notify: false);
      _applyFilters();
    }
  }

  bool _matchesSearch(NoteModel note) {
    if (_searchQuery.isEmpty) return true;
    final titleMatch = note.title.toLowerCase().contains(_searchQuery);

    String bodyText = '';
    if (note.body.isNotEmpty) {
      try {
        final bodyJson = jsonDecode(note.body);
        if (bodyJson is Map && bodyJson.containsKey('ops')) {
          final ops = bodyJson['ops'] as List?;
          if (ops != null) {
            bodyText = ops
                .where((op) => op is Map && op.containsKey('insert'))
                .map((op) {
                  final insert = op['insert'];
                  if (insert is String) {
                    return insert;
                  }
                  return '';
                })
                .join(' ')
                .toLowerCase();
          }
        } else {
          bodyText = note.body.toLowerCase();
        }
      } catch (e) {
        bodyText = note.body.toLowerCase();
      }
    }

    return titleMatch || bodyText.contains(_searchQuery);
  }

  void _applyFilters() {
    List<NoteModel> filtered = _all.toList();

    if (_activeCategory != 'all') {
      filtered = filtered
          .where((note) => note.category == _activeCategory)
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where(_matchesSearch).toList();
    }

    _sortPinnedFirst(filtered);

    _visible.clear();

    if (_searchQuery.isEmpty && _activeCategory == 'all') {
      final end = min(_pageSize, filtered.length);
      _visible.addAll(filtered.take(end));
      _hasMore = end < filtered.length;
    } else {
      _visible.addAll(filtered);
      _hasMore = false;
    }

    notifyListeners();
  }

  void _sortPinnedFirst(List<NoteModel> notes) {
    notes.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return 0;
    });
  }

  Future<void> renameAttachment(
    String noteId,
    String attachmentId,
    String newName,
  ) async {
    final note = getById(noteId);
    if (note == null) return;

    final attachmentIndex = note.attachments.indexWhere(
      (a) => a.id == attachmentId,
    );
    if (attachmentIndex == -1) return;

    // Create updated attachment
    final oldAttachment = note.attachments[attachmentIndex];
    final updatedAttachment = NoteAttachment(
      id: oldAttachment.id,
      name: newName,
      path: oldAttachment.path,
      type: oldAttachment.type,
      size: oldAttachment.size,
      createdAt: oldAttachment.createdAt,
    );

    // Update local list
    final updatedAttachments = List<NoteAttachment>.from(note.attachments);
    updatedAttachments[attachmentIndex] = updatedAttachment;

    final updatedNote = note.copyWith(attachments: updatedAttachments);

    // Update in local lists
    final noteIndex = _all.indexWhere((n) => n.id == noteId);
    if (noteIndex != -1) {
      _all[noteIndex] = updatedNote;
    }

    final visibleIndex = _visible.indexWhere((n) => n.id == noteId);
    if (visibleIndex != -1) {
      _visible[visibleIndex] = updatedNote;
    }

    // Update in Supabase
    final attachmentsJson = updatedAttachments
        .map(
          (att) => {
            'id': att.id,
            'name': att.name,
            'path': att.path,
            'type': att.type.index,
            'size': att.size,
            'createdAt': att.createdAt.toIso8601String(),
          },
        )
        .toList();
    final attachmentsString = jsonEncode(attachmentsJson);
    await SupabaseService.instance.updateNoteAttachments(
      noteId,
      attachmentsString,
    );

    notifyListeners();
  }
}
