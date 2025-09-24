import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thanette/src/providers/auth_provider.dart';
import 'package:thanette/src/widgets/thanette_logo.dart';
import 'package:thanette/src/screens/notes_list_screen.dart';

class LoginScreen extends StatefulWidget {
  static const route = '/login';
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _isRegister = false;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _continueWithEmail() async {
    final email = _emailController.text.trim();
    final name = _nameController.text.trim();
    if (email.isEmpty) return;
    try {
      debugPrint('[LoginScreen] continueWithEmail email=$email name=$name');
      if (_isRegister) {
        await context.read<AuthProvider>().registerWithEmailOnly(
          email,
          name: name.isEmpty ? null : name,
        );
      } else {
        await context.read<AuthProvider>().loginWithEmailOnly(email);
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(NotesListScreen.route);
    } catch (e) {
      debugPrint('[LoginScreen] continueWithEmail error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Giriş başarısız: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isCompact = size.height < 740;
    final isKeyboardOpen = keyboardHeight > 0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8F9FA), Color(0xFFFFFFFF)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: IntrinsicHeight(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: isCompact ? 20 : 32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo section
                      Center(
                        child: Column(
                          children: [
                            ThanetteLogo(
                              size: (_isRegister || isCompact || isKeyboardOpen)
                                  ? 44
                                  : 56,
                              showText: true,
                            ),
                            SizedBox(
                              height:
                                  (_isRegister || isCompact || isKeyboardOpen)
                                  ? 12
                                  : 24,
                            ),
                            if (!isKeyboardOpen)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  '✨ Yeni bir deneyim',
                                  style: TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Welcome text section
                      Text(
                        'tüm notların\ntek bir yerde',
                        style: TextStyle(
                          fontSize: (_isRegister || isCompact || isKeyboardOpen)
                              ? 22
                              : 28,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      SizedBox(
                        height: (_isRegister || isCompact || isKeyboardOpen)
                            ? 6
                            : 12,
                      ),
                      Text(
                        'istediğin zaman not al, düşüncelerini kaydet,\ngerisini bize bırak',
                        style: TextStyle(
                          color: const Color(0xFF6B7280),
                          fontSize: (_isRegister || isCompact || isKeyboardOpen)
                              ? 13
                              : 16,
                          height: 1.3,
                        ),
                      ),

                      SizedBox(
                        height: (_isRegister || isCompact || isKeyboardOpen)
                            ? 8
                            : 12,
                      ),

                      // Features section (hide on register, compact screens, or when keyboard is open)
                      if (!(_isRegister || isCompact || isKeyboardOpen)) ...[
                        _buildFeatureRow(
                          icon: Icons.edit_note_outlined,
                          title: 'Hızlı not alma',
                          subtitle: 'Düşüncelerini anında kaydet',
                        ),
                        const SizedBox(height: 12),
                        _buildFeatureRow(
                          icon: Icons.palette_outlined,
                          title: 'Renkli kategoriler',
                          subtitle: 'Notlarını renklerle organize et',
                        ),
                        const SizedBox(height: 12),
                        _buildFeatureRow(
                          icon: Icons.offline_bolt_outlined,
                          title: 'Şifresiz giriş',
                          subtitle: 'E-posta ile tek tıkla başla',
                        ),
                      ],

                      SizedBox(
                        height: (_isRegister || isCompact || isKeyboardOpen)
                            ? 8
                            : 16,
                      ),

                      // Email-only login section
                      Container(
                        padding: EdgeInsets.all(
                          (_isRegister || isCompact || isKeyboardOpen)
                              ? 14
                              : 24,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Mode toggle tabs
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.all(4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(10),
                                      onTap: () {
                                        if (_isRegister) {
                                          setState(() {
                                            _isRegister = false;
                                          });
                                        }
                                      },
                                      child: Container(
                                        height: 40,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: !_isRegister
                                              ? const Color(0xFFFFFFFF)
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          boxShadow: !_isRegister
                                              ? [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.04),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: const Text(
                                          'Giriş Yap',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF374151),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(10),
                                      onTap: () {
                                        if (!_isRegister) {
                                          setState(() {
                                            _isRegister = true;
                                          });
                                        }
                                      },
                                      child: Container(
                                        height: 40,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: _isRegister
                                              ? const Color(0xFFFFFFFF)
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          boxShadow: _isRegister
                                              ? [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.04),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: const Text(
                                          'Kayıt Ol',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF374151),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height:
                                  (_isRegister || isCompact || isKeyboardOpen)
                                  ? 12
                                  : 16,
                            ),
                            Text(
                              _isRegister
                                  ? 'İsmini ve e-posta adresi'
                                  : 'E-posta',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF374151),
                              ),
                            ),
                            SizedBox(
                              height:
                                  (_isRegister || isCompact || isKeyboardOpen)
                                  ? 12
                                  : 16,
                            ),
                            if (_isRegister) ...[
                              TextField(
                                controller: _nameController,
                                textCapitalization: TextCapitalization.words,
                                decoration: InputDecoration(
                                  hintText: 'Ad Soyad',
                                  prefixIcon: const Icon(Icons.person_outline),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF9FAFB),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                hintText: 'ornek@email.com',
                                prefixIcon: const Icon(Icons.mail_outline),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF9FAFB),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                            ),
                            SizedBox(
                              height:
                                  (_isRegister || isCompact || isKeyboardOpen)
                                  ? 10
                                  : 16,
                            ),
                            SizedBox(
                              width: double.infinity,
                              height:
                                  (_isRegister || isCompact || isKeyboardOpen)
                                  ? 48
                                  : 52,
                              child: ElevatedButton(
                                onPressed: _continueWithEmail,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFEC60FF),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  _isRegister ? 'Kayıt Ol' : 'Giriş Yap',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    _isRegister
                                        ? 'Hesabın var mı? '
                                        : 'Hesabın yok mu? ',
                                    style: const TextStyle(
                                      color: Color(0xFF6B7280),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    softWrap: false,
                                  ),
                                ),
                                TextButton(
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 6,
                                    ),
                                    minimumSize: const Size(0, 32),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isRegister = !_isRegister;
                                    });
                                  },
                                  child: Text(
                                    _isRegister ? 'Giriş Yap' : 'Kayıt Ol',
                                    style: const TextStyle(
                                      color: Color(0xFFEC60FF),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(
                        height: (_isRegister || isCompact || isKeyboardOpen)
                            ? 12
                            : 24,
                      ),

                      // Footer text
                      Center(
                        child: Text(
                          'Giriş yaparak Kullanım Şartları\'nı kabul etmiş olursun',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFEC60FF), Color(0xFFFF4D79)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
