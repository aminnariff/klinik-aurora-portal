import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/notification/notification_controller.dart';
import 'package:klinik_aurora_portal/models/notification/scheduled_notification.dart';
import 'package:klinik_aurora_portal/views/notification/notification_schedule_editor.dart';
import 'package:klinik_aurora_portal/views/widgets/button/button.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';

/// The queue of notifications waiting on the backend cron, plus what it has
/// already sent or failed to send.
class NotificationScheduledTab extends StatefulWidget {
  const NotificationScheduledTab({super.key});

  @override
  State<NotificationScheduledTab> createState() => _NotificationScheduledTabState();
}

class _NotificationScheduledTabState extends State<NotificationScheduledTab> {
  List<ScheduledNotification> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final value = await NotificationController.fetchScheduled(context);
    if (!mounted) return;

    setState(() {
      _loading = false;
      if (responseCode(value.code)) {
        _items = value.data ?? [];
      } else {
        _error = value.message ?? 'Unable to load the schedule.';
      }
    });
  }

  Future<void> _edit(ScheduledNotification item) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => NotificationScheduleEditor(notification: item),
    );
    if (saved == true) _load();
  }

  Future<void> _cancel(ScheduledNotification item) async {
    final confirmed = await showConfirmDialog(context, 'Cancel "${item.title}"? It will not be sent.');
    if (!confirmed || !mounted) return;

    final value = await NotificationController.cancelScheduled(context, item.id);
    if (!mounted) return;

    if (responseCode(value.code)) {
      _load();
    } else {
      showDialogError(context, value.message ?? 'Unable to cancel this notification.');
    }
  }

  Future<void> _delete(ScheduledNotification item) async {
    final confirmed = await showConfirmDialog(context, 'Remove "${item.title}" from the list?');
    if (!confirmed || !mounted) return;

    final value = await NotificationController.deleteScheduled(context, item.id);
    if (!mounted) return;

    if (responseCode(value.code)) {
      _load();
    } else {
      showDialogError(context, value.message ?? 'Unable to remove this notification.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFF9CA3AF)),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center, style: AppTypography.bodyMedium(context)),
            const SizedBox(height: 16),
            Button(_load, actionText: 'Retry', color: secondaryColor),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.schedule_rounded, size: 48, color: secondaryColor.withAlpha(100)),
            const SizedBox(height: 12),
            Text('Nothing scheduled', style: AppTypography.bodyLarge(context)),
            const SizedBox(height: 6),
            Text(
              'Compose an announcement and choose "Schedule for later".',
              style: AppTypography.bodyMedium(context).apply(color: textMutedColor),
            ),
          ],
        ),
      );
    }

    final overdue = _items.where((item) => item.isOverdue).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (overdue > 0) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFB45309)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$overdue notification${overdue == 1 ? '' : 's'} passed the send time but '
                    'have not gone out. The scheduler job may not be running.',
                    style: AppTypography.bodyMedium(
                      context,
                    ).apply(color: const Color(0xFF92400E), fontSizeDelta: -2),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Refresh'),
            ),
          ],
        ),
        Expanded(
          child: ListView.separated(
            itemCount: _items.length,
            separatorBuilder: (_, _) => const Divider(height: 20, color: Color(0xFFE5E7EB)),
            itemBuilder: (context, index) => _ScheduledRow(
              item: _items[index],
              onEdit: () => _edit(_items[index]),
              onCancel: () => _cancel(_items[index]),
              onDelete: () => _delete(_items[index]),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScheduledRow extends StatelessWidget {
  final ScheduledNotification item;
  final VoidCallback onEdit;
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  const _ScheduledRow({
    required this.item,
    required this.onEdit,
    required this.onCancel,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      item.title,
                      style: AppTypography.bodyMedium(context).apply(fontWeightDelta: 3),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusChip(item: item),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                item.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMedium(context).apply(color: textMutedColor, fontSizeDelta: -1),
              ),
              const SizedBox(height: 6),
              Text(
                '${_channelName(item.topic)} • ${item.isSent ? 'Sent ${_format(item.sentAt)}' : _format(item.triggerDateTime)}',
                style: AppTypography.bodyMedium(context).apply(color: textMutedColor, fontSizeDelta: -2),
              ),
              if (item.isFailed && item.lastError != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Failed after ${item.attempts} attempt${item.attempts == 1 ? '' : 's'}: ${item.lastError}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium(
                    context,
                  ).apply(color: const Color(0xFF991B1B), fontSizeDelta: -2),
                ),
              ],
            ],
          ),
        ),
        // Sent rows offer nothing: the API refuses both edit and delete on them
        // so the record of what recipients actually got stays intact.
        if (item.isPending) ...[
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            color: secondaryColor,
            tooltip: 'Edit',
            onPressed: onEdit,
          ),
          TextButton(onPressed: onCancel, child: const Text('Cancel')),
        ] else if (!item.isSent)
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
            color: const Color(0xFF9CA3AF),
            tooltip: 'Remove',
            onPressed: onDelete,
          ),
      ],
    );
  }

  static String _channelName(String topic) {
    for (final channel in notificationChannel) {
      if (channel.key == topic) return channel.name;
    }
    return topic;
  }

  static String _format(DateTime? value) {
    if (value == null) return '—';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(value.day)}/${two(value.month)}/${value.year} at ${two(value.hour)}:${two(value.minute)}';
  }
}

class _StatusChip extends StatelessWidget {
  final ScheduledNotification item;

  const _StatusChip({required this.item});

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color color;

    switch (item.status) {
      case 'SENT':
        label = 'Sent';
        color = const Color(0xFF16A34A);
      case 'FAILED':
        label = 'Failed';
        color = const Color(0xFFDC2626);
      case 'CANCELLED':
        label = 'Cancelled';
        color = const Color(0xFF9CA3AF);
      case 'SENDING':
        label = 'Sending';
        color = const Color(0xFF2563EB);
      default:
        label = item.isOverdue ? 'Overdue' : 'Pending';
        color = item.isOverdue ? const Color(0xFFB45309) : const Color(0xFF2563EB);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withAlpha(28), borderRadius: BorderRadius.circular(20)),
      child: Text(
        label,
        style: AppTypography.bodyMedium(context).apply(color: color, fontSizeDelta: -3, fontWeightDelta: 2),
      ),
    );
  }
}
