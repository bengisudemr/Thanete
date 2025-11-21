import 'dart:async';
import 'package:flutter/material.dart';
import 'package:thanette/src/models/file_annotation.dart';
import 'package:thanette/src/models/note_file.dart';
import 'package:thanette/src/services/annotation_service.dart';

enum AnnotationTool { pen, eraser, text, select }

class AnnotationProvider extends ChangeNotifier {
  final AnnotationService _annotationService = AnnotationService();

  // State variables
  NoteFile? _currentFile;
  FileAnnotation? _currentAnnotation;
  AnnotationTool _currentTool = AnnotationTool.pen;
  Color _currentColor = const Color(0xFF374151);
  double _currentStrokeWidth = 2.0;
  bool _isDrawing = false;
  List<DrawingStroke> _currentStrokes = [];
  List<DrawingStroke> _allStrokes = [];
  List<TextNote> _textNotes = [];
  List<Map<String, dynamic>> _undoStack = [];
  List<Map<String, dynamic>> _redoStack = [];
  bool _isLoading = false;
  String? _error;
  Timer? _autoSaveTimer;

  // Getters
  NoteFile? get currentFile => _currentFile;
  FileAnnotation? get currentAnnotation => _currentAnnotation;
  AnnotationTool get currentTool => _currentTool;
  Color get currentColor => _currentColor;
  double get currentStrokeWidth => _currentStrokeWidth;
  bool get isDrawing => _isDrawing;
  List<DrawingStroke> get currentStrokes => _currentStrokes;
  List<DrawingStroke> get allStrokes => _allStrokes;
  List<TextNote> get textNotes => _textNotes;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  // Initialize annotation for a file
  Future<void> initializeAnnotation(NoteFile file) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentFile = file;

      // Load existing annotation or create new one
      _currentAnnotation = await _annotationService.getAnnotation(file.id);

      if (_currentAnnotation != null) {
        _allStrokes = List.from(_currentAnnotation!.drawingStrokes);
        _textNotes = List.from(_currentAnnotation!.textNotes);
      } else {
        _allStrokes = [];
        _textNotes = [];
      }

      _currentStrokes = [];
      _undoStack = [];
      _redoStack = [];

      // Start auto-save timer
      _startAutoSave();
    } catch (e) {
      _error = 'Failed to load annotation: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Tool management
  void setTool(AnnotationTool tool) {
    _currentTool = tool;
    notifyListeners();
  }

  void setColor(Color color) {
    _currentColor = color;
    notifyListeners();
  }

  void setStrokeWidth(double width) {
    _currentStrokeWidth = width;
    notifyListeners();
  }

  // Drawing management
  void startDrawing(Offset point) {
    if (_currentTool != AnnotationTool.pen) return;

    _isDrawing = true;
    _currentStrokes = [
      DrawingStroke(
        points: [point],
        color: _currentColor,
        strokeWidth: _currentStrokeWidth,
        timestamp: DateTime.now(),
      ),
    ];
    notifyListeners();
  }

  void updateDrawing(Offset point) {
    if (!_isDrawing || _currentStrokes.isEmpty) return;

    final lastStroke = _currentStrokes.last;
    _currentStrokes[_currentStrokes.length - 1] = DrawingStroke(
      points: [...lastStroke.points, point],
      color: lastStroke.color,
      strokeWidth: lastStroke.strokeWidth,
      opacity: lastStroke.opacity,
      timestamp: lastStroke.timestamp,
    );
    // Reduce notifyListeners calls for better performance
    // Only notify every 5 points
    if (_currentStrokes.last.points.length % 5 == 0) {
      notifyListeners();
    }
  }

  void endDrawing() {
    if (!_isDrawing) return;

    _isDrawing = false;
    if (_currentStrokes.isNotEmpty) {
      _saveToUndoStack();
      _allStrokes.addAll(_currentStrokes);
      _currentStrokes = [];
      _redoStack.clear();
      // Auto-save after each stroke (async, no loading)
      saveAnnotation().catchError((e) => print('Auto-save error: $e'));
      notifyListeners();
    }
  }

  // Eraser functionality - erase entire strokes
  void eraseAtPoint(Offset point) {
    final eraserRadius = _currentStrokeWidth / 2;
    final strokesToKeep = <DrawingStroke>[];
    final initialStrokeCount = _allStrokes.length;

    for (final stroke in _allStrokes) {
      bool shouldKeepStroke = true;

      // Check if any point in the stroke is close to the eraser point
      for (final pathPoint in stroke.points) {
        final distance = (pathPoint - point).distance;
        if (distance <= eraserRadius) {
          // This stroke is touched by the eraser, remove it completely
          shouldKeepStroke = false;
          break;
        }
      }

      // Only keep strokes that weren't touched
      if (shouldKeepStroke) {
        strokesToKeep.add(stroke);
      }
    }

    // Only update if strokes were actually removed
    if (strokesToKeep.length != initialStrokeCount) {
      _saveToUndoStack();
      _allStrokes = strokesToKeep;
      _redoStack.clear();
      print('Erased strokes. Remaining strokes: ${strokesToKeep.length}');
      // Auto-save after erasing
      saveAnnotation().catchError((e) => print('Auto-save error: $e'));
      notifyListeners();
    }
  }

  // Text note management
  void addTextNote(Offset position) {
    if (_currentTool != AnnotationTool.text) return;

    final textNote = TextNote(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: '',
      position: position,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _saveToUndoStack();
    _textNotes.add(textNote);
    _redoStack.clear();
    notifyListeners();
  }

  void updateTextNote(String id, String text) {
    final index = _textNotes.indexWhere((note) => note.id == id);
    if (index != -1) {
      _textNotes[index] = _textNotes[index].copyWith(
        text: text,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
    }
  }

  void deleteTextNote(String id) {
    _saveToUndoStack();
    _textNotes.removeWhere((note) => note.id == id);
    _redoStack.clear();
    notifyListeners();
  }

  // Undo/Redo
  void _saveToUndoStack() {
    _undoStack.add({
      'strokes': _allStrokes.map((s) => s.toJson()).toList(),
      'textNotes': _textNotes.map((t) => t.toJson()).toList(),
    });

    // Limit undo stack size
    if (_undoStack.length > 50) {
      _undoStack.removeAt(0);
    }
  }

  void undo() {
    if (_undoStack.isEmpty) return;

    _redoStack.add({
      'strokes': _allStrokes.map((s) => s.toJson()).toList(),
      'textNotes': _textNotes.map((t) => t.toJson()).toList(),
    });

    final previousState = _undoStack.removeLast();
    _allStrokes = (previousState['strokes'] as List)
        .map((s) => DrawingStroke.fromJson(s as Map<String, dynamic>))
        .toList();
    _textNotes = (previousState['textNotes'] as List)
        .map((t) => TextNote.fromJson(t as Map<String, dynamic>))
        .toList();

    notifyListeners();
  }

  void redo() {
    if (_redoStack.isEmpty) return;

    _undoStack.add({
      'strokes': _allStrokes.map((s) => s.toJson()).toList(),
      'textNotes': _textNotes.map((t) => t.toJson()).toList(),
    });

    final nextState = _redoStack.removeLast();
    _allStrokes = (nextState['strokes'] as List)
        .map((s) => DrawingStroke.fromJson(s as Map<String, dynamic>))
        .toList();
    _textNotes = (nextState['textNotes'] as List)
        .map((t) => TextNote.fromJson(t as Map<String, dynamic>))
        .toList();

    notifyListeners();
  }

  // Auto-save
  void _startAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _saveAnnotation();
    });
  }

  Future<void> _saveAnnotation() async {
    if (_currentFile == null) return;

    try {
      final annotation = FileAnnotation(
        id:
            _currentAnnotation?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        fileId: _currentFile!.id,
        userId: _currentFile!.userId,
        drawingStrokes: _allStrokes,
        textNotes: _textNotes,
        createdAt: _currentAnnotation?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _annotationService.saveAnnotation(annotation);
      _currentAnnotation = annotation;
    } catch (e) {
      print('Auto-save failed: $e');
    }
  }

  // Manual save
  Future<void> saveAnnotation() async {
    if (_currentFile == null) return;

    try {
      await _saveAnnotation();
    } catch (e) {
      _error = 'Failed to save annotation: $e';
      notifyListeners();
    }
  }

  // Clear all annotations
  void clearAll() {
    _saveToUndoStack();
    _allStrokes.clear();
    _textNotes.clear();
    _currentStrokes.clear();
    _redoStack.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }
}
