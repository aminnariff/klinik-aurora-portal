import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';
import 'package:url_launcher/url_launcher.dart';

void showWhatsAppTemplateDialog({
  required BuildContext context,
  required String name,
  required String phone,
  required String service,
  required String branchName,
  required DateTime dateTime,
}) {
  final gmt8DateTime = dateTime.add(const Duration(hours: 8));

  final String formattedDate = DateFormat('dd MMM yyyy').format(gmt8DateTime);
  final String formattedTime = DateFormat('h:mm a').format(gmt8DateTime);

  final List<String> templates = [
    "Hi $name, this is a reminder about your *$service* appointment at $branchName on *$formattedDate* at *$formattedTime*.",
    "Hello $name, your *$service* is confirmed for *$formattedDate* at *$formattedTime*. See you at $branchName!",
    "Hi $name, thank you for booking *$service*. Your appointment is on *$formattedDate* at *$formattedTime* at $branchName.",
  ];

  String? customMessage;

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        surfaceTintColor: Colors.white,
        backgroundColor: Colors.white,
        title: Text('Send WhatsApp Message'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (String template in templates)
                ListTile(
                  title: Text(template, style: AppTypography.bodyMedium(context)),
                  onTap: () => _launchWhatsApp(phone, template),
                ),
              const Divider(),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Custom Message',
                  labelStyle: AppTypography.bodyMedium(context).apply(color: Colors.grey.shade600),
                  border: OutlineInputBorder(),
                ),
                cursorColor: primary,
                style: AppTypography.bodyMedium(context).apply(),
                maxLines: 3,
                onChanged: (val) {
                  customMessage = val;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (customMessage != null && customMessage!.trim().isNotEmpty) {
                _launchWhatsApp(phone, customMessage!);
              } else {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Send Custom'),
          ),
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ],
      );
    },
  );
}

void _launchWhatsApp(String phone, String message) async {
  final encodedMessage = Uri.encodeComponent(message);
  final url = "https://api.whatsapp.com/send?phone=6$phone?text=$encodedMessage&app_absent=1";

  if (await canLaunchUrl(Uri.parse(url))) {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } else {
    debugPrint('Could not launch WhatsApp');
  }
}
