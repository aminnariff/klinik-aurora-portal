import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';

class SearchToggle extends StatefulWidget {
  final String? hintText;
  final Function(String value) action;
  const SearchToggle({super.key, this.hintText, required this.action});

  @override
  State<SearchToggle> createState() => _SearchToggleState();
}

class _SearchToggleState extends State<SearchToggle> {
  bool _showTextField = false;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _controller.text.isEmpty) {
        setState(() => _showTextField = false);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleTapOutside() {
    if (_showTextField && !_focusNode.hasFocus) {
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _handleTapOutside,
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.search, color: CupertinoColors.activeBlue),
            onPressed: () {
              setState(() {
                _showTextField = true;
              });
              Future.delayed(Duration(milliseconds: 100), () {
                _focusNode.requestFocus();
              });
            },
          ),
          if (_showTextField || _controller.text.isNotEmpty)
            SizedBox(
              width: 150,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                cursorColor: primary,
                style: AppTypography.bodyMedium(context),
                decoration: InputDecoration(
                  hintText: widget.hintText ?? "Type to search...",
                  hintStyle: AppTypography.bodyMedium(context).apply(color: Colors.grey),
                  border: InputBorder.none,
                ),
                onEditingComplete: widget.action(_controller.text),
              ),
            ),
        ],
      ),
    );
  }
}
