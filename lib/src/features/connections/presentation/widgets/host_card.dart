import 'package:flutter/material.dart';
import 'package:sterminal/src/l10n/l10n.dart';

import '../../../../domain/models/host.dart';
import '../../../../utils/color_utils.dart';

class HostCard extends StatelessWidget {
  const HostCard({
    super.key,
    required this.host,
    required this.selected,
    required this.onTap,
    required this.onConnectRequested,
    required this.onFavoriteToggle,
    required this.onEditRequested,
    required this.subtitle,
    required this.lastConnectionLabel,
  });

  final Host host;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onConnectRequested;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onEditRequested;
  final String subtitle;
  final String lastConnectionLabel;

  @override
  Widget build(BuildContext context) {
    final color = parseColor(host.colorHex);
    final borderColor = selected
        ? color
        : Theme.of(context)
            .colorScheme
            .outline
            .withAlpha((0.2 * 255).round());
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final accent = color.withAlpha((0.1 * 255).round());

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).cardColor,
          border: Border.all(color: borderColor, width: 1.1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.03 * 255).round()),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                host.name.characters.first.toUpperCase(),
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: color, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          host.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        onPressed: onFavoriteToggle,
                        icon: Icon(
                          host.favorite
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          size: 20,
                          color: host.favorite
                              ? color
                              : textColor?.withAlpha((0.45 * 255).round()),
                        ),
                      ),
                    ],
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
                  const SizedBox(height: 4),
                  Text(
                    lastConnectionLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: textColor?.withAlpha((0.7 * 255).round()),
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                minimumSize: const Size(0, 0),
              ),
              onPressed: onConnectRequested,
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: Text(context.l10n.hostConnect),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                minimumSize: const Size(0, 0),
              ),
              onPressed: onEditRequested,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: Text(context.l10n.hostEdit),
            ),
          ],
        ),
      ),
    );
  }
}
