import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:provider/provider.dart';
import 'package:thanette/src/providers/auth_provider.dart';
import 'package:thanette/src/providers/notes_provider.dart';
import 'package:thanette/src/providers/editor_provider.dart';
import 'package:thanette/src/providers/theme_provider.dart';
import 'package:thanette/src/providers/annotation_provider.dart';
import 'package:thanette/src/providers/enhanced_annotation_provider.dart';
import 'package:thanette/src/providers/navigation_provider.dart';
import 'package:thanette/src/providers/chatbot_provider.dart';
import 'package:thanette/src/providers/app_theme_controller.dart';
import 'package:thanette/src/screens/login_screen.dart';
import 'package:thanette/src/screens/note_detail_screen.dart';
import 'package:thanette/src/screens/notes_list_screen.dart';
import 'package:thanette/src/screens/splash_screen.dart';
import 'package:thanette/src/screens/chatbot_screen.dart';
import 'package:thanette/src/screens/profile_screen.dart';

class AppNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    ThanetteApp.currentRouteNotifier.value = route.settings.name;
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    ThanetteApp.currentRouteNotifier.value = previousRoute?.settings.name;
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    ThanetteApp.currentRouteNotifier.value = previousRoute?.settings.name;
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    ThanetteApp.currentRouteNotifier.value = newRoute?.settings.name;
  }
}

class ThanetteApp extends StatefulWidget {
  const ThanetteApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static final ValueNotifier<String?> currentRouteNotifier =
      ValueNotifier<String?>(null);

  @override
  State<ThanetteApp> createState() => _ThanetteAppState();
}

class _ThanetteAppState extends State<ThanetteApp> {
  @override
  void initState() {
    super.initState();
    // Set initial route
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigatorState = ThanetteApp.navigatorKey.currentState;
      if (navigatorState != null) {
        final route = ModalRoute.of(navigatorState.context);
        ThanetteApp.currentRouteNotifier.value = route?.settings.name;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NotesProvider()..bootstrap()),
        ChangeNotifierProvider(create: (_) => EditorProvider()),
        ChangeNotifierProvider(create: (_) => AnnotationProvider()),
        ChangeNotifierProvider(create: (_) => EnhancedAnnotationProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => ChatbotProvider()),
        ChangeNotifierProvider(
          create: (_) {
            final controller = AppThemeController();
            // Bootstrap async olarak çağrılır, tamamlandığında notifyListeners() çağrılır
            controller.bootstrap();
            return controller;
          },
        ),
      ],
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Consumer<AppThemeController>(
          builder: (context, themeCtl, _) {
            return MaterialApp(
              navigatorKey: ThanetteApp.navigatorKey,
              navigatorObservers: [AppNavigatorObserver()],
              title: 'thanette',
              debugShowCheckedModeBanner: false,
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                quill.FlutterQuillLocalizations.delegate,
              ],
              supportedLocales: const [Locale('en'), Locale('tr')],
              theme: AppTheme.lightTheme,
              themeMode: ThemeMode.light,
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
                ChatbotScreen.route: (_) => const ChatbotScreen(),
                ProfileScreen.route: (_) => const ProfileScreen(),
              },
              builder: (context, child) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    child ?? const SizedBox.shrink(),
                    if (themeCtl.isChangingTheme) const _ThemeLoadingOverlay(),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ThemeLoadingOverlay extends StatelessWidget {
  const _ThemeLoadingOverlay();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        ModalBarrier(dismissible: false, color: Colors.black.withOpacity(0.2)),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
