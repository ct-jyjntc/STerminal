import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sterminal/src/l10n/l10n.dart';

import '../../../../core/app_providers.dart';
import '../../../../domain/models/host.dart';
import '../../../../utils/color_utils.dart';
import '../../../groups/application/group_providers.dart';
import '../../../vault/application/credential_providers.dart';
import '../../../vault/presentation/credential_form_sheet.dart';

Future<void> showHostFormSheet(
  BuildContext context, {
  Host? host,
}) {
  return showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: HostFormSheet(host: host),
      );
    },
  );
}

class HostFormSheet extends ConsumerStatefulWidget {
  const HostFormSheet({super.key, this.host});

  final Host? host;

  @override
  ConsumerState<HostFormSheet> createState() => _HostFormSheetState();
}

class _HostFormSheetState extends ConsumerState<HostFormSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _portController;
  String? _selectedGroup;
  String? _selectedCredential;
  late String _colorHex;
  bool _isSaving = false;

  static const _colorOptions = [
    '#4DD0E1',
    '#9575CD',
    '#F06292',
    '#FFB74D',
    '#AED581',
    '#4FC3F7',
  ];

  @override
  void initState() {
    super.initState();
    final host = widget.host;
    _nameController = TextEditingController(text: host?.name);
    _addressController = TextEditingController(text: host?.address);
    _portController =
        TextEditingController(text: (host?.port ?? 22).toString());
    _selectedGroup = host?.groupId;
    _selectedCredential = host?.credentialId;
    _colorHex = host?.colorHex ?? _colorOptions.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final groups = ref.watch(groupsStreamProvider);
    final credentials = ref.watch(credentialsStreamProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  widget.host == null
                      ? l10n.hostFormTitleNew
                      : l10n.hostFormTitleEdit,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  onPressed:
                      _isSaving ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.hostFormDisplayName,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: l10n.hostFormHostLabel,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _portController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.hostFormPortLabel,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            credentials.when(
              data: (items) {
                final dropdownItems = [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(l10n.hostFormSelectCredential),
                  ),
                  for (final credential in items)
                    DropdownMenuItem(
                      value: credential.id,
                      child:
                          Text('${credential.name} (${credential.username})'),
                    ),
                ];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String?>(
                            initialValue: _selectedCredential,
                            decoration: InputDecoration(
                              labelText: l10n.hostFormCredentialLabel,
                            ),
                            isExpanded: true,
                            items: dropdownItems,
                            onChanged: (value) {
                              setState(() {
                                _selectedCredential = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          tooltip: l10n.hostFormCreateCredential,
                          onPressed: () async {
                            await showCredentialFormSheet(context);
                          },
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                    if (items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          l10n.hostFormCredentialMissing,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                  ],
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => Text(l10n.genericErrorMessage('$error')),
            ),
            const SizedBox(height: 16),
            groups.when(
              data: (items) {
                final dropdownItems = [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(l10n.hostFormNoGroupOption),
                  ),
                  for (final group in items)
                    DropdownMenuItem(
                      value: group.id,
                      child: Text(group.name),
                    ),
                ];
                return DropdownButtonFormField<String?>(
                  initialValue: _selectedGroup,
                  decoration:
                      InputDecoration(labelText: l10n.hostFormGroupLabel),
                  isExpanded: true,
                  items: dropdownItems,
                  onChanged: (value) {
                    setState(() {
                      _selectedGroup = value;
                    });
                  },
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => Text(l10n.genericErrorMessage('$error')),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(l10n.hostFormAccentLabel),
                const SizedBox(width: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final color in _colorOptions)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _colorHex = color;
                          });
                        },
                        child: Container(
                          height: 28,
                          width: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: parseColor(color),
                            border: _colorHex == color
                                ? Border.all(color: Colors.white, width: 2)
                                : null,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSaving ? null : _submit,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.hostFormSave),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    if (_nameController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.hostFormValidation)),
      );
      return;
    }
    final credentialId = _selectedCredential;
    if (credentialId == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.hostFormCredentialMissing)),
      );
      return;
    }
    final port = int.tryParse(_portController.text) ?? 22;
    final now = DateTime.now();
    setState(() {
      _isSaving = true;
    });
    final repo = ref.read(hostsRepositoryProvider);
    final uuid = ref.read(uuidProvider);
    final host = widget.host;
    final updatedHost = host?.copyWith(
          name: _nameController.text.trim(),
          address: _addressController.text.trim(),
          port: port,
          credentialId: credentialId,
          groupId: _selectedGroup,
          colorHex: _colorHex,
          updatedAt: now,
        ) ??
        Host(
          id: uuid.v4(),
          name: _nameController.text.trim(),
          address: _addressController.text.trim(),
          port: port,
          credentialId: credentialId,
          groupId: _selectedGroup,
          colorHex: _colorHex,
          tags: const [],
          createdAt: now,
          updatedAt: now,
          description: null,
        );
    await repo.upsert(updatedHost);
    if (!mounted) return;
    setState(() {
      _isSaving = false;
    });
    Navigator.of(context).pop();
  }
}
