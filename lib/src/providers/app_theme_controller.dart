import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thanette/src/providers/theme_provider.dart';

enum AccentPalette { green, pink }

class AppThemeController extends ChangeNotifier {
  static const _paletteKey = 'app_theme_palette';

  AccentPalette _palette = AccentPalette.green;
  AccentPalette get palette => _palette;
  bool _isChangingTheme = false;
  bool get isChangingTheme => _isChangingTheme;

  Future<void> setPalette(AccentPalette palette) async {
    if (_palette == palette) return;
    _isChangingTheme = true;
    notifyListeners();
    _palette = palette;
    _applyPalette();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_paletteKey, _palette.name);
    // Delay to allow UI to show a loading overlay while theme rebuilds
    await Future.delayed(const Duration(milliseconds: 500));
    _isChangingTheme = false;
    notifyListeners();
  }

  Future<void> bootstrap() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedPalette = prefs.getString(_paletteKey);
      if (storedPalette != null) {
        for (final value in AccentPalette.values) {
          if (value.name == storedPalette) {
            _palette = value;
            break;
          }
        }
      }
    } catch (_) {
      // ignore storage errors, fall back to defaults
    }
    _applyPalette();
    notifyListeners();
  }

  void _applyPalette() {
    if (_palette == AccentPalette.green) {
      AppTheme.primaryPink = const Color(0xFF4A8F7F);
      AppTheme.secondaryPurple = const Color(0xFF7FB9AC);
      AppTheme.lightPink = const Color(0xFFE6F3EF);
    } else {
      // Refined indigo palette
      AppTheme.primaryPink = const Color.fromARGB(255, 255, 156, 235);
      AppTheme.secondaryPurple = const Color.fromARGB(255, 251, 165, 231);
      AppTheme.lightPink = const Color(0xFFEEF1FF);
    }
  }
}
