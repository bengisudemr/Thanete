import 'dart:typed_data';
import 'dart:io';
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

  /// Converts Supabase error messages to user-friendly Turkish messages
  String _translateErrorMessage(String errorMessage, {bool isLogin = false}) {
    final lowerError = errorMessage.toLowerCase();

    // Login errors
    if (isLogin) {
      if (lowerError.contains('invalid login credentials') ||
          lowerError.contains('invalid credentials') ||
          lowerError.contains('wrong password') ||
          lowerError.contains('incorrect password')) {
        return 'E-posta adresi veya şifre hatalı. Lütfen tekrar deneyin.';
      }
      if (lowerError.contains('email not confirmed') ||
          lowerError.contains('email not verified')) {
        return 'E-posta adresinizi doğrulamanız gerekiyor. Lütfen e-postanızı kontrol edin.';
      }
      if (lowerError.contains('user not found') ||
          lowerError.contains('no user found')) {
        return 'Bu e-posta adresi ile kayıtlı bir hesap bulunamadı.';
      }
      if (lowerError.contains('too many requests') ||
          lowerError.contains('rate limit')) {
        return 'Çok fazla deneme yaptınız. Lütfen birkaç dakika sonra tekrar deneyin.';
      }
    }

    // Sign up errors
    if (lowerError.contains('user already registered') ||
        lowerError.contains('email already exists') ||
        lowerError.contains('already registered')) {
      return 'Bu e-posta adresi zaten kayıtlı. Giriş yapmayı deneyin.';
    }

    // Password errors
    if (lowerError.contains('password should be at least') ||
        lowerError.contains('password too short')) {
      return 'Şifre en az 6 karakter olmalıdır.';
    }
    if (lowerError.contains('password is required')) {
      return 'Şifre gereklidir.';
    }

    // Email errors
    if (lowerError.contains('invalid email') ||
        lowerError.contains('email format')) {
      return 'Geçersiz e-posta adresi formatı. Lütfen doğru bir e-posta adresi girin.';
    }
    if (lowerError.contains('email is required')) {
      return 'E-posta adresi gereklidir.';
    }

    // Network/connection errors
    if (lowerError.contains('network') ||
        lowerError.contains('connection') ||
        lowerError.contains('timeout')) {
      return 'İnternet bağlantınızı kontrol edin ve tekrar deneyin.';
    }

    // Generic fallback
    return errorMessage;
  }

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
      return _translateErrorMessage(e.message, isLogin: false);
    } catch (e) {
      debugPrint('[SupabaseService] signUp unknown error: $e');
      return 'Kayıt sırasında hata oluştu. Lütfen tekrar deneyin.';
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
      return _translateErrorMessage(e.message, isLogin: true);
    } catch (e) {
      debugPrint('[SupabaseService] signIn unknown error: $e');
      return 'Giriş sırasında hata oluştu. Lütfen tekrar deneyin.';
    }
  }

  /// Enhanced sign up that returns a structured map and ensures profile exists.
  /// Throws AuthException on failure; returns a map on success.
  Future<Map<String, dynamic>?> signUpUser(
    String email,
    String password, {
    String? name,
    DateTime? birthDate,
  }) async {
    try {
      debugPrint('[SupabaseService] signUpUser start email=$email name=$name');

      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );

      // Some projects require email confirmation; session can be null here.
      final createdUserId = response.user?.id;

      // Try to sign in to establish a session if not present.
      if (_client.auth.currentSession == null) {
        await _client.auth.signInWithPassword(email: email, password: password);
      }

      // Ensure profile row exists (best-effort)
      try {
        await upsertProfile(name: name, birthDate: birthDate);
      } catch (e) {
        debugPrint(
          '[SupabaseService] upsertProfile after signUpUser failed: $e',
        );
      }

      final session = _client.auth.currentSession;
      final user = _client.auth.currentUser;

      return <String, dynamic>{
        'userId': user?.id ?? createdUserId,
        'email': email,
        'sessionEstablished': session != null,
        'requiresEmailConfirmation': response.session == null,
      };
    } on AuthException catch (e) {
      debugPrint('[SupabaseService] signUpUser auth error: ${e.message}');
      throw AuthException(_translateErrorMessage(e.message, isLogin: false));
    } catch (e) {
      debugPrint('[SupabaseService] signUpUser unknown error: $e');
      throw AuthException(
        'Kayıt sırasında hata oluştu. Lütfen tekrar deneyin.',
      );
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
      return _translateErrorMessage(e.message, isLogin: true);
    } catch (e) {
      debugPrint('[SupabaseService] signInWithEmailOnly unknown error: $e');
      return 'Giriş bağlantısı gönderilirken hata oluştu. Lütfen tekrar deneyin.';
    }
  }

  /// Ensure a row exists in public.profiles for the current user. Upserts by id.
  Future<void> upsertProfile({
    String? name,
    DateTime? birthDate,
    String? avatarUrl,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw AuthException('Not authenticated');
    }
    final payload = {
      'id': user.id,
      'email': user.email,
      if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
      if (birthDate != null) 'birth_date': birthDate.toIso8601String(),
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    };
    await _client.from('profiles').upsert(payload, onConflict: 'id');
  }

  /// Upload profile photo to Supabase Storage
  Future<String> uploadProfilePhoto(File file, String fileName) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw AuthException('Not authenticated');
    }

    // Create a unique file path for the profile photo
    // Path format: userId/fileName (storage policy checks foldername(name)[1] which is userId)
    final filePath = '${user.id}/$fileName';

    try {
      // Upload file to Supabase Storage (upsert to replace existing)
      // Try to remove existing avatar if it exists first
      try {
        await _client.storage.from('avatars').remove([filePath]);
      } catch (e) {
        // Ignore if file doesn't exist - this is fine
        debugPrint('[SupabaseService] No existing avatar to remove: $e');
      }

      await _client.storage
          .from('avatars')
          .uploadBinary(filePath, await file.readAsBytes());

      // Get public URL
      final publicUrl = _client.storage.from('avatars').getPublicUrl(filePath);

      debugPrint(
        '[SupabaseService] Profile photo uploaded successfully: $publicUrl',
      );
      return publicUrl;
    } catch (e) {
      debugPrint('[SupabaseService] Error uploading profile photo: $e');
      rethrow;
    }
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

  /// Update user email - sends confirmation email to new address
  Future<User?> updateUserEmail(String newEmail) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw AuthException('Not authenticated');
    }

    try {
      debugPrint('[SupabaseService] updateUserEmail start newEmail=$newEmail');

      final response = await _client.auth.updateUser(
        UserAttributes(email: newEmail),
      );

      debugPrint('[SupabaseService] updateUserEmail success');
      return response.user;
    } on AuthException catch (e) {
      debugPrint('[SupabaseService] updateUserEmail auth error: ${e.message}');
      throw AuthException(_translateErrorMessage(e.message, isLogin: false));
    } catch (e) {
      debugPrint('[SupabaseService] updateUserEmail unknown error: $e');
      throw AuthException(
        'E-posta güncellenirken hata oluştu. Lütfen tekrar deneyin.',
      );
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<Map<String, dynamic>> addNote(
    String title,
    String content, {
    String category = 'general',
  }) async {
    final user = _client.auth.currentUser;
    final userId = user?.id;
    if (userId == null) {
      throw AuthException('Not authenticated');
    }

    debugPrint('[SupabaseService] addNote start');
    debugPrint('[SupabaseService] current user: ${user?.email ?? 'unknown'}');

    try {
      final inserted = await _client
          .from('notes')
          .insert({
            'user_id': userId,
            'title': title,
            'content': content,
            'category': category,
          })
          .select()
          .single();

      return Map<String, dynamic>.from(inserted as Map);
    } catch (e) {
      debugPrint('[SupabaseService] addNote error: $e');
      rethrow;
    }
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
    String content, {
    String? category,
  }) async {
    final payload = {
      'title': title,
      'content': content,
      if (category != null) 'category': category,
    };
    final updated = await _client
        .from('notes')
        .update(payload)
        .eq('id', id)
        .select()
        .single();
    return Map<String, dynamic>.from(updated as Map);
  }

  Future<Map<String, dynamic>> updateNoteTodos(
    String id,
    String todosData,
  ) async {
    final updated = await _client
        .from('notes')
        .update({'todos': todosData})
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

  Future<Map<String, dynamic>> updateNotePin(String id, bool isPinned) async {
    final updated = await _client
        .from('notes')
        .update({'is_pinned': isPinned})
        .eq('id', id)
        .select()
        .single();
    return Map<String, dynamic>.from(updated as Map);
  }

  Future<Map<String, dynamic>> updateNoteDrawing(
    String id,
    String drawingData,
  ) async {
    print('SupabaseService: Updating drawing_data for note $id');
    print('SupabaseService: Drawing data: $drawingData');

    // Check authentication
    final user = _client.auth.currentUser;
    print('SupabaseService: Current user: ${user?.id}');
    print('SupabaseService: User email: ${user?.email}');

    try {
      final updated = await _client
          .from('notes')
          .update({'drawing_data': drawingData})
          .eq('id', id)
          .select()
          .single();

      print('SupabaseService: Drawing data updated successfully');
      return Map<String, dynamic>.from(updated as Map);
    } catch (e) {
      print('SupabaseService: Error updating drawing data: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateNoteAppleDrawing(
    String id,
    String appleDrawingData,
  ) async {
    final updated = await _client
        .from('notes')
        .update({'apple_drawing_data': appleDrawingData})
        .eq('id', id)
        .select()
        .single();
    return Map<String, dynamic>.from(updated as Map);
  }

  Future<Map<String, dynamic>> updateNoteAttachments(
    String id,
    String attachmentsData,
  ) async {
    final updated = await _client
        .from('notes')
        .update({'attachments': attachmentsData})
        .eq('id', id)
        .select()
        .single();
    return Map<String, dynamic>.from(updated as Map);
  }

  Future<String> uploadAttachment(
    String noteId,
    String fileName,
    List<int> fileData,
  ) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw AuthException('Not authenticated');
    }

    // Create a unique file path
    final filePath = 'notes/$noteId/$fileName';

    // Upload file to Supabase Storage
    await _client.storage
        .from('attachments')
        .uploadBinary(filePath, Uint8List.fromList(fileData));

    // Get public URL
    final publicUrl = _client.storage
        .from('attachments')
        .getPublicUrl(filePath);

    return publicUrl;
  }

  Future<void> deleteAttachment(String filePath) async {
    await _client.storage.from('attachments').remove([filePath]);
  }

  Future<Map<String, dynamic>> updateNoteCategory(
    String id,
    String category,
  ) async {
    final updated = await _client
        .from('notes')
        .update({'category': category})
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
