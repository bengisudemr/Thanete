import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Backend-only service for Thanette.
///
/// Integration hints for your existing UI (no UI code here):
/// - Call `await SupabaseService.instance.signIn(email, password)` to sign in.
/// - Call `await SupabaseService.instance.signUp(email, password)` to sign up.
/// - Call `await SupabaseService.instance.signOut()` to sign out.
/// - Call `await SupabaseService.instance.addNote(title, content)` to create a note.
/// - Call `await SupabaseService.instance.getNotes()` to fetch user notes.
/// - Listen realtime:
///   ```dart
///   final channel = SupabaseService.instance.subscribeToNotes((payload) {
///     // Refresh your notes provider/state here
///   });
///   // later: channel.unsubscribe();
///   ```
class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  SupabaseClient get _client => Supabase.instance.client;

  /// Password-based sign up. Returns null on success; error message on failure.
  Future<String?> signUp(String email, String password) async {
    try {
      debugPrint('[SupabaseService] signUp start email=$email');
      await _client.auth.signUp(email: email, password: password);
      // If no exception, treat as success (Supabase throws on failure)
      // Some projects may require email confirmation; user/session can be null.
      return null;
    } on AuthException catch (e) {
      debugPrint('[SupabaseService] signUp auth error: ${e.message}');
      return e.message;
    } catch (e) {
      debugPrint('[SupabaseService] signUp unknown error: $e');
      return 'Kayıt sırasında hata oluştu';
    }
  }

  /// Password-based sign in. Returns null on success; error message on failure.
  Future<String?> signIn(String email, String password) async {
    try {
      debugPrint('[SupabaseService] signIn start email=$email');
      await _client.auth.signInWithPassword(email: email, password: password);
      return null;
    } on AuthException catch (e) {
      debugPrint('[SupabaseService] signIn auth error: ${e.message}');
      return e.message;
    } catch (e) {
      debugPrint('[SupabaseService] signIn unknown error: $e');
      return 'Giriş sırasında hata oluştu';
    }
  }

  /// Email-only auth (magic link). Creates account on first sign-in.
  /// Returns null on success; error message on failure.
  Future<String?> signInWithEmailOnly(String email) async {
    try {
      debugPrint('[SupabaseService] signInWithEmailOnly start email=$email');
      await _client.auth.signInWithOtp(
        email: email,
        emailRedirectTo: 'io.supabase.flutter://login-callback/',
      );
      return null;
    } on AuthException catch (e) {
      debugPrint(
        '[SupabaseService] signInWithEmailOnly auth error: ${e.message}',
      );
      return e.message;
    } catch (e) {
      debugPrint('[SupabaseService] signInWithEmailOnly unknown error: $e');
      return 'Giriş bağlantısı gönderilirken hata oluştu';
    }
  }

  /// Ensure a row exists in public.profiles for the current user. Upserts by id.
  Future<void> upsertProfile({String? name}) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw AuthException('Not authenticated');
    }
    final payload = {
      'id': user.id,
      'email': user.email,
      if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
    };
    await _client.from('profiles').upsert(payload, onConflict: 'id');
  }

  /// Fetch current user's profile
  Future<Map<String, dynamic>?> getMyProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    final rows = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .limit(1);
    if (rows.isNotEmpty) {
      return Map<String, dynamic>.from(rows.first as Map);
    }
    return null;
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<Map<String, dynamic>> addNote(String title, String content) async {
    final user = _client.auth.currentUser;
    final userId = user?.id;
    if (userId == null) {
      throw AuthException('Not authenticated');
    }

    final inserted = await _client
        .from('notes')
        .insert({'user_id': userId, 'title': title, 'content': content})
        .select()
        .single();

    return Map<String, dynamic>.from(inserted as Map);
  }

  Future<List<Map<String, dynamic>>> getNotes() async {
    final user = _client.auth.currentUser;
    final userId = user?.id;
    if (userId == null) {
      throw AuthException('Not authenticated');
    }

    final result = await _client
        .from('notes')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (result as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<Map<String, dynamic>> updateNote(
    String id,
    String title,
    String content,
  ) async {
    final updated = await _client
        .from('notes')
        .update({'title': title, 'content': content})
        .eq('id', id)
        .select()
        .single();
    return Map<String, dynamic>.from(updated as Map);
  }

  Future<void> deleteNote(String id) async {
    await _client.from('notes').delete().eq('id', id);
  }

  Future<Map<String, dynamic>> updateNoteColor(String id, Color color) async {
    final colorValue = color.value; // Convert Color to int
    final updated = await _client
        .from('notes')
        .update({'color': colorValue})
        .eq('id', id)
        .select()
        .single();
    return Map<String, dynamic>.from(updated as Map);
  }

  RealtimeChannel subscribeToNotes(
    void Function(PostgresChangePayload payload) onChange,
  ) {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw AuthException('Not authenticated');
    }

    final channel = _client.channel('public:notes:user:$userId');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'notes',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: userId,
      ),
      callback: (payload) {
        onChange(payload);
      },
    );

    channel.subscribe();
    return channel;
  }
}
