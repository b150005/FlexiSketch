import 'dart:developer' as developer;
import 'dart:ui';

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
  Rect get bounds {
    _cachedBounds ??= path.getBounds();
    return _cachedBounds!;
  }

  @override
  void drawObject(Canvas canvas) {
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
