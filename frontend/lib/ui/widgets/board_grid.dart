import 'dart:math';

import 'package:flutter/material.dart';

/// Grid papan yang MENGISI seluruh area tersedia tanpa scroll: rasio
/// sel dihitung dari ukuran layar, sehingga papan memanfaatkan layar
/// penuh baik portrait maupun landscape (penting di iPad — target tap
/// sebesar mungkin).
class BoardGridLayout extends StatelessWidget {
  const BoardGridLayout({
    super.key,
    required this.rows,
    required this.cols,
    required this.itemBuilder,
    this.spacing = 8,
  });

  final int rows;
  final int cols;
  final double spacing;
  final Widget Function(BuildContext context, int row, int col) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth =
            (constraints.maxWidth - spacing * (cols - 1)) / cols;
        final cellHeight =
            (constraints.maxHeight - spacing * (rows - 1)) / rows;
        final aspect = cellWidth / max(cellHeight, 1);

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            childAspectRatio: aspect.isFinite && aspect > 0 ? aspect : 1,
          ),
          itemCount: rows * cols,
          itemBuilder: (context, index) =>
              itemBuilder(context, index ~/ cols, index % cols),
        );
      },
    );
  }
}
