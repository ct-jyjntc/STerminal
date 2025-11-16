import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sterminal/src/l10n/l10n.dart';

import '../../../core/app_providers.dart';
import '../../../domain/models/credential.dart';

Future<void> showCredentialFormSheet(
  BuildContext context, {
  Credential? credential,
}) {
  return showModalBottomSheet(
    useRootNavigator: true,
    context: context,
    isScrollControlled: true,
    builder: (_) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: CredentialFormSheet(credential: credential),
    ),
  );
}

class CredentialFormSheet extends ConsumerStatefulWidget {
  const CredentialFormSheet({super.key, this.credential});

  final Credential? credential;

  @override
  ConsumerState<CredentialFormSheet> createState() =>
      _CredentialFormSheetState();
}

class _CredentialFormSheetState extends ConsumerState<CredentialFormSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _privateKeyController;
  late final TextEditingController _passphraseController;
  late CredentialAuthKind _authKind;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final credential = widget.credential;
    _nameController = TextEditingController(text: credential?.name);
    _usernameController = TextEditingController(text: credential?.username);
    _passwordController = TextEditingController(text: credential?.password);
    _privateKeyController =
        TextEditingController(text: credential?.privateKey ?? '');
    _passphraseController =
        TextEditingController(text: credential?.passphrase ?? '');
    _authKind = credential?.authKind ?? CredentialAuthKind.password;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _privateKeyController.dispose();
    _passphraseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  widget.credential == null
                      ? l10n.credentialFormTitleNew
                      : l10n.credentialFormTitleEdit,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: l10n.credentialFormLabel),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _usernameController,
              decoration:
                  InputDecoration(labelText: l10n.credentialFormUsername),
            ),
            const SizedBox(height: 16),
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
              selected: {_authKind},
              onSelectionChanged: (value) {
                setState(() {
                  _authKind = value.first;
                });
              },
            ),
            const SizedBox(height: 16),
            if (_authKind == CredentialAuthKind.password)
              TextField(
                controller: _passwordController,
                decoration:
                    InputDecoration(labelText: l10n.credentialFormPassword),
                obscureText: true,
              )
            else
              Column(
                children: [
                  TextField(
                    controller: _privateKeyController,
                    decoration: InputDecoration(
                      labelText: l10n.credentialFormPrivateKey,
                    ),
                    maxLines: 6,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passphraseController,
                    decoration: InputDecoration(
                      labelText: l10n.credentialFormPassphrase,
                    ),
                    obscureText: true,
                  ),
                ],
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.credentialFormSave),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty ||
        _usernameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.credentialFormValidation)),
      );
      return;
    }

    final repo = ref.read(credentialsRepositoryProvider);
    final uuid = ref.read(uuidProvider);
    final now = DateTime.now();
    final updated = widget.credential?.copyWith(
          name: _nameController.text.trim(),
          username: _usernameController.text.trim(),
          authKind: _authKind,
          password: _authKind == CredentialAuthKind.password
              ? _passwordController.text
              : null,
          privateKey: _authKind == CredentialAuthKind.keyPair
              ? _privateKeyController.text.trim()
              : null,
          passphrase: _authKind == CredentialAuthKind.keyPair
              ? _passphraseController.text.trim().isEmpty
                  ? null
                  : _passphraseController.text.trim()
              : null,
          updatedAt: now,
        ) ??
        Credential(
          id: uuid.v4(),
          name: _nameController.text.trim(),
          username: _usernameController.text.trim(),
          authKind: _authKind,
          password: _authKind == CredentialAuthKind.password
              ? _passwordController.text
              : null,
          privateKey: _authKind == CredentialAuthKind.keyPair
              ? _privateKeyController.text.trim()
              : null,
          passphrase: _authKind == CredentialAuthKind.keyPair
              ? _passphraseController.text.trim().isEmpty
                  ? null
                  : _passphraseController.text.trim()
              : null,
          createdAt: now,
          updatedAt: now,
        );
    setState(() {
      _saving = true;
    });
    await repo.upsert(updated);
    if (!mounted) return;
    Navigator.of(context).pop();
  }
}
