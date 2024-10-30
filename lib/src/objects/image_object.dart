import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'drawable_object.dart';

/// 画像オブジェクト
///
/// 画像を表示・操作するためのオブジェクトです。
class ImageObject extends DrawableObject {
  /// 画像データ
  final ui.Image image;

  /// 元のサイズ
  final Size originalSize;

  ImageObject({
    required this.image,
    required super.position,
    super.rotation,
    super.scale,
  }) : originalSize = Size(image.width.toDouble(), image.height.toDouble());

  @override
  Rect get bounds {
    final size = originalSize * scale;
    return Rect.fromLTWH(position.dx - size.width / 2, position.dy - size.height / 2, size.width, size.height);
  }

  @override
  void drawObject(Canvas canvas) {
    final center = bounds.center;
    canvas
      ..translate(center.dx, center.dy)
      ..rotate(rotation)
      ..scale(scale)
      ..translate(-originalSize.width / 2, -originalSize.height / 2)
      ..drawImage(image, Offset.zero, Paint());
  }

  @override
  bool intersects(Path other) {
    final imagePath = Path()..addRect(bounds);
    return Path.combine(PathOperation.intersect, imagePath, other).computeMetrics().isNotEmpty;
  }
}
