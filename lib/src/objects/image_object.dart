import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../serialization/object_serializer.dart';
import '../serialization/serializers/image_object_serializer.dart';
import 'drawable_object.dart';

/// 画像オブジェクト
///
/// 画像を表示・操作するためのオブジェクトです。
class ImageObject extends DrawableObject {
  /// 画像データ
  final ui.Image image;

  final Paint paint;

  final Size _size;

  /// 画像のサイズを取得する
  Size get size => _size;

  Rect? _localBoundsCache;

  ImageObject({
    required this.image,
    required super.globalCenter,
    required Size? size,
    Paint? paint,
  })  : _size = size ?? Size(image.width.toDouble(), image.height.toDouble()),
        paint = paint ?? Paint();

  @override
  String get type => 'image';

  @override
  ObjectSerializer get serializer => ImageObjectSerializer.instance;

  @override
  Rect get localBounds {
    _localBoundsCache ??= Rect.fromCenter(
      center: Offset.zero,
      width: _size.width,
      height: _size.height,
    );
    return _localBoundsCache!;
  }

  @override
  void drawObject(Canvas canvas) {
    final srcRect = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final dstRect = Rect.fromCenter(
      center: Offset.zero,
      width: _size.width,
      height: _size.height,
    );

    canvas.drawImageRect(image, srcRect, dstRect, paint);
  }

  @override
  bool checkIntersection(Path other) {
    // 画像は矩形として交差判定
    final imagePath = Path()..addRect(bounds);
    try {
      final intersectionPath = Path.combine(
        PathOperation.intersect,
        imagePath,
        other,
      );

      return intersectionPath.computeMetrics().fold(0.0, (sum, metric) => sum + metric.length) > 1.0;
    } catch (e) {
      return true;
    }
  }

  @override
  bool checkContainsPoint(Offset localPoint) {
    // 画像は矩形として判定
    return localBounds.contains(localPoint);
  }
}
