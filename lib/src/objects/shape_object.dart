import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tools/shape_tool.dart';
import 'drawable_object.dart';

/// 図形オブジェクト
///
/// 矩形や縁などの基本図形を表現するためのオブジェクトです。
/// 図形は始点と終点から定義される矩形領域内に描画されます。
class ShapeObject extends DrawableObject {
  /// 図形の描画開始点（グローバル座標系）
  final Offset _startPoint;
  Offset get startPoint => _startPoint;

  /// 図形の描画終点（グローバル座標系）
  Offset _endPoint;
  Offset get endPoint => _endPoint;

  /// 図形のパスのキャッシュ
  Path? _shapePath;

  /// ローカル座標系でのバウンディングボックスのキャッシュ
  Rect? _localBoundsCache;

  /// 図形の種類（矩形、円など）
  final ShapeType shapeType;

  /// 描画スタイル（色、線幅など）
  Paint paint;

  // 図形の最小サイズ（ピクセル単位）
  static const double minSize = 10.0;

  /// コンストラクタ
  ///
  /// [startPoint] 図形の描画開始点（グローバル座標系）
  /// [endPoint] 図形の描画終点（グローバル座標系）
  /// [shapeType] 図形の種類
  /// [paint] 描画スタイル
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

  /// キャッシュされたパスを取得する
  ///
  /// パスが未作成の場合は新規作成します。
  Path _createPath() {
    _shapePath ??= _buildShapePath();
    return _shapePath!;
  }

  /// 図形の種類に応じたパスを生成する
  Path _buildShapePath() {
    final path = Path();

    // グローバル座標からローカル座標に変換
    final rect = Rect.fromPoints(_startPoint - globalCenter, _endPoint - globalCenter);

    switch (shapeType) {
      case ShapeType.rectangle:
        path.addRect(rect);
        break;
      case ShapeType.circle:
        // 円は矩形に内接する楕円として描画
        path.addOval(rect);
        break;
      default:
        // 未知の図形タイプの場合は空のパスを返す
        break;
    }

    return path;
  }

  /// 図形の終点を更新する
  ///
  /// 最小サイズの制約を適用し、必要に応じて縦横比を維持します。
  /// [newEndPoint] 新しい終点座標
  void updateShape(Offset newEndPoint) {
    // 最小サイズを確保
    final currentRect = Rect.fromPoints(_startPoint, newEndPoint);

    // 最小サイズの制約を適用
    if (currentRect.width < minSize || currentRect.height < minSize) {
      // 最小サイズを保持しつつ、アスペクト比を維持
      final aspect = currentRect.width / currentRect.height;
      double newWidth, newHeight;

      if (currentRect.width < minSize) {
        newWidth = minSize;
        newHeight = minSize / aspect;
      } else {
        newHeight = minSize;
        newWidth = minSize * aspect;
      }

      // 開始点からの相対位置で新しい終点を計算
      final direction = (newEndPoint - _startPoint).direction;
      newEndPoint = _startPoint + Offset(newWidth * math.cos(direction), newHeight * math.sin(direction));
    }

    updateEndPoint(newEndPoint);
  }

  /// 図形の終点を直接更新する
  ///
  /// キャッシュを無効化し、オブジェクトの中心位置を更新します。
  /// [newEndPoint] 新しい終点座標
  void updateEndPoint(Offset newEndPoint) {
    _endPoint = newEndPoint;
    _shapePath = null;
    _localBoundsCache = null;
    globalCenter = Rect.fromPoints(_startPoint, _endPoint).center;
  }
}
