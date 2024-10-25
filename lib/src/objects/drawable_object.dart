import 'dart:ui';
import 'dart:developer' as developer;

import '../tools/shape_tool.dart';

abstract class DrawableObject {
  void draw(Canvas canvas);
  bool intersects(Path other);
}

class PathObject extends DrawableObject {
  Path path;
  Paint paint;

  PathObject({required this.path, required this.paint});

  @override
  void draw(Canvas canvas) {
    canvas.drawPath(path, paint);
  }

  @override
  bool intersects(Path other) {
    // バウンディングボックスで大まかな判定を最初に行う（パフォーマンス最適化）
    if (!path.getBounds().overlaps(other.getBounds())) {
      return false;
    }

    // パスの交差判定
    try {
      // 2つのパスを組み合わせて交差部分を取得
      Path intersectionPath = Path.combine(
        PathOperation.intersect,
        path,
        other,
      );

      // パスメトリクスを計算
      PathMetrics metrics = intersectionPath.computeMetrics();

      // 交差部分の長さや面積をチェック
      double totalLength = 0;
      for (PathMetric metric in metrics) {
        totalLength += metric.length;
      }

      // 閾値（必要に応じて調整）
      const double minimumIntersectionLength = 1.0;
      return totalLength > minimumIntersectionLength;
    } catch (e) {
      // パスの操作中にエラーが発生した場合はフォールバック
      developer.log('Path intersection calculation error: $e');
      return false;
    }
  }
}

class ShapeObject extends DrawableObject {
  Offset startPoint;
  Offset endPoint;
  ShapeType shapeType;
  Paint paint;

  ShapeObject({
    required this.startPoint,
    required this.endPoint,
    required this.shapeType,
    required this.paint,
  });

  @override
  void draw(Canvas canvas) {
    switch (shapeType) {
      case ShapeType.rectangle:
        final rect = Rect.fromPoints(startPoint, endPoint);
        canvas.drawRect(rect, paint);
        break;
      case ShapeType.circle:
        final center = Offset(
          (startPoint.dx + endPoint.dx) / 2,
          (startPoint.dy + endPoint.dy) / 2,
        );
        final radius = (endPoint - startPoint).distance / 2;
        canvas.drawCircle(center, radius, paint);
        break;
    }
  }

  @override
  bool intersects(Path other) {
    final shapePath = Path();
    switch (shapeType) {
      case ShapeType.rectangle:
        shapePath.addRect(Rect.fromPoints(startPoint, endPoint));
        break;
      case ShapeType.circle:
        final center = Offset(
          (startPoint.dx + endPoint.dx) / 2,
          (startPoint.dy + endPoint.dy) / 2,
        );
        final radius = (endPoint - startPoint).distance / 2;
        shapePath.addOval(Rect.fromCircle(center: center, radius: radius));
        break;
    }
    return Path.combine(PathOperation.intersect, shapePath, other).computeMetrics().isNotEmpty;
  }
}
