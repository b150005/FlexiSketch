import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

import '../../flexi_sketch_controller.dart';
import '../objects/drawable_object.dart';

/// CanvasPainterクラスは、キャンバス上に描画を行うためのカスタムペインターです。
///
/// このクラスは、FlexiSketchControllerを使用して描画するオブジェクトを管理し、
/// 変換行列を適用して描画を行います。
class CanvasPainter extends CustomPainter {
  /// 描画を管理するコントローラー
  final FlexiSketchController controller;

  /// 描画に適用する変換行列
  final Matrix4 transform;

  CanvasPainter({required this.controller, required this.transform}) : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    // 現在のキャンバスの状態を保存
    canvas.save();
    // スケールを適用
    canvas.scale(controller.scale);
    // 変換行列を適用
    canvas.transform(transform.storage);

    // 可視領域を計算
    final Rect visibleRect = _calculateVisibleRect(canvas, size);

    // グリッドを描画
    _drawGrid(canvas, visibleRect);

    // すべてのオブジェクトを描画
    for (var object in controller.objects) {
      if (_isObjectVisible(object, visibleRect)) {
        object.draw(canvas);
      }
    }

    // 現在のパスがあれば描画
    if (controller.currentPath != null) {
      controller.currentPath!.draw(canvas);
    }

    // 現在の形状があれば描画
    if (controller.currentShape != null) {
      controller.currentShape!.draw(canvas);
    }

    canvas.restore(); // 保存した状態を復元
  }

  /// 可視領域を計算する
  ///
  /// このメソッドは、与えられたキャンバスとサイズを基に、現在の変換行列の逆行列を使用して可視領域の矩形を計算します。
  /// これにより、描画するオブジェクトが画面に表示されるかどうかを判断するための基準となる矩形を取得します。
  Rect _calculateVisibleRect(Canvas canvas, Size size) {
    // 変換行列の逆行列を計算
    final Matrix4 inverseTransform = Matrix4.inverted(transform);

    final topLeft = inverseTransform.transform3(Vector3(0, 0, 0));
    final bottomRight = inverseTransform.transform3(Vector3(size.width, size.height, 0));

    // 矩形を作成
    return Rect.fromPoints(Offset(topLeft.x, topLeft.y), Offset(bottomRight.x, bottomRight.y));
  }

  /// オブジェクトが可視領域内にあるかどうかを判断する
  ///
  /// このメソッドは、与えられた DrawableObject が可視領域と交差しているかどうかを確認するために使用されます。
  /// 具体的な実装は DrawableObject の実装に依存します。
  bool _isObjectVisible(DrawableObject object, Rect visibleRect) {
    // 実装はDrawableObjectに基づいて行う必要があります。
    // 例えば、オブジェクトのバウンディングボックスがvisibleRectと交差しているかを確認することができます。

    // プレースホルダー
    return true;
  }

  /// グリッドを描画する
  ///
  /// このメソッドは、指定された可視領域内にグリッドを描画します。
  /// グリッドのサイズは固定されており、指定された色と透明度で描画されます。
  void _drawGrid(Canvas canvas, Rect visibleRect) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.5) // グリッドの色と透明度
      ..strokeWidth = 0.5; // グリッドの線の太さ

    const gridSize = 20.0;
    final startX = (visibleRect.left / gridSize).floor() * gridSize; // グリッドの開始X座標
    final endX = (visibleRect.right / gridSize).ceil() * gridSize; // グリッドの終了X座標
    final startY = (visibleRect.top / gridSize).floor() * gridSize; // グリッドの開始Y座標
    final endY = (visibleRect.bottom / gridSize).ceil() * gridSize; // グリッドの終了Y座標

    // 縦のグリッドラインを描画
    for (double x = startX; x <= endX; x += gridSize) {
      canvas.drawLine(Offset(x, visibleRect.top), Offset(x, visibleRect.bottom), paint);
    }

    // 横のグリッドラインを描画
    for (double y = startY; y <= endY; y += gridSize) {
      canvas.drawLine(Offset(visibleRect.left, y), Offset(visibleRect.right, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CanvasPainter oldDelegate) {
    // 再描画が必要かどうかを判断する
    return oldDelegate.controller != controller || // コントローラーが異なる場合
        oldDelegate.transform != transform || // 変換行列が異なる場合
        oldDelegate.controller.objects.length != controller.objects.length; // オブジェクトの数が異なる場合
  }
}
