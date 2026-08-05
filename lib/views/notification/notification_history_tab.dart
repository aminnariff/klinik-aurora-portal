import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/controllers/api_controller.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/models/notification/notification_history.dart';
import 'package:klinik_aurora_portal/views/widgets/button/button.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';

/// The injected [fetch] returns the backend future; the widget re-fetches on
/// init and on Refresh/Retry. This keeps the tab testable without a network.
class NotificationHistoryTab extends StatefulWidget {
  final Future<ApiResponse<NotificationHistoryResponse>> Function() fetch;

  const NotificationHistoryTab({super.key, required this.fetch});

  @override
  State<NotificationHistoryTab> createState() => _NotificationHistoryTabState();
}

class _NotificationHistoryTabState extends State<NotificationHistoryTab> {
  late Future<ApiResponse<NotificationHistoryResponse>> _future = widget.fetch();

  void _refresh() {
    setState(() {
      _future = widget.fetch();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Previously sent', style: AppTypography.bodyMedium(context).apply(fontWeightDelta: 3)),
            IconButton(
              tooltip: 'Refresh',
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded, color: secondaryColor),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: FutureBuilder<ApiResponse<NotificationHistoryResponse>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: secondaryColor));
              }
              if (snapshot.hasError || !responseCode(snapshot.data?.code)) {
                return _ErrorState(onRetry: _refresh);
              }
              final items = snapshot.data?.data?.items ?? const <NotificationHistoryItem>[];
              if (items.isEmpty) {
                return const Center(child: Text('No announcements sent yet.'));
              }
              return ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFE5E7EB)),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.title ?? 'Untitled',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodyMedium(context).apply(fontWeightDelta: 3),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatDate(item.createdDate),
                              style: AppTypography.bodyMedium(
                                context,
                              ).apply(color: const Color(0xFF9CA3AF), fontSizeDelta: -3),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.description ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMedium(
                            context,
                          ).apply(color: const Color(0xFF6B7280), fontSizeDelta: -1),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatDate(String? createdDate) {
    if (createdDate == null || createdDate.isEmpty) return '';
    try {
      return DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(createdDate).toLocal());
    } catch (_) {
      return createdDate;
    }
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, color: Color(0xFF9CA3AF), size: 40),
          const SizedBox(height: 8),
          Text('Unable to load announcements.', style: AppTypography.bodyMedium(context)),
          const SizedBox(height: 12),
          Button(onRetry, actionText: 'Retry', color: secondaryColor),
        ],
      ),
    );
  }
}
