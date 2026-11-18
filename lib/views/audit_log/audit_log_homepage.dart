import 'dart:convert';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:klinik_aurora_portal/config/app_colors.dart';
import 'package:klinik_aurora_portal/config/route_names.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/audit_log/audit_log_controller.dart';
import 'package:klinik_aurora_portal/controllers/top_bar/top_bar_controller.dart';
import 'package:klinik_aurora_portal/views/homepage/homepage.dart';
import 'package:klinik_aurora_portal/views/widgets/button/app_button.dart';
import 'package:klinik_aurora_portal/views/widgets/debouncer/debouncer.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/app_filter_field.dart';
import 'package:klinik_aurora_portal/views/widgets/shortcuts/portal_shortcuts.dart';
import 'package:klinik_aurora_portal/views/widgets/toast/toast.dart';
import 'package:provider/provider.dart';

/// Super Admin searchable Audit Trail & Activity Log Viewer (#7).
class AuditLogHomepage extends StatefulWidget {
  static const routeName = RouteNames.auditLog;
  static const displayName = RouteNames.auditLogDisplay;

  const AuditLogHomepage({super.key});

  @override
  State<AuditLogHomepage> createState() => _AuditLogHomepageState();
}

class _AuditLogHomepageState extends State<AuditLogHomepage> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final _debouncer = Debouncer(milliseconds: 350);

  bool _loading = true;
  String? _error;
  AuditLogPageResponse? _pageData;
  int _page = 1;
  String? _entityType;
  String? _action;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    PortalSearchFocusBus.register(_searchFocus);
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      if (!mounted) return;
      context.read<TopBarController>().pageValue = Homepage.getPageId(AuditLogHomepage.displayName);
    });
    _fetch();
  }

  @override
  void dispose() {
    PortalSearchFocusBus.unregister(_searchFocus);
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _fetch({int? page}) async {
    if (page != null) _page = page;
    setState(() {
      _loading = true;
      _error = null;
    });
    final fmt = DateFormat('yyyy-MM-dd');
    final res = await AuditLogController.fetch(
      context,
      page: _page,
      pageSize: 25,
      entityType: _entityType,
      action: _action,
      search: _searchCtrl.text,
      startDate: _dateRange != null ? fmt.format(_dateRange!.start) : null,
      endDate: _dateRange != null ? fmt.format(_dateRange!.end) : null,
    );
    if (!mounted) return;
    if (responseCode(res.code) && res.data != null) {
      setState(() {
        _pageData = res.data;
        _loading = false;
      });
    } else {
      setState(() {
        _error = res.message ?? 'Failed to load audit logs.';
        _loading = false;
      });
    }
  }

  Future<void> _exportCsv() async {
    final rows = _pageData?.data ?? [];
    if (rows.isEmpty) return;
    final buf = StringBuffer('Timestamp,Admin,Email,Branch,Entity,EntityId,Action,Summary,IP\n');
    for (final r in rows) {
      String esc(String? s) => '"${(s ?? '').replaceAll('"', '""')}"';
      buf.writeln([
        esc(r.createdDate),
        esc(r.adminName),
        esc(r.adminEmail),
        esc(r.branchName ?? 'HQ'),
        esc(r.entityType),
        esc(r.entityId),
        esc(r.action),
        esc(r.summary),
        esc(r.ipAddress),
      ].join(','));
    }
    await FileSaver.instance.saveFile(
      name: 'aurora_audit_log_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}',
      bytes: Uint8List.fromList(utf8.encode(buf.toString())),
      fileExtension: 'csv',
      mimeType: MimeType.csv,
    );
    if (mounted) AppToast.snackbar(context, 'Exported ${rows.length} audit rows to CSV.');
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: now.add(const Duration(days: 1)),
      initialDateRange: _dateRange ??
          DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
      _fetch(page: 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final items = _pageData?.data ?? [];
    final isNarrow = MediaQuery.sizeOf(context).width < 900;

    return Scaffold(
      backgroundColor: colors.canvas,
      body: Padding(
        padding: EdgeInsets.all(isNarrow ? 12 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ───────────────────────────────────────────────────
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Audit Trail & Activity Log',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: colors.inkPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Immutable Super Admin accountability ledger across appointments, rosters, points, and recalls.',
                      style: TextStyle(fontSize: 13, color: colors.inkMuted),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AppButton.secondary(
                      text: _dateRange == null
                          ? 'Date Range'
                          : '${DateFormat('dd MMM').format(_dateRange!.start)} – ${DateFormat('dd MMM').format(_dateRange!.end)}',
                      icon: Icon(Icons.date_range_rounded, size: 16, color: colors.inkSecondary),
                      onPressed: _pickDateRange,
                    ),
                    if (_dateRange != null)
                      IconButton(
                        tooltip: 'Clear date filter',
                        onPressed: () {
                          setState(() => _dateRange = null);
                          _fetch(page: 1);
                        },
                        icon: Icon(Icons.close_rounded, size: 18, color: colors.inkMuted),
                      ),
                    AppButton.secondary(
                      text: 'Export CSV',
                      icon: Icon(Icons.download_rounded, size: 16, color: colors.inkSecondary),
                      onPressed: items.isEmpty ? null : _exportCsv,
                    ),
                    AppButton.primary(
                      text: 'Refresh',
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      onPressed: () => _fetch(),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Filter Toolbar ───────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.border),
              ),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: isNarrow ? double.infinity : 300,
                    child: AppFilterField(
                      controller: _searchCtrl,
                      focusNode: _searchFocus,
                      hintText: 'Search admin, summary, or ID... (press /)',
                      onChanged: (_) => _debouncer.run(() => _fetch(page: 1)),
                      onClear: () => _fetch(page: 1),
                    ),
                  ),
                  _dropdownChip(
                    context,
                    hint: 'All Entities',
                    value: _entityType,
                    options: _pageData?.entityTypes ??
                        const ['appointment', 'branch_roster', 'service', 'point', 'user'],
                    onChanged: (v) {
                      setState(() => _entityType = v);
                      _fetch(page: 1);
                    },
                  ),
                  _dropdownChip(
                    context,
                    hint: 'All Actions',
                    value: _action,
                    options: _pageData?.actions ??
                        const ['CREATE', 'UPDATE', 'TRANSFER', 'STATUS_CHANGE', 'CANCEL', 'DELETE', 'RECALL_SENT'],
                    onChanged: (v) {
                      setState(() => _action = v);
                      _fetch(page: 1);
                    },
                  ),
                  if (_pageData != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: colors.brandSoftBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colors.brandBorder),
                      ),
                      child: Text(
                        '${_pageData!.totalCount} events',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.brandText),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Content ──────────────────────────────────────────────────
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.border),
                ),
                child: _loading
                    ? Center(child: CircularProgressIndicator(color: colors.brandPrimary))
                    : _error != null
                        ? Center(child: Text(_error!, style: TextStyle(color: colors.danger)))
                        : items.isEmpty
                            ? Center(
                                child: Text(
                                  'No audit events match your filters.',
                                  style: TextStyle(color: colors.inkMuted, fontSize: 14),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(12),
                                itemCount: items.length,
                                separatorBuilder: (_, _) => Divider(height: 1, color: colors.border),
                                itemBuilder: (context, idx) => _buildRow(context, items[idx]),
                              ),
              ),
            ),

            // ── Pagination ───────────────────────────────────────────────
            if (_pageData != null && _pageData!.totalPage > 1) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Page ${_pageData!.currentPage} of ${_pageData!.totalPage}',
                    style: TextStyle(fontSize: 12, color: colors.inkMuted),
                  ),
                  const SizedBox(width: 12),
                  AppButton.secondary(
                    text: 'Previous',
                    height: 36,
                    onPressed: _page > 1 ? () => _fetch(page: _page - 1) : null,
                  ),
                  const SizedBox(width: 8),
                  AppButton.secondary(
                    text: 'Next',
                    height: 36,
                    onPressed: _page < _pageData!.totalPage ? () => _fetch(page: _page + 1) : null,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _dropdownChip(
    BuildContext context, {
    required String hint,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    final colors = context.appColors;
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: colors.inputFill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: options.contains(value) ? value : null,
          hint: Text(hint, style: TextStyle(fontSize: 12, color: colors.inkMuted)),
          dropdownColor: colors.surfaceElevated,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.inkPrimary),
          items: [
            DropdownMenuItem<String?>(value: null, child: Text(hint)),
            for (final opt in options)
              DropdownMenuItem<String?>(value: opt, child: Text(opt)),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, AuditLogEntry e) {
    final colors = context.appColors;
    final badgeColor = _actionColor(colors, e.action);
    final hasDiff = e.beforeState != null || e.afterState != null;

    return InkWell(
      onTap: () => _showDiffDialog(context, e),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: badgeColor.withValues(alpha: 0.35)),
              ),
              child: Text(
                e.action,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: badgeColor),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.summary,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.inkPrimary),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 10,
                    runSpacing: 4,
                    children: [
                      Text(
                        '${e.adminName} (${e.adminEmail})',
                        style: TextStyle(fontSize: 12, color: colors.inkSecondary),
                      ),
                      Text(
                        '· ${e.entityType}#${e.entityId.length > 10 ? e.entityId.substring(0, 10) : e.entityId}',
                        style: TextStyle(fontSize: 12, color: colors.inkMuted),
                      ),
                      if (e.branchName != null)
                        Text('· ${e.branchName}', style: TextStyle(fontSize: 12, color: colors.inkMuted)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(e.createdDate, style: TextStyle(fontSize: 12, color: colors.inkMuted)),
                if (hasDiff) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Inspect diff →',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: colors.brandText),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _actionColor(AppColors colors, String action) {
    switch (action.toUpperCase()) {
      case 'CREATE':
        return colors.success;
      case 'DELETE':
      case 'CANCEL':
        return colors.danger;
      case 'TRANSFER':
      case 'RESCHEDULE':
        return colors.warning;
      case 'RECALL_SENT':
        return colors.brandText;
      default:
        return colors.info;
    }
  }

  void _showDiffDialog(BuildContext context, AuditLogEntry e) {
    final colors = context.appColors;
    const encoder = JsonEncoder.withIndent('  ');
    final beforeJson = e.beforeState != null ? encoder.convert(e.beforeState) : '— (none)';
    final afterJson = e.afterState != null ? encoder.convert(e.afterState) : '— (none)';

    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colors.border),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 680,
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.84,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 14),
                decoration: BoxDecoration(
                  color: colors.surfaceSubtle,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  border: Border(bottom: BorderSide(color: colors.border)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${e.action} · ${e.entityType}',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: colors.inkPrimary),
                          ),
                          Text(
                            '${e.adminName} · ${e.createdDate}${e.ipAddress != null ? ' · IP ${e.ipAddress}' : ''}',
                            style: TextStyle(fontSize: 12, color: colors.inkMuted),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: Icon(Icons.close_rounded, color: colors.inkMuted),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.summary, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.inkPrimary)),
                      const SizedBox(height: 14),
                      LayoutBuilder(
                        builder: (_, box) {
                          final stacked = box.maxWidth < 520;
                          final beforeCard = _jsonPane(ctx, 'Before State', beforeJson, colors.danger);
                          final afterCard = _jsonPane(ctx, 'After State', afterJson, colors.success);
                          if (stacked) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [beforeCard, const SizedBox(height: 12), afterCard],
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: beforeCard),
                              const SizedBox(width: 12),
                              Expanded(child: afterCard),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                decoration: BoxDecoration(
                  color: colors.surfaceSubtle,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                  border: Border(top: BorderSide(color: colors.border)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AppButton.primary(text: 'Close', onPressed: () => Navigator.of(ctx).pop()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _jsonPane(BuildContext context, String label, String content, Color accent) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceSubtle,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: accent)),
          const SizedBox(height: 8),
          SelectableText(
            content,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              height: 1.45,
              color: colors.inkPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
