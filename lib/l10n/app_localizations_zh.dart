// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'STerminal';

  @override
  String get commonCancel => '取消';

  @override
  String get commonConfirm => '确认';

  @override
  String get commonDelete => '删除';

  @override
  String get commonSearch => '搜索';

  @override
  String get commonPrevious => '上一个';

  @override
  String get commonNext => '下一个';

  @override
  String get commonReplace => '替换';

  @override
  String get commonReplaceAll => '全部替换';

  @override
  String get connectionsTitle => '连接';

  @override
  String get connectionsNewHost => '新建主机';

  @override
  String get connectionsSearchHint => '按主机、标签或地址搜索';

  @override
  String get filterAll => '全部';

  @override
  String get filterUngrouped => '未分组';

  @override
  String connectionsLoadError(String error) {
    return '加载主机失败：$error';
  }

  @override
  String hostInspectorLoadError(String error) {
    return '加载主机失败：$error';
  }

  @override
  String get hostInspectorEmpty => '选择一台主机以查看详情';

  @override
  String get hostCreateButton => '创建主机';

  @override
  String get hostConnect => '连接';

  @override
  String get hostEdit => '编辑';

  @override
  String get hostDeleteTooltip => '删除主机';

  @override
  String get hostDeleteTitle => '删除主机';

  @override
  String hostDeleteMessage(String name) {
    return '确定要删除 $name 吗？';
  }

  @override
  String get hostNoDescription => '暂无描述';

  @override
  String get hostNoTags => '暂无标签';

  @override
  String get hostMissingCredential => '凭证缺失';

  @override
  String get hostInspectorEndpoint => '终端地址';

  @override
  String get hostInspectorCredential => '凭证';

  @override
  String get hostInspectorTags => '标签';

  @override
  String get hostFormTitleNew => '新建主机';

  @override
  String get hostFormTitleEdit => '编辑主机';

  @override
  String get hostFormDisplayName => '显示名称';

  @override
  String get hostFormHostLabel => '主机 / IP';

  @override
  String get hostFormPortLabel => '端口';

  @override
  String get hostFormCredentialLabel => '凭证';

  @override
  String get hostFormSelectCredential => '选择凭证';

  @override
  String get hostFormCreateCredential => '新建凭证';

  @override
  String get hostFormGroupLabel => '分组';

  @override
  String get hostFormNoGroupOption => '无分组';

  @override
  String get hostFormAccentLabel => '颜色';

  @override
  String get hostFormSave => '保存主机';

  @override
  String get hostFormValidation => '请填写名称、主机地址和凭证。';

  @override
  String get hostFormInlineToggle => '手动填写凭证';

  @override
  String get hostFormInlineCancel => '使用已有凭证';

  @override
  String get hostFormCredentialInlineTitle => '凭证信息';

  @override
  String get hostFormCredentialInlineRequired => '请填写完整的凭证信息。';

  @override
  String get hostFormCredentialMissing => '请先选择或创建凭证。';

  @override
  String get groupsTitle => '分组';

  @override
  String get groupsNew => '新建分组';

  @override
  String get groupsNoDescription => '暂无描述';

  @override
  String groupsHostCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 台主机',
    );
    return '$_temp0';
  }

  @override
  String get groupsDeleteTitle => '删除分组';

  @override
  String get groupsDeleteMessage => '该分组下的主机将变为未分组。';

  @override
  String get groupFormTitleNew => '新增分组';

  @override
  String get groupFormTitleEdit => '编辑分组';

  @override
  String get groupFormNameLabel => '分组名称';

  @override
  String get groupFormDescriptionLabel => '描述';

  @override
  String get groupFormSave => '保存分组';

  @override
  String get groupFormValidation => '名称不能为空。';

  @override
  String get snippetsTitle => '脚本';

  @override
  String get snippetsNew => '新建片段';

  @override
  String get snippetsEmpty => '暂无片段';

  @override
  String get snippetsPanelHint => '创建片段以便快速发送';

  @override
  String get snippetsCopyMessage => '已复制命令';

  @override
  String get snippetsDeleteTitle => '删除片段';

  @override
  String snippetsDeleteMessage(String title) {
    return '确定删除 $title 吗？';
  }

  @override
  String get snippetFormTitleNew => '新建片段';

  @override
  String get snippetFormTitleEdit => '编辑脚本';

  @override
  String get snippetFormTitleLabel => '标题';

  @override
  String get snippetFormCommandLabel => '命令';

  @override
  String get snippetFormSave => '保存片段';

  @override
  String get snippetFormValidation => '标题和命令不能为空。';

  @override
  String get vaultTitle => '凭证';

  @override
  String get vaultNew => '新建凭证';

  @override
  String get vaultEmpty => '暂无凭证';

  @override
  String get vaultDeleteTitle => '删除凭证';

  @override
  String get vaultDeleteMessage => '引用该凭证的主机需要手动更新。';

  @override
  String get credentialFormTitleNew => '新增凭证';

  @override
  String get credentialFormTitleEdit => '编辑凭证';

  @override
  String get credentialFormLabel => '标签';

  @override
  String get credentialFormUsername => '用户名';

  @override
  String get credentialFormPassword => '密码';

  @override
  String get credentialFormKeyPair => '密钥对';

  @override
  String get credentialFormPrivateKey => '私钥（PEM）';

  @override
  String get credentialFormPassphrase => '密钥密码（可选）';

  @override
  String get credentialFormSave => '保存凭证';

  @override
  String get credentialFormValidation => '名称和用户名不能为空。';

  @override
  String get credentialAuthPassword => '密码';

  @override
  String get credentialAuthKeyPair => '密钥对';

  @override
  String get credentialUnknownUser => '未知用户';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsAppearance => '外观';

  @override
  String get settingsThemeLight => '浅色';

  @override
  String get settingsThemeDark => '深色';

  @override
  String get settingsThemeSystem => '系统';

  @override
  String get settingsConfirm => '连接确认';

  @override
  String get settingsConfirmSubtitle => '连接前弹出确认';

  @override
  String settingsConfirmDialogTitle(String name) {
    return '连接到 $name？';
  }

  @override
  String settingsConfirmDialogMessage(String name) {
    return '将为 $name 打开新的终端会话，确认继续？';
  }

  @override
  String get settingsMultiWindow => '多窗口连接';

  @override
  String get settingsMultiWindowSubtitle => '每次连接都在新窗口打开';

  @override
  String get settingsImport => '导入数据';

  @override
  String get settingsImportSubtitle => '使用备份覆盖本地数据';

  @override
  String get settingsImportAction => '导入';

  @override
  String get settingsImportSuccess => '导入完成';

  @override
  String settingsImportFailure(String error) {
    return '导入失败：$error';
  }

  @override
  String get settingsImportCancelled => '已取消导入';

  @override
  String get settingsImportConfirmTitle => '要覆盖现有数据吗？';

  @override
  String get settingsImportConfirmMessage => '当前所有主机、分组、凭证与脚本都会被备份数据替换。';

  @override
  String get settingsExport => '导出数据';

  @override
  String get settingsExportSubtitle => '生成主机与凭证备份';

  @override
  String get settingsExportAction => '导出';

  @override
  String settingsExportSuccess(String path) {
    return '备份已保存到 $path';
  }

  @override
  String settingsExportFailure(String error) {
    return '导出失败：$error';
  }

  @override
  String get settingsExportCancelled => '已取消导出';

  @override
  String genericErrorMessage(String error) {
    return '错误：$error';
  }

  @override
  String get hostLastConnectedNever => '从未连接';

  @override
  String get hostLastConnectedJustNow => '刚刚连接';

  @override
  String hostLastConnectedMinutes(int minutes) {
    return '$minutes 分钟前连接';
  }

  @override
  String hostLastConnectedHours(int hours) {
    return '$hours 小时前连接';
  }

  @override
  String hostLastConnectedDays(int days) {
    return '$days 天前连接';
  }

  @override
  String get terminalReconnectTooltip => '重新连接';

  @override
  String get terminalNewSnippetTooltip => '新建片段';

  @override
  String get terminalSidebarFiles => '文件';

  @override
  String get terminalSidebarCommands => '命令';

  @override
  String get terminalSidebarHistory => '历史';

  @override
  String get terminalSidebarFilesLoading => '正在加载文件…';

  @override
  String get terminalSidebarFilesConnect => '连接后可查看文件';

  @override
  String get terminalSidebarFilesEmpty => '文件夹为空';

  @override
  String terminalSidebarFilesError(String error) {
    return '加载文件失败：$error';
  }

  @override
  String get terminalSidebarFilesRefresh => '刷新';

  @override
  String get terminalSidebarFilesUp => '上一级';

  @override
  String get terminalSidebarFilesRefreshSuccess => '已刷新';

  @override
  String get terminalSidebarFilesNewFile => '新建文件';

  @override
  String get terminalSidebarFilesNewFolder => '新建文件夹';

  @override
  String get terminalSidebarFilesRename => '重命名';

  @override
  String get terminalSidebarFilesDownload => '下载文件';

  @override
  String get terminalSidebarFilesUpload => '上传文件';

  @override
  String get terminalSidebarFilesDelete => '删除';

  @override
  String get terminalSidebarFilesNewFilePrompt => '输入文件名';

  @override
  String get terminalSidebarFilesNewFolderPrompt => '输入文件夹名称';

  @override
  String terminalSidebarFilesRenamePrompt(String name) {
    return '重命名 $name';
  }

  @override
  String get terminalSidebarFilesDeleteTitle => '删除项目';

  @override
  String terminalSidebarFilesDeleteConfirm(String name) {
    return '确定删除 $name 吗？该操作无法撤销。';
  }

  @override
  String terminalSidebarFilesDownloadSuccess(String path) {
    return '已保存到 $path';
  }

  @override
  String terminalSidebarFilesDownloadFailure(String error) {
    return '下载失败：$error';
  }

  @override
  String terminalSidebarFilesUploadSuccess(String name) {
    return '已上传 $name';
  }

  @override
  String terminalSidebarFilesUploadFailure(String error) {
    return '上传失败：$error';
  }

  @override
  String get terminalSidebarFilesEditHint => '编辑文件内容';

  @override
  String get terminalSidebarFilesSave => '保存';

  @override
  String terminalSidebarFilesSaveSuccess(String name) {
    return '已保存 $name';
  }

  @override
  String terminalSidebarFilesEditFailure(String error) {
    return '打开文件失败：$error';
  }

  @override
  String get terminalSidebarFilesCopyPath => '复制路径';

  @override
  String terminalSidebarFilesCopyPathSuccess(String path) {
    return '已复制：$path';
  }

  @override
  String get terminalSidebarFilesPathHint => '输入路径';

  @override
  String get terminalSidebarFilesPreviewUnsupported => '仅支持预览文本文件';

  @override
  String get terminalSidebarHistoryTitle => '历史命令';

  @override
  String get terminalSidebarHistoryEmpty => '暂无命令';

  @override
  String get terminalSidebarHistoryClear => '清空历史';

  @override
  String get settingsHistoryLimit => '历史数量限制';

  @override
  String settingsHistoryLimitSubtitle(int count) {
    return '最多保留 $count 条命令';
  }

  @override
  String get settingsDownloadPath => '下载位置';

  @override
  String get settingsDownloadPathUnset => '未设置';

  @override
  String get settingsDownloadPathChoose => '选择文件夹';

  @override
  String get settingsDownloadPathClear => '清除';

  @override
  String get terminalSidebarHistoryPlaceholder => '暂无历史记录';

  @override
  String get terminalCredentialDeleted => '凭证已删除';

  @override
  String terminalCredentialError(String error) {
    return '凭证错误：$error';
  }

  @override
  String get terminalHostRemoved => '主机已删除';

  @override
  String terminalHostError(String error) {
    return '无法找到主机：$error';
  }

  @override
  String terminalConnectingMessage(String host) {
    return '正在连接 $host...';
  }

  @override
  String terminalConnectionFailed(String error) {
    return '连接失败：$error';
  }
}
