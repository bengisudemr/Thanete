import 'dart:async';
import 'package:flutter/material.dart';
import 'package:thanette/src/models/file_annotation.dart';
import 'package:thanette/src/models/note_file.dart';
import 'package:thanette/src/services/annotation_service.dart';
import 'package:thanette/src/widgets/enhanced_annotation_toolbar.dart';

class EnhancedAnnotationProvider extends ChangeNotifier {
  final AnnotationService _annotationService = AnnotationService();

  // State variables
  NoteFile? _currentFile;
  FileAnnotation? _currentAnnotation;
  AnnotationTool _currentTool = AnnotationTool.pen;
  ShapeType? _currentShape;
  Color _currentColor = const Color(0xFF374151);
  double _currentStrokeWidth = 2.0;
  bool _isDrawing = false;

  // Drawing data
  List<DrawingStroke> _currentStrokes = [];
  List<DrawingStroke> _allStrokes = [];
  List<TextNote> _textNotes = [];
  String? _activeTextNoteId;
  List<ShapeAnnotation> _shapes = [];

  // History management
  List<AnnotationState> _undoStack = [];
  List<AnnotationState> _redoStack = [];

  // UI state
  bool _isLoading = false;
  String? _error;
  Timer? _autoSaveTimer;

  // Layer management
  List<AnnotationLayer> _layers = [];
  int _activeLayerIndex = 0;

  // Getters
  NoteFile? get currentFile => _currentFile;
  FileAnnotation? get currentAnnotation => _currentAnnotation;
  AnnotationTool get currentTool => _currentTool;
  ShapeType? get currentShape => _currentShape;
  Color get currentColor => _currentColor;
  double get currentStrokeWidth => _currentStrokeWidth;
  bool get isDrawing => _isDrawing;
  List<DrawingStroke> get currentStrokes => _currentStrokes;
  List<DrawingStroke> get allStrokes => _allStrokes;
  List<TextNote> get textNotes => _textNotes;
  String? get activeTextNoteId => _activeTextNoteId;
  List<ShapeAnnotation> get shapes => _shapes;
  List<AnnotationLayer> get layers => _layers;
  int get activeLayerIndex => _activeLayerIndex;
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
        _shapes = _loadShapesFromAnnotation(_currentAnnotation!);
      } else {
        _allStrokes = [];
        _textNotes = [];
        _shapes = [];
      }

      _currentStrokes = [];
      _undoStack = [];
      _redoStack = [];

      // Initialize layers
      _initializeLayers();

      // Start auto-save timer
      _startAutoSave();
    } catch (e) {
      _error = 'Annotation yüklenirken hata: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _initializeLayers() {
    _layers = [
      AnnotationLayer(
        id: 'background',
        name: 'Arka Plan',
        isVisible: true,
        isLocked: false,
        opacity: 1.0,
      ),
      AnnotationLayer(
        id: 'annotations',
        name: 'Notlar',
        isVisible: true,
        isLocked: false,
        opacity: 1.0,
      ),
    ];
    _activeLayerIndex = 1; // Start with annotations layer
  }

  List<ShapeAnnotation> _loadShapesFromAnnotation(FileAnnotation annotation) {
    // Convert old annotation data to new shape format
    // This is a placeholder - implement based on your data structure
    return [];
  }

  // Tool management
  void setTool(AnnotationTool tool) {
    if (_currentTool != tool) {
      _saveCurrentState();
      _currentTool = tool;
      notifyListeners();
    }
  }

  void setShape(ShapeType shape) {
    _currentShape = shape;
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
    if (_currentTool != AnnotationTool.pen &&
        _currentTool != AnnotationTool.highlighter)
      return;

    _isDrawing = true;
    _currentStrokes = [
      DrawingStroke(
        points: [point],
        color: _currentTool == AnnotationTool.highlighter
            ? _currentColor.withOpacity(0.3)
            : _currentColor,
        strokeWidth: _currentTool == AnnotationTool.highlighter
            ? _currentStrokeWidth * 2
            : _currentStrokeWidth,
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
      timestamp: lastStroke.timestamp,
    );
    notifyListeners();
  }

  void endDrawing() {
    if (!_isDrawing || _currentStrokes.isEmpty) return;

    _isDrawing = false;
    _allStrokes.addAll(_currentStrokes);
    _currentStrokes = [];
    _saveCurrentState();
    notifyListeners();
  }

  // Shape drawing
  void startShapeDrawing(Offset startPoint) {
    if (_currentTool != AnnotationTool.shapes || _currentShape == null) return;

    _isDrawing = true;
    notifyListeners();
  }

  void updateShapeDrawing(Offset currentPoint) {
    if (!_isDrawing || _currentTool != AnnotationTool.shapes) return;
    notifyListeners();
  }

  void endShapeDrawing(Offset endPoint) {
    if (!_isDrawing ||
        _currentTool != AnnotationTool.shapes ||
        _currentShape == null)
      return;

    // Create shape annotation based on current shape type
    final shape = ShapeAnnotation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: _currentShape!,
      startPoint: Offset.zero, // Will be set properly
      endPoint: endPoint,
      color: _currentColor,
      strokeWidth: _currentStrokeWidth,
      timestamp: DateTime.now(),
    );

    _shapes.add(shape);
    _isDrawing = false;
    _saveCurrentState();
    notifyListeners();
  }

  // Eraser
  void eraseAtPoint(Offset point) {
    if (_currentTool != AnnotationTool.eraser) return;

    final eraserRadius = _currentStrokeWidth * 2;

    // Remove strokes that intersect with eraser
    _allStrokes.removeWhere((stroke) {
      return stroke.points.any((strokePoint) {
        final distance = (strokePoint - point).distance;
        return distance <= eraserRadius;
      });
    });

    // Remove shapes that intersect with eraser
    _shapes.removeWhere((shape) {
      // Simple intersection check - can be improved
      return _pointInShape(point, shape);
    });

    notifyListeners();
  }

  bool _pointInShape(Offset point, ShapeAnnotation shape) {
    // Simple bounding box check - implement proper shape intersection
    final bounds = Rect.fromPoints(shape.startPoint, shape.endPoint);
    return bounds.contains(point);
  }

  // Text management
  void addTextNote(Offset position) {
    final textNote = TextNote(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: 'Metin notu',
      position: position,
      backgroundColor: Colors.yellow.withOpacity(0.8),
      textColor: Colors.black,
      fontSize: 16.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _textNotes.add(textNote);
    _activeTextNoteId = textNote.id;
    _saveCurrentState();
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

  void updateTextNotePosition(String id, Offset position) {
    final index = _textNotes.indexWhere((note) => note.id == id);
    if (index != -1) {
      _textNotes[index] = _textNotes[index].copyWith(
        position: position,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
    }
  }

  void updateTextNoteTextColor(String id, Color color) {
    final index = _textNotes.indexWhere((note) => note.id == id);
    if (index != -1) {
      _textNotes[index] = _textNotes[index].copyWith(
        textColor: color,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
    }
  }

  void updateTextNoteBackgroundColor(String id, Color color) {
    final index = _textNotes.indexWhere((note) => note.id == id);
    if (index != -1) {
      _textNotes[index] = _textNotes[index].copyWith(
        backgroundColor: color,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
    }
  }

  // Convenience: update the most recently edited/created note
  void setLatestTextNoteTextColor(Color color) {
    if (_textNotes.isEmpty) return;
    // Pick the note with latest updatedAt
    _textNotes.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
    final latest = _textNotes.last;
    updateTextNoteTextColor(latest.id, color);
  }

  void setLatestTextNoteBackgroundColor(Color color) {
    if (_textNotes.isEmpty) return;
    _textNotes.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
    final latest = _textNotes.last;
    updateTextNoteBackgroundColor(latest.id, color);
  }

  void setActiveTextNoteId(String? id) {
    _activeTextNoteId = id;
    notifyListeners();
  }

  // Prefer updating the active note when available
  void setActiveTextNoteTextColor(Color color) {
    if (_activeTextNoteId != null) {
      updateTextNoteTextColor(_activeTextNoteId!, color);
    } else {
      setLatestTextNoteTextColor(color);
    }
  }

  void setActiveTextNoteBackgroundColor(Color color) {
    if (_activeTextNoteId != null) {
      updateTextNoteBackgroundColor(_activeTextNoteId!, color);
    } else {
      setLatestTextNoteBackgroundColor(color);
    }
  }

  void deleteTextNote(String id) {
    _textNotes.removeWhere((note) => note.id == id);
    if (_activeTextNoteId == id) {
      _activeTextNoteId = null;
    }
    _saveCurrentState();
    notifyListeners();
  }

  // History management
  void _saveCurrentState() {
    final state = AnnotationState(
      strokes: List.from(_allStrokes),
      textNotes: List.from(_textNotes),
      shapes: List.from(_shapes),
      timestamp: DateTime.now(),
    );

    _undoStack.add(state);
    _redoStack.clear(); // Clear redo stack when new action is performed

    // Limit undo stack size
    if (_undoStack.length > 50) {
      _undoStack.removeAt(0);
    }
  }

  void undo() {
    if (_undoStack.isEmpty) return;

    // Save current state to redo stack
    final currentState = AnnotationState(
      strokes: List.from(_allStrokes),
      textNotes: List.from(_textNotes),
      shapes: List.from(_shapes),
      timestamp: DateTime.now(),
    );
    _redoStack.add(currentState);

    // Restore previous state
    final previousState = _undoStack.removeLast();
    _allStrokes = List.from(previousState.strokes);
    _textNotes = List.from(previousState.textNotes);
    _shapes = List.from(previousState.shapes);

    notifyListeners();
  }

  void redo() {
    if (_redoStack.isEmpty) return;

    // Save current state to undo stack
    final currentState = AnnotationState(
      strokes: List.from(_allStrokes),
      textNotes: List.from(_textNotes),
      shapes: List.from(_shapes),
      timestamp: DateTime.now(),
    );
    _undoStack.add(currentState);

    // Restore next state
    final nextState = _redoStack.removeLast();
    _allStrokes = List.from(nextState.strokes);
    _textNotes = List.from(nextState.textNotes);
    _shapes = List.from(nextState.shapes);

    notifyListeners();
  }

  // Layer management
  void setActiveLayer(int index) {
    if (index >= 0 && index < _layers.length) {
      _activeLayerIndex = index;
      notifyListeners();
    }
  }

  void toggleLayerVisibility(int index) {
    if (index >= 0 && index < _layers.length) {
      _layers[index] = _layers[index].copyWith(
        isVisible: !_layers[index].isVisible,
      );
      notifyListeners();
    }
  }

  void toggleLayerLock(int index) {
    if (index >= 0 && index < _layers.length) {
      _layers[index] = _layers[index].copyWith(
        isLocked: !_layers[index].isLocked,
      );
      notifyListeners();
    }
  }

  void setLayerOpacity(int index, double opacity) {
    if (index >= 0 && index < _layers.length) {
      _layers[index] = _layers[index].copyWith(
        opacity: opacity.clamp(0.0, 1.0),
      );
      notifyListeners();
    }
  }

  // Actions
  void clearAll() {
    _allStrokes.clear();
    _textNotes.clear();
    _shapes.clear();
    _currentStrokes.clear();
    _saveCurrentState();
    notifyListeners();
  }

  Future<void> saveAnnotation() async {
    if (_currentFile == null) return;

    try {
      final annotation = FileAnnotation(
        id:
            _currentAnnotation?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        fileId: _currentFile!.id,
        userId: 'current_user', // Get from auth
        drawingStrokes: _allStrokes,
        textNotes: _textNotes,
        createdAt: _currentAnnotation?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _annotationService.saveAnnotation(annotation);
      _currentAnnotation = annotation;
    } catch (e) {
      _error = 'Kaydetme hatası: $e';
      notifyListeners();
    }
  }

  Future<void> exportAnnotation() async {
    // Implement export functionality
    // Could export as image, PDF, or other formats
  }

  Future<void> shareAnnotation() async {
    // Implement share functionality
  }

  // Auto-save
  void _startAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_allStrokes.isNotEmpty ||
          _textNotes.isNotEmpty ||
          _shapes.isNotEmpty) {
        saveAnnotation();
      }
    });
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }
}

// Supporting classes
class AnnotationState {
  final List<DrawingStroke> strokes;
  final List<TextNote> textNotes;
  final List<ShapeAnnotation> shapes;
  final DateTime timestamp;

  AnnotationState({
    required this.strokes,
    required this.textNotes,
    required this.shapes,
    required this.timestamp,
  });
}

class ShapeAnnotation {
  final String id;
  final ShapeType type;
  final Offset startPoint;
  final Offset endPoint;
  final Color color;
  final double strokeWidth;
  final DateTime timestamp;

  ShapeAnnotation({
    required this.id,
    required this.type,
    required this.startPoint,
    required this.endPoint,
    required this.color,
    required this.strokeWidth,
    required this.timestamp,
  });

  ShapeAnnotation copyWith({
    String? id,
    ShapeType? type,
    Offset? startPoint,
    Offset? endPoint,
    Color? color,
    double? strokeWidth,
    DateTime? timestamp,
  }) {
    return ShapeAnnotation(
      id: id ?? this.id,
      type: type ?? this.type,
      startPoint: startPoint ?? this.startPoint,
      endPoint: endPoint ?? this.endPoint,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

class AnnotationLayer {
  final String id;
  final String name;
  final bool isVisible;
  final bool isLocked;
  final double opacity;

  AnnotationLayer({
    required this.id,
    required this.name,
    required this.isVisible,
    required this.isLocked,
    required this.opacity,
  });

  AnnotationLayer copyWith({
    String? id,
    String? name,
    bool? isVisible,
    bool? isLocked,
    double? opacity,
  }) {
    return AnnotationLayer(
      id: id ?? this.id,
      name: name ?? this.name,
      isVisible: isVisible ?? this.isVisible,
      isLocked: isLocked ?? this.isLocked,
      opacity: opacity ?? this.opacity,
    );
  }
}
