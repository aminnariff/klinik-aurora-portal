import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/asset/app_asset_controller.dart';
import 'package:klinik_aurora_portal/utils/image_helper.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';

/// Reusable multi-image field (e.g. for promotions):
/// allows pasting URLs or uploading files up to [maxImages].
class AppMultiImageField extends StatefulWidget {
  final List<String> images;
  final ValueChanged<List<String>> onChanged;
  final String? folder;
  final int maxImages;
  final String title;

  const AppMultiImageField({
    super.key,
    required this.images,
    required this.onChanged,
    this.folder = 'promotion',
    this.maxImages = 3,
    this.title = 'Images',
  });

  @override
  State<AppMultiImageField> createState() => _AppMultiImageFieldState();
}

class _AppMultiImageFieldState extends State<AppMultiImageField> {
  bool _uploading = false;
  final TextEditingController _urlInput = TextEditingController();
  bool _showUrlInput = false;

  static const _allowedExtensions = ['png', 'jpg', 'jpeg', 'webp', 'gif'];

  Future<void> _pickAndUpload() async {
    if (widget.images.length >= widget.maxImages) return;

    final files = await FilePicker.pickFiles();
    final file = files.firstOrNull;
    if (file == null) return;

    final extension = (file.extension ?? '').toLowerCase();
    if (!_allowedExtensions.contains(extension)) {
      if (mounted) {
        showDialogError(context, 'Please choose an image file (${_allowedExtensions.join(', ')}).');
      }
      return;
    }

    setState(() => _uploading = true);

    final Uint8List bytes = await file.readAsBytes();
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
      final updated = List<String>.from(widget.images)..add(response.data!);
      widget.onChanged(updated);
    } else {
      showDialogError(context, response.message ?? 'Unable to upload the image.');
    }
  }

  void _addUrl() {
    final text = _urlInput.text.trim();
    if (text.isEmpty) return;
    if (widget.images.length >= widget.maxImages) return;

    final updated = List<String>.from(widget.images)..add(text);
    widget.onChanged(updated);
    _urlInput.clear();
    setState(() => _showUrlInput = false);
  }

  void _removeImage(int index) {
    final removed = widget.images[index];
    final updated = List<String>.from(widget.images)..removeAt(index);
    widget.onChanged(updated);

    if (removed.contains('storage.googleapis.com') || removed.contains('firebasestorage.googleapis.com')) {
      AppAssetController.delete(removed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canAdd = widget.images.length < widget.maxImages;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${widget.title} (${widget.images.length}/${widget.maxImages})',
              style: AppTypography.bodyMedium(context).apply(fontWeightDelta: 2),
            ),
            if (canAdd && !_uploading)
              Row(
                children: [
                  TextButton.icon(
                    onPressed: _pickAndUpload,
                    icon: const Icon(Icons.upload_file_rounded, size: 16),
                    label: const Text('Upload File', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 4),
                  TextButton.icon(
                    onPressed: () {
                      setState(() => _showUrlInput = !_showUrlInput);
                    },
                    icon: Icon(_showUrlInput ? Icons.close : Icons.link_rounded, size: 16),
                    label: Text(_showUrlInput ? 'Cancel' : 'Paste URL', style: const TextStyle(fontSize: 12)),
                  ),
                ],
              ),
          ],
        ),
        if (_uploading) ...[
          const SizedBox(height: 8),
          const LinearProgressIndicator(),
        ],
        if (_showUrlInput && canAdd) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _urlInput,
                  decoration: const InputDecoration(
                    hintText: 'https://example.com/image.jpg',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _addUrl(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _addUrl,
                style: ElevatedButton.styleFrom(
                  backgroundColor: secondaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: const Text('Add'),
              ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        if (widget.images.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Text(
              'No images added yet. Click "Upload File" or "Paste URL" above.',
              style: AppTypography.bodyMedium(context).apply(color: textMutedColor, fontSizeDelta: -2),
            ),
          )
        else
          for (int i = 0; i < widget.images.length; i++) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      resolveImageUrl(widget.images[i]),
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 56,
                        height: 56,
                        color: const Color(0xFFF3F4F6),
                        child: const Icon(Icons.broken_image, size: 20, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Image ${i + 1}',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.images[i],
                          style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626), size: 20),
                    tooltip: 'Remove',
                    onPressed: () => _removeImage(i),
                  ),
                ],
              ),
            ),
          ],
      ],
    );
  }
}
