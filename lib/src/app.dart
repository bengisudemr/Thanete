import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:provider/provider.dart';
import 'package:thanette/src/providers/auth_provider.dart';
import 'package:thanette/src/providers/notes_provider.dart';
import 'package:thanette/src/providers/editor_provider.dart';
import 'package:thanette/src/screens/login_screen.dart';
import 'package:thanette/src/screens/note_detail_screen.dart';
import 'package:thanette/src/screens/notes_list_screen.dart';
import 'package:thanette/src/screens/splash_screen.dart';

class ThanetteApp extends StatelessWidget {
  const ThanetteApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseColor = const Color(0xFF7B61FF);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NotesProvider()..bootstrap()),
        ChangeNotifierProvider(create: (_) => EditorProvider()),
      ],
      child: MaterialApp(
        title: 'thanette',
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          quill.FlutterQuillLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('tr')],
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: baseColor,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF5F5F7),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.black,
            elevation: 0,
            centerTitle: false,
          ),
        ),
        initialRoute: SplashScreen.route,
        routes: {
          SplashScreen.route: (_) => const SplashScreen(),
          LoginScreen.route: (_) => const LoginScreen(),
          NotesListScreen.route: (_) => const NotesListScreen(),
          NoteDetailScreen.route: (ctx) {
            final args =
                ModalRoute.of(ctx)!.settings.arguments as NoteDetailArgs?;
            return NoteDetailScreen(args: args ?? const NoteDetailArgs());
          },
        },
      ),
    );
  }
}
