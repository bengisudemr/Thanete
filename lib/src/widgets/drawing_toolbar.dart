import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:thanette/src/models/drawing.dart';
import 'package:thanette/src/providers/theme_provider.dart';

class DrawingToolbar extends StatelessWidget {
  final DrawingSettings settings;
  final Function(DrawingSettings) onSettingsChanged;
  final VoidCallback onUndo;
  final VoidCallback onClear;
  final VoidCallback onExit;
  final bool canUndo;
  final double maxHeight;

  const DrawingToolbar({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
    required this.onUndo,
    required this.onClear,
    required this.onExit,
    required this.canUndo,
    required this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.18),
            blurRadius: 16,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCircleButton(
                icon: CupertinoIcons.xmark,
                onPressed: onExit,
                background: CupertinoColors.systemGrey6,
                iconColor: theme.colorScheme.onSurface,
              ),
              const SizedBox(height: 8),
              _buildCircleButton(
                icon: CupertinoIcons.arrow_2_squarepath,
                onPressed: canUndo ? onUndo : null,
                background: theme.colorScheme.primary.withOpacity(0.12),
                iconColor: canUndo
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
              ),
              const SizedBox(height: 8),
              _buildCircleButton(
                icon: CupertinoIcons.delete_left,
                onPressed: onClear,
                background: CupertinoColors.systemRed.withOpacity(0.12),
                iconColor: CupertinoColors.systemRed,
              ),
              const SizedBox(height: 10),
              _buildToolButton(
                context,
                icon: CupertinoIcons.pencil,
                selected: settings.tool == DrawingTool.pen,
                onTap: () => _changeTool(DrawingTool.pen),
              ),
              const SizedBox(height: 8),
              _buildToolButton(
                context,
                icon: CupertinoIcons.paintbrush,
                selected: settings.tool == DrawingTool.highlighter,
                onTap: () => _changeTool(DrawingTool.highlighter),
              ),
              const SizedBox(height: 8),
              _buildToolButton(
                context,
                icon: CupertinoIcons.trash,
                selected: settings.tool == DrawingTool.eraser,
                onTap: () => _changeTool(DrawingTool.eraser),
              ),
              const SizedBox(height: 10),
              if (settings.tool != DrawingTool.eraser)
                _buildColorColumn(context),
              if (settings.tool != DrawingTool.eraser)
                const SizedBox(height: 10),
              _buildStrokeSlider(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required Color background,
    required Color iconColor,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minSize: 44,
      onPressed: onPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: Icon(
          icon,
          color: onPressed != null ? iconColor : iconColor.withOpacity(0.4),
          size: 22,
        ),
      ),
    );
  }

  Widget _buildToolButton(
    BuildContext context, {
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minSize: 44,
      onPressed: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: selected ? AppTheme.primaryGradientLinear : null,
          color: selected ? null : theme.colorScheme.surfaceVariant,
          border: Border.all(
            color: selected
                ? Colors.transparent
                : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: selected ? Colors.white : theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildColorColumn(BuildContext context) {
    final colors = <Color>[
      Colors.black,
      AppTheme.primaryPink,
      AppTheme.secondaryPurple,
      const Color(0xFF1D9BF0),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFF9333EA),
    ];

    return SizedBox(
      height: 120,
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: colors.length,
        itemBuilder: (context, index) {
          final color = colors[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: GestureDetector(
              onTap: () => onSettingsChanged(settings.copyWith(color: color)),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: settings.color == color
                        ? Colors.white
                        : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: settings.color == color
                    ? const Icon(
                        CupertinoIcons.check_mark,
                        size: 14,
                        color: Colors.white,
                      )
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStrokeSlider(BuildContext context) {
    final theme = Theme.of(context);
    final minValue = settings.tool == DrawingTool.highlighter
        ? 8.0
        : settings.tool == DrawingTool.eraser
        ? 5.0
        : 1.0;
    final maxValue = settings.tool == DrawingTool.highlighter
        ? 20.0
        : settings.tool == DrawingTool.eraser
        ? 50.0
        : 10.0;

    return Column(
      children: [
        SizedBox(
          height: 120,
          child: RotatedBox(
            quarterTurns: 3,
            child: CupertinoSlider(
              value: settings.strokeWidth.clamp(minValue, maxValue),
              min: minValue,
              max: maxValue,
              onChanged: (value) {
                onSettingsChanged(settings.copyWith(strokeWidth: value));
              },
              activeColor: theme.colorScheme.primary,
              thumbColor: theme.colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${settings.strokeWidth.round()}px',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  void _changeTool(DrawingTool tool) {
    DrawingSettings newSettings = settings.copyWith(tool: tool);

    switch (tool) {
      case DrawingTool.pen:
        newSettings = newSettings.copyWith(strokeWidth: 2.0, opacity: 1.0);
        break;
      case DrawingTool.highlighter:
        newSettings = newSettings.copyWith(strokeWidth: 12.0, opacity: 0.6);
        break;
      case DrawingTool.eraser:
        newSettings = newSettings.copyWith(strokeWidth: 20.0, opacity: 1.0);
        break;
    }

    onSettingsChanged(newSettings);
  }
}
