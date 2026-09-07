import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/asset/app_asset_controller.dart';
import 'package:klinik_aurora_portal/utils/image_helper.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';

/// Reusable image field: allows pasting an image URL or uploading a file to Firebase Storage.
class AppImageField extends StatefulWidget {
  final InputFieldAttribute field;
  final String? folder;
  final VoidCallback? onChanged;
  final double previewHeight;
  final double previewWidth;

  const AppImageField({
    super.key,
    required this.field,
    this.folder,
    this.onChanged,
    this.previewHeight = 64,
    this.previewWidth = 110,
  });

  @override
  State<AppImageField> createState() => _AppImageFieldState();
}

class _AppImageFieldState extends State<AppImageField> {
  bool _uploading = false;

  static const _allowedExtensions = ['png', 'jpg', 'jpeg', 'webp', 'gif'];

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles();
    final file = result?.files.firstOrNull;
    if (file == null || file.bytes == null) return;

    final extension = (file.extension ?? '').toLowerCase();
    if (!_allowedExtensions.contains(extension)) {
      if (mounted) {
        showDialogError(context, 'Please choose an image file (${_allowedExtensions.join(', ')}).');
      }
      return;
    }

    setState(() => _uploading = true);

    final Uint8List bytes = file.bytes!;
    if (bytes.lengthInBytes > 5 * 1024 * 1024) {
      if (!mounted) return;
      setState(() => _uploading = false);
      showDialogError(context, 'Image exceeds 5 MB. Please compress it and try again.');
      return;
    }

    final response = await AppAssetController.upload(
      bytes: bytes,
      filename: file.name,
      previousUrl: widget.field.controller.text,
      folder: widget.folder,
    );

    if (!mounted) return;
    setState(() => _uploading = false);

    if (responseCode(response.code) && response.data != null) {
      widget.field.controller.text = response.data!;
      widget.onChanged?.call();
    } else {
      showDialogError(context, response.message ?? 'Unable to upload the image.');
    }
  }

  Future<void> _clear() async {
    final current = widget.field.controller.text.trim();
    widget.field.controller.clear();
    widget.onChanged?.call();
    setState(() {});

    if (current.isNotEmpty && (current.contains('storage.googleapis.com') || current.contains('firebasestorage.googleapis.com'))) {
      AppAssetController.delete(current);
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.field.controller.text.trim();
    final hasValue = value.isNotEmpty;
    final resolvedUrl = resolveImageUrl(value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: InputField(
                field: widget.field
                  ..onChanged = (_) {
                    widget.onChanged?.call();
                    setState(() {});
                  },
              ),
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: _uploading
                  ? const SizedBox(
                      width: 48,
                      height: 48,
                      child: Center(
                        child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                    )
                  : Row(
                      children: [
                        Tooltip(
                          message: hasValue ? 'Replace image' : 'Upload image',
                          child: InkWell(
                            onTap: _pickAndUpload,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: secondaryColor.withAlpha(35),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                              ),
                              child: Icon(
                                hasValue ? Icons.autorenew_rounded : Icons.upload_rounded,
                                size: 20,
                                color: secondaryColor,
                              ),
                            ),
                          ),
                        ),
                        if (hasValue) ...[
                          const SizedBox(width: 6),
                          Tooltip(
                            message: 'Remove image',
                            child: InkWell(
                              onTap: _clear,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFE5E7EB)),
                                ),
                                child: const Icon(Icons.delete_outline_rounded, size: 20, color: Color(0xFFD32F2F)),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
        if (hasValue) ...[
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  resolvedUrl,
                  height: widget.previewHeight,
                  width: widget.previewWidth,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    height: widget.previewHeight,
                    width: widget.previewWidth,
                    color: const Color(0xFFF1F5F9),
                    alignment: Alignment.center,
                    child: Text(
                      'Unreachable',
                      style: AppTypography.bodyMedium(context).apply(color: textMutedColor, fontSizeDelta: -3),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value.contains('storage.googleapis.com') || value.contains('firebasestorage.googleapis.com')
                          ? 'Stored in Firebase Storage.'
                          : (value.startsWith('http://') || value.startsWith('https://'))
                              ? 'External link.'
                              : 'Stored on local server.',
                      style: AppTypography.bodyMedium(context).apply(color: textMutedColor, fontSizeDelta: -3),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
