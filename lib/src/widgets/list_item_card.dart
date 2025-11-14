import 'package:flutter/material.dart';

class ListItemCard extends StatelessWidget {
  const ListItemCard({
    super.key,
    required this.leading,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    required this.actions,
    this.onTap,
    this.selected = false,
  });

  final String leading;
  final Color accentColor;
  final String title;
  final String subtitle;
  final List<Widget> actions;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).cardColor;
    final accentBackground = accentColor.withAlpha((0.08 * 255).round());
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: selected ? surface.withAlpha((0.92 * 255).round()) : surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((0.02 * 255).round()),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accentBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  leading,
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(color: accentColor, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: textColor?.withAlpha((0.65 * 255).round()),
                          ),
                    ),
                  ],
                ),
              ),
              if (actions.isNotEmpty) ...[
                const SizedBox(width: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: actions,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
