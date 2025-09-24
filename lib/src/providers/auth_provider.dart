import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thanette/src/providers/supabase_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _loggedIn = false;
  String? _email;
  static const String _defaultPassword = 'thanette-default-password';

  bool get isLoggedIn => _loggedIn;
  String? get email => _email;

  // Passwordless login/register: sends magic link to email
  Future<void> requestMagicLink(String email) async {
    await Supabase.instance.client.auth.signInWithOtp(
      email: email,
      emailRedirectTo: 'io.supabase.flutter://login-callback/',
    );
    _email = email;
    notifyListeners();
  }

  // Keep for compatibility in other parts (not used by UI now)
  Future<void> loginWithPassword(String email, String password) async {
    await SupabaseService.instance.signIn(email, password);
    _email = email;
    _loggedIn = true;
    notifyListeners();
  }

  Future<void> register(String email, String password) async {
    await SupabaseService.instance.signUp(email, password);
    _email = email;
    notifyListeners();
  }

  // Email-only quick flow: create if needed, then sign in immediately
  Future<void> loginOrRegisterWithEmailOnly(
    String email, {
    String? name,
  }) async {
    debugPrint(
      '[AuthProvider] loginOrRegisterWithEmailOnly start email=$email',
    );
    // Try to create the user; if already exists, continue.
    await SupabaseService.instance.signUp(email, _defaultPassword);
    final error = await SupabaseService.instance.signIn(
      email,
      _defaultPassword,
    );
    if (error != null) {
      debugPrint('[AuthProvider] loginOrRegisterWithEmailOnly failed: $error');
      // If user exists with unknown password, fall back to magic link
      if (error.toLowerCase().contains('invalid login credentials') ||
          error.toLowerCase().contains('email not confirmed')) {
        final mlErr = await SupabaseService.instance.signInWithEmailOnly(email);
        if (mlErr != null) {
          throw AuthException(mlErr);
        }
        throw AuthException(
          'Hesap mevcut. Giriş bağlantısı e-postana gönderildi.',
        );
      }
      throw AuthException(error);
    }
    _email = email;
    _loggedIn = true;
    debugPrint(
      '[AuthProvider] loginOrRegisterWithEmailOnly success email=$email',
    );
    // Save profile row
    try {
      await SupabaseService.instance.upsertProfile(name: name);
    } catch (e) {
      debugPrint('[AuthProvider] upsertProfile failed: $e');
    }
    notifyListeners();
  }

  // Login only: try default password; if invalid, send magic link and inform UI
  Future<void> loginWithEmailOnly(String email) async {
    debugPrint('[AuthProvider] loginWithEmailOnly start email=$email');
    final error = await SupabaseService.instance.signIn(
      email,
      _defaultPassword,
    );
    if (error != null) {
      if (error.toLowerCase().contains('invalid login credentials') ||
          error.toLowerCase().contains('email not confirmed')) {
        final mlErr = await SupabaseService.instance.signInWithEmailOnly(email);
        if (mlErr != null) {
          throw AuthException(mlErr);
        }
        throw AuthException('Giriş bağlantısı e-postana gönderildi.');
      }
      throw AuthException(error);
    }
    _email = email;
    _loggedIn = true;
    notifyListeners();
  }

  // Register only: create then sign in; optionally save name
  Future<void> registerWithEmailOnly(String email, {String? name}) async {
    debugPrint('[AuthProvider] registerWithEmailOnly start email=$email');
    final signUpErr = await SupabaseService.instance.signUp(
      email,
      _defaultPassword,
    );
    if (signUpErr != null) {
      throw AuthException(signUpErr);
    }
    final signInErr = await SupabaseService.instance.signIn(
      email,
      _defaultPassword,
    );
    if (signInErr != null) {
      throw AuthException(signInErr);
    }
    _email = email;
    _loggedIn = true;
    try {
      await SupabaseService.instance.upsertProfile(name: name);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> setLoggedInFromSession() async {
    final session = Supabase.instance.client.auth.currentSession;
    _loggedIn = session != null;
    _email = session?.user.email;
    notifyListeners();
  }

  Future<void> logout() async {
    await SupabaseService.instance.signOut();
    _loggedIn = false;
    _email = null;
    notifyListeners();
  }
}
