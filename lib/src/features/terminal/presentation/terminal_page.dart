import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dartssh2/dartssh2.dart';
import 'package:file_selector/file_selector.dart' as file_selector;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:socks5_proxy/socks_client.dart';
import 'package:sterminal/src/l10n/l10n.dart';
import 'package:xterm/xterm.dart';

import 'package:sterminal/l10n/app_localizations.dart';
import '../../../core/app_providers.dart';
import '../../../domain/models/credential.dart';
import '../../../domain/models/host.dart';
import '../../../domain/models/proxy_settings.dart';
import '../../../domain/models/snippet.dart';
import '../../connections/application/hosts_providers.dart';
import '../application/command_history_service.dart';
import '../../settings/application/settings_controller.dart';
import '../../snippets/application/snippet_providers.dart';
import '../../snippets/presentation/snippet_form_sheet.dart';
import '../../vault/application/credential_providers.dart';

class _TerminalSession {
  _TerminalSession({
    required this.id,
    required this.displayName,
    required this.terminal,
    required this.controller,
    required this.pathController,
    required this.focusNode,
  });

  final String id;
  final String displayName;
  final Terminal terminal;
  final TerminalController controller;
  final TextEditingController pathController;
  final FocusNode focusNode;
  SSHClient? client;
  SSHSession? session;
  StreamSubscription<Uint8List>? stdoutSub;
  StreamSubscription<Uint8List>? stderrSub;
  SftpClient? sftp;
  String rootDirectory = '';
  String currentDirectory = '';
  List<_FileNode> fileTree = const <_FileNode>[];
  Set<String> loadingPaths = <String>{};
  bool initialFileLoading = false;
  String? fileError;
  bool connecting = false;
  String? error;
  bool hasAttemptedConnection = false;
  bool entryContextMenuActive = false;
  final StringBuffer commandBuffer = StringBuffer();

  void dispose() {
    stdoutSub?.cancel();
    stderrSub?.cancel();
    session?.close();
    client?.close();
    sftp?.close();
    pathController.dispose();
    controller.dispose();
    focusNode.dispose();
  }
}

class TerminalPage extends ConsumerStatefulWidget {
  const TerminalPage({super.key, required this.hostId});

  final String hostId;

  @override
  ConsumerState<TerminalPage> createState() => _TerminalPageState();
}

class _TerminalPageState extends ConsumerState<TerminalPage> {
  final List<_TerminalSession> _sessions = [];
  String? _activeSessionId;
  int _sessionCounter = 1;
  List<Snippet> _snippetCache = const [];
  List<String> _commandHistory = const [];
  late final CommandHistoryService _historyService;
  TerminalSidebarTab _sidebarTab = TerminalSidebarTab.commands;

  @override
  void initState() {
    super.initState();
    _historyService = ref.read(commandHistoryServiceProvider);
    _loadHistory();
  }

  @override
  void dispose() {
    for (final session in _sessions) {
      session.dispose();
    }
    super.dispose();
  }

  _TerminalSession? get _activeSession {
    if (_sessions.isEmpty) return null;
    final targetId = _activeSessionId;
    if (targetId == null) return _sessions.first;
    return _sessions.firstWhere(
      (session) => session.id == targetId,
      orElse: () => _sessions.first,
    );
  }

  void _focusSession(_TerminalSession session) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      FocusScope.of(context).requestFocus(session.focusNode);
    });
  }

  void _ensureSessionsInitialized(Host host, Credential credential) {
    if (_sessions.isEmpty) {
      final session = _createSession();
      setState(() {
        _sessions.add(session);
        _activeSessionId = session.id;
      });
      _focusSession(session);
    }
    for (final session in _sessions) {
      _maybeConnect(session, host, credential);
    }
  }

  _TerminalSession _createSession() {
    final sessionNumber = _sessionCounter++;
    final sessionId = 'session_$sessionNumber';
    return _TerminalSession(
      id: sessionId,
      displayName: 'T$sessionNumber',
      terminal: Terminal(
        maxLines: 10000,
        platform: TerminalTargetPlatform.macos,
      ),
      controller: TerminalController(),
      pathController: TextEditingController(),
      focusNode: FocusNode(),
    );
  }

  void _addSession(Host host, Credential credential) {
    final session = _createSession();
    setState(() {
      _sessions.add(session);
      _activeSessionId = session.id;
    });
    _focusSession(session);
    _maybeConnect(session, host, credential);
  }

  void _closeSession(String sessionId) {
    if (_sessions.length <= 1) return;
    _TerminalSession? removed;
    setState(() {
      removed = _sessions.firstWhere((session) => session.id == sessionId);
      _sessions.remove(removed);
      if (_activeSessionId == sessionId) {
        _activeSessionId = _sessions.isNotEmpty ? _sessions.last.id : null;
      }
    });
    removed?.dispose();
    final active = _activeSession;
    if (active != null) {
      _focusSession(active);
    }
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
            _ensureSessionsInitialized(host, credential);
            final session = _activeSession;
            if (session == null) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
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
                    _buildSessionRail(
                      context: context,
                      host: host,
                      credential: credential,
                      activeSession: session,
                      isStandaloneWindow: isStandaloneWindow,
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0, 12, 24, 4),
                            child: Row(
                              children: [
                                if (!isStandaloneWindow)
                                  ...[
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8),
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
                                  const EdgeInsets.fromLTRB(0, 0, 0, 16),
                              child: DecoratedBox(
                                decoration:
                                    BoxDecoration(color: terminalTheme.background),
                                child: TerminalView(
                                  key: ValueKey(session.id),
                                  session.terminal,
                                  controller: session.controller,
                                  autofocus: true,
                                  focusNode: session.focusNode,
                                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
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
                                ? _buildSidebarContentWithContextMenu(
                                    context,
                                    l10n,
                                    snippets,
                                    session,
                                  )
                                : _buildSidebarContent(
                                    context,
                                    l10n,
                                    snippets,
                                    session,
                                  ),
                          ),
                          if (session.error != null)
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                session.error!,
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

  Widget _buildSessionRail({
    required BuildContext context,
    required Host host,
    required Credential credential,
    required _TerminalSession activeSession,
    required bool isStandaloneWindow,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 88,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: const Border(
          right: BorderSide(color: Colors.white10, width: 1),
        ),
      ),
      child: Column(
        children: [
          SizedBox(height: isStandaloneWindow ? 56 : 56),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _sessions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final session = _sessions[index];
                final selected = session.id == activeSession.id;
                return _SessionRailIcon(
                  icon: Icons.terminal,
                  color: selected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                  background: selected
                      ? colorScheme.primaryContainer
                      : colorScheme.surfaceVariant.withOpacity(0.6),
                  label: session.displayName,
                  onTap: () {
                    setState(() {
                      _activeSessionId = session.id;
                    });
                    _focusSession(session);
                  },
                  onClose: _sessions.length > 1
                      ? () => _closeSession(session.id)
                      : null,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            child: Center(
              child: _CapsuleIconButton(
                icon: Icons.add,
                background: colorScheme.primaryContainer,
                foreground: colorScheme.onPrimaryContainer,
                onPressed: () => _addSession(host, credential),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _maybeConnect(
    _TerminalSession session,
    Host host,
    Credential credential,
  ) {
    if (session.hasAttemptedConnection || session.connecting) {
      return;
    }
    session.hasAttemptedConnection = true;
    _reconnect(session, host, credential);
  }

  Future<void> _reconnect(
    _TerminalSession session,
    Host host,
    Credential credential,
  ) async {
    final l10n = context.l10n;
    await session.stdoutSub?.cancel();
    await session.stderrSub?.cancel();
    session.session?.close();
    session.client?.close();
    session.sftp?.close();
    setState(() {
      session.connecting = true;
      session.error = null;
      session.sftp = null;
      session.rootDirectory = '';
      _updateCurrentDirectory(session, '');
      session.fileTree = const <_FileNode>[];
      session.fileError = null;
      session.loadingPaths = <String>{};
      session.initialFileLoading = false;
    });
    session.terminal.buffer.clear();
    session.terminal
        .write('${l10n.terminalConnectingMessage(host.address)}\r\n');
    try {
      final socket = await _createSocket(host, l10n);
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
      final shellSession = await client.shell(
        pty: SSHPtyConfig(
          type: 'xterm-256color',
          width: session.terminal.viewWidth,
          height: session.terminal.viewHeight,
        ),
      );
      session.stdoutSub =
          shellSession.stdout.listen((data) => _onData(session, data));
      session.stderrSub =
          shellSession.stderr.listen((data) => _onData(session, data));
      session.terminal.onOutput = (data) {
        final shouldSend = _handleTerminalInput(session, data);
        if (shouldSend) {
          shellSession.write(Uint8List.fromList(utf8.encode(data)));
        }
      };
      session.terminal.onResize = (width, height, pixelWidth, pixelHeight) {
        shellSession.resizeTerminal(width, height, pixelWidth, pixelHeight);
      };
      if (!mounted) return;
      setState(() {
        session.client = client;
        session.session = shellSession;
        session.connecting = false;
        session.error = null;
      });
      unawaited(_initSftp(session));
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
          session.error = message;
          session.connecting = false;
        });
      }
      session.terminal.write('\r\n$message\r\n');
    }
  }

  Future<SSHSocket> _createSocket(Host host, AppLocalizations l10n) async {
    final resolvedProxy = await _resolveProxy(host, l10n);
    if (resolvedProxy == null) {
      return SSHSocket.connect(host.address, host.port);
    }
    final proxySettings = ProxySettings(
      _toInternetAddress(resolvedProxy.host),
      resolvedProxy.port,
      username: resolvedProxy.username?.isEmpty ?? true
          ? null
          : resolvedProxy.username,
      password: resolvedProxy.password?.isEmpty ?? true
          ? null
          : resolvedProxy.password,
    );
    final targetAddress = _toInternetAddress(host.address);
    final Socket socket = await SocksTCPClient.connect(
      [proxySettings],
      targetAddress,
      host.port,
    );
    return _SocksSSHSocket(socket);
  }

  Future<_ResolvedProxy?> _resolveProxy(
    Host host,
    AppLocalizations l10n,
  ) async {
    switch (host.proxy.mode) {
      case HostProxyMode.none:
        return null;
      case HostProxyMode.customSocks:
        final proxyHost = host.proxy.host;
        final proxyPort = host.proxy.port;
        if (proxyHost == null || proxyPort == null) {
          throw Exception(l10n.hostFormProxyValidation);
        }
        return _ResolvedProxy(
          host: proxyHost,
          port: proxyPort,
          username: host.proxy.username,
          password: host.proxy.password,
        );
    }
  }

  InternetAddress _toInternetAddress(String host) {
    final parsed = InternetAddress.tryParse(host);
    if (parsed != null) return parsed;
    return InternetAddress(host, type: InternetAddressType.unix);
  }

  void _onData(_TerminalSession session, Uint8List data) {
    final text = utf8.decode(data);
    session.terminal.write(text);
  }

  bool _handleTerminalInput(_TerminalSession session, String data) {
    var inEscapeSequence = false;
    var sawCsiPrefix = false;
    for (final codePoint in data.runes) {
      if (codePoint == 27) {
        // Start of an ANSI escape sequence (arrow keys, etc.); ignore for history.
        inEscapeSequence = true;
        sawCsiPrefix = false;
        continue;
      }
      if (inEscapeSequence) {
        if (!sawCsiPrefix && codePoint == 91) {
          // CSI introducer '['.
          sawCsiPrefix = true;
          continue;
        }
        // CSI sequences end with a final byte in the 64–126 range.
        if (codePoint >= 64 && codePoint <= 126) {
          inEscapeSequence = false;
          sawCsiPrefix = false;
        }
        continue;
      }
      if (codePoint == 9) {
        // Tab pressed: show local completion suggestions instead of sending to host.
        final current = session.commandBuffer.toString();
        unawaited(_showCompletionSuggestions(session, prefix: current));
        return false;
      }
      if (codePoint == 13 || codePoint == 10) {
        final command = session.commandBuffer.toString().trim();
        session.commandBuffer.clear();
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
        if (session.commandBuffer.isNotEmpty) {
          final text = session.commandBuffer.toString();
          session.commandBuffer
            ..clear()
            ..write(text.substring(0, text.length - 1));
        }
      } else if (codePoint >= 32) {
        session.commandBuffer.write(String.fromCharCode(codePoint));
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

  Future<void> _showCompletionSuggestions(
    _TerminalSession session, {
    required String prefix,
  }) async {
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
      useRootNavigator: true,
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
      final current = session.commandBuffer.toString();
      if (selected.startsWith(current)) {
        final remaining = selected.substring(current.length);
        session.terminal.paste('$remaining ');
        session.commandBuffer
          ..clear()
          ..write('$selected ');
      } else {
        // Fall back to sending full suggestion.
        session.terminal.paste('$selected ');
        session.commandBuffer
          ..clear()
          ..write('$selected ');
      }
    }
  }

  Widget _buildSidebarContentWithContextMenu(
    BuildContext context,
    AppLocalizations l10n,
    AsyncValue<List<Snippet>> snippets,
    _TerminalSession session,
  ) {
    return _ContextMenuRegion(
      onShowMenu: (position) {
        if (session.entryContextMenuActive) return;
        _showFileContextMenu(
          context,
          position,
          session: session,
          parentPath: session.currentDirectory,
        );
      },
      child: _buildSidebarContent(context, l10n, snippets, session),
    );
  }

  Widget _buildSidebarContent(
    BuildContext context,
    AppLocalizations l10n,
    AsyncValue<List<Snippet>> snippets,
    _TerminalSession session,
  ) {
    switch (_sidebarTab) {
      case TerminalSidebarTab.files:
        return _buildFilesSidebar(context, l10n, session);
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
                          session.terminal.paste('${snippet.command}\r');
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
        return _buildHistorySidebar(context, l10n, session);
    }
  }

  Widget _buildFilesSidebar(
    BuildContext context,
    AppLocalizations l10n,
    _TerminalSession session,
  ) {
    if (session.sftp == null) {
      return Center(
        child: Text(
          session.connecting
              ? l10n.terminalSidebarFilesLoading
              : l10n.terminalSidebarFilesConnect,
        ),
      );
    }
    final hasPath = session.currentDirectory.isNotEmpty;
    final isRefreshing =
        session.initialFileLoading ||
            session.loadingPaths.contains(session.currentDirectory);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: session.pathController,
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
                    _loadDirectory(session, trimmed);
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: l10n.terminalSidebarFilesRefresh,
                onPressed: !isRefreshing && hasPath
                    ? () => _loadDirectory(session, session.currentDirectory)
                    : null,
              ),
            ],
          ),
        ),
        Expanded(
          child: _buildFileList(context, l10n, session),
        ),
      ],
    );
  }

  Widget _buildHistorySidebar(
    BuildContext context,
    AppLocalizations l10n,
    _TerminalSession session,
  ) {
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
                  session.terminal.textInput('$command ');
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

  Widget _buildFileList(
    BuildContext context,
    AppLocalizations l10n,
    _TerminalSession session,
  ) {
    if (session.initialFileLoading && session.fileTree.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (session.fileError != null && session.fileTree.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              session.fileError!,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: session.currentDirectory.isEmpty
                  ? null
                  : () => _loadDirectory(session, session.currentDirectory),
              child: Text(l10n.terminalSidebarFilesRefresh),
            ),
          ],
        ),
      );
    }
    if (session.fileTree.isEmpty) {
      return Center(child: Text(l10n.terminalSidebarFilesEmpty));
    }
    final flatNodes = _flattenTree(session.fileTree);
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
              await _toggleDirectory(session, node);
            } else {
              setState(() {
                session.currentDirectory = parentPath;
              });
              await _openFilePreview(session, node.entry, parentPath);
            }
          },
          onContextMenu: (position) {
            session.entryContextMenuActive = true;
            _updateCurrentDirectory(
              session,
              node.isDir ? node.path : parentPath,
            );
            _showFileContextMenu(
              context,
              position,
              session: session,
              entry: node.entry,
              parentPath: node.isDir ? node.path : parentPath,
              fullPath: node.path,
            ).whenComplete(() => session.entryContextMenuActive = false);
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

  Future<void> _initSftp(_TerminalSession session) async {
    final client = session.client;
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
      session.sftp?.close();
      setState(() {
        session.sftp = sftp;
        session.rootDirectory = rootPath;
        _updateCurrentDirectory(session, rootPath);
        session.fileTree = const <_FileNode>[];
        session.fileError = null;
        session.loadingPaths = {rootPath};
        session.initialFileLoading = true;
      });
      final loadedRoot = await _loadDirectory(session, rootPath);
      if (!loadedRoot && homePath != rootPath) {
        // Fallback to the user's home directory if root is not accessible.
        setState(() {
          session.rootDirectory = homePath;
          _updateCurrentDirectory(session, homePath);
          session.fileTree = const <_FileNode>[];
          session.fileError = null;
          session.loadingPaths = {homePath};
          session.initialFileLoading = true;
        });
        await _loadDirectory(session, homePath);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        session.fileError = l10n.terminalSidebarFilesError('$error');
        session.initialFileLoading = false;
      });
    }
  }

  Future<bool> _loadDirectory(
    _TerminalSession session,
    String path, {
    bool setCurrent = true,
  }) async {
    final sftp = session.sftp;
    if (sftp == null) return false;
    final l10n = context.l10n;
    setState(() {
      if (setCurrent) _updateCurrentDirectory(session, path);
      session.fileError = null;
      session.loadingPaths = {...session.loadingPaths, path};
      session.fileTree = _updateNode(
        session.fileTree,
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
        final isRootPath =
            path == session.rootDirectory || session.fileTree.isEmpty;
        session.fileTree = _setChildrenForPath(
          session.fileTree,
          path,
          nodes,
          rootDirectory: session.rootDirectory,
          isRootPath: isRootPath,
        );
        session.loadingPaths = {...session.loadingPaths}..remove(path);
        session.initialFileLoading = false;
      });
      return true;
    } catch (error) {
      if (!mounted) return false;
      final message = l10n.terminalSidebarFilesError('$error');
      setState(() {
        session.fileError = message;
        session.loadingPaths = {...session.loadingPaths}..remove(path);
        session.fileTree = _updateNode(
          session.fileTree,
          path,
          (node) => node.copyWith(
            isLoading: false,
            error: message,
          ),
        );
        session.initialFileLoading = false;
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
    required String rootDirectory,
    bool isRootPath = false,
  }) {
    if (isRootPath && (nodes.isEmpty || path == rootDirectory)) {
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

  void _updateCurrentDirectory(_TerminalSession session, String path) {
    session.currentDirectory = path;
    session.pathController.text = path;
  }

  Future<void> _toggleDirectory(_TerminalSession session, _FileNode node) async {
    if (!_ensureSftpReady(session)) return;
    final shouldExpand = !node.isExpanded;
    if (shouldExpand) {
      setState(() {
        _updateCurrentDirectory(session, node.path);
        session.fileTree = _updateNode(
          session.fileTree,
          node.path,
          (current) => current.copyWith(
            isExpanded: true,
            isLoading: current.children.isEmpty,
            error: null,
          ),
        );
        session.loadingPaths = {...session.loadingPaths, node.path};
      });
      await _loadDirectory(session, node.path, setCurrent: false);
    } else {
      setState(() {
        _updateCurrentDirectory(session, node.path);
        session.fileTree = _updateNode(
          session.fileTree,
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
    required _TerminalSession session,
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
    final targetParent = parentPath ?? session.currentDirectory;
    switch (result) {
      case _FileContextAction.newFile:
        await _handleCreateEntry(session, isDirectory: false);
        break;
      case _FileContextAction.newFolder:
        await _handleCreateEntry(session, isDirectory: true);
        break;
      case _FileContextAction.rename:
        if (entry != null) {
          await _handleRenameEntry(session, entry, parentPath: targetParent);
        }
        break;
      case _FileContextAction.download:
        if (entry != null && !isDir) {
          await _handleDownloadEntry(session, entry, parentPath: targetParent);
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
        await _handleUploadFile(session);
        break;
      case _FileContextAction.delete:
        if (entry != null) {
          await _handleDeleteEntry(session, entry, parentPath: targetParent);
        }
        break;
    }
  }

  Future<void> _handleCreateEntry(
    _TerminalSession session, {
    required bool isDirectory,
  }) async {
    if (!_ensureSftpReady(session)) return;
    final l10n = context.l10n;
    final name = await _promptForInput(
      title: isDirectory
          ? l10n.terminalSidebarFilesNewFolderPrompt
          : l10n.terminalSidebarFilesNewFilePrompt,
    );
    if (name == null || name.trim().isEmpty) return;
    final path = _joinPath(session.currentDirectory, name.trim());
    try {
      final sftp = session.sftp!;
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
      await _loadDirectory(session, session.currentDirectory);
      if (!mounted) return;
      _showSnackBarMessage(l10n.terminalSidebarFilesRefreshSuccess);
    } catch (error) {
      if (!mounted) return;
      _showSnackBarMessage(l10n.terminalSidebarFilesError('$error'));
    }
  }

  Future<void> _handleRenameEntry(
    _TerminalSession session,
    SftpName entry, {
    required String parentPath,
  }) async {
    if (!_ensureSftpReady(session)) return;
    final l10n = context.l10n;
    final name = await _promptForInput(
      title: l10n.terminalSidebarFilesRenamePrompt(entry.filename),
      initial: entry.filename,
    );
    if (name == null || name.trim().isEmpty || name == entry.filename) return;
    final newPath = _joinPath(parentPath, name.trim());
    final oldPath = _joinPath(parentPath, entry.filename);
    try {
      await session.sftp!.rename(oldPath, newPath);
      await _loadDirectory(session, parentPath, setCurrent: false);
      if (!mounted) return;
      _showSnackBarMessage(l10n.terminalSidebarFilesRefreshSuccess);
    } catch (error) {
      if (!mounted) return;
      _showSnackBarMessage(l10n.terminalSidebarFilesError('$error'));
    }
  }

  Future<void> _handleDeleteEntry(
    _TerminalSession session,
    SftpName entry, {
    required String parentPath,
  }) async {
    if (!_ensureSftpReady(session)) return;
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
    final path = _joinPath(parentPath, entry.filename);
    try {
      if (_isDirectory(entry)) {
        await session.sftp!.rmdir(path);
      } else {
        await session.sftp!.remove(path);
      }
      await _loadDirectory(session, parentPath, setCurrent: false);
      if (!mounted) return;
      _showSnackBarMessage(l10n.terminalSidebarFilesRefreshSuccess);
    } catch (error) {
      if (!mounted) return;
      _showSnackBarMessage(l10n.terminalSidebarFilesError('$error'));
    }
  }

  Future<void> _handleDownloadEntry(
    _TerminalSession session,
    SftpName entry, {
    required String parentPath,
  }) async {
    final sftp = session.sftp;
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

  Future<void> _handleUploadFile(_TerminalSession session) async {
    if (!_ensureSftpReady(session)) return;
    final l10n = context.l10n;
    final selected = await file_selector.openFile();
    if (selected == null) return;
    final data = await selected.readAsBytes();
    final remotePath = _joinPath(session.currentDirectory, selected.name);
    try {
      final file = await session.sftp!.open(
        remotePath,
        mode: SftpFileOpenMode.create |
            SftpFileOpenMode.write |
            SftpFileOpenMode.truncate,
      );
      await file.writeBytes(Uint8List.fromList(data));
      await file.close();
      await _loadDirectory(session, session.currentDirectory);
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
    _TerminalSession session,
    SftpName entry,
    String parentPath,
  ) async {
    if (_isDirectory(entry)) return;
    final l10n = context.l10n;
    if (!_isTextFile(entry.filename)) {
      _showSnackBarMessage(l10n.terminalSidebarFilesPreviewUnsupported);
      return;
    }
    final sftp = session.sftp;
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

  bool _ensureSftpReady(_TerminalSession session) {
    if (session.sftp == null || session.currentDirectory.isEmpty) {
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

class _ResolvedProxy {
  const _ResolvedProxy({
    required this.host,
    required this.port,
    this.username,
    this.password,
  });

  final String host;
  final int port;
  final String? username;
  final String? password;
}

class _SocksSSHSocket implements SSHSocket {
  _SocksSSHSocket(this._socket);

  final Socket _socket;

  @override
  Stream<Uint8List> get stream => _socket;

  @override
  StreamSink<List<int>> get sink => _socket;

  @override
  Future<void> get done => _socket.done;

  @override
  Future<void> close() async {
    await _socket.close();
  }

  @override
  void destroy() {
    _socket.destroy();
  }
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
                .surfaceVariant
                .withOpacity(0.4)
            : null,
        child: widget.child,
      ),
    );
  }
}

class _SessionRailIcon extends StatelessWidget {
  const _SessionRailIcon({
    required this.icon,
    required this.color,
    required this.background,
    required this.onTap,
    this.onClose,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final VoidCallback onTap;
  final VoidCallback? onClose;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: background,
          shape: const StadiumBorder(),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            onLongPress: onClose,
            child: SizedBox(
              width: 58,
              height: 32,
              child: Center(
                child: Icon(icon, color: color, size: 20),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
      ],
    );
  }
}

class _CapsuleIconButton extends StatelessWidget {
  const _CapsuleIconButton({
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onPressed,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 58,
          height: 32,
          child: Center(
            child: Icon(icon, color: foreground, size: 20),
          ),
        ),
      ),
    );
  }
}
