import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/campaign/campaign_asset_controller.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';

/// An image slot in the campaign editor: paste a URL, or upload a file.
///
/// Both paths write to the same controller, so the stored `theme_config` shape
/// is identical either way — an uploaded image is just a URL that happens to
/// point at our own bucket. Pasting a CDN link keeps working for anyone who
/// prefers it.
class CampaignImageField extends StatefulWidget {
  final InputFieldAttribute field;

  /// Notifies the parent so the live preview and validation refresh.
  final VoidCallback onChanged;

  const CampaignImageField({super.key, required this.field, required this.onChanged});

  @override
  State<CampaignImageField> createState() => _CampaignImageFieldState();
}

class _CampaignImageFieldState extends State<CampaignImageField> {
  bool _uploading = false;

  static const _allowedExtensions = ['png', 'jpg', 'jpeg', 'webp', 'gif'];

  Future<void> _pickAndUpload() async {
    // Deliberately bare `pickFiles()`, matching the branch/promotion uploads.
    //
    // The tidier-looking `pickFile()` hardcodes `withData: false` internally,
    // which leaves `bytes` null on web and forces `readAsBytes()` to fetch the
    // blob: URL instead — that fetch fails here. With no arguments, `withData`
    // defaults to `kIsWeb`, so the bytes are already in hand on the portal.
    final result = await FilePicker.pickFiles();
    final file = result?.files.firstOrNull;
    if (file == null) return;

    // Extension is checked after picking rather than via FileType.custom, again
    // matching the existing uploads — the custom filter behaves inconsistently
    // across platforms.
    final extension = (file.extension ?? '').toLowerCase();
    if (!_allowedExtensions.contains(extension)) {
      if (mounted) {
        showDialogError(context, 'Please choose an image file (${_allowedExtensions.join(', ')}).');
      }
      return;
    }

    setState(() => _uploading = true);

    final Uint8List bytes;
    try {
      bytes = await file.readAsBytes();
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploading = false);
      showDialogError(context, 'Could not read that file: $e');
      return;
    }

    // Mirrors the server's own 5 MB multer limit, so an oversized file is
    // rejected before spending time uploading it.
    if (bytes.lengthInBytes > 5 * 1024 * 1024) {
      if (!mounted) return;
      setState(() => _uploading = false);
      showDialogError(context, 'That image is larger than 5 MB. Please compress it and try again.');
      return;
    }

    // The current value becomes previousUrl so the server can clean up the
    // image being replaced instead of leaving it orphaned in the bucket.
    final response = await CampaignAssetController.upload(
      bytes: bytes,
      filename: file.name,
      previousUrl: widget.field.controller.text,
    );

    if (!mounted) return;
    setState(() => _uploading = false);

    if (responseCode(response.code) && response.data != null) {
      widget.field.controller.text = response.data!;
      widget.onChanged();
    } else {
      showDialogError(context, response.message ?? 'Unable to upload the image.');
    }
  }

  Future<void> _clear() async {
    final current = widget.field.controller.text.trim();
    widget.field.controller.clear();
    widget.onChanged();

    // Fire-and-forget: the field is already cleared in the UI, and a failed
    // bucket cleanup should not block the admin or surface as an error.
    if (current.isNotEmpty) {
      CampaignAssetController.delete(current);
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.field.controller.text.trim();
    final hasValue = value.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: InputField(field: widget.field..onChanged = (_) => widget.onChanged())),
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
                  value,
                  height: 64,
                  width: 110,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    height: 64,
                    width: 110,
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
                child: Text(
                  value.contains('/campaign-assets/')
                      ? 'Stored in Firebase Storage. Replacing or removing it deletes the old file.'
                      : 'External link. Hosting and availability are managed outside this portal.',
                  style: AppTypography.bodyMedium(context).apply(color: textMutedColor, fontSizeDelta: -3),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
