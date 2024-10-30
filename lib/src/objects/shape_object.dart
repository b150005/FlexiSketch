import 'package:flutter/material.dart';

import '../tools/shape_tool.dart';
import 'drawable_object.dart';

/// 図形オブジェクト
///
/// 矩形や縁などの基本図形を表現するためのオブジェクトです。
class ShapeObject extends DrawableObject {
  /// 始点
  Offset startPoint;

  /// 終点
  Offset endPoint;

  /// 図形の種類
  ShapeType shapeType;

  /// 描画スタイル
  Paint paint;

  ShapeObject({
    required this.startPoint,
    required this.endPoint,
    required this.shapeType,
    required this.paint,
  }) : super(position: Offset.zero);

  @override
  Rect get bounds {
    return Rect.fromPoints(startPoint, endPoint);
  }

  @override
  void drawObject(Canvas canvas) {
    switch (shapeType) {
      case ShapeType.rectangle:
        canvas.drawRect(bounds, paint);
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
        shapePath.addRect(bounds);
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
