import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/asset/app_asset_controller.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

class AppAttachmentField extends StatefulWidget {
  final TextEditingController controller;
  final String? folder;
  final VoidCallback? onChanged;

  const AppAttachmentField({
    super.key,
    required this.controller,
    this.folder = 'appointment',
    this.onChanged,
  });

  @override
  State<AppAttachmentField> createState() => _AppAttachmentFieldState();
}

class _AppAttachmentFieldState extends State<AppAttachmentField> {
  bool _uploading = false;
  static const _allowedExtensions = ['png', 'jpg', 'jpeg', 'webp', 'gif', 'pdf'];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  bool _isImage(String url) {
    final lower = url.toLowerCase();
    return lower.contains('.png') ||
        lower.contains('.jpg') ||
        lower.contains('.jpeg') ||
        lower.contains('.webp') ||
        lower.contains('.gif');
  }

  Future<void> _pickAndUpload() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: _allowedExtensions,
    );
    final file = files.firstOrNull;
    if (file == null) return;

    final ext = (file.extension ?? '').toLowerCase();
    if (!_allowedExtensions.contains(ext)) {
      if (mounted) {
        showDialogError(context, 'Please choose an image or PDF file (${_allowedExtensions.join(', ')}).');
      }
      return;
    }

    setState(() => _uploading = true);

    final Uint8List bytes = await file.readAsBytes();
    if (bytes.lengthInBytes > 10 * 1024 * 1024) {
      if (!mounted) return;
      setState(() => _uploading = false);
      showDialogError(context, 'File exceeds 10 MB limit.');
      return;
    }

    final response = await AppAssetController.upload(
      bytes: bytes,
      filename: file.name,
      folder: widget.folder,
    );

    if (!mounted) return;
    setState(() => _uploading = false);

    if (responseCode(response.code) && response.data != null) {
      widget.controller.text = response.data!;
      widget.onChanged?.call();
    } else {
      showDialogError(context, response.message ?? 'Unable to upload attachment.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.controller.text.trim();
    final hasUrl = url.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: widget.controller,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Attachment URL (optional)',
                  labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  hintText: 'Paste URL or click Upload button',
                  hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFD1D5DB)),
                  prefixIcon: const Icon(Icons.link_rounded, size: 16, color: Color(0xFF6B7280)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFD1D5DB))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFD1D5DB))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF6366F1))),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _uploading
                ? const SizedBox(width: 42, height: 42, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
                : ElevatedButton.icon(
                    onPressed: _pickAndUpload,
                    icon: const Icon(Icons.upload_file_rounded, size: 16),
                    label: Text(hasUrl ? 'Replace' : 'Upload', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: secondaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
            if (hasUrl) ...[
              const SizedBox(width: 6),
              IconButton(
                onPressed: () {
                  widget.controller.clear();
                  widget.onChanged?.call();
                },
                tooltip: 'Clear attachment',
                icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
              ),
            ],
          ],
        ),
        if (hasUrl) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Icon(
                  _isImage(url) ? Icons.image_rounded : Icons.picture_as_pdf_rounded,
                  size: 20,
                  color: _isImage(url) ? Colors.blue.shade600 : Colors.red.shade600,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    url,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {
                    final uri = Uri.tryParse(url);
                    if (uri != null) {
                      launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.open_in_new_rounded, size: 14),
                  label: const Text('View', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
