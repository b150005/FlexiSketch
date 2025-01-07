import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

import '../../flexi_sketch_controller.dart';
import '../objects/drawable_object.dart';

/// CanvasPainterクラスは、キャンバス上に描画を行うためのカスタムペインターです。
///
/// このクラスは、FlexiSketchControllerを使用して描画するオブジェクトを管理し、変換行列を適用して描画を行います。
/// また、選択オブジェクトの UI 要素(ハンドルなど)の描画も担当します。
class CanvasPainter extends CustomPainter {
  /// 描画を管理するコントローラー
  final FlexiSketchController controller;

  /// 描画に適用する変換行列
  final Matrix4 transform;

  /// オブジェクト操作ハンドルのサイズ
  final double handleSize;

  /// 選択枠の色
  static const selectionBorderColor = Colors.lightBlue;

  /// 選択ハンドルの枠線色
  static const handleBorderColor = Colors.lightBlue;

  /// 選択ハンドルの背景色
  static const handleFillColor = Colors.white;

  /// 削除ハンドルの色
  static const deleteHandleColor = Colors.red;

  /// 選択枠の線幅
  static const selectionBorderWidth = 2.0;

  /// ハンドル枠の線幅
  static const handleBorderWidth = 2.0;

  /// 選択枠のダッシュパターン
  static const dashPattern = <double>[5, 5];

  /// コンストラクタ
  ///
  /// [controller] 描画を管理するコントローラ
  /// [transform] 描画に適用する変換行列
  /// [handleSize] オブジェクト操作ハンドルのサイズ(デフォルト: `12.0`)
  CanvasPainter({required this.controller, required this.transform, this.handleSize = 12.0})
      : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    // 現在のキャンバスの状態を保存
    canvas.save();
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

        // 選択状態のオブジェクトは選択時 UI (枠線・ハンドル)を描画
        if (object.isSelected) {
          _drawSelectionUI(canvas, object);
        }
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

    // 保存した状態を復元
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CanvasPainter oldDelegate) {
    // 再描画が必要かどうかを判断する
    return (oldDelegate.controller != controller || // コントローラーが異なる場合
        oldDelegate.transform != transform || // 変換行列が異なる場合
        oldDelegate.handleSize != handleSize || // ハンドルサイズが異なる場合
        oldDelegate.controller.objects.length != controller.objects.length); // オブジェクトの数が異なる場合
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

  /// グリッドを描画する
  ///
  /// このメソッドは、指定された可視領域内にグリッドを描画します。
  /// グリッドのサイズは固定されており、指定された色と透明度で描画されます。
  void _drawGrid(Canvas canvas, Rect visibleRect) {
    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.5) // グリッドの色と透明度
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

  /// オブジェクトが可視領域内にあるかどうか
  ///
  /// このメソッドは、与えられた DrawableObject が可視領域と交差しているかどうかを確認します。
  ///
  /// [object] 判定対象のオブジェクト
  /// [visibleRect] 可視領域を表す矩形
  bool _isObjectVisible(DrawableObject object, Rect visibleRect) {
    return visibleRect.overlaps(object.bounds);
  }

  /// 選択 UI を描画する
  ///
  /// 選択されたオブジェクトの周囲に選択枠とハンドルを描画します。
  ///
  /// [canvas] 描画対象のキャンバス
  /// [object] 選択されたオブジェクト
  void _drawSelectionUI(Canvas canvas, DrawableObject object) {
    final bounds = object.bounds;

    // 選択枠を描画
    _drawSelectionBorder(canvas, bounds);

    // 各種ハンドルを描画
    _drawCornerHandles(canvas, bounds); // 四隅の拡大・縮小ハンドル
    _drawRotationHandle(canvas, bounds); // 回転ハンドル
    _drawDeleteHandle(canvas, bounds); // 削除ハンドル
  }

  /// 選択枠を描画する
  ///
  /// [canvas] 描画対象のキャンバス
  /// [bounds] オブジェクトのバウンディングボックス
  void _drawSelectionBorder(Canvas canvas, Rect bounds) {
    final paint = Paint()
      ..color = selectionBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = selectionBorderWidth;

    // 点線のパスを作成
    final path = Path();
    var start = bounds.topLeft;
    var current = start;

    for (final point in [
      bounds.topRight,
      bounds.bottomRight,
      bounds.bottomLeft,
      bounds.topLeft,
    ]) {
      _addDashedLine(path, current, point, dashPattern);
      current = point;
    }

    canvas.drawPath(path, paint);
  }

  /// 点線を描画するためのパスを追加する
  ///
  /// [path] 追加先のパス
  /// [start] 開始点
  /// [end] 終了点
  /// [pattern] 点線のパターン(実戦と空白の長さの配列)
  void _addDashedLine(Path path, Offset start, Offset end, List<double> pattern) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = (end - start).distance;
    final steps = pattern.reduce((a, b) => a + b);
    final count = (distance / steps).ceil();

    var x = start.dx;
    var y = start.dy;
    var drawn = true;

    path.moveTo(start.dx, start.dy);

    for (var i = 0; i < count; i++) {
      for (final length in pattern) {
        x += dx * length / distance;
        y += dy * length / distance;

        if (drawn) {
          path.lineTo(x, y);
        } else {
          path.moveTo(x, y);
        }
        drawn = !drawn;
      }
    }
  }

  /// 四隅のリサイズハンドルを描画する
  ///
  /// [canvas] 描画対象のキャンバス
  /// [bounds] オブジェクトのバウンディングボックス
  void _drawCornerHandles(Canvas canvas, Rect bounds) {
    final handlePaint = Paint()
      ..color = handleFillColor
      ..style = PaintingStyle.fill;

    final handleBorderPaint = Paint()
      ..color = handleBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = handleBorderWidth;

    for (final point in [
      bounds.topLeft,
      bounds.topRight,
      bounds.bottomLeft,
      bounds.bottomRight,
    ]) {
      canvas
        ..drawCircle(point, handleSize / 2, handlePaint)
        ..drawCircle(point, handleSize / 2, handleBorderPaint);
    }
  }

  /// 回転ハンドルを描画する
  ///
  /// [canvas] 描画対象のキャンバス
  /// [bounds] オブジェクトのバウンディングボックス
  void _drawRotationHandle(Canvas canvas, Rect bounds) {
    final handlePaint = Paint()
      ..color = handleFillColor
      ..style = PaintingStyle.fill;

    final handleBorderPaint = Paint()
      ..color = handleBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = handleBorderWidth;

    final rotationHandle = Offset(bounds.center.dx, bounds.top - 20);

    canvas
      ..drawCircle(rotationHandle, handleSize / 2, handlePaint)
      ..drawCircle(rotationHandle, handleSize / 2, handleBorderPaint)
      ..drawLine(Offset(bounds.center.dx, bounds.top), rotationHandle, handleBorderPaint);
  }

  /// 削除ハンドルを描画する
  ///
  /// [canvas] 描画対象のキャンバス
  /// [bounds] オブジェクトのバウンディングボックス
  void _drawDeleteHandle(Canvas canvas, Rect bounds) {
    final handlePaint = Paint()
      ..color = deleteHandleColor
      ..style = PaintingStyle.fill;

    final handleBorderPaint = Paint()
      ..color = handleBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = handleBorderWidth;

    final deleteHandle = Offset(bounds.center.dx, bounds.bottom + 20);

    canvas
      ..drawCircle(deleteHandle, handleSize / 2, handlePaint)
      ..drawCircle(deleteHandle, handleSize / 2, handleBorderPaint)
      ..drawLine(Offset(bounds.center.dx, bounds.bottom), deleteHandle, handleBorderPaint);
  }
}
