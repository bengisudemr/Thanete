import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thanette/src/providers/auth_provider.dart';
import 'package:thanette/src/providers/theme_provider.dart';
import 'package:thanette/src/screens/login_screen.dart';
import 'package:thanette/src/screens/notes_list_screen.dart';

class SplashScreen extends StatefulWidget {
  static const route = '/';
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<AuthProvider>().setLoggedInFromSession();
      if (!mounted) return;
      final logged = context.read<AuthProvider>().isLoggedIn;
      if (logged) {
        Navigator.of(context).pushReplacementNamed(NotesListScreen.route);
      } else {
        Navigator.of(context).pushReplacementNamed(LoginScreen.route);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.backgroundSecondary,
      body: Center(child: _SplashContent()),
    );
  }
}

class _SplashContent extends StatefulWidget {
  const _SplashContent();

  @override
  State<_SplashContent> createState() => _SplashContentState();
}

class _SplashContentState extends State<_SplashContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppTheme.animationMedium,
    )..forward();
    _scaleAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _opacityAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            _Logo(),
            SizedBox(height: AppTheme.spacingXL),
            Text(
              'thanette',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: AppTheme.spacingM),
            _ProgressPill(),
          ],
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradientLinear,
        borderRadius: BorderRadius.circular(AppTheme.radiusXXLarge),
        boxShadow: AppTheme.glassmorphismShadow,
      ),
      child: const Icon(Icons.edit, color: Colors.white),
    );
  }
}

class _ProgressPill extends StatelessWidget {
  const _ProgressPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingXXL,
        vertical: AppTheme.spacingS,
      ),
      decoration: BoxDecoration(
        color: AppTheme.backgroundPrimary,
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          SizedBox(
            height: 12,
            width: 12,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          SizedBox(width: AppTheme.spacingS),
          Text(
            'Hazırlanıyor...',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
