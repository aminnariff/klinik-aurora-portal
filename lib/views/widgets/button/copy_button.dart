import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CopyButton extends StatelessWidget {
  final String textToCopy;
  final Color? iconColor;
  final String? tooltip;

  const CopyButton({super.key, required this.textToCopy, this.iconColor, this.tooltip});

  void _copyToClipboard(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: textToCopy));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Copied to clipboard')));
  }

  @override
  Widget build(BuildContext context) {
    final button = IconButton(
      icon: Icon(Icons.copy, color: iconColor ?? Theme.of(context).iconTheme.color),
      onPressed: () => _copyToClipboard(context),
      tooltip: tooltip ?? 'Copy',
    );

    return button;
  }
}
