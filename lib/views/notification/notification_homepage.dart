import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/notification/notification_controller.dart';
import 'package:klinik_aurora_portal/views/notification/notification_channel_step.dart';
import 'package:klinik_aurora_portal/views/notification/notification_compose_step.dart';
import 'package:klinik_aurora_portal/views/notification/notification_history_tab.dart';
import 'package:klinik_aurora_portal/views/notification/notification_review_step.dart';
import 'package:klinik_aurora_portal/views/widgets/button/button.dart';
import 'package:klinik_aurora_portal/views/widgets/card/card_container.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';

class NotificationHomepage extends StatefulWidget {
  const NotificationHomepage({super.key});

  @override
  State<NotificationHomepage> createState() => _NotificationHomepageState();
}

class _NotificationHomepageState extends State<NotificationHomepage> {
  int _step = 1;
  bool _showHistory = false;
  bool _sending = false;
  DropdownAttribute? _channel;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      _titleController.text = 'Exciting Updates Coming Soon!';
      _contentController.text =
          'We will be launching new updates soon. Stay tuned for a better and smoother experience with Klinik Aurora.';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  bool get _canProceed {
    if (_step == 1) return _channel != null;
    if (_step == 2) return _titleController.text.trim().isNotEmpty;
    return true;
  }

  void _next() {
    setState(() => _step += 1);
  }

  void _resetWizard() {
    setState(() {
      _step = 1;
      _channel = null;
      _titleController.clear();
      _contentController.clear();
    });
  }

  Future<void> _send() async {
    final channel = _channel;
    if (channel == null) return;

    setState(() => _sending = true);
    final confirmed = await showConfirmDialog(
      context,
      'Are you sure you want to send this notification to ${channel.name}? This action cannot be undone.',
    );
    if (!confirmed) {
      if (mounted) setState(() => _sending = false);
      return;
    }

    if (!mounted) return;

    final value = await NotificationController.send(
      context,
      topic: channel.key,
      title: _titleController.text.trim(),
      body: _contentController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _sending = false);

    if (responseCode(value.code)) {
      showDialogSuccess(
        context,
        'Notification successfully sent to ${channel.name}. They should receive it within a few minutes.',
      );
      _resetWizard();
    } else {
      final message = value.message ?? '';
      showDialogError(
        context,
        message.isNotEmpty && message != 'An Error Occurred.'
            ? message
            : 'Unable to send the notification at the moment. Please try again later. If the issue persists, contact the app developer.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxDialogWidth = math.min(760.0, MediaQuery.of(context).size.width * 0.92);
    final minDialogWidth = math.min(560.0, maxDialogWidth);

    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: maxDialogWidth,
          minWidth: minDialogWidth,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: CardContainer(
          Padding(
            padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Announcement Center', style: AppTypography.displayMedium(context)),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      color: const Color(0xFF637381),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _SegmentedControl(
                  selected: _showHistory ? 1 : 0,
                  onChanged: (index) => setState(() => _showHistory = index == 1),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _showHistory
                      ? NotificationHistoryTab(fetch: () => NotificationController.fetchHistory(context))
                      : _buildWizard(context),
                ),
                if (!_showHistory) ...[const SizedBox(height: 16), _buildFooter()],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWizard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepIndicator(current: _step),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: switch (_step) {
                1 => NotificationChannelStep(
                  key: const ValueKey('step-1'),
                  channels: notificationChannel,
                  selected: _channel,
                  onSelected: (channel) => setState(() => _channel = channel),
                ),
                2 => NotificationComposeStep(
                  key: const ValueKey('step-2'),
                  titleController: _titleController,
                  contentController: _contentController,
                  onChanged: () => setState(() {}),
                ),
                _ => NotificationReviewStep(
                  key: const ValueKey('step-3'),
                  channel: _channel ?? notificationChannel.first,
                  title: _titleController.text,
                  body: _contentController.text,
                ),
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_step > 1)
          TextButton(onPressed: _sending ? null : () => setState(() => _step -= 1), child: const Text('Back'))
        else
          const SizedBox.shrink(),
        if (_step < 3)
          Button(_canProceed && !_sending ? _next : null, actionText: 'Next', color: secondaryColor)
        else
          Button(
            _sending ? null : _send,
            actionText: _sending ? 'Sending…' : 'Send Announcement',
            color: secondaryColor,
          ),
      ],
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int current;

  const _StepIndicator({required this.current});

  @override
  Widget build(BuildContext context) {
    const steps = ['Channel', 'Compose', 'Review'];
    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0) ...[
            const SizedBox(width: 8),
            Container(width: 24, height: 1, color: const Color(0xFFE5E7EB)),
            const SizedBox(width: 8),
          ],
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i + 1 <= current ? secondaryColor : const Color(0xFFE5E7EB),
                ),
                alignment: Alignment.center,
                child: i + 1 < current
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : Text(
                        '${i + 1}',
                        style: AppTypography.bodyMedium(
                          context,
                        ).apply(color: i + 1 <= current ? Colors.white : const Color(0xFF9CA3AF), fontSizeDelta: -3),
                      ),
              ),
              const SizedBox(width: 6),
              Text(
                steps[i],
                style: AppTypography.bodyMedium(context).apply(
                  color: i + 1 <= current ? textPrimaryColor : const Color(0xFF9CA3AF),
                  fontWeightDelta: i + 1 == current ? 3 : 0,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _SegmentedControl extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const _SegmentedControl({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Segment(label: 'Compose', isSelected: selected == 0, onTap: () => onChanged(0)),
          const SizedBox(width: 4),
          _Segment(label: 'History', isSelected: selected == 1, onTap: () => onChanged(1)),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _Segment({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: isSelected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected ? [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 4)] : null,
          ),
          child: Text(
            label,
            style: AppTypography.bodyMedium(context).apply(
              color: isSelected ? textPrimaryColor : const Color(0xFF637381),
              fontWeightDelta: isSelected ? 3 : 0,
            ),
          ),
        ),
      ),
    );
  }
}
