import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:thanette/src/models/note.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thanette/src/models/drawing.dart';
import 'package:thanette/src/providers/supabase_service.dart';

class NotesProvider extends ChangeNotifier {
  final List<NoteModel> _all = [];
  final List<NoteModel> _visible = [];
  static const int _pageSize = 8;
  bool _isLoading = false;
  bool _hasMore = true;
  String _searchQuery = '';
  RealtimeChannel? _notesChannel;

  List<NoteModel> get items => List.unmodifiable(_visible);
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String get searchQuery => _searchQuery;

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
      final notes = await SupabaseService.instance.getNotes();

      _all.clear();
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

        _all.add(
          NoteModel(
            id: (n['id'] ?? '').toString(),
            title: (n['title'] ?? 'untitled').toString(),
            body: (n['content'] ?? '').toString(),
            color: noteColor,
            isPinned: n['is_pinned'] == true,
          ),
        );
      }

      // Sort notes: pinned notes first, then by creation order
      _all.sort((a, b) {
        // Pinned notes always come first
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;

        // For same pin status, maintain creation order (newer first)
        return 0;
      });

      _visible.clear();
      final end = min(_pageSize, _all.length);
      _visible.addAll(_all.sublist(0, end));
      _hasMore = end < _all.length;
    } catch (_) {
      // On error, avoid stuck loader
      _visible.clear();
      _hasMore = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void loadNextPage() {
    if (_isLoading || !_hasMore) return;
    _isLoading = true;
    final start = _visible.length;
    final end = min(start + _pageSize, _all.length);
    _visible.addAll(_all.sublist(start, end));
    _hasMore = end < _all.length;
    _isLoading = false;
    notifyListeners();
  }

  // Legacy local create (kept if UI calls it). Does NOT persist.
  String createNote() {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final colorPool = const [
      Color(0xFF7B61FF),
      Color(0xFFFFD166),
      Color(0xFF6EE7B7),
      Color(0xFF111827),
    ];
    final note = NoteModel(
      id: id,
      title: '',
      body: '',
      color: colorPool[DateTime.now().millisecond % colorPool.length],
    );
    _all.insert(0, note);
    _visible.insert(0, note);
    notifyListeners();
    return id;
  }

  // New: Persisted create that inserts to Supabase and returns new id.
  Future<String> createNoteRemote({String title = '', String body = ''}) async {
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
    final inserted = await SupabaseService.instance.addNote(finalTitle, body);
    final id = (inserted['id'] ?? '').toString();

    final note = NoteModel(
      id: id,
      title: finalTitle,
      body: body,
      color: colorPool[DateTime.now().millisecond % colorPool.length],
    );

    _all.insert(0, note);
    _visible.insert(0, note);
    notifyListeners();
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
  }) {
    final index = _all.indexWhere((n) => n.id == id);
    if (index == -1) return;
    _all[index].title = title.isEmpty ? 'untitled' : title;
    _all[index].body = body;
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
  }) async {
    // Ensure we don't save empty titles to database
    final finalTitle = title.trim().isEmpty ? 'untitled' : title.trim();
    await SupabaseService.instance.updateNote(id, finalTitle, body);
    updateNote(id: id, title: finalTitle, body: body);
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

    // Reorder notes: pinned notes first, then by creation order
    _all.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return 0; // Keep original order for same pin status
    });

    // Update visible list
    _visible.clear();
    final end = min(_pageSize, _all.length);
    _visible.addAll(_all.sublist(0, end));
    _hasMore = end < _all.length;

    notifyListeners();
  }

  Future<void> togglePinRemote(String id) async {
    final index = _all.indexWhere((n) => n.id == id);
    if (index == -1) return;

    final newPinState = !_all[index].isPinned;

    try {
      await SupabaseService.instance.updateNotePin(id, newPinState);
      _all[index].isPinned = newPinState;

      // Reorder notes: pinned notes first, then by creation order
      _all.sort((a, b) {
        // Pinned notes always come first
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;

        // For same pin status, maintain creation order (newer first)
        return 0;
      });

      // Update visible list
      _visible.clear();
      final end = min(_pageSize, _all.length);
      _visible.addAll(_all.sublist(0, end));
      _hasMore = end < _all.length;

      notifyListeners();
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

    // Update visible list
    _visible.clear();
    final end = min(_pageSize, _all.length);
    _visible.addAll(_all.sublist(0, end));
    _hasMore = end < _all.length;

    notifyListeners();
  }

  void addAttachmentToNote(String noteId, NoteAttachment attachment) {
    final index = _all.indexWhere((n) => n.id == noteId);
    if (index != -1) {
      _all[index].addAttachment(attachment);
      final vIndex = _visible.indexWhere((n) => n.id == noteId);
      if (vIndex != -1) {
        _visible[vIndex] = _all[index];
      }
      notifyListeners();
    }
  }

  void removeAttachmentFromNote(String noteId, String attachmentId) {
    final index = _all.indexWhere((n) => n.id == noteId);
    if (index != -1) {
      _all[index].removeAttachment(attachmentId);
      final vIndex = _visible.indexWhere((n) => n.id == noteId);
      if (vIndex != -1) {
        _visible[vIndex] = _all[index];
      }
      notifyListeners();
    }
  }

  void updateNoteDrawing(String noteId, DrawingData? drawingData) {
    final index = _all.indexWhere((n) => n.id == noteId);
    if (index != -1) {
      _all[index].updateDrawing(drawingData);
      final vIndex = _visible.indexWhere((n) => n.id == noteId);
      if (vIndex != -1) {
        _visible[vIndex] = _all[index];
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
    _visible.clear();

    if (_searchQuery.isEmpty) {
      // If search is empty, show all notes with pagination
      final end = min(_pageSize, _all.length);
      _visible.addAll(_all.sublist(0, end));
      _hasMore = end < _all.length;
    } else {
      // Filter notes by title containing the search query
      final filteredNotes = _all.where((note) {
        return note.title.toLowerCase().contains(_searchQuery);
      }).toList();

      // Sort filtered notes: pinned notes first
      filteredNotes.sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return 0;
      });

      _visible.addAll(filteredNotes);
      _hasMore = false; // No pagination for search results
    }

    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _visible.clear();
    final end = min(_pageSize, _all.length);
    _visible.addAll(_all.sublist(0, end));
    _hasMore = end < _all.length;
    notifyListeners();
  }
}
