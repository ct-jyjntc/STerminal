import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'STerminal'**
  String get appTitle;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @connectionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Connections'**
  String get connectionsTitle;

  /// No description provided for @connectionsNewHost.
  ///
  /// In en, this message translates to:
  /// **'New host'**
  String get connectionsNewHost;

  /// No description provided for @connectionsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by host, tag or address'**
  String get connectionsSearchHint;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterUngrouped.
  ///
  /// In en, this message translates to:
  /// **'Ungrouped'**
  String get filterUngrouped;

  /// No description provided for @connectionsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load hosts: {error}'**
  String connectionsLoadError(String error);

  /// No description provided for @hostInspectorLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load host: {error}'**
  String hostInspectorLoadError(String error);

  /// No description provided for @hostInspectorEmpty.
  ///
  /// In en, this message translates to:
  /// **'Select a host to inspect'**
  String get hostInspectorEmpty;

  /// No description provided for @hostCreateButton.
  ///
  /// In en, this message translates to:
  /// **'Create host'**
  String get hostCreateButton;

  /// No description provided for @hostConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get hostConnect;

  /// No description provided for @hostEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get hostEdit;

  /// No description provided for @hostDeleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete host'**
  String get hostDeleteTooltip;

  /// No description provided for @hostDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete host'**
  String get hostDeleteTitle;

  /// No description provided for @hostDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove {name}?'**
  String hostDeleteMessage(String name);

  /// No description provided for @hostNoDescription.
  ///
  /// In en, this message translates to:
  /// **'No description'**
  String get hostNoDescription;

  /// No description provided for @hostNoTags.
  ///
  /// In en, this message translates to:
  /// **'No tags'**
  String get hostNoTags;

  /// No description provided for @hostMissingCredential.
  ///
  /// In en, this message translates to:
  /// **'Missing credential'**
  String get hostMissingCredential;

  /// No description provided for @hostInspectorEndpoint.
  ///
  /// In en, this message translates to:
  /// **'Endpoint'**
  String get hostInspectorEndpoint;

  /// No description provided for @hostInspectorCredential.
  ///
  /// In en, this message translates to:
  /// **'Credential'**
  String get hostInspectorCredential;

  /// No description provided for @hostInspectorTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get hostInspectorTags;

  /// No description provided for @hostFormTitleNew.
  ///
  /// In en, this message translates to:
  /// **'New host'**
  String get hostFormTitleNew;

  /// No description provided for @hostFormTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit host'**
  String get hostFormTitleEdit;

  /// No description provided for @hostFormDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get hostFormDisplayName;

  /// No description provided for @hostFormHostLabel.
  ///
  /// In en, this message translates to:
  /// **'Host / IP'**
  String get hostFormHostLabel;

  /// No description provided for @hostFormPortLabel.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get hostFormPortLabel;

  /// No description provided for @hostFormCredentialLabel.
  ///
  /// In en, this message translates to:
  /// **'Credential'**
  String get hostFormCredentialLabel;

  /// No description provided for @hostFormSelectCredential.
  ///
  /// In en, this message translates to:
  /// **'Select credential'**
  String get hostFormSelectCredential;

  /// No description provided for @hostFormCreateCredential.
  ///
  /// In en, this message translates to:
  /// **'Create credential'**
  String get hostFormCreateCredential;

  /// No description provided for @hostFormGroupLabel.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get hostFormGroupLabel;

  /// No description provided for @hostFormNoGroupOption.
  ///
  /// In en, this message translates to:
  /// **'No group'**
  String get hostFormNoGroupOption;

  /// No description provided for @hostFormAccentLabel.
  ///
  /// In en, this message translates to:
  /// **'Accent'**
  String get hostFormAccentLabel;

  /// No description provided for @hostFormSave.
  ///
  /// In en, this message translates to:
  /// **'Save host'**
  String get hostFormSave;

  /// No description provided for @hostFormValidation.
  ///
  /// In en, this message translates to:
  /// **'Name, host, and credential are required.'**
  String get hostFormValidation;

  /// No description provided for @hostFormInlineToggle.
  ///
  /// In en, this message translates to:
  /// **'Enter credential manually'**
  String get hostFormInlineToggle;

  /// No description provided for @hostFormInlineCancel.
  ///
  /// In en, this message translates to:
  /// **'Use saved credential'**
  String get hostFormInlineCancel;

  /// No description provided for @hostFormCredentialInlineTitle.
  ///
  /// In en, this message translates to:
  /// **'Credential details'**
  String get hostFormCredentialInlineTitle;

  /// No description provided for @hostFormCredentialInlineRequired.
  ///
  /// In en, this message translates to:
  /// **'Fill in complete credential information.'**
  String get hostFormCredentialInlineRequired;

  /// No description provided for @hostFormCredentialMissing.
  ///
  /// In en, this message translates to:
  /// **'Please select or create a credential first.'**
  String get hostFormCredentialMissing;

  /// No description provided for @groupsTitle.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get groupsTitle;

  /// No description provided for @groupsNew.
  ///
  /// In en, this message translates to:
  /// **'New group'**
  String get groupsNew;

  /// No description provided for @groupsNoDescription.
  ///
  /// In en, this message translates to:
  /// **'No description'**
  String get groupsNoDescription;

  /// No description provided for @groupsHostCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {{count} host} other {{count} hosts}}'**
  String groupsHostCount(int count);

  /// No description provided for @groupsDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete group'**
  String get groupsDeleteTitle;

  /// No description provided for @groupsDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Hosts in this group will become ungrouped.'**
  String get groupsDeleteMessage;

  /// No description provided for @groupFormTitleNew.
  ///
  /// In en, this message translates to:
  /// **'Add group'**
  String get groupFormTitleNew;

  /// No description provided for @groupFormTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit group'**
  String get groupFormTitleEdit;

  /// No description provided for @groupFormNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Group name'**
  String get groupFormNameLabel;

  /// No description provided for @groupFormDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get groupFormDescriptionLabel;

  /// No description provided for @groupFormSave.
  ///
  /// In en, this message translates to:
  /// **'Save group'**
  String get groupFormSave;

  /// No description provided for @groupFormValidation.
  ///
  /// In en, this message translates to:
  /// **'Name is required.'**
  String get groupFormValidation;

  /// No description provided for @snippetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Scripts'**
  String get snippetsTitle;

  /// No description provided for @snippetsNew.
  ///
  /// In en, this message translates to:
  /// **'New snippet'**
  String get snippetsNew;

  /// No description provided for @snippetsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No snippets yet'**
  String get snippetsEmpty;

  /// No description provided for @snippetsPanelHint.
  ///
  /// In en, this message translates to:
  /// **'Create snippets to quick send'**
  String get snippetsPanelHint;

  /// No description provided for @snippetsCopyMessage.
  ///
  /// In en, this message translates to:
  /// **'Copied command'**
  String get snippetsCopyMessage;

  /// No description provided for @snippetsDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete snippet'**
  String get snippetsDeleteTitle;

  /// No description provided for @snippetsDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {title}?'**
  String snippetsDeleteMessage(String title);

  /// No description provided for @snippetFormTitleNew.
  ///
  /// In en, this message translates to:
  /// **'New snippet'**
  String get snippetFormTitleNew;

  /// No description provided for @snippetFormTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit script'**
  String get snippetFormTitleEdit;

  /// No description provided for @snippetFormTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get snippetFormTitleLabel;

  /// No description provided for @snippetFormCommandLabel.
  ///
  /// In en, this message translates to:
  /// **'Command'**
  String get snippetFormCommandLabel;

  /// No description provided for @snippetFormSave.
  ///
  /// In en, this message translates to:
  /// **'Save snippet'**
  String get snippetFormSave;

  /// No description provided for @snippetFormValidation.
  ///
  /// In en, this message translates to:
  /// **'Title and command are required.'**
  String get snippetFormValidation;

  /// No description provided for @vaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Credentials'**
  String get vaultTitle;

  /// No description provided for @vaultNew.
  ///
  /// In en, this message translates to:
  /// **'New credential'**
  String get vaultNew;

  /// No description provided for @vaultEmpty.
  ///
  /// In en, this message translates to:
  /// **'No credentials yet'**
  String get vaultEmpty;

  /// No description provided for @vaultDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete credential'**
  String get vaultDeleteTitle;

  /// No description provided for @vaultDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Hosts referencing this credential will need to be updated manually.'**
  String get vaultDeleteMessage;

  /// No description provided for @credentialFormTitleNew.
  ///
  /// In en, this message translates to:
  /// **'Add credential'**
  String get credentialFormTitleNew;

  /// No description provided for @credentialFormTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit credential'**
  String get credentialFormTitleEdit;

  /// No description provided for @credentialFormLabel.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get credentialFormLabel;

  /// No description provided for @credentialFormUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get credentialFormUsername;

  /// No description provided for @credentialFormPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get credentialFormPassword;

  /// No description provided for @credentialFormKeyPair.
  ///
  /// In en, this message translates to:
  /// **'Key pair'**
  String get credentialFormKeyPair;

  /// No description provided for @credentialFormPrivateKey.
  ///
  /// In en, this message translates to:
  /// **'Private key (PEM)'**
  String get credentialFormPrivateKey;

  /// No description provided for @credentialFormPassphrase.
  ///
  /// In en, this message translates to:
  /// **'Passphrase (optional)'**
  String get credentialFormPassphrase;

  /// No description provided for @credentialFormSave.
  ///
  /// In en, this message translates to:
  /// **'Save credential'**
  String get credentialFormSave;

  /// No description provided for @credentialFormValidation.
  ///
  /// In en, this message translates to:
  /// **'Name and username are required.'**
  String get credentialFormValidation;

  /// No description provided for @credentialAuthPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get credentialAuthPassword;

  /// No description provided for @credentialAuthKeyPair.
  ///
  /// In en, this message translates to:
  /// **'Key pair'**
  String get credentialAuthKeyPair;

  /// No description provided for @credentialUnknownUser.
  ///
  /// In en, this message translates to:
  /// **'unknown'**
  String get credentialUnknownUser;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsConfirm.
  ///
  /// In en, this message translates to:
  /// **'Connection confirmation'**
  String get settingsConfirm;

  /// No description provided for @settingsConfirmSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Prompt before opening remote session'**
  String get settingsConfirmSubtitle;

  /// No description provided for @settingsConfirmDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect to {name}?'**
  String settingsConfirmDialogTitle(String name);

  /// No description provided for @settingsConfirmDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'A terminal session will open for {name}. Continue?'**
  String settingsConfirmDialogMessage(String name);

  /// No description provided for @settingsMultiWindow.
  ///
  /// In en, this message translates to:
  /// **'Multi-window terminals'**
  String get settingsMultiWindow;

  /// No description provided for @settingsMultiWindowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open each connection in a separate window'**
  String get settingsMultiWindowSubtitle;

  /// No description provided for @settingsImport.
  ///
  /// In en, this message translates to:
  /// **'Import data'**
  String get settingsImport;

  /// No description provided for @settingsImportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Replace local data with a backup'**
  String get settingsImportSubtitle;

  /// No description provided for @settingsImportAction.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get settingsImportAction;

  /// No description provided for @settingsImportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Import completed'**
  String get settingsImportSuccess;

  /// No description provided for @settingsImportFailure.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String settingsImportFailure(String error);

  /// No description provided for @settingsImportCancelled.
  ///
  /// In en, this message translates to:
  /// **'Import cancelled'**
  String get settingsImportCancelled;

  /// No description provided for @settingsImportConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Replace existing data?'**
  String get settingsImportConfirmTitle;

  /// No description provided for @settingsImportConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Current hosts, groups, credentials and scripts will be overwritten.'**
  String get settingsImportConfirmMessage;

  /// No description provided for @settingsExport.
  ///
  /// In en, this message translates to:
  /// **'Export data'**
  String get settingsExport;

  /// No description provided for @settingsExportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a backup of hosts and credentials'**
  String get settingsExportSubtitle;

  /// No description provided for @settingsExportAction.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get settingsExportAction;

  /// No description provided for @settingsExportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup saved to {path}'**
  String settingsExportSuccess(String path);

  /// No description provided for @settingsExportFailure.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String settingsExportFailure(String error);

  /// No description provided for @settingsExportCancelled.
  ///
  /// In en, this message translates to:
  /// **'Export cancelled'**
  String get settingsExportCancelled;

  /// No description provided for @genericErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String genericErrorMessage(String error);

  /// No description provided for @hostLastConnectedNever.
  ///
  /// In en, this message translates to:
  /// **'Never connected'**
  String get hostLastConnectedNever;

  /// No description provided for @hostLastConnectedJustNow.
  ///
  /// In en, this message translates to:
  /// **'Connected just now'**
  String get hostLastConnectedJustNow;

  /// No description provided for @hostLastConnectedMinutes.
  ///
  /// In en, this message translates to:
  /// **'Connected {minutes}m ago'**
  String hostLastConnectedMinutes(int minutes);

  /// No description provided for @hostLastConnectedHours.
  ///
  /// In en, this message translates to:
  /// **'Connected {hours}h ago'**
  String hostLastConnectedHours(int hours);

  /// No description provided for @hostLastConnectedDays.
  ///
  /// In en, this message translates to:
  /// **'Connected {days}d ago'**
  String hostLastConnectedDays(int days);

  /// No description provided for @terminalReconnectTooltip.
  ///
  /// In en, this message translates to:
  /// **'Reconnect'**
  String get terminalReconnectTooltip;

  /// No description provided for @terminalNewSnippetTooltip.
  ///
  /// In en, this message translates to:
  /// **'New snippet'**
  String get terminalNewSnippetTooltip;

  /// No description provided for @terminalSidebarFiles.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get terminalSidebarFiles;

  /// No description provided for @terminalSidebarCommands.
  ///
  /// In en, this message translates to:
  /// **'Commands'**
  String get terminalSidebarCommands;

  /// No description provided for @terminalSidebarHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get terminalSidebarHistory;

  /// No description provided for @terminalSidebarFilesLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading files...'**
  String get terminalSidebarFilesLoading;

  /// No description provided for @terminalSidebarFilesConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect to load files.'**
  String get terminalSidebarFilesConnect;

  /// No description provided for @terminalSidebarFilesEmpty.
  ///
  /// In en, this message translates to:
  /// **'Folder is empty.'**
  String get terminalSidebarFilesEmpty;

  /// No description provided for @terminalSidebarFilesError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load files: {error}'**
  String terminalSidebarFilesError(String error);

  /// No description provided for @terminalSidebarFilesRefresh.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get terminalSidebarFilesRefresh;

  /// No description provided for @terminalSidebarFilesUp.
  ///
  /// In en, this message translates to:
  /// **'Parent folder'**
  String get terminalSidebarFilesUp;

  /// No description provided for @terminalSidebarFilesRefreshSuccess.
  ///
  /// In en, this message translates to:
  /// **'Refreshed'**
  String get terminalSidebarFilesRefreshSuccess;

  /// No description provided for @terminalSidebarFilesNewFile.
  ///
  /// In en, this message translates to:
  /// **'New file'**
  String get terminalSidebarFilesNewFile;

  /// No description provided for @terminalSidebarFilesNewFolder.
  ///
  /// In en, this message translates to:
  /// **'New folder'**
  String get terminalSidebarFilesNewFolder;

  /// No description provided for @terminalSidebarFilesRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get terminalSidebarFilesRename;

  /// No description provided for @terminalSidebarFilesDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get terminalSidebarFilesDownload;

  /// No description provided for @terminalSidebarFilesUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get terminalSidebarFilesUpload;

  /// No description provided for @terminalSidebarFilesDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get terminalSidebarFilesDelete;

  /// No description provided for @terminalSidebarFilesNewFilePrompt.
  ///
  /// In en, this message translates to:
  /// **'Enter a file name'**
  String get terminalSidebarFilesNewFilePrompt;

  /// No description provided for @terminalSidebarFilesNewFolderPrompt.
  ///
  /// In en, this message translates to:
  /// **'Enter a folder name'**
  String get terminalSidebarFilesNewFolderPrompt;

  /// No description provided for @terminalSidebarFilesRenamePrompt.
  ///
  /// In en, this message translates to:
  /// **'Rename {name}'**
  String terminalSidebarFilesRenamePrompt(String name);

  /// No description provided for @terminalSidebarFilesDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete item'**
  String get terminalSidebarFilesDeleteTitle;

  /// No description provided for @terminalSidebarFilesDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}? This cannot be undone.'**
  String terminalSidebarFilesDeleteConfirm(String name);

  /// No description provided for @terminalSidebarFilesDownloadSuccess.
  ///
  /// In en, this message translates to:
  /// **'Saved to {path}'**
  String terminalSidebarFilesDownloadSuccess(String path);

  /// No description provided for @terminalSidebarFilesDownloadFailure.
  ///
  /// In en, this message translates to:
  /// **'Download failed: {error}'**
  String terminalSidebarFilesDownloadFailure(String error);

  /// No description provided for @terminalSidebarFilesUploadSuccess.
  ///
  /// In en, this message translates to:
  /// **'Uploaded {name}'**
  String terminalSidebarFilesUploadSuccess(String name);

  /// No description provided for @terminalSidebarFilesUploadFailure.
  ///
  /// In en, this message translates to:
  /// **'Upload failed: {error}'**
  String terminalSidebarFilesUploadFailure(String error);

  /// No description provided for @terminalSidebarFilesEditHint.
  ///
  /// In en, this message translates to:
  /// **'Edit file content'**
  String get terminalSidebarFilesEditHint;

  /// No description provided for @terminalSidebarFilesSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get terminalSidebarFilesSave;

  /// No description provided for @terminalSidebarFilesSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Saved {name}'**
  String terminalSidebarFilesSaveSuccess(String name);

  /// No description provided for @terminalSidebarFilesEditFailure.
  ///
  /// In en, this message translates to:
  /// **'Failed to open file: {error}'**
  String terminalSidebarFilesEditFailure(String error);

  /// No description provided for @terminalSidebarFilesCopyPath.
  ///
  /// In en, this message translates to:
  /// **'Copy path'**
  String get terminalSidebarFilesCopyPath;

  /// No description provided for @terminalSidebarFilesCopyPathSuccess.
  ///
  /// In en, this message translates to:
  /// **'Copied: {path}'**
  String terminalSidebarFilesCopyPathSuccess(String path);

  /// No description provided for @terminalSidebarFilesPathHint.
  ///
  /// In en, this message translates to:
  /// **'Enter path'**
  String get terminalSidebarFilesPathHint;

  /// No description provided for @terminalSidebarFilesPreviewUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Only text files can be previewed.'**
  String get terminalSidebarFilesPreviewUnsupported;

  /// No description provided for @terminalSidebarHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get terminalSidebarHistoryTitle;

  /// No description provided for @terminalSidebarHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No commands yet.'**
  String get terminalSidebarHistoryEmpty;

  /// No description provided for @terminalSidebarHistoryClear.
  ///
  /// In en, this message translates to:
  /// **'Clear history'**
  String get terminalSidebarHistoryClear;

  /// No description provided for @settingsHistoryLimit.
  ///
  /// In en, this message translates to:
  /// **'History limit'**
  String get settingsHistoryLimit;

  /// No description provided for @settingsHistoryLimitSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep up to {count} commands'**
  String settingsHistoryLimitSubtitle(int count);

  /// No description provided for @settingsDownloadPath.
  ///
  /// In en, this message translates to:
  /// **'Download folder'**
  String get settingsDownloadPath;

  /// No description provided for @settingsDownloadPathUnset.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get settingsDownloadPathUnset;

  /// No description provided for @settingsDownloadPathChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose folder'**
  String get settingsDownloadPathChoose;

  /// No description provided for @settingsDownloadPathClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get settingsDownloadPathClear;

  /// No description provided for @terminalSidebarHistoryPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'No history yet.'**
  String get terminalSidebarHistoryPlaceholder;

  /// No description provided for @terminalCredentialDeleted.
  ///
  /// In en, this message translates to:
  /// **'Credential deleted'**
  String get terminalCredentialDeleted;

  /// No description provided for @terminalCredentialError.
  ///
  /// In en, this message translates to:
  /// **'Credential error: {error}'**
  String terminalCredentialError(String error);

  /// No description provided for @terminalHostRemoved.
  ///
  /// In en, this message translates to:
  /// **'Host removed'**
  String get terminalHostRemoved;

  /// No description provided for @terminalHostError.
  ///
  /// In en, this message translates to:
  /// **'Host not found: {error}'**
  String terminalHostError(String error);

  /// No description provided for @terminalConnectingMessage.
  ///
  /// In en, this message translates to:
  /// **'Connecting to {host}...'**
  String terminalConnectingMessage(String host);

  /// No description provided for @terminalConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed: {error}'**
  String terminalConnectionFailed(String error);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
