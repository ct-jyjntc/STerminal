import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sterminal/src/l10n/l10n.dart';
import 'package:xterm/xterm.dart';

import '../../../core/app_providers.dart';
import '../../../domain/models/credential.dart';
import '../../../domain/models/host.dart';
import '../../connections/application/hosts_providers.dart';
import '../../snippets/application/snippet_providers.dart';
import '../../snippets/presentation/snippet_form_sheet.dart';
import '../../vault/application/credential_providers.dart';

class TerminalPage extends ConsumerStatefulWidget {
  const TerminalPage({super.key, required this.hostId});

  final String hostId;

  @override
  ConsumerState<TerminalPage> createState() => _TerminalPageState();
}

class _TerminalPageState extends ConsumerState<TerminalPage> {
  late final Terminal _terminal;
  final TerminalController _terminalController = TerminalController();
  SSHClient? _client;
  SSHSession? _session;
  StreamSubscription<Uint8List>? _stdoutSub;
  StreamSubscription<Uint8List>? _stderrSub;
  Host? _currentHost;
  Credential? _currentCredential;
  bool _connecting = false;
  String? _error;
  String? _autoConnectAttemptedHostId;

  @override
  void initState() {
    super.initState();
    _terminal = Terminal(
      maxLines: 10000,
      platform: TerminalTargetPlatform.macos,
    );
  }

  @override
  void dispose() {
    _stdoutSub?.cancel();
    _stderrSub?.cancel();
    _session?.close();
    _client?.close();
    _terminalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hostAsync = ref.watch(hostByIdProvider(widget.hostId));

    return hostAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.terminalHostError('$error'))),
      ),
      data: (host) {
        if (host == null) {
          return Scaffold(
            body: Center(child: Text(l10n.terminalHostRemoved)),
          );
        }
        final credentialAsync = ref.watch(
          credentialByIdProvider(host.credentialId),
        );
        return credentialAsync.when(
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Scaffold(
            appBar: AppBar(title: Text(host.name)),
            body: Center(child: Text(l10n.terminalCredentialError('$error'))),
          ),
          data: (credential) {
            if (credential == null) {
              return Scaffold(
                appBar: AppBar(title: Text(host.name)),
                body: Center(child: Text(l10n.terminalCredentialDeleted)),
              );
            }
            _maybeConnect(host, credential);
            final snippets = ref.watch(snippetsStreamProvider);
            final brightness = Theme.of(context).brightness;
            final isDark = brightness == Brightness.dark;
            final terminalTheme =
                isDark ? TerminalThemes.defaultTheme : _lightTerminalTheme;
            return Scaffold(
              appBar: AppBar(
                title: Text('${host.name} (${host.address}:${host.port})'),
                actions: [
                  IconButton(
                    tooltip: l10n.terminalReconnectTooltip,
                    onPressed: _connecting
                        ? null
                        : () {
                            setState(() {
                              _autoConnectAttemptedHostId = host.id;
                            });
                            _reconnect(host, credential);
                          },
                    icon: const Icon(Icons.refresh),
                  ),
                  IconButton(
                    tooltip: l10n.terminalNewSnippetTooltip,
                    onPressed: () => showSnippetFormSheet(context),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              body: Row(
                children: [
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: terminalTheme.background),
                      child: TerminalView(
                        _terminal,
                        controller: _terminalController,
                        autofocus: true,
                        padding: const EdgeInsets.all(16),
                        theme: terminalTheme,
                        keyboardAppearance:
                            isDark ? Brightness.dark : Brightness.light,
                        backgroundOpacity: 1.0,
                      ),
                    ),
                  ),
                  Container(
                    width: 280,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      border: const Border(left: BorderSide(color: Colors.white10)),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        ListTile(
                          title: Text(l10n.snippetsTitle),
                          trailing: IconButton(
                            icon: const Icon(Icons.add),
                            tooltip: l10n.terminalNewSnippetTooltip,
                            onPressed: () => showSnippetFormSheet(context),
                          ),
                        ),
                        Expanded(
                          child: snippets.when(
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (error, _) =>
                                Center(child: Text(l10n.genericErrorMessage('$error'))),
                            data: (items) {
                              if (items.isEmpty) {
                                return Center(
                                  child: Text(l10n.snippetsPanelHint),
                                );
                              }
                              return ListView.separated(
                                padding: const EdgeInsets.all(8),
                                itemBuilder: (context, index) {
                                  final snippet = items[index];
                                  return ListTile(
                                    dense: true,
                                    title: Text(snippet.title),
                                    subtitle: Text(
                                      snippet.command,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    onTap: () {
                                      _terminal.paste('${snippet.command}\r');
                                    },
                                  );
                                },
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemCount: items.length,
                              );
                            },
                          ),
                        ),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              _error!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _maybeConnect(Host host, Credential credential) {
    if (_autoConnectAttemptedHostId == host.id || _connecting) {
      return;
    }
    _autoConnectAttemptedHostId = host.id;
    if (_currentHost?.id == host.id &&
        _currentCredential?.id == credential.id &&
        _client != null) {
      return;
    }
    _reconnect(host, credential);
  }

  Future<void> _reconnect(Host host, Credential credential) async {
    final l10n = context.l10n;
    await _stdoutSub?.cancel();
    await _stderrSub?.cancel();
    _session?.close();
    _client?.close();
    setState(() {
      _connecting = true;
      _error = null;
    });
    _terminal.buffer.clear();
    _terminal.write('${l10n.terminalConnectingMessage(host.address)}\r\n');
    try {
      final socket = await SSHSocket.connect(host.address, host.port);
      final identities = <SSHKeyPair>[];
      if (credential.authKind == CredentialAuthKind.keyPair &&
          (credential.privateKey?.isNotEmpty ?? false)) {
        identities.addAll(
          SSHKeyPair.fromPem(
            credential.privateKey!,
            (credential.passphrase?.isEmpty ?? true)
                ? null
                : credential.passphrase,
          ),
        );
      }
      final client = SSHClient(
        socket,
        username: credential.username,
        identities: identities.isEmpty ? null : identities,
        onPasswordRequest: credential.authKind == CredentialAuthKind.password
            ? () => credential.password ?? ''
            : null,
      );
      final session = await client.shell(
        pty: SSHPtyConfig(
          type: 'xterm-256color',
          width: _terminal.viewWidth,
          height: _terminal.viewHeight,
        ),
      );
      _stdoutSub = session.stdout.listen(_onData);
      _stderrSub = session.stderr.listen(_onData);
      _terminal.onOutput = (data) {
        session.write(Uint8List.fromList(utf8.encode(data)));
      };
      _terminal.onResize = (width, height, pixelWidth, pixelHeight) {
        session.resizeTerminal(width, height, pixelWidth, pixelHeight);
      };
      if (!mounted) return;
      setState(() {
        _client = client;
        _session = session;
        _connecting = false;
        _currentHost = host;
        _currentCredential = credential;
        _error = null;
      });
      await ref.read(hostsRepositoryProvider).upsert(
            host.copyWith(
              lastConnectedAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
    } catch (error) {
      final message = l10n.terminalConnectionFailed('$error');
      if (mounted) {
        setState(() {
          _error = message;
          _connecting = false;
        });
      }
      _terminal.write('\r\n$message\r\n');
    }
  }

  void _onData(Uint8List data) {
    final text = utf8.decode(data);
    _terminal.write(text);
  }
}

const TerminalTheme _lightTerminalTheme = TerminalTheme(
  cursor: Color(0xFF1F1F1F),
  selection: Color(0x33212121),
  foreground: Color(0xFF202124),
  background: Color(0xFFF8F9FA),
  black: Color(0xFF000000),
  red: Color(0xFFB3261E),
  green: Color(0xFF0F9D58),
  yellow: Color(0xFFBC8B2C),
  blue: Color(0xFF1A73E8),
  magenta: Color(0xFF9336A6),
  cyan: Color(0xFF018786),
  white: Color(0xFFE5E5E5),
  brightBlack: Color(0xFF5F6368),
  brightRed: Color(0xFFE95420),
  brightGreen: Color(0xFF34A853),
  brightYellow: Color(0xFFF9AB00),
  brightBlue: Color(0xFF4285F4),
  brightMagenta: Color(0xFFAA46BB),
  brightCyan: Color(0xFF24C1C7),
  brightWhite: Color(0xFF202124),
  searchHitBackground: Color(0xFFFFFF8D),
  searchHitBackgroundCurrent: Color(0xFF8AB4F8),
  searchHitForeground: Color(0xFF000000),
);
