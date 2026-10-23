import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Emil Kowalski perceived-performance table skeleton:
/// Replaces solitary spinning wheels with layout-preserving bone placeholders.
/// Eliminates layout shift when network requests resolve.
class AppTableSkeleton extends StatelessWidget {
  final int rows;
  final double rowHeight;
  final EdgeInsets padding;

  const AppTableSkeleton({
    super.key,
    this.rows = 6,
    this.rowHeight = 48.0,
    this.padding = const EdgeInsets.all(16.0),
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFF1F5F9), // slate-100
      highlightColor: Colors.white,
      period: const Duration(milliseconds: 1400),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Table Header row
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  _headerBone(120),
                  const SizedBox(width: 24),
                  _headerBone(100),
                  const SizedBox(width: 24),
                  _headerBone(80),
                  const SizedBox(width: 24),
                  _headerBone(70),
                  const Spacer(),
                  _headerBone(60),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Rows
            Expanded(
              child: ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: rows,
                separatorBuilder: (_, _) => const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFF1F5F9),
                ),
                itemBuilder: (context, index) {
                  // Vary widths slightly so placeholder looks like realistic table rows
                  final nameWidth = 100.0 + (index % 3) * 20.0;
                  final serviceWidth = 85.0 + (index % 2) * 15.0;

                  return SizedBox(
                    height: rowHeight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          // Column 1: Patient Name & ref
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _bone(nameWidth, 13),
                              const SizedBox(height: 5),
                              _bone(65, 10),
                            ],
                          ),
                          const SizedBox(width: 32),
                          // Column 2: Service
                          _bone(serviceWidth, 13),
                          const SizedBox(width: 32),
                          // Column 3: Doctor / Branch
                          _bone(75, 13),
                          const SizedBox(width: 32),
                          // Column 4: Status pill placeholder
                          Container(
                            width: 76,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          const Spacer(),
                          // Column 5: Date / Actions
                          _bone(70, 13),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerBone(double width) {
    return Container(
      width: width,
      height: 12,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }

  Widget _bone(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
