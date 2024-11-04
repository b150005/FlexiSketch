import 'package:flutter/material.dart';

import '../storage/sketch_storage.dart';
import 'sketch_thumbnail.dart';

/// スケッチのサムネイルをグリッド表示するウィジェット
class SketchGrid extends StatelessWidget {
  final List<SketchMetadata> sketches;
  final void Function(SketchMetadata) onSketchTap;
  final double spacing;
  final double thumbnailSize;

  const SketchGrid({
    super.key,
    required this.sketches,
    required this.onSketchTap,
    this.spacing = 16,
    this.thumbnailSize = 150,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = (constraints.maxWidth / (thumbnailSize + spacing)).floor();
        return GridView.builder(
          padding: EdgeInsets.all(spacing),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 1,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
          ),
          itemCount: sketches.length,
          itemBuilder: (context, index) {
            return SketchThumbnail(
              metadata: sketches[index],
              size: thumbnailSize,
              onTap: () => onSketchTap(sketches[index]),
            );
          },
        );
      },
    );
  }
}
