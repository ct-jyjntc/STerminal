import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';
import 'package:file_selector/file_selector.dart' as file_selector;
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
import '../../settings/application/settings_controller.dart';
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
  List<SftpName> _fileEntries = const <SftpName>[];
  bool _loadingFiles = false;
  String? _fileError;
  bool _entryContextMenuActive = false;
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
          child: _sidebarTab == TerminalSidebarTab.files
              ? _buildSidebarContentWithContextMenu(context, l10n, snippets)
              : _buildSidebarContent(context, l10n, snippets),
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
      _fileEntries = const <SftpName>[];
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

Widget _buildSidebarContentWithContextMenu(
  BuildContext context,
  AppLocalizations l10n,
  AsyncValue<List<Snippet>> snippets,
) {
  return _ContextMenuRegion(
    onShowMenu: (position) {
      if (_entryContextMenuActive) return;
      _showFileContextMenu(context, position);
    },
    child: _buildSidebarContent(context, l10n, snippets),
  );
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
        final VoidCallback onTap = isDir
            ? () =>
                _loadDirectory(_joinPath(_currentDirectory, entry.filename))
            : () => _openFilePreview(entry);
        return _HoverableItem(
          onTap: onTap,
          onContextMenu: (position) {
            _entryContextMenuActive = true;
            _showFileContextMenu(
              context,
              position,
              entry: entry,
            ).whenComplete(() => _entryContextMenuActive = false);
          },
          child: ListTile(
            dense: true,
            leading: Icon(isDir ? Icons.folder : Icons.insert_drive_file),
            title: Text(entry.filename),
            subtitle: !isDir && entry.attr.size != null
                ? Text(_formatFileSize(entry.attr.size!))
                : null,
            onTap: null,
          ),
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

  String _joinLocalPath(String base, String child) {
    if (base.isEmpty) return child;
    final separator = Platform.pathSeparator;
    var normalized = base;
    if (!normalized.endsWith(separator)) {
      normalized += separator;
    }
    return '$normalized$child';
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

  Future<void> _showFileContextMenu(
    BuildContext context,
    Offset position, {
    SftpName? entry,
  }) async {
    final overlay = Overlay.of(context);
    final renderBox = overlay.context.findRenderObject() as RenderBox;
    final rect = RelativeRect.fromRect(
      Rect.fromPoints(position, position),
      Offset.zero & renderBox.size,
    );
    final isDir = entry != null && _isDirectory(entry);
    final items = <PopupMenuEntry<_FileContextAction>>[
      PopupMenuItem(
        value: _FileContextAction.newFile,
        child: Text(context.l10n.terminalSidebarFilesNewFile),
      ),
      PopupMenuItem(
        value: _FileContextAction.newFolder,
        child: Text(context.l10n.terminalSidebarFilesNewFolder),
      ),
      PopupMenuItem(
        value: _FileContextAction.upload,
        child: Text(context.l10n.terminalSidebarFilesUpload),
      ),
    ];
    if (entry != null) {
      items.add(const PopupMenuDivider());
      items.add(
        PopupMenuItem(
          value: _FileContextAction.rename,
          child: Text(context.l10n.terminalSidebarFilesRename),
        ),
      );
      items.add(
        PopupMenuItem(
          value: _FileContextAction.download,
          enabled: !isDir,
          child: Text(context.l10n.terminalSidebarFilesDownload),
        ),
      );
      items.add(
        PopupMenuItem(
          value: _FileContextAction.delete,
          child: Text(context.l10n.terminalSidebarFilesDelete),
        ),
      );
    }
    final result = await showMenu<_FileContextAction>(
      context: context,
      position: rect,
      items: items,
    );
    if (result == null) return;
    if (!mounted) return;
    switch (result) {
      case _FileContextAction.newFile:
        await _handleCreateEntry(isDirectory: false);
        break;
      case _FileContextAction.newFolder:
        await _handleCreateEntry(isDirectory: true);
        break;
      case _FileContextAction.rename:
        if (entry != null) {
          await _handleRenameEntry(entry);
        }
        break;
      case _FileContextAction.download:
        if (entry != null && !isDir) {
          await _handleDownloadEntry(entry);
        }
        break;
      case _FileContextAction.upload:
        await _handleUploadFile();
        break;
      case _FileContextAction.delete:
        if (entry != null) {
          await _handleDeleteEntry(entry);
        }
        break;
    }
  }

  Future<void> _handleCreateEntry({
    required bool isDirectory,
  }) async {
    if (!_ensureSftpReady()) return;
    final l10n = context.l10n;
    final name = await _promptForInput(
      title: isDirectory
          ? l10n.terminalSidebarFilesNewFolderPrompt
          : l10n.terminalSidebarFilesNewFilePrompt,
    );
    if (name == null || name.trim().isEmpty) return;
    final path = _joinPath(_currentDirectory, name.trim());
    try {
      final sftp = _sftp!;
      if (isDirectory) {
        await sftp.mkdir(path);
      } else {
        final file = await sftp.open(
          path,
          mode: SftpFileOpenMode.create |
              SftpFileOpenMode.write |
              SftpFileOpenMode.truncate,
        );
        await file.close();
      }
      await _loadDirectory(_currentDirectory);
      if (!mounted) return;
      _showSnackBarMessage(l10n.terminalSidebarFilesRefreshSuccess);
    } catch (error) {
      if (!mounted) return;
      _showSnackBarMessage(l10n.terminalSidebarFilesError('$error'));
    }
  }

  Future<void> _handleRenameEntry(SftpName entry) async {
    if (!_ensureSftpReady()) return;
    final l10n = context.l10n;
    final name = await _promptForInput(
      title: l10n.terminalSidebarFilesRenamePrompt(entry.filename),
      initial: entry.filename,
    );
    if (name == null || name.trim().isEmpty || name == entry.filename) return;
    final newPath = _joinPath(_currentDirectory, name.trim());
    final oldPath = _joinPath(_currentDirectory, entry.filename);
    try {
      await _sftp!.rename(oldPath, newPath);
      await _loadDirectory(_currentDirectory);
      if (!mounted) return;
      _showSnackBarMessage(l10n.terminalSidebarFilesRefreshSuccess);
    } catch (error) {
      if (!mounted) return;
      _showSnackBarMessage(l10n.terminalSidebarFilesError('$error'));
    }
  }

  Future<void> _handleDeleteEntry(SftpName entry) async {
    if (!_ensureSftpReady()) return;
    final l10n = context.l10n;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.terminalSidebarFilesDeleteTitle),
        content: Text(
          l10n.terminalSidebarFilesDeleteConfirm(entry.filename),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.commonConfirm),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    if (!mounted) return;
    if (!mounted) return;
    final path = _joinPath(_currentDirectory, entry.filename);
    try {
      if (_isDirectory(entry)) {
        await _sftp!.rmdir(path);
      } else {
        await _sftp!.remove(path);
      }
      await _loadDirectory(_currentDirectory);
      if (!mounted) return;
      _showSnackBarMessage(l10n.terminalSidebarFilesRefreshSuccess);
    } catch (error) {
      if (!mounted) return;
      _showSnackBarMessage(l10n.terminalSidebarFilesError('$error'));
    }
  }

  Future<void> _handleDownloadEntry(SftpName entry) async {
    final sftp = _sftp;
    if (sftp == null) return;
    final l10n = context.l10n;
    final settings = ref.read(settingsControllerProvider);
    String? targetPath;
    if (settings.downloadDirectory?.isNotEmpty ?? false) {
      targetPath =
          _joinLocalPath(settings.downloadDirectory!, entry.filename);
    } else {
      final saveLocation = await file_selector.getSaveLocation(
        suggestedName: entry.filename,
      );
      if (saveLocation == null) return;
      targetPath = saveLocation.path;
    }
    final remotePath = _joinPath(_currentDirectory, entry.filename);
    try {
      final file = await sftp.open(remotePath, mode: SftpFileOpenMode.read);
      final bytes = await file.readBytes();
      await file.close();
      final output = File(targetPath);
      await output.parent.create(recursive: true);
      await output.writeAsBytes(bytes);
      if (!mounted) return;
      _showSnackBarMessage(
        l10n.terminalSidebarFilesDownloadSuccess(targetPath),
      );
    } catch (error) {
      if (!mounted) return;
      _showSnackBarMessage(
        l10n.terminalSidebarFilesDownloadFailure('$error'),
      );
    }
  }

  Future<void> _handleUploadFile() async {
    if (!_ensureSftpReady()) return;
    final l10n = context.l10n;
    final selected = await file_selector.openFile();
    if (selected == null) return;
    final data = await selected.readAsBytes();
    final remotePath = _joinPath(_currentDirectory, selected.name);
    try {
      final file = await _sftp!.open(
        remotePath,
        mode: SftpFileOpenMode.create |
            SftpFileOpenMode.write |
            SftpFileOpenMode.truncate,
      );
      await file.writeBytes(Uint8List.fromList(data));
      await file.close();
      await _loadDirectory(_currentDirectory);
      if (!mounted) return;
      _showSnackBarMessage(
        l10n.terminalSidebarFilesUploadSuccess(selected.name),
      );
    } catch (error) {
      if (!mounted) return;
      _showSnackBarMessage(
        l10n.terminalSidebarFilesUploadFailure('$error'),
      );
    }
  }

  Future<void> _openFilePreview(SftpName entry) async {
    if (_isDirectory(entry)) return;
    final sftp = _sftp;
    if (sftp == null) return;
    final l10n = context.l10n;
    final remotePath = _joinPath(_currentDirectory, entry.filename);
    try {
      final file = await sftp.open(remotePath, mode: SftpFileOpenMode.read);
      final bytes = await file.readBytes();
      await file.close();
      final text = utf8.decode(bytes, allowMalformed: true);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          final controller = TextEditingController(text: text);
          return AlertDialog(
            contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            title: Text(entry.filename),
            content: SizedBox(
              width: 600,
              child: TextField(
                controller: controller,
                maxLines: 24,
                decoration: InputDecoration(
                  hintText: l10n.terminalSidebarFilesEditHint,
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.commonCancel),
              ),
                FilledButton(
                  onPressed: () async {
                    final newText = controller.text;
                    final data = Uint8List.fromList(utf8.encode(newText));
                    final writer = await sftp.open(
                    remotePath,
                    mode: SftpFileOpenMode.write |
                        SftpFileOpenMode.truncate |
                        SftpFileOpenMode.create,
                  );
                  await writer.writeBytes(data);
                  await writer.close();
                  if (!mounted) return;
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                  _showSnackBarMessage(
                    l10n.terminalSidebarFilesSaveSuccess(entry.filename),
                  );
                },
                child: Text(l10n.terminalSidebarFilesSave),
              ),
            ],
          );
        },
      );
    } catch (error) {
      if (!mounted) return;
      _showSnackBarMessage(
        l10n.terminalSidebarFilesEditFailure('$error'),
      );
    }
  }

  Future<String?> _promptForInput({
    required String title,
    String initial = '',
  }) async {
    final controller = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isEmpty) return;
              Navigator.of(dialogContext).pop(value);
            },
            child: Text(context.l10n.commonConfirm),
          ),
        ],
      ),
    );
    controller.dispose();
    return result?.trim();
  }

  bool _ensureSftpReady() {
    if (_sftp == null || _currentDirectory.isEmpty) {
      _showSnackBarMessage(context.l10n.terminalSidebarFilesConnect);
      return false;
    }
    return true;
  }

  void _showSnackBarMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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

enum _FileContextAction {
  newFile,
  newFolder,
  rename,
  download,
  upload,
  delete,
}

class _ContextMenuRegion extends StatefulWidget {
  const _ContextMenuRegion({required this.child, required this.onShowMenu});

  final Widget child;
  final ValueChanged<Offset> onShowMenu;

  @override
  State<_ContextMenuRegion> createState() => _ContextMenuRegionState();
}

class _HoverableItem extends StatelessWidget {
  const _HoverableItem({
    required this.child,
    required this.onContextMenu,
    required this.onTap,
  });

  final Widget child;
  final ValueChanged<Offset> onContextMenu;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onSecondaryTapDown: (details) =>
            onContextMenu(details.globalPosition),
        hoverColor: Theme.of(context).hoverColor,
        child: child,
      ),
    );
  }
}

class _ContextMenuRegionState extends State<_ContextMenuRegion> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onSecondaryTapDown: (details) async {
        setState(() => _pressed = true);
        widget.onShowMenu(details.globalPosition);
        await Future.delayed(const Duration(milliseconds: 80));
        if (mounted) {
          setState(() => _pressed = false);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        color: _pressed
            ? Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.4)
            : null,
        child: widget.child,
      ),
    );
  }
}
