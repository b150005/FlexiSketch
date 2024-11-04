import 'package:flutter/material.dart';

import '../storage/sketch_storage.dart';

class SketchPreview extends StatelessWidget {
  final SketchMetadata metadata;
  final VoidCallback? onTap;
  final double width;
  final double height;

  const SketchPreview({
    super.key,
    required this.metadata,
    this.onTap,
    this.width = 200,
    this.height = 150,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // プレビュー画像
            if (metadata.previewImageUrl != null)
              Image.network(
                metadata.previewImageUrl!,
                width: width,
                height: height,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
              )
            else
              Container(
                width: width,
                height: height,
                color: Colors.grey[200],
                child: const Icon(Icons.image_not_supported),
              ),

            // メタデータ
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metadata.title,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '最終更新: ${_formatDate(metadata.updatedAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day} ${date.hour}:${date.minute}';
  }
}

// プレビューのグリッド表示用ウィジェット
class SketchPreviewGrid extends StatelessWidget {
  final List<SketchMetadata> sketches;
  final Function(SketchMetadata) onSketchTap;
  final int crossAxisCount;
  final double spacing;
  final double childAspectRatio;

  const SketchPreviewGrid({
    super.key,
    required this.sketches,
    required this.onSketchTap,
    this.crossAxisCount = 3,
    this.spacing = 8.0,
    this.childAspectRatio = 0.75,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: sketches.length,
      itemBuilder: (context, index) {
        final sketch = sketches[index];
        return SketchPreview(
          metadata: sketch,
          onTap: () => onSketchTap(sketch),
        );
      },
    );
  }
}
