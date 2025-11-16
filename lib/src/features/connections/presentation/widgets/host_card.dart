import 'package:flutter/material.dart';
import 'package:sterminal/src/l10n/l10n.dart';

import '../../../../domain/models/host.dart';
import '../../../../widgets/list_item_card.dart';

class HostCard extends StatelessWidget {
  const HostCard({
    super.key,
    required this.host,
    required this.selected,
    required this.onTap,
    required this.onConnectRequested,
    required this.onEditRequested,
    required this.onDeleteRequested,
    required this.subtitle,
  });

  final Host host;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onConnectRequested;
  final VoidCallback onEditRequested;
  final VoidCallback onDeleteRequested;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListItemCard(
      title: host.name,
      subtitle: subtitle,
      onTap: onTap,
      selected: selected,
      actions: [
        IconButton(
          tooltip: context.l10n.hostConnect,
          onPressed: onConnectRequested,
          icon: const Icon(Icons.play_arrow_rounded),
        ),
        IconButton(
          tooltip: context.l10n.hostEdit,
          onPressed: onEditRequested,
          icon: const Icon(Icons.edit_outlined),
        ),
        IconButton(
          tooltip: context.l10n.hostDeleteTooltip,
          onPressed: onDeleteRequested,
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    );
  }
}
