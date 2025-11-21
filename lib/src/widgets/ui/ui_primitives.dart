import 'package:flutter/material.dart';
import 'package:thanette/src/providers/theme_provider.dart';

/// Shared layout primitives for the refreshed Thanette UI.
///
/// These widgets wrap core Material 3 components with a consistent spacing,
/// typography and elevation language. They aim to keep the UI minimal, soft,
/// and user-friendly while preserving all existing functionality hooks.

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.body,
    this.title,
    this.actions,
    this.leading,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.background,
    this.safeArea = true,
    this.padded = true,
  });

  final Widget body;
  final String? title;
  final List<Widget>? actions;
  final Widget? leading;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Color? background;
  final bool safeArea;
  final bool padded;

  @override
  Widget build(BuildContext context) {
    final scaffoldBody = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null || leading != null || (actions?.isNotEmpty ?? false))
          AppTopBar(title: title, leading: leading, actions: actions),
        Expanded(
          child: padded
              ? Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingXXL,
                    vertical: AppTheme.spacingXL,
                  ),
                  child: body,
                )
              : body,
        ),
      ],
    );

    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: background ?? theme.scaffoldBackgroundColor,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: safeArea ? SafeArea(child: scaffoldBody) : scaffoldBody,
    );
  }
}

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.centerTitle = false,
  });

  final String? title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool centerTitle;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingXXL,
        vertical: AppTheme.spacingL,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              if (leading != null)
                Padding(
                  padding: const EdgeInsets.only(left: AppTheme.spacingL),
                  child: leading!,
                ),
              if (leading == null) const SizedBox(width: AppTheme.spacingL),
              Expanded(
                child: Text(
                  title ?? '',
                  textAlign: centerTitle ? TextAlign.center : TextAlign.start,
                  style: theme.textTheme.titleLarge,
                ),
              ),
              if (actions != null && actions!.isNotEmpty)
                Row(mainAxisSize: MainAxisSize.min, children: actions!),
              const SizedBox(width: AppTheme.spacingL),
            ],
          ),
        ),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.expand = true,
  });

  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final child = icon != null
        ? Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: expand
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: AppTheme.spacingS),
              Text(label),
            ],
          )
        : Text(label);

    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: Size(expand ? double.infinity : 0, 48),
      ),
      child: child,
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.expand = true,
  });

  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final child = icon != null
        ? Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: expand
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: AppTheme.spacingS),
              Text(label),
            ],
          )
        : Text(label);

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: Size(expand ? double.infinity : 0, 48),
      ),
      child: child,
    );
  }
}

class TertiaryButton extends StatelessWidget {
  const TertiaryButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.expand = true,
  });

  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final child = icon != null
        ? Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: expand
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: AppTheme.spacingS),
              Text(label),
            ],
          )
        : Text(label);

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: Size(expand ? double.infinity : 0, 48),
      ),
      child: child,
    );
  }
}

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppTheme.spacingXXL),
    this.margin,
    this.onTap,
    this.borderColor,
    this.borderWidth = 1,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? borderColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        border: Border.all(
          color: borderColor ?? theme.colorScheme.outline,
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: onTap != null
          ? InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
              onTap: onTap,
              child: card,
            )
          : card,
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(
        bottom: AppTheme.spacingL,
        top: AppTheme.spacingXXL,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleLarge),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppTheme.spacingS),
                    child: Text(
                      subtitle!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.primaryAction,
    this.secondaryAction,
    this.icon,
  });

  final String title;
  final String message;
  final Widget? primaryAction;
  final Widget? secondaryAction;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingXXXL,
        vertical: AppTheme.spacingXXXL,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) Icon(icon, size: 48, color: theme.colorScheme.primary),
          Text(
            title,
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (primaryAction != null || secondaryAction != null)
            Padding(
              padding: const EdgeInsets.only(top: AppTheme.spacingXXL),
              child: Column(
                children: [
                  if (primaryAction != null) primaryAction!,
                  if (secondaryAction != null) ...[
                    const SizedBox(height: AppTheme.spacingM),
                    secondaryAction!,
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

