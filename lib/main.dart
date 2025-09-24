import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thanette/src/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables if .env exists. If not, fall back to hardcoded values below.
  try {
    await dotenv.load(fileName: 'assets/env/.env');
  } catch (_) {}

  final supabaseUrl =
      dotenv.env['SUPABASE_URL'] ?? 'https://hlwfutlmvzeelcangmuu.supabase.co';
  final supabaseAnonKey =
      dotenv.env['SUPABASE_ANON_KEY'] ??
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhsd2Z1dGxtdnplZWxjYW1nbXV1Iiwicm9sZSI6ImFub25iLCJpYXQiOjE3NTg2MDM4NTUsImV4cCI6MjA3NDE3OTg1NX0.NNtruX2YaAuvjn5JG2OWc348fsTZ5MJk_BXFq4dvPaA';

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  runApp(const ThanetteApp());
}
