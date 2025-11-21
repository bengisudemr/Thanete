import 'package:flutter/material.dart';

class NavigationProvider extends ChangeNotifier {
  final List<String> _navigationHistory = [];
  int _currentIndex = -1;

  List<String> get navigationHistory => _navigationHistory;
  int get currentIndex => _currentIndex;
  bool get canUndo => _currentIndex > 0;
  bool get canRedo => _currentIndex < _navigationHistory.length - 1;

  void push(String route) {
    // Remove any routes after current index (for redo)
    if (_currentIndex < _navigationHistory.length - 1) {
      _navigationHistory.removeRange(
        _currentIndex + 1,
        _navigationHistory.length,
      );
    }

    _navigationHistory.add(route);
    _currentIndex = _navigationHistory.length - 1;

    // Limit history size
    if (_navigationHistory.length > 20) {
      _navigationHistory.removeAt(0);
      _currentIndex--;
    }

    notifyListeners();
  }

  void undo() {
    if (!canUndo) return;
    _currentIndex--;
    notifyListeners();
  }

  void redo() {
    if (!canRedo) return;
    _currentIndex++;
    notifyListeners();
  }

  String? getCurrentRoute() {
    if (_currentIndex >= 0 && _currentIndex < _navigationHistory.length) {
      return _navigationHistory[_currentIndex];
    }
    return null;
  }

  void clear() {
    _navigationHistory.clear();
    _currentIndex = -1;
    notifyListeners();
  }
}
