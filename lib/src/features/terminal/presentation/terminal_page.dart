import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sterminal/src/l10n/l10n.dart';
import 'package:xterm/xterm.dart';

import 'package:sterminal/l10n/app_localizations.dart';
import '../../../core/app_providers.dart';
import '../../../domain/models/credential.dart';
import '../../../domain/models/host.dart';
import '../../../domain/models/snippet.dart';
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
  SftpClient? _sftp;
  String _currentDirectory = '';
  List<SftpName> _fileEntries = const [];
  bool _loadingFiles = false;
  String? _fileError;
  Host? _currentHost;
  Credential? _currentCredential;
  bool _connecting = false;
  String? _error;
  String? _autoConnectAttemptedHostId;
  TerminalSidebarTab _sidebarTab = TerminalSidebarTab.commands;

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
    _sftp?.close();
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
              backgroundColor: Theme.of(context).colorScheme.surface,
              body: SafeArea(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(24, 8, 24, 4),
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 48),
                                  child: IconButton(
                                    icon: const Icon(Icons.arrow_back),
                                    tooltip: MaterialLocalizations.of(context)
                                        .backButtonTooltip,
                                    onPressed: () =>
                                        Navigator.of(context).maybePop(),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '${host.name} (${host.address}:${host.port})',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: DecoratedBox(
                                decoration:
                                    BoxDecoration(color: terminalTheme.background),
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
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 320,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        border:
                            const Border(left: BorderSide(color: Colors.white10)),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                            child: SegmentedButton<TerminalSidebarTab>(
                              segments: [
                                ButtonSegment(
                                  value: TerminalSidebarTab.files,
                                  label: Text(l10n.terminalSidebarFiles),
                                ),
                                ButtonSegment(
                                  value: TerminalSidebarTab.commands,
                                  label: Text(l10n.terminalSidebarCommands),
                                ),
                                ButtonSegment(
                                  value: TerminalSidebarTab.history,
                                  label: Text(l10n.terminalSidebarHistory),
                                ),
                              ],
                              selected: {_sidebarTab},
                              onSelectionChanged: (value) {
                                setState(() {
                                  _sidebarTab = value.first;
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: _buildSidebarContent(
                              context,
                              l10n,
                              snippets,
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
    _sftp?.close();
    setState(() {
      _connecting = true;
      _error = null;
      _sftp = null;
      _currentDirectory = '';
      _fileEntries = const [];
      _fileError = null;
      _loadingFiles = false;
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
      unawaited(_initSftp());
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

  Widget _buildSidebarContent(
    BuildContext context,
    AppLocalizations l10n,
    AsyncValue<List<Snippet>> snippets,
  ) {
    switch (_sidebarTab) {
      case TerminalSidebarTab.files:
        return _buildFilesSidebar(context, l10n);
      case TerminalSidebarTab.commands:
        return Column(
          children: [
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
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemCount: items.length,
                  );
                },
              ),
            ),
          ],
        );
      case TerminalSidebarTab.history:
        return Center(
          child: Text(
            l10n.terminalSidebarHistoryPlaceholder,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Theme.of(context).hintColor),
          ),
        );
    }
  }

  Widget _buildFilesSidebar(BuildContext context, AppLocalizations l10n) {
    if (_sftp == null) {
      return Center(
        child: Text(
          _connecting
              ? l10n.terminalSidebarFilesLoading
              : l10n.terminalSidebarFilesConnect,
        ),
      );
    }
    final hasPath = _currentDirectory.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  hasPath ? _currentDirectory : '',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: l10n.terminalSidebarFilesRefresh,
                onPressed: !_loadingFiles && hasPath
                    ? () => _loadDirectory(_currentDirectory)
                    : null,
              ),
            ],
          ),
        ),
        if (hasPath && _currentDirectory != '/')
          ListTile(
            dense: true,
            leading: const Icon(Icons.arrow_upward),
            title: Text(l10n.terminalSidebarFilesUp),
            onTap: _loadingFiles
                ? null
                : () => _loadDirectory(_parentDirectory(_currentDirectory)),
          ),
        Expanded(
          child: _buildFileList(context, l10n),
        ),
      ],
    );
  }

  Widget _buildFileList(BuildContext context, AppLocalizations l10n) {
    if (_loadingFiles) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_fileError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _fileError!,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _currentDirectory.isEmpty
                  ? null
                  : () => _loadDirectory(_currentDirectory),
              child: Text(l10n.terminalSidebarFilesRefresh),
            ),
          ],
        ),
      );
    }
    if (_fileEntries.isEmpty) {
      return Center(child: Text(l10n.terminalSidebarFilesEmpty));
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: _fileEntries.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final entry = _fileEntries[index];
        final isDir = _isDirectory(entry);
        return ListTile(
          dense: true,
          leading: Icon(isDir ? Icons.folder : Icons.insert_drive_file),
          title: Text(entry.filename),
          subtitle: !isDir && entry.attr.size != null
              ? Text(_formatFileSize(entry.attr.size!))
              : null,
          onTap: isDir
              ? () => _loadDirectory(_joinPath(_currentDirectory, entry.filename))
              : null,
        );
      },
    );
  }

  Future<void> _initSftp() async {
    final client = _client;
    if (client == null) return;
    final l10n = context.l10n;
    try {
      final sftp = await client.sftp();
      final root = await sftp.absolute('.');
      if (!mounted) {
        sftp.close();
        return;
      }
      _sftp?.close();
      setState(() {
        _sftp = sftp;
      });
      await _loadDirectory(root);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _fileError = l10n.terminalSidebarFilesError('$error');
        _loadingFiles = false;
      });
    }
  }

  Future<void> _loadDirectory(String path) async {
    final sftp = _sftp;
    if (sftp == null) return;
    final l10n = context.l10n;
    setState(() {
      _loadingFiles = true;
      _fileError = null;
    });
    try {
      final entries = await sftp.listdir(path);
      entries.removeWhere(
        (entry) => entry.filename == '.' || entry.filename == '..',
      );
      entries.sort((a, b) {
        final dirA = _isDirectory(a) ? 0 : 1;
        final dirB = _isDirectory(b) ? 0 : 1;
        if (dirA != dirB) return dirA - dirB;
        return a.filename.toLowerCase().compareTo(b.filename.toLowerCase());
      });
      if (!mounted) return;
      setState(() {
        _currentDirectory = path;
        _fileEntries = entries;
        _loadingFiles = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _fileError = l10n.terminalSidebarFilesError('$error');
        _loadingFiles = false;
      });
    }
  }

  bool _isDirectory(SftpName entry) {
    return entry.attr.mode?.type == SftpFileType.directory;
  }

  String _parentDirectory(String path) {
    if (path.isEmpty || path == '/') return '/';
    var normalized = path;
    if (normalized.endsWith('/') && normalized.length > 1) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    final index = normalized.lastIndexOf('/');
    if (index <= 0) return '/';
    return normalized.substring(0, index);
  }

  String _joinPath(String base, String child) {
    if (child.startsWith('/')) return child;
    var result = base.isEmpty ? '/' : base;
    if (!result.endsWith('/')) {
      result += '/';
    }
    return result == '//' ? '/$child' : '$result$child';
  }

  String _formatFileSize(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    double size = bytes.toDouble();
    var unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    return '${size.toStringAsFixed(unitIndex == 0 ? 0 : 1)} ${units[unitIndex]}';
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

enum TerminalSidebarTab { files, commands, history }
