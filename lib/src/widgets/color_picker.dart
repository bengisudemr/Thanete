import 'package:flutter/material.dart';

class ColorPicker extends StatelessWidget {
  final Color selectedColor;
  final ValueChanged<Color> onColorChanged;
  final List<Color> availableColors;

  const ColorPicker({
    super.key,
    required this.selectedColor,
    required this.onColorChanged,
    this.availableColors = const [
      Color(0xFFEC60FF), // Pink
      Color(0xFFFF4D79), // Red
      Color(0xFF667EEA), // Purple
      Color(0xFF764BA2), // Dark Purple
      Color(0xFF6EE7B7), // Green
      Color(0xFF3B82F6), // Blue
      Color(0xFFFBBF24), // Yellow
      Color(0xFFF59E0B), // Orange
      Color(0xFF8B5CF6), // Violet
      Color(0xFFEC4899), // Pink Red
      Color(0xFF10B981), // Emerald
      Color(0xFF059669), // Dark Green
      Color(0xFFEF4444), // Red
      Color(0xFF8B5A2B), // Brown
      Color(0xFF6B7280), // Gray
      Color(0xFF1F2937), // Dark Gray
    ],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEC60FF), Color(0xFFFF4D79)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.palette_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Renk Seç',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Color grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: availableColors.length,
            itemBuilder: (context, index) {
              final color = availableColors[index];
              final isSelected = color.value == selectedColor.value;

              return GestureDetector(
                onTap: () {
                  onColorChanged(color);
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: isSelected ? 12 : 6,
                        offset: const Offset(0, 4),
                      ),
                      if (isSelected)
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: isSelected
                      ? const Center(
                          child: Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 24,
                          ),
                        )
                      : null,
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          // Selected color preview
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: selectedColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selectedColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: selectedColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Seçili renk: ${_getColorName(selectedColor)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getColorName(Color color) {
    final colorMap = {
      const Color(0xFFEC60FF): 'Pembe',
      const Color(0xFFFF4D79): 'Kırmızı',
      const Color(0xFF667EEA): 'Mor',
      const Color(0xFF764BA2): 'Koyu Mor',
      const Color(0xFF6EE7B7): 'Yeşil',
      const Color(0xFF3B82F6): 'Mavi',
      const Color(0xFFFBBF24): 'Sarı',
      const Color(0xFFF59E0B): 'Turuncu',
      const Color(0xFF8B5CF6): 'Menekşe',
      const Color(0xFFEC4899): 'Pembe Kırmızı',
      const Color(0xFF10B981): 'Zümrüt',
      const Color(0xFF059669): 'Koyu Yeşil',
      const Color(0xFFEF4444): 'Kırmızı',
      const Color(0xFF8B5A2B): 'Kahverengi',
      const Color(0xFF6B7280): 'Gri',
      const Color(0xFF1F2937): 'Koyu Gri',
    };

    return colorMap[color] ?? 'Özel Renk';
  }
}
