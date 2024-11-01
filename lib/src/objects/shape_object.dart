import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tools/shape_tool.dart';
import 'drawable_object.dart';

/// 図形オブジェクト
///
/// 矩形や縁などの基本図形を表現するためのオブジェクトです。
class ShapeObject extends DrawableObject {
  /// 始点
  final Offset _startPoint;
  Offset get startPoint => _startPoint;

  /// 終点
  Offset _endPoint;
  Offset get endPoint => _endPoint;

  Path? _shapePath;

  Rect? _localBoundsCache;

  /// 図形の種類
  final ShapeType shapeType;

  /// 描画スタイル
  Paint paint;

  // 最小サイズの定数
  static const double MIN_SIZE = 10.0;

  ShapeObject({
    required Offset startPoint,
    required Offset endPoint,
    required this.shapeType,
    required this.paint,
  })  : _startPoint = startPoint,
        _endPoint = endPoint,
        super(globalCenter: Rect.fromPoints(startPoint, endPoint).center);

  @override
  Rect get localBounds {
    _localBoundsCache ??= _createPath().getBounds();
    return _localBoundsCache!;
  }

  @override
  void drawObject(Canvas canvas) {
    canvas.drawPath(_createPath(), paint);
  }

  @override
  bool checkIntersection(Path other) {
    try {
      final transformedPath = _createPath().transform(transform.storage);
      final intersectionPath = Path.combine(
        PathOperation.intersect,
        transformedPath,
        other,
      );

      return intersectionPath.computeMetrics().fold(0.0, (sum, metric) => sum + metric.length) > 1.0;
    } catch (e) {
      return true;
    }
  }

  @override
  bool checkContainsPoint(Offset localPoint) {
    try {
      final testPath = Path()
        ..addRect(Rect.fromCenter(
          center: localPoint,
          width: 10.0,
          height: 10.0,
        ));

      final intersectionPath = Path.combine(
        PathOperation.intersect,
        _createPath(),
        testPath,
      );

      return !intersectionPath.getBounds().isEmpty;
    } catch (e) {
      return true;
    }
  }

  Path _createPath() {
    _shapePath ??= _buildShapePath();
    return _shapePath!;
  }

  Path _buildShapePath() {
    final path = Path();
    final rect = Rect.fromPoints(_startPoint - globalCenter, _endPoint - globalCenter);

    switch (shapeType) {
      case ShapeType.rectangle:
        path.addRect(rect);
        break;
      // case ShapeType.ellipse:
      //   path.addOval(rect);
      //   break;
      // 他の図形タイプも同様に実装
      default:
        break;
    }

    return path;
  }

  void updateShape(Offset newEndPoint) {
    // 最小サイズを確保
    final currentRect = Rect.fromPoints(_startPoint, newEndPoint);
    if (currentRect.width < MIN_SIZE || currentRect.height < MIN_SIZE) {
      // 最小サイズを保持しつつ、アスペクト比を維持
      final aspect = currentRect.width / currentRect.height;
      final newSize = Size(math.max(MIN_SIZE, currentRect.width), math.max(MIN_SIZE, currentRect.height));
      // 新しい終点を計算
      newEndPoint = _startPoint + Offset(newSize.width, newSize.height);
    }

    updateEndPoint(newEndPoint);
  }

  void updateEndPoint(Offset newEndPoint) {
    _endPoint = newEndPoint;
    _shapePath = null;
    _localBoundsCache = null;
    globalCenter = Rect.fromPoints(_startPoint, _endPoint).center;
  }
}
