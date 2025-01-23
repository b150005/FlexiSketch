import 'dart:ui';

import '../serialization/object_serializer.dart';
import '../serialization/serializers/path_object_serializer.dart';
import 'drawable_object.dart';

/// パス(線)オブジェクト
///
/// フリーハンドの線や消しゴムの軌跡を表現するためのオブジェクトです。
/// 全ての座標は中心を原点とするローカル座標系で管理されます。
class PathObject extends DrawableObject {
  /// 中心が原点のローカル座標系で定義される形状を表すパス
  final Path _path;

  /// 形状を表すパスを取得する
  Path get path => _path;

  /// 描画スタイル（色、線幅など）
  final Paint paint;

  /// ローカル座標のバウンディングボックス(矩形)のキャッシュ
  Rect? _localBoundsCache;

  /// コンストラクタ
  ///
  /// [inputPath] 入力パス（任意の座標系）
  /// [paint] 描画スタイル
  PathObject({required Path inputPath, required this.paint})
      : _path = inputPath,
        super(globalCenter: inputPath.getBounds().center);

  @override
  String get type => 'path';

  @override
  ObjectSerializer get serializer => PathObjectSerializer.instance;

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
      final Path transformedPath = _path.transform(transform.storage);
      final Path intersectionPath = Path.combine(
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
      final Path testPath = Path()
        ..addRect(Rect.fromCenter(
          center: localPoint,
          width: 10.0,
          height: 10.0,
        ));

      final Path intersectionPath = Path.combine(
        PathOperation.intersect,
        _path,
        testPath,
      );

      return !intersectionPath.getBounds().isEmpty;
    } catch (e) {
      return true;
    }
  }

  @override
  PathObject clone() {
    final Path clonedPath = Path()..addPath(_path, Offset.zero);
    final Paint clonedPaint = Paint()
      ..color = paint.color
      ..strokeWidth = paint.strokeWidth
      ..style = paint.style
      ..strokeCap = paint.strokeCap
      ..strokeJoin = paint.strokeJoin
      ..blendMode = paint.blendMode;

    final PathObject clone = PathObject(
      inputPath: clonedPath,
      paint: clonedPaint,
    );

    // 変換状態をコピー
    clone
      ..globalCenter = globalCenter
      ..rotation = rotation
      ..scale = scale
      ..isSelected = false;

    return clone;
  }

  /// パスに新しい点を追加する
  ///
  /// 現在のパスの最後の点から指定された点まで直線を引きます。
  ///
  /// [localPoint] 追加する点のローカル座標
  void addPoint(Offset localPoint) {
    _path.lineTo(localPoint.dx, localPoint.dy);
    invalidateBounds();
  }

  /// パスのバウンディングボックスのキャッシュを無効化する
  ///
  /// パスが更新された際に呼び出され、次回のバウンディングボックス計算で新しい値が計算されるようにします。
  void invalidateBounds() {
    _localBoundsCache = null;
  }

  /// 現在の変換を適用したパスを取得する
  ///
  /// 現在の位置、回転、スケールなどの変換が適用されたパスを返します。
  ///
  /// Returns: グローバル座標系での変換済みパス
  Path getTransformedPath() {
    return _path.transform(transform.storage);
  }
}
