import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sterminal/src/l10n/l10n.dart';

import '../../../../core/app_providers.dart';
import '../../../../domain/models/credential.dart';
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
  late final TextEditingController _descriptionController;
  late final TextEditingController _tagsController;
  late final TextEditingController _credentialNameController;
  late final TextEditingController _credentialUsernameController;
  late final TextEditingController _credentialPasswordController;
  late final TextEditingController _credentialPrivateKeyController;
  late final TextEditingController _credentialPassphraseController;
  String? _selectedGroup;
  String? _selectedCredential;
  late bool _isFavorite;
  late String _colorHex;
  bool _isSaving = false;
  bool _createCredentialInline = false;
  CredentialAuthKind _credentialAuthKind = CredentialAuthKind.password;

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
    _descriptionController = TextEditingController(text: host?.description);
    _tagsController = TextEditingController(
      text: host == null ? '' : host.tags.join(', '),
    );
    _credentialNameController = TextEditingController();
    _credentialUsernameController = TextEditingController();
    _credentialPasswordController = TextEditingController();
    _credentialPrivateKeyController = TextEditingController();
    _credentialPassphraseController = TextEditingController();
    _selectedGroup = host?.groupId;
    _selectedCredential = host?.credentialId;
    _isFavorite = host?.favorite ?? false;
    _colorHex = host?.colorHex ?? _colorOptions.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _portController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    _credentialNameController.dispose();
    _credentialUsernameController.dispose();
    _credentialPasswordController.dispose();
    _credentialPrivateKeyController.dispose();
    _credentialPassphraseController.dispose();
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
                if (items.isEmpty && !_createCredentialInline) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _createCredentialInline = true;
                      });
                    }
                  });
                }
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
                final showInline = _createCredentialInline || items.isEmpty;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (items.isNotEmpty) ...[
                      Row(
                        children: [
                          Expanded(
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: l10n.hostFormCredentialLabel,
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String?>(
                                  value: _selectedCredential,
                                  isExpanded: true,
                                  items: dropdownItems,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedCredential = value;
                                    });
                                  },
                                ),
                              ),
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
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _createCredentialInline = !_createCredentialInline;
                              if (!_createCredentialInline) {
                                _credentialNameController.clear();
                                _credentialUsernameController.clear();
                                _credentialPasswordController.clear();
                                _credentialPrivateKeyController.clear();
                                _credentialPassphraseController.clear();
                              }
                            });
                          },
                          icon: Icon(
                            showInline ? Icons.close : Icons.edit,
                          ),
                          label: Text(
                            showInline
                                ? l10n.hostFormInlineCancel
                                : l10n.hostFormInlineToggle,
                          ),
                        ),
                      ),
                    ],
                    if (showInline) ...[
                      const SizedBox(height: 12),
                      _CredentialInlineFields(
                        title: l10n.hostFormCredentialInlineTitle,
                        nameController: _credentialNameController,
                        usernameController: _credentialUsernameController,
                        passwordController: _credentialPasswordController,
                        privateKeyController: _credentialPrivateKeyController,
                        passphraseController: _credentialPassphraseController,
                        authKind: _credentialAuthKind,
                        onAuthKindChanged: (value) {
                          setState(() {
                            _credentialAuthKind = value;
                          });
                        },
                      ),
                    ],
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
                return InputDecorator(
                  decoration:
                      InputDecoration(labelText: l10n.hostFormGroupLabel),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _selectedGroup,
                      isExpanded: true,
                      items: dropdownItems,
                      onChanged: (value) {
                        setState(() {
                          _selectedGroup = value;
                        });
                      },
                    ),
                  ),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => Text(l10n.genericErrorMessage('$error')),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              minLines: 2,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.hostFormDescriptionLabel,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _tagsController,
              decoration: InputDecoration(
                labelText: l10n.hostFormTagsLabel,
              ),
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
                const Spacer(),
                Row(
                  children: [
                    Text(l10n.hostFormFavoriteLabel),
                    Switch(
                      value: _isFavorite,
                      onChanged: (value) {
                        setState(() {
                          _isFavorite = value;
                        });
                      },
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
    String? credentialId = _selectedCredential;
    if (credentialId == null && _createCredentialInline) {
      if (_credentialNameController.text.trim().isEmpty ||
          _credentialUsernameController.text.trim().isEmpty ||
          (_credentialAuthKind == CredentialAuthKind.password &&
              _credentialPasswordController.text.isEmpty) ||
          (_credentialAuthKind == CredentialAuthKind.keyPair &&
              _credentialPrivateKeyController.text.trim().isEmpty)) {
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.hostFormCredentialInlineRequired)),
          );
          return;
      }
      final credentialsRepo = ref.read(credentialsRepositoryProvider);
      final uuid = ref.read(uuidProvider);
      final credential = Credential(
        id: uuid.v4(),
        name: _credentialNameController.text.trim(),
        username: _credentialUsernameController.text.trim(),
        authKind: _credentialAuthKind,
        password: _credentialAuthKind == CredentialAuthKind.password
            ? _credentialPasswordController.text
            : null,
        privateKey: _credentialAuthKind == CredentialAuthKind.keyPair
            ? _credentialPrivateKeyController.text.trim()
            : null,
        passphrase: _credentialAuthKind == CredentialAuthKind.keyPair
            ? _credentialPassphraseController.text.trim().isEmpty
                ? null
                : _credentialPassphraseController.text.trim()
            : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await credentialsRepo.upsert(credential);
      credentialId = credential.id;
    }
    if (credentialId == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.hostFormCredentialMissing)),
      );
      return;
    }
    final port = int.tryParse(_portController.text) ?? 22;
    final now = DateTime.now();
    final tags = _tagsController.text
        .split(',')
        .map((e) => e.trim())
        .where((element) => element.isNotEmpty)
        .toList();
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
          favorite: _isFavorite,
          tags: tags,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
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
          favorite: _isFavorite,
          tags: tags,
          createdAt: now,
          updatedAt: now,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        );
    await repo.upsert(updatedHost);
    if (!mounted) return;
    setState(() {
      _isSaving = false;
    });
    Navigator.of(context).pop();
  }
}

class _CredentialInlineFields extends StatelessWidget {
  const _CredentialInlineFields({
    required this.title,
    required this.nameController,
    required this.usernameController,
    required this.passwordController,
    required this.privateKeyController,
    required this.passphraseController,
    required this.authKind,
    required this.onAuthKindChanged,
  });

  final String title;
  final TextEditingController nameController;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final TextEditingController privateKeyController;
  final TextEditingController passphraseController;
  final CredentialAuthKind authKind;
  final ValueChanged<CredentialAuthKind> onAuthKindChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final surface = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Card(
      color: surface.withAlpha((0.15 * 255).round()),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration:
                  InputDecoration(labelText: l10n.credentialFormLabel),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: usernameController,
              decoration:
                  InputDecoration(labelText: l10n.credentialFormUsername),
            ),
            const SizedBox(height: 12),
            SegmentedButton<CredentialAuthKind>(
              segments: [
                ButtonSegment(
                  value: CredentialAuthKind.password,
                  label: Text(l10n.credentialAuthPassword),
                  icon: const Icon(Icons.lock_outline),
                ),
                ButtonSegment(
                  value: CredentialAuthKind.keyPair,
                  label: Text(l10n.credentialAuthKeyPair),
                  icon: const Icon(Icons.vpn_key),
                ),
              ],
              selected: {authKind},
              onSelectionChanged: (value) => onAuthKindChanged(value.first),
            ),
            const SizedBox(height: 12),
            if (authKind == CredentialAuthKind.password)
              TextField(
                controller: passwordController,
                decoration:
                    InputDecoration(labelText: l10n.credentialFormPassword),
                obscureText: true,
              )
            else ...[
              TextField(
                controller: privateKeyController,
                decoration:
                    InputDecoration(labelText: l10n.credentialFormPrivateKey),
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passphraseController,
                decoration:
                    InputDecoration(labelText: l10n.credentialFormPassphrase),
                obscureText: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
