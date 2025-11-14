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
    required this.onEditRequested,
    required this.subtitle,
  });

  final Host host;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onConnectRequested;
  final VoidCallback onEditRequested;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final color = parseColor(host.colorHex);
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final accent = color.withAlpha((0.08 * 255).round());
    final surface = Theme.of(context).cardColor;

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
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: context.l10n.hostEdit,
                    onPressed: onEditRequested,
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: context.l10n.hostConnect,
                    onPressed: onConnectRequested,
                    icon: const Icon(Icons.play_arrow_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
