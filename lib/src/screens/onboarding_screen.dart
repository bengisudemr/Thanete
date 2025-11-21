import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:thanette/src/providers/theme_provider.dart';
import 'package:thanette/src/screens/login_screen.dart';
import 'package:thanette/src/widgets/ui/ui_primitives.dart';

class OnboardingScreen extends StatefulWidget {
  static const route = '/onboarding';
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  final List<_OnboardItem> _items = const [
    _OnboardItem(
      title: 'Çizim ve Görsel Notlama',
      subtitle:
          'Görseller üzerinde çizim yap, not ekle ve açıklamalarla zenginleştir.',
      icon: Icons.brush_outlined,
      lottieAsset: 'assets/lottie/drawing.json',
    ),
    _OnboardItem(
      title: 'Yapılacaklar ve Düzen',
      subtitle: 'Görev listeleri oluştur, notlarını renklerle kategorize et.',
      icon: Icons.checklist_outlined,
      lottieAsset: 'assets/lottie/checklist.json',
    ),
    _OnboardItem(
      title: 'AI Asistan ile Akış',
      subtitle: 'Sohbet ederek fikirlerini düzenle, hızlıca yol al.',
      icon: Icons.auto_awesome,
      lottieAsset: 'assets/lottie/ai_assistant.json',
    ),
  ];

  void _next() {
    if (_index < _items.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _finish();
    }
  }

  void _finish() {
    Navigator.of(context).pushReplacementNamed(LoginScreen.route);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      padded: false,
      body: Column(
        children: [
          _OnboardingHeader(onSkip: _finish),
          Expanded(
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (i) => setState(() => _index = i),
              itemCount: _items.length,
              itemBuilder: (context, i) => _OnboardCard(item: _items[i]),
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          _DotsIndicator(length: _items.length, index: _index),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacingXXL,
              AppTheme.spacingXL,
              AppTheme.spacingXXL,
              AppTheme.spacingXXXL,
            ),
            child: PrimaryButton(
              onPressed: _next,
              label: _index == _items.length - 1 ? 'Başla' : 'Devam',
              icon: _index == _items.length - 1 ? Icons.arrow_forward : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingHeader extends StatelessWidget {
  const _OnboardingHeader({required this.onSkip});

  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryPink.withOpacity(0.12),
                  AppTheme.secondaryPurple.withOpacity(0.06),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(AppTheme.radiusXXLarge),
                bottomRight: Radius.circular(AppTheme.radiusXXLarge),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingXXL,
                vertical: AppTheme.spacingXL,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradientLinear,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusXLarge,
                          ),
                          boxShadow: AppTheme.buttonShadow,
                        ),
                        child: const Icon(Icons.edit, color: Colors.white),
                      ),
                      const SizedBox(width: AppTheme.spacingM),
                      Text('thanette', style: AppTheme.textTheme.headlineSmall),
                      const Spacer(),
                      TertiaryButton(
                        onPressed: onSkip,
                        label: 'Atla',
                        expand: false,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    'Daha nazik ve modern not deneyimi.',
                    style: AppTheme.textTheme.headlineSmall?.copyWith(
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Text(
                    'Çizimlerden yapılacaklara ve AI asistanına kadar\nher şey tek yerde toplandı.',
                    style: AppTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -28,
            left: AppTheme.spacingXXL,
            right: AppTheme.spacingXXL,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingXXL,
                vertical: AppTheme.spacingL,
              ),
              decoration: BoxDecoration(
                color: AppTheme.backgroundPrimary,
                borderRadius: BorderRadius.circular(AppTheme.radiusXXLarge),
                boxShadow: AppTheme.primaryShadow,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome_outlined,
                    color: AppTheme.primaryPink,
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: Text(
                      'Akışınızı düzenleyin, fikirlerinizi daha hızlı yakalayın.',
                      style: AppTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? lottieAsset; // optional lottie path
  const _OnboardItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.lottieAsset,
  });
}

class _OnboardCard extends StatelessWidget {
  final _OnboardItem item;
  const _OnboardCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppTheme.spacingXXL,
        right: AppTheme.spacingXXL,
        top: AppTheme.spacingXXXL,
        bottom: AppTheme.spacingXL,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Illustration (try Lottie first, fallback to icon)
          SizedBox(
            width: 250,
            height: 250,
            child: item.lottieAsset != null
                ? Lottie.asset(
                    item.lottieAsset!,
                    repeat: true,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stack) {
                      return _IconCircle(icon: item.icon);
                    },
                  )
                : _IconCircle(icon: item.icon),
          ),
          const SizedBox(height: 24),
          Text(
            item.title,
            textAlign: TextAlign.center,
            style: AppTheme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            item.subtitle,
            textAlign: TextAlign.center,
            style: AppTheme.textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconCircle extends StatelessWidget {
  final IconData icon;
  const _IconCircle({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundTertiary.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
      child: Center(child: Icon(icon, size: 96, color: AppTheme.primaryPink)),
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  const _DotsIndicator({required this.length, required this.index});

  final int length;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: AppTheme.animationFast,
          curve: AppTheme.animationCurve,
          margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingS),
          height: 10,
          width: active ? 24 : 10,
          decoration: BoxDecoration(
            color: active
                ? AppTheme.primaryPink
                : AppTheme.primaryPink.withOpacity(0.18),
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          ),
        );
      }),
    );
  }
}
