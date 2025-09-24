import 'package:flutter/material.dart';

class ThanetteLogo extends StatelessWidget {
  final double size;
  final bool showText;
  const ThanetteLogo({super.key, this.size = 72, this.showText = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _imageOrFallback(size),
        if (showText) ...[
          const SizedBox(height: 12),
          _gradientText(
            'thanette',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          ),
        ],
      ],
    );
  }

  Widget _imageOrFallback(double size) {
    // Use gradient logo for now - asset will be added later
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFFEC60FF), Color(0xFFFF4D79)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: _gradientText(
        't',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 40,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  static Widget _gradientText(String text, {required TextStyle style}) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Color(0xFFEC60FF), Color(0xFFFF4D79)],
      ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
      child: Text(text, style: style.copyWith(color: Colors.white)),
    );
  }
}
