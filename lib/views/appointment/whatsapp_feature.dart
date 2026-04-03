import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';
import 'package:url_launcher/url_launcher.dart';

void showWhatsAppTemplateDialog({
  required BuildContext context,
  required List<String> templates,
  required String name,
  required String phone,
  required String service,
  required String branchName,
  required String branchPhone,
  required DateTime dateTime,
}) {
  final gmt8DateTime = dateTime.add(const Duration(hours: 8));

  final String formattedDate = DateFormat('dd MMM yyyy').format(gmt8DateTime);
  final String formattedTime = DateFormat('h:mm a').format(gmt8DateTime);

  final values = {
    "name": name,
    "service": service,
    "branchName": branchName,
    "branchPhone": branchPhone,
    "formattedDate": formattedDate,
    "formattedTime": formattedTime,
  };

  templates = templates.map((t) => renderTemplate(t, values)).toList();

  final TextEditingController customController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        surfaceTintColor: Colors.white,
        backgroundColor: Colors.white,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 600, maxHeight: MediaQuery.of(context).size.height * 0.85),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.green.withOpacity(0.15), shape: BoxShape.circle),
                      child: const Icon(Icons.chat_rounded, color: Colors.green, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Send WhatsApp Message',
                            style: AppTypography.bodyMedium(
                              context,
                            ).copyWith(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'To: $name ($phone)',
                            style: AppTypography.bodyMedium(context).apply(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Suggested Templates',
                          style: AppTypography.bodyMedium(
                            context,
                          ).copyWith(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
                        ),
                        const SizedBox(height: 12),
                        if (templates.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(
                                'No templates available.',
                                style: AppTypography.bodyMedium(context).apply(color: Colors.grey.shade500),
                              ),
                            ),
                          )
                        else
                          ...templates.map(
                            (template) => Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _launchWhatsApp(phone, template),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Ink(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey.shade200),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            template,
                                            style: AppTypography.bodyMedium(context).copyWith(height: 1.4),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: primary.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(Icons.send_rounded, color: primary, size: 20),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                        const SizedBox(height: 24),
                        Text(
                          'Or write a custom message',
                          style: AppTypography.bodyMedium(
                            context,
                          ).copyWith(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: customController,
                          decoration: InputDecoration(
                            hintText: 'Type your message here...',
                            hintStyle: AppTypography.bodyMedium(context).apply(color: Colors.grey.shade400),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: primary, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          cursorColor: primary,
                          style: AppTypography.bodyMedium(context).apply(),
                          maxLines: 4,
                          minLines: 3,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.info_outline_rounded, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 6),
                            Text(
                              'Tap a tag to insert into your custom message',
                              style: AppTypography.bodyMedium(
                                context,
                              ).copyWith(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final entry in values.entries)
                              ActionChip(
                                label: Text(
                                  '{{${entry.key}}}',
                                  style: AppTypography.bodyMedium(
                                    context,
                                  ).copyWith(fontSize: 12, color: primary, fontWeight: FontWeight.w600),
                                ),
                                onPressed: () {
                                  final currentText = customController.text;
                                  final textToInsert = (currentText.isNotEmpty && !currentText.endsWith(' '))
                                      ? ' ${entry.value}'
                                      : entry.value;
                                  final newText = currentText + textToInsert;
                                  customController.value = TextEditingValue(
                                    text: newText,
                                    selection: TextSelection.collapsed(offset: newText.length),
                                  );
                                },
                                backgroundColor: primary.withOpacity(0.1),
                                side: const BorderSide(color: Colors.transparent),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (customController.text.trim().isNotEmpty) {
                                _launchWhatsApp(phone, customController.text);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.send, size: 18),
                            label: const Text('Send Custom Message', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

String renderTemplate(String template, Map<String, String> values) {
  return template.replaceAllMapped(RegExp(r'\{\{(\w+)\}\}'), (match) {
    final key = match.group(1); // gets the placeholder name like 'name'
    return values[key] ?? match.group(0)!; // fallback to the original {{key}} if missing
  });
}

void _launchWhatsApp(String phone, String message) async {
  final encodedMessage = Uri.encodeComponent(message);
  final url = 'https://web.whatsapp.com/send?phone=6$phone&text=$encodedMessage';

  if (await canLaunchUrl(Uri.parse(url))) {
    await launchUrl(Uri.parse(url), mode: LaunchMode.inAppWebView);
  } else {
    debugPrint('Could not launch WhatsApp Web');
  }
}
