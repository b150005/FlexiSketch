import 'dart:developer' as developer;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'drawable_object.dart';

/// パス(線)オブジェクト
///
/// フリーハンドの線や消しゴムの軌跡を表現するためのオブジェクトです。
class PathObject extends DrawableObject {
  /// 形状
  Path path;

  /// 描画スタイル
  Paint paint;

  /// バウンディングボックス(矩形)のキャッシュ
  Rect? _cachedBounds;

  PathObject({required this.path, required this.paint}) : super(position: Offset.zero);

  @override
  Rect get localBounds {
    _cachedBounds ??= path.getBounds();
    return _cachedBounds!;
  }

  @override
  void drawObject(Canvas canvas) {
    // 変換はDrawableObjectのdrawメソッドで適用されるため、オリジナルのパスをそのまま描画
    canvas.drawPath(path, paint);
  }

  @override
  bool intersects(Path other) {
    // バウンディングボックスで大まかな判定を最初に行う（パフォーマンス最適化）
    // if (!path.getBounds().overlaps(other.getBounds())) {
    //   return false;
    // }

    // 現在の変換を適用したパスを取得
    final center = localBounds.center;
    final matrix = Matrix4.identity()
      ..translate(position.dx, position.dy)
      ..translate(center.dx, center.dy)
      ..rotateZ(rotation)
      ..scale(scale)
      ..translate(-center.dx, -center.dy);

    final transformedPath = path.transform(matrix.storage);

    // 変換済みのパスで大まかな交差判定を行う(パフォーマンス最適化)
    if (!transformedPath.getBounds().overlaps(other.getBounds())) {
      return false;
    }

    // パスの交差判定
    try {
      // 2つのパスを組み合わせて交差部分を取得
      Path intersectionPath = Path.combine(
        PathOperation.intersect,
        transformedPath,
        other,
      );

      // パスメトリクスを計算
      PathMetrics metrics = intersectionPath.computeMetrics();

      // 交差部分の長さ・面積のチェック
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
