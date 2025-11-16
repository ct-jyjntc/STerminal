// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'STerminal';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonSearch => 'Search';

  @override
  String get commonPrevious => 'Previous';

  @override
  String get commonNext => 'Next';

  @override
  String get commonReplace => 'Replace';

  @override
  String get commonReplaceAll => 'Replace all';

  @override
  String get connectionsTitle => 'Connections';

  @override
  String get connectionsNewHost => 'New host';

  @override
  String get connectionsSearchHint => 'Search by host, tag or address';

  @override
  String get filterAll => 'All';

  @override
  String get filterUngrouped => 'Ungrouped';

  @override
  String connectionsLoadError(String error) {
    return 'Failed to load hosts: $error';
  }

  @override
  String hostInspectorLoadError(String error) {
    return 'Failed to load host: $error';
  }

  @override
  String get hostInspectorEmpty => 'Select a host to inspect';

  @override
  String get hostCreateButton => 'Create host';

  @override
  String get hostConnect => 'Connect';

  @override
  String get hostEdit => 'Edit';

  @override
  String get hostInspectorProxy => 'Proxy';

  @override
  String get hostDeleteTooltip => 'Delete host';

  @override
  String get hostDeleteTitle => 'Delete host';

  @override
  String hostDeleteMessage(String name) {
    return 'Are you sure you want to remove $name?';
  }

  @override
  String get hostNoDescription => 'No description';

  @override
  String get hostNoTags => 'No tags';

  @override
  String get hostMissingCredential => 'Missing credential';

  @override
  String get hostInspectorEndpoint => 'Endpoint';

  @override
  String get hostInspectorCredential => 'Credential';

  @override
  String get hostInspectorTags => 'Tags';

  @override
  String get hostFormTitleNew => 'New host';

  @override
  String get hostFormTitleEdit => 'Edit host';

  @override
  String get hostFormDisplayName => 'Display name';

  @override
  String get hostFormHostLabel => 'Host / IP';

  @override
  String get hostFormPortLabel => 'Port';

  @override
  String get hostFormCredentialLabel => 'Credential';

  @override
  String get hostFormSelectCredential => 'Select credential';

  @override
  String get hostFormCreateCredential => 'Create credential';

  @override
  String get hostFormGroupLabel => 'Group';

  @override
  String get hostFormNoGroupOption => 'No group';

  @override
  String get hostFormAccentLabel => 'Accent';

  @override
  String get hostFormProxyLabel => 'Proxy';

  @override
  String get hostFormProxyNone => 'No proxy';

  @override
  String get hostFormProxySystem => 'System proxy';

  @override
  String get hostFormProxyCustom => 'Custom SOCKS proxy';

  @override
  String get hostFormProxyHost => 'Proxy host';

  @override
  String get hostFormProxyPort => 'Proxy port';

  @override
  String get hostFormProxyUsername => 'Proxy username (optional)';

  @override
  String get hostFormProxyPassword => 'Proxy password (optional)';

  @override
  String get hostFormProxyValidation =>
      'Proxy host and port are required for custom SOCKS proxy.';

  @override
  String get hostFormSave => 'Save host';

  @override
  String get hostFormValidation => 'Name, host, and credential are required.';

  @override
  String get hostFormInlineToggle => 'Enter credential manually';

  @override
  String get hostFormInlineCancel => 'Use saved credential';

  @override
  String get hostFormCredentialInlineTitle => 'Credential details';

  @override
  String get hostFormCredentialInlineRequired =>
      'Fill in complete credential information.';

  @override
  String get hostFormCredentialMissing =>
      'Please select or create a credential first.';

  @override
  String get groupsTitle => 'Groups';

  @override
  String get groupsNew => 'New group';

  @override
  String get groupsNoDescription => 'No description';

  @override
  String groupsHostCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hosts',
      one: '$count host',
    );
    return '$_temp0';
  }

  @override
  String get groupsDeleteTitle => 'Delete group';

  @override
  String get groupsDeleteMessage =>
      'Hosts in this group will become ungrouped.';

  @override
  String get groupFormTitleNew => 'Add group';

  @override
  String get groupFormTitleEdit => 'Edit group';

  @override
  String get groupFormNameLabel => 'Group name';

  @override
  String get groupFormDescriptionLabel => 'Description';

  @override
  String get groupFormSave => 'Save group';

  @override
  String get groupFormValidation => 'Name is required.';

  @override
  String get snippetsTitle => 'Scripts';

  @override
  String get snippetsNew => 'New snippet';

  @override
  String get snippetsEmpty => 'No snippets yet';

  @override
  String get snippetsPanelHint => 'Create snippets to quick send';

  @override
  String get snippetsCopyMessage => 'Copied command';

  @override
  String get snippetsDeleteTitle => 'Delete snippet';

  @override
  String snippetsDeleteMessage(String title) {
    return 'Are you sure you want to delete $title?';
  }

  @override
  String get snippetFormTitleNew => 'New snippet';

  @override
  String get snippetFormTitleEdit => 'Edit script';

  @override
  String get snippetFormTitleLabel => 'Title';

  @override
  String get snippetFormCommandLabel => 'Command';

  @override
  String get snippetFormSave => 'Save snippet';

  @override
  String get snippetFormValidation => 'Title and command are required.';

  @override
  String get vaultTitle => 'Credentials';

  @override
  String get vaultNew => 'New credential';

  @override
  String get vaultEmpty => 'No credentials yet';

  @override
  String get vaultDeleteTitle => 'Delete credential';

  @override
  String get vaultDeleteMessage =>
      'Hosts referencing this credential will need to be updated manually.';

  @override
  String get credentialFormTitleNew => 'Add credential';

  @override
  String get credentialFormTitleEdit => 'Edit credential';

  @override
  String get credentialFormLabel => 'Label';

  @override
  String get credentialFormUsername => 'Username';

  @override
  String get credentialFormPassword => 'Password';

  @override
  String get credentialFormKeyPair => 'Key pair';

  @override
  String get credentialFormPrivateKey => 'Private key (PEM)';

  @override
  String get credentialFormPassphrase => 'Passphrase (optional)';

  @override
  String get credentialFormSave => 'Save credential';

  @override
  String get credentialFormValidation => 'Name and username are required.';

  @override
  String get credentialAuthPassword => 'Password';

  @override
  String get credentialAuthKeyPair => 'Key pair';

  @override
  String get credentialUnknownUser => 'unknown';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsConfirm => 'Connection confirmation';

  @override
  String get settingsConfirmSubtitle => 'Prompt before opening remote session';

  @override
  String settingsConfirmDialogTitle(String name) {
    return 'Connect to $name?';
  }

  @override
  String settingsConfirmDialogMessage(String name) {
    return 'A terminal session will open for $name. Continue?';
  }

  @override
  String get settingsMultiWindow => 'Multi-window terminals';

  @override
  String get settingsMultiWindowSubtitle =>
      'Open each connection in a separate window';

  @override
  String get settingsImport => 'Import data';

  @override
  String get settingsImportSubtitle => 'Replace local data with a backup';

  @override
  String get settingsImportAction => 'Import';

  @override
  String get settingsImportSuccess => 'Import completed';

  @override
  String settingsImportFailure(String error) {
    return 'Import failed: $error';
  }

  @override
  String get settingsImportCancelled => 'Import cancelled';

  @override
  String get settingsImportConfirmTitle => 'Replace existing data?';

  @override
  String get settingsImportConfirmMessage =>
      'Current hosts, groups, credentials and scripts will be overwritten.';

  @override
  String get settingsExport => 'Export data';

  @override
  String get settingsExportSubtitle =>
      'Create a backup of hosts and credentials';

  @override
  String get settingsExportAction => 'Export';

  @override
  String settingsExportSuccess(String path) {
    return 'Backup saved to $path';
  }

  @override
  String settingsExportFailure(String error) {
    return 'Export failed: $error';
  }

  @override
  String get settingsExportCancelled => 'Export cancelled';

  @override
  String get terminalProxyNotFound =>
      'No SOCKS proxy found in system configuration.';

  @override
  String genericErrorMessage(String error) {
    return 'Error: $error';
  }

  @override
  String get hostLastConnectedNever => 'Never connected';

  @override
  String get hostLastConnectedJustNow => 'Connected just now';

  @override
  String hostLastConnectedMinutes(int minutes) {
    return 'Connected ${minutes}m ago';
  }

  @override
  String hostLastConnectedHours(int hours) {
    return 'Connected ${hours}h ago';
  }

  @override
  String hostLastConnectedDays(int days) {
    return 'Connected ${days}d ago';
  }

  @override
  String get terminalReconnectTooltip => 'Reconnect';

  @override
  String get terminalNewSnippetTooltip => 'New snippet';

  @override
  String get terminalSidebarFiles => 'Files';

  @override
  String get terminalSidebarCommands => 'Commands';

  @override
  String get terminalSidebarHistory => 'History';

  @override
  String get terminalSidebarFilesLoading => 'Loading files...';

  @override
  String get terminalSidebarFilesConnect => 'Connect to load files.';

  @override
  String get terminalSidebarFilesEmpty => 'Folder is empty.';

  @override
  String terminalSidebarFilesError(String error) {
    return 'Failed to load files: $error';
  }

  @override
  String get terminalSidebarFilesRefresh => 'Reload';

  @override
  String get terminalSidebarFilesUp => 'Parent folder';

  @override
  String get terminalSidebarFilesRefreshSuccess => 'Refreshed';

  @override
  String get terminalSidebarFilesNewFile => 'New file';

  @override
  String get terminalSidebarFilesNewFolder => 'New folder';

  @override
  String get terminalSidebarFilesRename => 'Rename';

  @override
  String get terminalSidebarFilesDownload => 'Download';

  @override
  String get terminalSidebarFilesUpload => 'Upload';

  @override
  String get terminalSidebarFilesDelete => 'Delete';

  @override
  String get terminalSidebarFilesNewFilePrompt => 'Enter a file name';

  @override
  String get terminalSidebarFilesNewFolderPrompt => 'Enter a folder name';

  @override
  String terminalSidebarFilesRenamePrompt(String name) {
    return 'Rename $name';
  }

  @override
  String get terminalSidebarFilesDeleteTitle => 'Delete item';

  @override
  String terminalSidebarFilesDeleteConfirm(String name) {
    return 'Delete $name? This cannot be undone.';
  }

  @override
  String terminalSidebarFilesDownloadSuccess(String path) {
    return 'Saved to $path';
  }

  @override
  String terminalSidebarFilesDownloadFailure(String error) {
    return 'Download failed: $error';
  }

  @override
  String terminalSidebarFilesUploadSuccess(String name) {
    return 'Uploaded $name';
  }

  @override
  String terminalSidebarFilesUploadFailure(String error) {
    return 'Upload failed: $error';
  }

  @override
  String get terminalSidebarFilesEditHint => 'Edit file content';

  @override
  String get terminalSidebarFilesSave => 'Save';

  @override
  String terminalSidebarFilesSaveSuccess(String name) {
    return 'Saved $name';
  }

  @override
  String terminalSidebarFilesEditFailure(String error) {
    return 'Failed to open file: $error';
  }

  @override
  String get terminalSidebarFilesCopyPath => 'Copy path';

  @override
  String terminalSidebarFilesCopyPathSuccess(String path) {
    return 'Copied: $path';
  }

  @override
  String get terminalSidebarFilesPathHint => 'Enter path';

  @override
  String get terminalSidebarFilesPreviewUnsupported =>
      'Only text files can be previewed.';

  @override
  String get terminalSidebarHistoryTitle => 'History';

  @override
  String get terminalSidebarHistoryEmpty => 'No commands yet.';

  @override
  String get terminalSidebarHistoryClear => 'Clear history';

  @override
  String get settingsHistoryLimit => 'History limit';

  @override
  String settingsHistoryLimitSubtitle(int count) {
    return 'Keep up to $count commands';
  }

  @override
  String get settingsDownloadPath => 'Download folder';

  @override
  String get settingsDownloadPathUnset => 'Not set';

  @override
  String get settingsDownloadPathChoose => 'Choose folder';

  @override
  String get settingsDownloadPathClear => 'Clear';

  @override
  String get terminalSidebarHistoryPlaceholder => 'No history yet.';

  @override
  String get terminalCredentialDeleted => 'Credential deleted';

  @override
  String terminalCredentialError(String error) {
    return 'Credential error: $error';
  }

  @override
  String get terminalHostRemoved => 'Host removed';

  @override
  String terminalHostError(String error) {
    return 'Host not found: $error';
  }

  @override
  String terminalConnectingMessage(String host) {
    return 'Connecting to $host...';
  }

  @override
  String terminalConnectionFailed(String error) {
    return 'Connection failed: $error';
  }
}
