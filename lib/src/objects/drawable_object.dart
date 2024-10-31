import 'dart:developer' as developer;

import 'package:flutter/material.dart';

/// 描画可能なオブジェクトの基底クラス
///
/// すべての描画可能なオブジェクト(パス、図形、画像)に共通する機能を提供します。
/// 移動、回転、スケール(拡大・縮小)、削除などの基本的な変換操作と、選択状態の管理を行います。
abstract class DrawableObject {
  /// オブジェクトが選択されているかどうか
  bool isSelected = false;

  /// 位置
  Offset position;

  /// 回転角度[rad]
  double rotation = 0.0;

  /// スケール
  double scale = 1.0;

  DrawableObject({
    required this.position,
    this.rotation = 0.0,
    this.scale = 1.0,
  });

  /// オブジェクト自身のローカル座標系でのバウンディングボックスを取得する
  ///
  /// 位置(position)、回転(rotation)、スケール(scale)などの変換が適用される前の、オブジェクトの元々のサイズと形状を定義します。
  Rect get localBounds;

  /// 現在の変換を適用したバウンディングボックス(オブジェクトの矩形)を取得する
  ///
  /// 全ての変換(移動、回転、スケール)が適用された後の、キャンバス座標系での実際の矩形領域を表します。
  Rect get bounds {
    final rect = localBounds;
    final matrix = Matrix4.identity()
      ..translate(position.dx, position.dy) // 位置の移動
      ..translate(rect.center.dx, rect.center.dy) // 中心を基準として回転・スケール
      ..rotateZ(rotation)
      ..scale(scale)
      ..translate(-rect.center.dx, -rect.center.dy); // 中心での変換を元に戻す

    return MatrixUtils.transformRect(matrix, rect);
  }

  /// オブジェクトの変換行列を取得する
  Matrix4 get transform {
    return Matrix4.identity()
      ..translate(position.dx, position.dy)
      ..rotateZ(rotation)
      ..scale(scale);
  }

  /// オブジェクトを描画する
  ///
  /// [canvas] 描画対象のキャンバス
  void draw(Canvas canvas) {
    canvas.save();

    // オブジェクトの変換を適用
    final center = localBounds.center;
    canvas
      ..translate(position.dx, position.dy) // 位置の移動
      ..translate(center.dx, center.dy) //中心点に移動
      ..rotate(rotation) // 回転
      ..scale(scale) // スケーリング
      ..translate(-center.dx, -center.dy); // 中心点から戻す

    // オブジェクトの描画
    drawObject(canvas);

    canvas.restore();

    // 選択 UI の描画(変換を適用せず描画)
    if (isSelected) {
      _drawSelectionUI(canvas);
    }
  }

  /// オブジェクト固有の描画処理
  ///
  /// サブクラスでオーバーライドして実際の描画処理を実装します。
  void drawObject(Canvas canvas);

  /// 選択時の UI(枠線・各種ハンドル)の描画
  ///
  /// オブジェクト選択時に呼び出され、枠線と各種操作(移動、回転、削除、拡大・縮小)用のハンドルを描画します。
  void _drawSelectionUI(Canvas canvas) {
    // 変換済みのバウンディングボックスを取得
    final rect = bounds;
    final borderPaint = Paint()
      ..color = Colors.lightBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRect(rect, borderPaint);
    _drawHandles(canvas, rect);
  }

  /// 各種操作用ハンドルの描画
  ///
  /// [canvas] 描画対象のキャンバス
  /// [rect] 配置対象の矩形
  void _drawHandles(Canvas canvas, Rect rect) {
    final handlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final handleBorderPaint = Paint()
      ..color = Colors.lightBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final corners = [
      rect.topLeft,
      rect.topRight,
      rect.bottomLeft,
      rect.bottomRight,
    ];

    // 四隅に配置する拡大・縮小ハンドル
    for (final corner in corners) {
      canvas
        ..drawCircle(corner, 6.0, handlePaint)
        ..drawCircle(corner, 6.0, handleBorderPaint);
    }

    final rotationHandle = Offset(rect.center.dx, rect.top - 20);
    // 上部の回転ハンドル
    canvas
      ..drawCircle(rotationHandle, 6.0, handlePaint)
      ..drawCircle(rotationHandle, 6.0, handleBorderPaint)
      ..drawLine(rect.topCenter, rotationHandle, handleBorderPaint);

    final deleteHandle = Offset(rect.center.dx, rect.bottom + 20);
    final deleteHandlePaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    // 下部の削除ハンドル
    canvas
      ..drawCircle(deleteHandle, 6.0, deleteHandlePaint)
      ..drawLine(rect.bottomCenter, deleteHandle, handleBorderPaint);
  }

  /// 指定された線(Path)と交差するかどうか
  ///
  /// [other] 交差判定対象の線(Path)
  bool intersects(Path other);

  /// 指定された点がオブジェクト内に含まれるかどうか
  ///
  /// [point] 判定対象の点の座標
  bool containsPoint(Offset point) {
    return bounds.contains(point);
  }

  /// オブジェクトを移動する
  ///
  /// [delta] 変位
  void translate(Offset delta) {
    position += delta;
  }

  /// オブジェクトを回転する
  ///
  /// [angle] 回転角度[rad]
  void rotate(double angle) {
    rotation += angle;
  }

  /// オブジェクトをリサイズする
  ///
  /// [newScale] スケール値の変更量
  void resize(double newScale) {
    scale *= newScale;
  }
}
