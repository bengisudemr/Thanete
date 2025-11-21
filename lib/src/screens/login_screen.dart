import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thanette/src/providers/auth_provider.dart';
import 'package:thanette/src/providers/theme_provider.dart';
import 'package:thanette/src/screens/notes_list_screen.dart';
import 'package:thanette/src/widgets/ui/ui_primitives.dart';

class LoginScreen extends StatefulWidget {
  static const route = '/login';
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  DateTime? _birthDate;
  bool _isRegister = false; // login <-> register
  bool _obscurePassword = true;
  String? _emailError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _continueWithEmail() async {
    // Clear previous errors
    setState(() {
      _emailError = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen email adresinizi girin')),
      );
      return;
    }
    if (password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lütfen şifrenizi girin')));
      return;
    }

    try {
      debugPrint(
        '[LoginScreen] continueWithEmail email=$email isRegister=$_isRegister',
      );

      if (_isRegister) {
        // Register with email + password + optional name & birthDate
        await context.read<AuthProvider>().signUpUser(
          email,
          password,
          name: _nameController.text.trim().isEmpty
              ? null
              : _nameController.text.trim(),
          birthDate: _birthDate,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kayıt başarılı! Hoş geldiniz!')),
        );
        Navigator.of(context).pushReplacementNamed(NotesListScreen.route);
      } else {
        // Login with password (required)
        await context.read<AuthProvider>().loginWithPassword(email, password);
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(NotesListScreen.route);
      }
    } catch (e) {
      debugPrint('[LoginScreen] continueWithEmail error: $e');
      if (!mounted) return;
      
      // Extract error message from AuthException
      String errorMessage = 'Bir hata oluştu. Lütfen tekrar deneyin.';
      if (e is AuthException) {
        errorMessage = e.message;
      } else if (e.toString().contains('AuthException')) {
        // Try to extract message from string representation
        final match = RegExp(r'AuthException: (.+)').firstMatch(e.toString());
        if (match != null) {
          errorMessage = match.group(1) ?? errorMessage;
        }
      }
      
      // Check if it's an email already registered error
      final isEmailAlreadyRegistered = errorMessage.toLowerCase().contains('zaten kayıtlı') ||
          errorMessage.toLowerCase().contains('already registered') ||
          errorMessage.toLowerCase().contains('email already exists');
      
      if (isEmailAlreadyRegistered && _isRegister) {
        // Show error under email field only, no SnackBar
        setState(() {
          _emailError = errorMessage;
        });
      } else {
        // Show SnackBar for other errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildSimpleAuth();
  }

  Widget _buildSimpleAuth() {
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    return AppScaffold(
      padded: false,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingXXL,
          vertical: AppTheme.spacingXXL,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isKeyboardOpen) ...[
              const SizedBox(height: AppTheme.spacingXXL),
              _LoginHero(),
              const SizedBox(height: AppTheme.spacingXXXL),
            ],
            SurfaceCard(
              padding: const EdgeInsets.all(AppTheme.spacingXXL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _isRegister
                        ? 'Yeni bir hesap oluştur'
                        : 'Tekrar hoş geldin',
                    style: AppTheme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Text(
                    _isRegister
                        ? 'Kayıt olmak için bilgilerini paylaş.'
                        : 'thanette hesabınla giriş yap.',
                    style: AppTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  if (_isRegister) ...[
                    const SizedBox(height: AppTheme.spacingXL),
                    TextField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        hintText: 'Ad Soyad',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    _BirthDatePicker(
                      birthDate: _birthDate,
                      onPick: (date) => setState(() => _birthDate = date),
                    ),
                  ],
                  if (_isRegister) const SizedBox(height: AppTheme.spacingXL),
                  if (!_isRegister) const SizedBox(height: AppTheme.spacingXXL),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) {
                      // Clear error when user starts typing
                      if (_emailError != null) {
                        setState(() {
                          _emailError = null;
                        });
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'E‑posta adresi',
                      prefixIcon: const Icon(Icons.mail_outline),
                      errorText: _emailError,
                      errorMaxLines: 2,
                    ),
                  ),
                  if (_emailError != null) ...[
                    const SizedBox(height: AppTheme.spacingS),
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingM),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        border: Border.all(
                          color: AppTheme.error.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 20,
                            color: AppTheme.error,
                          ),
                          const SizedBox(width: AppTheme.spacingS),
                          Expanded(
                            child: Text(
                              _emailError!,
                              style: AppTheme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.error,
                              ),
                            ),
                          ),
                          if (_isRegister)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isRegister = false;
                                  _emailError = null;
                                });
                              },
                              child: Text(
                                'Giriş Yap',
                                style: AppTheme.textTheme.bodySmall?.copyWith(
                                  color: AppTheme.primaryPink,
                                  fontWeight: AppTheme.fontWeightSemiBold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppTheme.spacingM),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: 'Şifre',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXXL),
                  PrimaryButton(
                    onPressed: _continueWithEmail,
                    label: _isRegister ? 'Kayıt Ol' : 'Giriş Yap',
                    icon: Icons.arrow_forward,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingXL),
            SurfaceCard(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingXXL,
                vertical: AppTheme.spacingL,
              ),
              borderColor: Colors.transparent,
              borderWidth: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isRegister ? 'Hesabın var mı?' : 'Hesabın yok mu?',
                    style: AppTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  TertiaryButton(
                    onPressed: () => setState(() => _isRegister = !_isRegister),
                    label: _isRegister ? 'Giriş Yap' : 'Kayıt Ol',
                    expand: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingXXL),
          ],
        ),
      ),
    );
  }

  // (removed) legacy feature row helper
}

class _LoginHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradientLinear,
            borderRadius: BorderRadius.circular(AppTheme.radiusXXLarge),
            boxShadow: AppTheme.primaryShadow,
          ),
          child: const Icon(Icons.edit_note, color: Colors.white, size: 40),
        ),
        const SizedBox(height: AppTheme.spacingXL),
        Text('thanette', style: AppTheme.textTheme.headlineLarge),
        const SizedBox(height: AppTheme.spacingS),
        Text(
          'Modern, sakin ve güçlü bir not alanı.',
          style: AppTheme.textTheme.bodyLarge?.copyWith(
            color: AppTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _BirthDatePicker extends StatelessWidget {
  const _BirthDatePicker({required this.birthDate, required this.onPick});

  final DateTime? birthDate;
  final ValueChanged<DateTime?> onPick;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime(now.year - 18, now.month, now.day),
          firstDate: DateTime(1900, 1, 1),
          lastDate: now,
          helpText: 'Doğum Tarihi',
        );
        onPick(picked);
      },
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
        decoration: BoxDecoration(
          color: AppTheme.backgroundPrimary,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Row(
          children: [
            Icon(
              Icons.cake_outlined,
              color: AppTheme.primaryPink.withOpacity(0.8),
            ),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: Text(
                birthDate == null
                    ? 'Doğum Tarihi'
                    : '${birthDate!.day.toString().padLeft(2, '0')}.${birthDate!.month.toString().padLeft(2, '0')}.${birthDate!.year}',
                style: AppTheme.textTheme.bodyLarge?.copyWith(
                  color: birthDate == null
                      ? AppTheme.textSecondary
                      : AppTheme.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppTheme.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
