import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';

class NotificationChannelStep extends StatelessWidget {
  final List<DropdownAttribute> channels;
  final DropdownAttribute? selected;
  final ValueChanged<DropdownAttribute> onSelected;

  const NotificationChannelStep({super.key, required this.channels, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final channel in channels) ...[
          _ChannelCard(channel: channel, isSelected: selected?.key == channel.key, onTap: () => onSelected(channel)),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 4),
        Text(
          'Subscribers receive this as a push notification on their phone.',
          style: AppTypography.bodyMedium(context).apply(color: const Color(0xFF9CA3AF), fontSizeDelta: -2),
        ),
      ],
    );
  }
}

class _ChannelCard extends StatelessWidget {
  final DropdownAttribute channel;
  final bool isSelected;
  final VoidCallback onTap;

  const _ChannelCard({required this.channel, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Semantics(
        selected: isSelected,
        button: true,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEFFAFC) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isSelected ? secondaryColor : const Color(0xFFE5E7EB), width: isSelected ? 2 : 1),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: primaryColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  channel.key == 'general' ? Icons.group_rounded : Icons.person_pin_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(channel.name, style: AppTypography.bodyMedium(context).apply(fontWeightDelta: 3)),
                    const SizedBox(height: 2),
                    Text(
                      channel.key == 'general' ? 'Everyone who has the app installed' : 'Users who are signed in',
                      style: AppTypography.bodyMedium(context).apply(color: const Color(0xFF6B7280), fontSizeDelta: -1),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 22,
                child: isSelected
                    ? const ExcludeSemantics(child: Icon(Icons.check_circle_rounded, color: secondaryColor, size: 22))
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
