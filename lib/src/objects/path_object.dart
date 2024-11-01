import 'dart:developer' as developer;
import 'dart:ui';

import 'drawable_object.dart';

/// パス(線)オブジェクト
///
/// フリーハンドの線や消しゴムの軌跡を表現するためのオブジェクトです。
class PathObject extends DrawableObject {
  /// 形状
  final Path _path;
  Path get path => _path;

  /// 描画スタイル
  final Paint paint;

  /// ローカル座標のバウンディングボックス(矩形)のキャッシュ
  Rect? _localBoundsCache;

  PathObject({required Path inputPath, required this.paint})
      : _path = _centerPath(inputPath),
        super(globalCenter: inputPath.getBounds().center);

  @override
  Rect get localBounds {
    _localBoundsCache ??= _path.getBounds();
    return _localBoundsCache!;
  }

  @override
  void drawObject(Canvas canvas) {
    // 変換は DrawableObject の draw メソッドで適用されるため、オリジナルのパスをそのまま描画
    canvas.drawPath(_path, paint);
  }

  @override
  bool checkIntersection(Path other) {
    try {
      final transformedPath = _path.transform(transform.storage);
      final intersectionPath = Path.combine(
        PathOperation.intersect,
        transformedPath,
        other,
      );

      double totalLength = 0;
      for (PathMetric metric in intersectionPath.computeMetrics()) {
        totalLength += metric.length;
      }
      return totalLength > 1.0;
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
        _path,
        testPath,
      );

      return !intersectionPath.getBounds().isEmpty;
    } catch (e) {
      return true;
    }
  }

  static Path _centerPath(Path inputPath) {
    final bounds = inputPath.getBounds();
    return inputPath.shift(-bounds.center);
  }

  // パスを更新する
  void addPoint(Offset localPoint) {
    _path.lineTo(localPoint.dx, localPoint.dy);
    invalidateBounds();
  }

  // パスが更新されたときにキャッシュをクリアする
  void invalidateBounds() {
    _localBoundsCache = null;
  }

  // 現在のグローバル変換を適用したパスを取得
  Path getTransformedPath() {
    return _path.transform(transform.storage);
  }
}
