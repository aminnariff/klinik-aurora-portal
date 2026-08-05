import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';

/// Phone-style mockup of the push notification a subscriber will receive.
class NotificationPreview extends StatelessWidget {
  final String title;
  final String body;
  final double width;

  const NotificationPreview({super.key, required this.title, required this.body, this.width = 240});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 20,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(color: tertiaryColor, borderRadius: BorderRadius.circular(10)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('9:41', style: AppTypography.bodyMedium(context).apply(color: Colors.white, fontSizeDelta: -6)),
                const Icon(Icons.battery_full, color: Colors.white, size: 12),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  clipBehavior: Clip.antiAlias,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: primaryColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    'assets/icons/logo/klinik-aurora.png',
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'Klinik Aurora',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodyMedium(context).apply(fontWeightDelta: 2, fontSizeDelta: -1),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'now',
                            style: AppTypography.bodyMedium(
                              context,
                            ).apply(color: const Color(0xFF9CA3AF), fontSizeDelta: -3),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title.isEmpty ? 'Notification title' : title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMedium(context).apply(fontWeightDelta: 3),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        body.isEmpty ? 'Notification content preview' : body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMedium(
                          context,
                        ).apply(color: const Color(0xFF6B7280), fontSizeDelta: -1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
