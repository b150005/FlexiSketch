import 'package:flutter/material.dart';

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
    // パスの交差判定の実装
    // この実装は単純化されており、完全な判定には更に複雑なロジックが必要です
    return path.getBounds().overlaps(other.getBounds());
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