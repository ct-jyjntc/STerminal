import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dartssh2/dartssh2.dart';
import 'package:file_selector/file_selector.dart' as file_selector;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:sterminal/src/l10n/l10n.dart';
import 'package:xterm/xterm.dart';

import 'package:sterminal/l10n/app_localizations.dart';
import '../../../core/app_providers.dart';
import '../../../domain/models/credential.dart';
import '../../../domain/models/host.dart';
import '../../../domain/models/snippet.dart';
import '../../connections/application/hosts_providers.dart';
import '../application/command_history_service.dart';
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
  String _rootDirectory = '';
  String _currentDirectory = '';
  late final TextEditingController _pathController;
  List<_FileNode> _fileTree = const <_FileNode>[];
  List<Snippet> _snippetCache = const [];
  Set<String> _loadingPaths = <String>{};
  bool _initialFileLoading = false;
  String? _fileError;
  bool _entryContextMenuActive = false;
  List<String> _commandHistory = const [];
  final StringBuffer _commandBuffer = StringBuffer();
  late final CommandHistoryService _historyService;
  Host? _currentHost;
  Credential? _currentCredential;
  bool _connecting = false;
  String? _error;
  String? _autoConnectAttemptedHostId;
  TerminalSidebarTab _sidebarTab = TerminalSidebarTab.commands;

  @override
  void initState() {
    super.initState();
    _historyService = ref.read(commandHistoryServiceProvider);
    _loadHistory();
    _pathController = TextEditingController();
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
    _pathController.dispose();
    _terminalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hostAsync = ref.watch(hostByIdProvider(widget.hostId));
    final isStandaloneWindow =
        ref.watch(windowArgumentsProvider).shouldStartInTerminal;

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
            snippets.whenData((items) {
              _snippetCache = items;
            });
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
                            padding: isStandaloneWindow
                                ? const EdgeInsets.fromLTRB(66, 16, 24, 4)
                                : const EdgeInsets.fromLTRB(24, 8, 24, 4),
                            child: Row(
                              children: [
                                if (!isStandaloneWindow)
                                  ...[
                                    Padding(
                                      padding: const EdgeInsets.only(left: 48),
                                      child: IconButton(
                                        icon: const Icon(Icons.arrow_back),
                                        tooltip:
                                            MaterialLocalizations.of(context)
                                                .backButtonTooltip,
                                        onPressed: () =>
                                            Navigator.of(context).maybePop(),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                  ]
                                else
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
                        keyboardType: TextInputType.multiline,
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
      _rootDirectory = '';
      _updateCurrentDirectory('');
      _fileTree = const <_FileNode>[];
      _fileError = null;
      _loadingPaths = <String>{};
      _initialFileLoading = false;
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
        final shouldSend = _handleTerminalInput(data);
        if (shouldSend) {
          session.write(Uint8List.fromList(utf8.encode(data)));
        }
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

  bool _handleTerminalInput(String data) {
    for (final codePoint in data.runes) {
      if (codePoint == 9) {
        // Tab pressed: show local completion suggestions instead of sending to host.
        final current = _commandBuffer.toString();
        unawaited(_showCompletionSuggestions(prefix: current));
        return false;
      }
      if (codePoint == 13 || codePoint == 10) {
        final command = _commandBuffer.toString().trim();
        _commandBuffer.clear();
        if (command.isNotEmpty) {
          final limit =
              ref.read(settingsControllerProvider).historyLimit.clamp(10, 200);
          final history = List<String>.from(_commandHistory);
          history.remove(command);
          history.insert(0, command);
          if (history.length > limit) {
            history.removeRange(limit, history.length);
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              _commandHistory = history;
            });
          });
          _historyService.save(history);
        }
      } else if (codePoint == 127 || codePoint == 8) {
        if (_commandBuffer.isNotEmpty) {
          final text = _commandBuffer.toString();
          _commandBuffer
            ..clear()
            ..write(text.substring(0, text.length - 1));
        }
      } else if (codePoint >= 32) {
        _commandBuffer.write(String.fromCharCode(codePoint));
      }
    }
    return true;
  }

  Future<void> _loadHistory() async {
    final stored = _historyService.load();
    if (!mounted) return;
    setState(() {
      _commandHistory = List.unmodifiable(stored);
    });
  }

  Future<void> _showCompletionSuggestions({required String prefix}) async {
    if (!mounted) return;
    final lowerPrefix = prefix.toLowerCase();
    final historyMatches = _commandHistory.where((cmd) {
      if (lowerPrefix.isEmpty) return true;
      return cmd.toLowerCase().startsWith(lowerPrefix);
    });
    final snippetMatches = _snippetCache
        .map((s) => s.command)
        .where((cmd) {
          if (lowerPrefix.isEmpty) return true;
          return cmd.toLowerCase().startsWith(lowerPrefix);
        });
    final seen = <String>{};
    final suggestions = <String>[];
    for (final cmd in [...historyMatches, ...snippetMatches]) {
      final trimmed = cmd.trim();
      if (trimmed.isEmpty || seen.contains(trimmed)) continue;
      seen.add(trimmed);
      suggestions.add(trimmed);
      if (suggestions.length >= 15) break;
    }
    if (suggestions.isEmpty) {
      _showSnackBarMessage(context.l10n.terminalSidebarHistoryEmpty);
      return;
    }
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      constraints: const BoxConstraints(maxHeight: 440),
      builder: (sheetContext) {
        return ListView.separated(
          itemCount: suggestions.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final suggestion = suggestions[index];
            return ListTile(
              dense: true,
              leading: const Icon(Icons.keyboard_tab),
              title: Text(suggestion),
              onTap: () => Navigator.of(sheetContext).pop(suggestion),
            );
          },
        );
      },
    );
    if (selected != null && selected.isNotEmpty) {
      final current = _commandBuffer.toString();
      if (selected.startsWith(current)) {
        final remaining = selected.substring(current.length);
        _terminal.paste('$remaining ');
        _commandBuffer
          ..clear()
          ..write('$selected ');
      } else {
        // Fall back to sending full suggestion.
        _terminal.paste('$selected ');
        _commandBuffer
          ..clear()
          ..write('$selected ');
      }
    }
  }

  Widget _buildSidebarContentWithContextMenu(
    BuildContext context,
    AppLocalizations l10n,
    AsyncValue<List<Snippet>> snippets,
  ) {
    return _ContextMenuRegion(
      onShowMenu: (position) {
        if (_entryContextMenuActive) return;
        _showFileContextMenu(context, position, parentPath: _currentDirectory);
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
        return _buildHistorySidebar(context, l10n);
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
    final isRefreshing =
        _initialFileLoading || _loadingPaths.contains(_currentDirectory);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _pathController,
                  enabled: !isRefreshing,
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: l10n.terminalSidebarFiles,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 8,
                    ),
                  ),
                  onSubmitted: (value) {
                    final trimmed = value.trim();
                    if (trimmed.isEmpty || isRefreshing) return;
                    _loadDirectory(trimmed);
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: l10n.terminalSidebarFilesRefresh,
                onPressed: !isRefreshing && hasPath
                    ? () => _loadDirectory(_currentDirectory)
                    : null,
              ),
            ],
          ),
        ),
        Expanded(
          child: _buildFileList(context, l10n),
        ),
      ],
    );
  }

  Widget _buildHistorySidebar(
      BuildContext context, AppLocalizations l10n) {
    if (_commandHistory.isEmpty) {
      return Center(
        child: Text(
          l10n.terminalSidebarHistoryEmpty,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Theme.of(context).hintColor),
        ),
      );
    }
    return Column(
      children: [
        ListTile(
          title: Text(l10n.terminalSidebarHistoryTitle),
          trailing: IconButton(
            tooltip: l10n.terminalSidebarHistoryClear,
            onPressed: () {
              setState(() {
                _commandHistory = const [];
              });
              _historyService.clear();
            },
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemBuilder: (context, index) {
              final command = _commandHistory[index];
              return ListTile(
                dense: true,
                title: Text(command),
                onTap: () {
                  _terminal.textInput('$command ');
                },
              );
            },
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemCount: _commandHistory.length,
          ),
        ),
      ],
    );
  }

  Widget _buildFileList(BuildContext context, AppLocalizations l10n) {
    if (_initialFileLoading && _fileTree.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_fileError != null && _fileTree.isEmpty) {
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
    if (_fileTree.isEmpty) {
      return Center(child: Text(l10n.terminalSidebarFilesEmpty));
    }
    final flatNodes = _flattenTree(_fileTree);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: flatNodes.length,
      itemBuilder: (context, index) {
        final display = flatNodes[index];
        final node = display.node;
        final isDir = node.isDir;
        final depth = display.depth;
        final parentPath = _parentDirectory(node.path);
        return _HoverableItem(
          onTap: () async {
            if (isDir) {
              await _toggleDirectory(node);
            } else {
              setState(() {
                _currentDirectory = parentPath;
              });
              await _openFilePreview(node.entry, parentPath);
            }
          },
          onContextMenu: (position) {
            _entryContextMenuActive = true;
            _updateCurrentDirectory(node.isDir ? node.path : parentPath);
            _showFileContextMenu(
              context,
              position,
              entry: node.entry,
              parentPath: node.isDir ? node.path : parentPath,
              fullPath: node.path,
            ).whenComplete(() => _entryContextMenuActive = false);
          },
          child: Row(
            children: [
              SizedBox(width: depth * 12.0),
              if (isDir)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: _buildExpandIcon(node),
                )
              else
                const SizedBox(width: 28),
              Expanded(
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading:
                      Icon(isDir ? Icons.folder : Icons.insert_drive_file),
                  title: Text(node.name),
                  subtitle: !isDir && node.entry.attr.size != null
                      ? Text(_formatFileSize(node.entry.attr.size!))
                      : null,
                  trailing: !isDir && node.isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : !isDir && node.error != null
                          ? const Icon(Icons.error_outline,
                              color: Colors.redAccent)
                          : null,
                  onTap: null,
                ),
              ),
            ],
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
      final homePath = await sftp.absolute('.');
      const rootPath = '/';
      if (!mounted) {
        sftp.close();
        return;
      }
      _sftp?.close();
      setState(() {
        _sftp = sftp;
        _rootDirectory = rootPath;
        _updateCurrentDirectory(rootPath);
        _fileTree = const <_FileNode>[];
        _fileError = null;
        _loadingPaths = {rootPath};
        _initialFileLoading = true;
      });
      final loadedRoot = await _loadDirectory(rootPath);
      if (!loadedRoot && homePath != rootPath) {
        // Fallback to the user's home directory if root is not accessible.
        setState(() {
          _rootDirectory = homePath;
          _updateCurrentDirectory(homePath);
          _fileTree = const <_FileNode>[];
          _fileError = null;
          _loadingPaths = {homePath};
          _initialFileLoading = true;
        });
        await _loadDirectory(homePath);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _fileError = l10n.terminalSidebarFilesError('$error');
        _initialFileLoading = false;
      });
    }
  }

  Future<bool> _loadDirectory(String path, {bool setCurrent = true}) async {
    final sftp = _sftp;
    if (sftp == null) return false;
    final l10n = context.l10n;
    setState(() {
      if (setCurrent) _updateCurrentDirectory(path);
      _fileError = null;
      _loadingPaths = {..._loadingPaths, path};
      _fileTree = _updateNode(
        _fileTree,
        path,
        (node) => node.copyWith(
          isLoading: true,
          error: null,
          isExpanded: true,
        ),
      );
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
      if (!mounted) return false;
      final nodes = entries
          .map(
            (entry) => _FileNode(
              name: entry.filename,
              path: _joinPath(path, entry.filename),
              entry: entry,
              isDir: _isDirectory(entry),
            ),
          )
          .toList();
      setState(() {
        final isRootPath = path == _rootDirectory || _fileTree.isEmpty;
        _fileTree = _setChildrenForPath(
          _fileTree,
          path,
          nodes,
          isRootPath: isRootPath,
        );
        _loadingPaths = {..._loadingPaths}..remove(path);
        _initialFileLoading = false;
      });
      return true;
    } catch (error) {
      if (!mounted) return false;
      final message = l10n.terminalSidebarFilesError('$error');
      setState(() {
        _fileError = message;
        _loadingPaths = {..._loadingPaths}..remove(path);
        _fileTree = _updateNode(
          _fileTree,
          path,
          (node) => node.copyWith(
            isLoading: false,
            error: message,
          ),
        );
        _initialFileLoading = false;
      });
      return false;
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

  List<_FileNode> _setChildrenForPath(
    List<_FileNode> nodes,
    String path,
    List<_FileNode> children, {
    bool isRootPath = false,
  }) {
    if (isRootPath && (nodes.isEmpty || path == _rootDirectory)) {
      return children;
    }
    return _updateNode(
      nodes,
      path,
      (node) => node.copyWith(
        children: children,
        isExpanded: true,
        isLoading: false,
        error: null,
      ),
    );
  }

  List<_FileNode> _updateNode(
    List<_FileNode> nodes,
    String path,
    _FileNode Function(_FileNode) transform,
  ) {
    return nodes
        .map((node) {
          if (node.path == path) {
            return transform(node);
          }
          if (path.startsWith('${node.path}/')) {
            return node.copyWith(
              children: _updateNode(node.children, path, transform),
            );
          }
          return node;
        })
        .toList(growable: false);
  }

  bool _isTextFile(String filename) {
    final lower = filename.toLowerCase();
    const allowedNames = {
      'readme',
      'license',
    };
    if (allowedNames.contains(lower)) return true;
    final dotIndex = lower.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == lower.length - 1) return false;
    final ext = lower.substring(dotIndex + 1);
    const textExts = {
      'txt',
      'log',
      'conf',
      'ini',
      'json',
      'yaml',
      'yml',
      'sh',
      'bash',
      'zsh',
      'py',
      'js',
      'ts',
      'md',
      'properties',
      'cfg',
      'env',
      'bashrc',
      'zshrc',
      'profile',
      'bash_profile',
      'gitconfig',
      'gitignore',
    };
    return textExts.contains(ext);
  }

  MonacoLanguage _languageForFilename(String filename) {
    final lower = filename.toLowerCase();
    if (lower == 'dockerfile') return MonacoLanguage.dockerfile;
    if (lower.endsWith('makefile')) return MonacoLanguage.shell;
    if (lower.endsWith('bashrc') || lower.endsWith('zshrc')) {
      return MonacoLanguage.shell;
    }
    final dotIndex = lower.lastIndexOf('.');
    final ext = dotIndex >= 0 ? lower.substring(dotIndex + 1) : lower;
    switch (ext) {
      case 'dart':
        return MonacoLanguage.dart;
      case 'js':
      case 'mjs':
        return MonacoLanguage.javascript;
      case 'ts':
      case 'tsx':
        return MonacoLanguage.typescript;
      case 'json':
        return MonacoLanguage.json;
      case 'yaml':
      case 'yml':
        return MonacoLanguage.yaml;
      case 'md':
      case 'markdown':
        return MonacoLanguage.markdown;
      case 'sh':
      case 'bash':
      case 'zsh':
        return MonacoLanguage.shell;
      case 'py':
        return MonacoLanguage.python;
      case 'go':
        return MonacoLanguage.go;
      case 'rs':
        return MonacoLanguage.rust;
      case 'rb':
        return MonacoLanguage.ruby;
      case 'php':
        return MonacoLanguage.php;
      case 'java':
        return MonacoLanguage.java;
      case 'kt':
      case 'kts':
        return MonacoLanguage.kotlin;
      case 'swift':
        return MonacoLanguage.swift;
      case 'c':
        return MonacoLanguage.c;
      case 'cc':
      case 'cpp':
      case 'cxx':
      case 'hpp':
        return MonacoLanguage.cpp;
      case 'cs':
        return MonacoLanguage.csharp;
      case 'html':
      case 'htm':
        return MonacoLanguage.html;
      case 'css':
      case 'scss':
        return MonacoLanguage.css;
      case 'ini':
      case 'conf':
      case 'cfg':
        return MonacoLanguage.ini;
      case 'sql':
        return MonacoLanguage.sql;
      case 'xml':
        return MonacoLanguage.xml;
      case 'txt':
      case 'log':
        return MonacoLanguage.plaintext;
      default:
        return MonacoLanguage.plaintext;
    }
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

  void _updateCurrentDirectory(String path) {
    _currentDirectory = path;
    _pathController.text = path;
  }

  Future<void> _toggleDirectory(_FileNode node) async {
    if (!_ensureSftpReady()) return;
    final shouldExpand = !node.isExpanded;
    if (shouldExpand) {
      setState(() {
        _updateCurrentDirectory(node.path);
        _fileTree = _updateNode(
          _fileTree,
          node.path,
          (current) => current.copyWith(
            isExpanded: true,
            isLoading: current.children.isEmpty,
            error: null,
          ),
        );
        _loadingPaths = {..._loadingPaths, node.path};
      });
      await _loadDirectory(node.path, setCurrent: false);
    } else {
      setState(() {
        _updateCurrentDirectory(node.path);
        _fileTree = _updateNode(
          _fileTree,
          node.path,
          (current) => current.copyWith(isExpanded: false),
        );
      });
    }
  }

  List<_DisplayFileNode> _flattenTree(
    List<_FileNode> nodes, [
    int depth = 0,
  ]) {
    final flattened = <_DisplayFileNode>[];
    for (final node in nodes) {
      flattened.add(_DisplayFileNode(node: node, depth: depth));
      if (node.isExpanded && node.children.isNotEmpty) {
        flattened.addAll(_flattenTree(node.children, depth + 1));
      }
    }
    return flattened;
  }

  Widget _buildExpandIcon(_FileNode node) {
    if (node.isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    if (node.error != null) {
      return const Icon(Icons.error_outline, size: 20, color: Colors.redAccent);
    }
    return Icon(
      node.isExpanded ? Icons.expand_more : Icons.chevron_right,
      size: 20,
    );
  }

  Future<void> _showFileContextMenu(
    BuildContext context,
    Offset position, {
    SftpName? entry,
    String? parentPath,
    String? fullPath,
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
          value: _FileContextAction.copyPath,
          child: Text(context.l10n.terminalSidebarFilesCopyPath),
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
    final targetParent = parentPath ?? _currentDirectory;
    switch (result) {
      case _FileContextAction.newFile:
        await _handleCreateEntry(isDirectory: false);
        break;
      case _FileContextAction.newFolder:
        await _handleCreateEntry(isDirectory: true);
        break;
      case _FileContextAction.rename:
        if (entry != null) {
          await _handleRenameEntry(entry, parentPath: targetParent);
        }
        break;
      case _FileContextAction.download:
        if (entry != null && !isDir) {
          await _handleDownloadEntry(entry, parentPath: targetParent);
        }
        break;
      case _FileContextAction.copyPath:
        if (entry != null) {
          final pathToCopy = fullPath ?? _joinPath(targetParent, entry.filename);
          await Clipboard.setData(ClipboardData(text: pathToCopy));
          if (!context.mounted) return;
          _showSnackBarMessage(
            context.l10n.terminalSidebarFilesCopyPathSuccess(pathToCopy),
          );
        }
        break;
      case _FileContextAction.upload:
        await _handleUploadFile();
        break;
      case _FileContextAction.delete:
        if (entry != null) {
          await _handleDeleteEntry(entry, parentPath: targetParent);
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

  Future<void> _handleRenameEntry(
    SftpName entry, {
    required String parentPath,
  }) async {
    if (!_ensureSftpReady()) return;
    final l10n = context.l10n;
    final name = await _promptForInput(
      title: l10n.terminalSidebarFilesRenamePrompt(entry.filename),
      initial: entry.filename,
    );
    if (name == null || name.trim().isEmpty || name == entry.filename) return;
    final newPath = _joinPath(parentPath, name.trim());
    final oldPath = _joinPath(parentPath, entry.filename);
    try {
      await _sftp!.rename(oldPath, newPath);
      await _loadDirectory(parentPath, setCurrent: false);
      if (!mounted) return;
      _showSnackBarMessage(l10n.terminalSidebarFilesRefreshSuccess);
    } catch (error) {
      if (!mounted) return;
      _showSnackBarMessage(l10n.terminalSidebarFilesError('$error'));
    }
  }

  Future<void> _handleDeleteEntry(
    SftpName entry, {
    required String parentPath,
  }) async {
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
    final path = _joinPath(parentPath, entry.filename);
    try {
      if (_isDirectory(entry)) {
        await _sftp!.rmdir(path);
      } else {
        await _sftp!.remove(path);
      }
      await _loadDirectory(parentPath, setCurrent: false);
      if (!mounted) return;
      _showSnackBarMessage(l10n.terminalSidebarFilesRefreshSuccess);
    } catch (error) {
      if (!mounted) return;
      _showSnackBarMessage(l10n.terminalSidebarFilesError('$error'));
    }
  }

  Future<void> _handleDownloadEntry(
    SftpName entry, {
    required String parentPath,
  }) async {
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
    final remotePath = _joinPath(parentPath, entry.filename);
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

  Future<void> _openFilePreview(
    SftpName entry,
    String parentPath,
  ) async {
    if (_isDirectory(entry)) return;
    final l10n = context.l10n;
    if (!_isTextFile(entry.filename)) {
      _showSnackBarMessage(l10n.terminalSidebarFilesPreviewUnsupported);
      return;
    }
    final sftp = _sftp;
    if (sftp == null) return;
    final remotePath = _joinPath(parentPath, entry.filename);
    try {
      final file = await sftp.open(remotePath, mode: SftpFileOpenMode.read);
      final bytes = await file.readBytes();
      await file.close();
      final text = utf8.decode(bytes, allowMalformed: true);
      if (!mounted) return;
      await _showFileEditor(
        context: context,
        filename: entry.filename,
        initialText: text,
        onSave: (newText) async {
          final data = Uint8List.fromList(utf8.encode(newText));
          final writer = await sftp.open(
            remotePath,
            mode: SftpFileOpenMode.write |
                SftpFileOpenMode.truncate |
                SftpFileOpenMode.create,
          );
          await writer.writeBytes(data);
          await writer.close();
          _showSnackBarMessage(
            l10n.terminalSidebarFilesSaveSuccess(entry.filename),
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
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showFileEditor({
    required BuildContext context,
    required String filename,
    required String initialText,
    required Future<void> Function(String text) onSave,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final language = _languageForFilename(filename);
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        MonacoController? monacoController;
        String currentValue = initialText;
        bool saving = false;
        return StatefulBuilder(
          builder: (context, setState) {
            final surfaceColor = theme.colorScheme.surface;
            return Dialog(
              insetPadding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 1080,
                  maxHeight: 820,
                  minWidth: 720,
                  minHeight: 520,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              filename,
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            tooltip: MaterialLocalizations.of(context)
                                .closeButtonTooltip,
                            icon: const Icon(Icons.close),
                            onPressed:
                                saving ? null : () => Navigator.of(dialogContext).pop(),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: surfaceColor,
                              border: Border.all(
                                color: theme.dividerColor.withOpacity(0.4),
                              ),
                            ),
                            child: MonacoEditor(
                              initialValue: initialText,
                              autofocus: true,
                              backgroundColor: surfaceColor,
                              options: EditorOptions(
                                language: language,
                                theme: isDark ? MonacoTheme.vsDark : MonacoTheme.vs,
                                minimap: false,
                                lineNumbers: true,
                                fontSize: 14,
                                fontFamily:
                                    'JetBrains Mono, SFMono-Regular, Menlo, monospace',
                                lineHeight: 1.35,
                                wordWrap: true,
                                scrollBeyondLastLine: false,
                                padding: const {'top': 12, 'bottom': 12},
                              ),
                              showStatusBar: true,
                              onReady: (controller) async {
                                monacoController = controller;
                                currentValue = await controller.getValue(
                                  defaultValue: initialText,
                                );
                              },
                              onContentChanged: (value) {
                                currentValue = value;
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              context.l10n.terminalSidebarFilesEditHint,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.hintColor,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: saving
                                ? null
                                : () => Navigator.of(dialogContext).pop(),
                            child: Text(context.l10n.commonCancel),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: saving
                                ? null
                                : () async {
                                    setState(() => saving = true);
                                    try {
                                      final latest = monacoController != null
                                          ? await monacoController!
                                              .getValue(defaultValue: currentValue)
                                          : currentValue;
                                      await onSave(latest);
                                      if (dialogContext.mounted) {
                                        Navigator.of(dialogContext).pop();
                                      }
                                    } catch (error) {
                                      if (dialogContext.mounted) {
                                        ScaffoldMessenger.of(dialogContext)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              context.l10n
                                                  .terminalSidebarFilesEditFailure(
                                                      '$error'),
                                            ),
                                          ),
                                        );
                                      }
                                    } finally {
                                      if (dialogContext.mounted) {
                                        setState(() => saving = false);
                                      }
                                    }
                                  },
                            icon: saving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save),
                            label: Text(context.l10n.terminalSidebarFilesSave),
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
}

class _FileNode {
  const _FileNode({
    required this.name,
    required this.path,
    required this.entry,
    required this.isDir,
    this.children = const <_FileNode>[],
    this.isExpanded = false,
    this.isLoading = false,
    this.error,
  });

  final String name;
  final String path;
  final SftpName entry;
  final bool isDir;
  final List<_FileNode> children;
  final bool isExpanded;
  final bool isLoading;
  final String? error;

  _FileNode copyWith({
    String? name,
    String? path,
    SftpName? entry,
    bool? isDir,
    List<_FileNode>? children,
    bool? isExpanded,
    bool? isLoading,
    Object? error = _sentinel,
  }) {
    return _FileNode(
      name: name ?? this.name,
      path: path ?? this.path,
      entry: entry ?? this.entry,
      isDir: isDir ?? this.isDir,
      children: children ?? this.children,
      isExpanded: isExpanded ?? this.isExpanded,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _sentinel) ? this.error : error as String?,
    );
  }
}

class _DisplayFileNode {
  const _DisplayFileNode({
    required this.node,
    required this.depth,
  });

  final _FileNode node;
  final int depth;
}

const _sentinel = Object();

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
  copyPath,
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
