library pagination;

import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/color.dart';

class Pagination extends StatefulWidget {
  const Pagination(
      {super.key,

      /// Total number of pages
      required this.numOfPages,

      /// Current selected page
      required this.selectedPage,

      /// Number of pages visible in the widget between the previous and next buttons
      required this.pagesVisible,

      /// Callback function when a page is selected
      required this.onPageChanged,

      /// Icon for the previous button
      this.previousIcon,

      /// Icon for the next button
      this.nextIcon,

      /// Spacing between the individual page buttons
      this.spacing});

  final int numOfPages;
  final int selectedPage;
  final int pagesVisible;
  final Function onPageChanged;
  final Icon? previousIcon;
  final Icon? nextIcon;
  final double? spacing;

  @override
  State<Pagination> createState() => _PaginationState();
}

class _PaginationState extends State<Pagination> {
  late int _startPage;
  late int _endPage;

  @override
  void initState() {
    super.initState();
    _calculateVisiblePages();
  }

  @override
  void didUpdateWidget(Pagination oldWidget) {
    super.didUpdateWidget(oldWidget);
    _calculateVisiblePages();
  }

  void _calculateVisiblePages() {
    /// If the number of pages is less than or equal to the number of pages visible, then show all the pages
    if (widget.numOfPages <= widget.pagesVisible) {
      _startPage = 1;
      _endPage = widget.numOfPages;
    } else {
      /// If the number of pages is greater than the number of pages visible, then show the pages visible
      int middle = (widget.pagesVisible - 1) ~/ 2;
      if (widget.selectedPage <= middle + 1) {
        _startPage = 1;
        _endPage = widget.pagesVisible;
      } else if (widget.selectedPage >= widget.numOfPages - middle) {
        _startPage = widget.numOfPages - (widget.pagesVisible - 1);
        _endPage = widget.numOfPages;
      } else {
        _startPage = widget.selectedPage - middle;
        _endPage = widget.selectedPage + middle;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: widget.previousIcon ??
              Icon(
                Icons.arrow_circle_left_outlined,
                color: widget.selectedPage > 1 ? secondaryColor : Colors.grey,
                size: 35,
              ),
          onPressed: widget.selectedPage > 1 ? () => widget.onPageChanged(widget.selectedPage - 1) : null,
        ),
        SizedBox(
          width: widget.spacing ?? 0,
        ),
        for (int i = _startPage; i <= _endPage; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            child: TextButton(
              style: i == widget.selectedPage
                  ? ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(secondaryColor),
                      elevation: WidgetStateProperty.all(15),
                    )
                  : ButtonStyle(
                      elevation: WidgetStateProperty.all(0),
                    ),
              onPressed: () => widget.onPageChanged(i),
              child: Text(
                '$i',
                style: i == widget.selectedPage
                    ? const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      )
                    : const TextStyle(
                        fontSize: 14,
                        color: secondaryColor,
                        fontWeight: FontWeight.w700,
                      ),
              ),
            ),
          ),
        SizedBox(
          width: widget.spacing ?? 0,
        ),
        IconButton(
          icon: widget.nextIcon ??
              Icon(
                Icons.arrow_circle_right_outlined,
                color: widget.selectedPage < widget.numOfPages ? secondaryColor : Colors.grey,
                size: 35,
              ),
          onPressed:
              widget.selectedPage < widget.numOfPages ? () => widget.onPageChanged(widget.selectedPage + 1) : null,
        ),
      ],
    );
  }
}
