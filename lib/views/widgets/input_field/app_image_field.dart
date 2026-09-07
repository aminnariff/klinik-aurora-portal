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
  late String _initialValue;

  static const _allowedExtensions = ['png', 'jpg', 'jpeg', 'webp', 'gif'];

  @override
  void initState() {
    super.initState();
    _initialValue = widget.field.controller.text.trim();
  }

  Future<void> _handleReplace() async {
    final hasValue = widget.field.controller.text.trim().isNotEmpty;
    if (hasValue) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 22),
              SizedBox(width: 10),
              Text('Replace Image?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
          content: const Text(
            'Uploading a new image will stage it for this record. Remember to click "Update" or "Create" at the bottom to save your changes to the database.',
            style: TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B7280))),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Choose File'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    await _pickAndUpload();
  }

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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 22),
            SizedBox(width: 10),
            Text('Remove Image?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
        content: const Text(
          'This will remove the image from this record. Click "Update" or "Create" at the bottom to save your changes to the database.',
          style: TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      widget.field.controller.clear();
      widget.onChanged?.call();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.field.controller.text.trim();
    final hasValue = value.isNotEmpty;
    final isModified = value != _initialValue;
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
                            onTap: _handleReplace,
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
        if (isModified) ...[
          Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFFD97706)),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Image modified — click Update/Create to apply changes.',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF92400E)),
                  ),
                ),
              ],
            ),
          ),
        ],
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
