import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

import '../../flexi_sketch_controller.dart';
import '../objects/drawable_object.dart';
import '../objects/text_object.dart';

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
  static const Color selectionBorderColor = Colors.lightBlue;

  /// 選択ハンドルの枠線色
  static const Color handleBorderColor = Colors.lightBlue;

  /// 選択ハンドルの背景色
  static const Color handleFillColor = Colors.white;

  /// 削除ハンドルの色
  static const Color deleteHandleColor = Colors.red;

  /// 編集ハンドルの色
  static const Color editHandleColor = Colors.lightBlue;

  /// 選択枠の線幅
  static const double selectionBorderWidth = 2.0;

  /// ハンドル枠の線幅
  static const double handleBorderWidth = 2.0;

  /// 選択枠のダッシュパターン
  static const List<double> dashPattern = <double>[5, 5];

  /// デバッグモードのフラグ
  final bool debugMode;

  /// (デバッグ用) グリッド線に表示するテキストの文字色
  static const Color _debugTextColor = Colors.black87;

  /// (デバッグ用) グリッド線に表示するテキストのフォントサイズ
  static const double _debugTextSize = 10.0;

  /// (デバッグ用) グリッド線に表示するテキストのパディング
  static const double _debugTextPadding = 2.0;

  /// (デバッグ用) グリッド線に表示するグローバル座標の間隔
  static const double _debugCoordinateInterval = 100.0;

  /// コンストラクタ
  ///
  /// [controller] 描画を管理するコントローラ
  /// [transform] 描画に適用する変換行列
  /// [handleSize] オブジェクト操作ハンドルのサイズ(デフォルト: `12.0`)
  CanvasPainter({
    required this.controller,
    required this.transform,
    this.handleSize = 12.0,
    this.debugMode = false,
  }) : super(repaint: controller);

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

    // デバッグモードが有効な場合は座標を描画
    if (debugMode) {
      _drawDebugCoordinates(canvas, visibleRect);
    }

    // すべてのオブジェクトを描画
    for (var object in controller.objects) {
      if (_isObjectVisible(object, visibleRect)) {
        object.draw(canvas);

        // 選択状態のオブジェクトは選択時 UI (枠線・ハンドル)を描画
        if (object.isSelected) {
          _drawSelectionUI(canvas, object, showDeleteHandle: !controller.preserveImages);
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

    final Vector3 topLeft = inverseTransform.transform3(Vector3(0, 0, 0));
    final Vector3 bottomRight = inverseTransform.transform3(Vector3(size.width, size.height, 0));

    // 矩形を作成
    return Rect.fromPoints(Offset(topLeft.x, topLeft.y), Offset(bottomRight.x, bottomRight.y));
  }

  /// グリッドを描画する
  ///
  /// このメソッドは、指定された可視領域内にグリッドを描画します。
  /// グリッドのサイズは固定されており、指定された色と透明度で描画されます。
  void _drawGrid(Canvas canvas, Rect visibleRect) {
    final Paint paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.5) // グリッドの色と透明度
      ..strokeWidth = 0.5; // グリッドの線の太さ

    const double gridSize = 20.0;
    final double startX = (visibleRect.left / gridSize).floor() * gridSize; // グリッドの開始X座標
    final double endX = (visibleRect.right / gridSize).ceil() * gridSize; // グリッドの終了X座標
    final double startY = (visibleRect.top / gridSize).floor() * gridSize; // グリッドの開始Y座標
    final double endY = (visibleRect.bottom / gridSize).ceil() * gridSize; // グリッドの終了Y座標

    // 縦のグリッドラインを描画
    for (double x = startX; x <= endX; x += gridSize) {
      canvas.drawLine(Offset(x, visibleRect.top), Offset(x, visibleRect.bottom), paint);
    }

    // 横のグリッドラインを描画
    for (double y = startY; y <= endY; y += gridSize) {
      canvas.drawLine(Offset(visibleRect.left, y), Offset(visibleRect.right, y), paint);
    }
  }

  /// デバッグ用の座標を描画する
  void _drawDebugCoordinates(Canvas canvas, Rect visibleRect) {
    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    // X軸の座標を描画（上部）
    final double startX = (visibleRect.left / _debugCoordinateInterval).floor() * _debugCoordinateInterval;
    final double endX = (visibleRect.right / _debugCoordinateInterval).ceil() * _debugCoordinateInterval;

    for (double x = startX; x <= endX; x += _debugCoordinateInterval) {
      final String text = x.toStringAsFixed(0);
      textPainter.text = TextSpan(
        text: text,
        style: TextStyle(
          color: _debugTextColor,
          fontSize: _debugTextSize,
        ),
      );
      textPainter.layout();

      // テキストを描画
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, visibleRect.top + _debugTextPadding),
      );
    }

    // Y軸の座標を描画（右側）
    final double startY = (visibleRect.top / _debugCoordinateInterval).floor() * _debugCoordinateInterval;
    final double endY = (visibleRect.bottom / _debugCoordinateInterval).ceil() * _debugCoordinateInterval;

    for (double y = startY; y <= endY; y += _debugCoordinateInterval) {
      final String text = y.toStringAsFixed(0);
      textPainter.text = TextSpan(
        text: text,
        style: TextStyle(
          color: _debugTextColor,
          fontSize: _debugTextSize,
        ),
      );
      textPainter.layout();

      // テキストを描画
      textPainter.paint(
        canvas,
        Offset(
          visibleRect.right - textPainter.width - _debugTextPadding,
          y - textPainter.height / 2,
        ),
      );
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
  void _drawSelectionUI(
    Canvas canvas,
    DrawableObject object, {
    bool showDeleteHandle = true,
  }) {
    final Rect bounds = object.bounds;

    // 選択枠を描画
    _drawSelectionBorder(canvas, bounds);

    // 各種ハンドルを描画
    _drawCornerHandles(canvas, bounds); // 四隅の拡大・縮小ハンドル
    _drawRotationHandle(canvas, bounds); // 回転ハンドル
    if (showDeleteHandle) _drawDeleteHandle(canvas, bounds); // 削除ハンドル

    // TextObjectの場合は編集ハンドルを追加
    if (object is TextObject) {
      _drawEditHandle(canvas, bounds);
    }
  }

  /// 選択枠を描画する
  ///
  /// [canvas] 描画対象のキャンバス
  /// [bounds] オブジェクトのバウンディングボックス
  void _drawSelectionBorder(Canvas canvas, Rect bounds) {
    final Paint paint = Paint()
      ..color = selectionBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = selectionBorderWidth;

    // 点線のパスを作成
    final Path path = Path();
    Offset start = bounds.topLeft;
    Offset current = start;

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
    final double dx = end.dx - start.dx;
    final double dy = end.dy - start.dy;
    final double distance = (end - start).distance;
    final double steps = pattern.reduce((a, b) => a + b);
    final int count = (distance / steps).ceil();

    double x = start.dx;
    double y = start.dy;
    bool drawn = true;

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
    final Paint handlePaint = Paint()
      ..color = handleFillColor
      ..style = PaintingStyle.fill;

    final Paint handleBorderPaint = Paint()
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
    final Paint handlePaint = Paint()
      ..color = handleFillColor
      ..style = PaintingStyle.fill;

    final Paint handleBorderPaint = Paint()
      ..color = handleBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = handleBorderWidth;

    final Offset rotateHandle = Offset(bounds.center.dx, bounds.top - 20);
    final Offset rotateHandleBottom = Offset(rotateHandle.dx, rotateHandle.dy + 12);

    /// ハンドルのサイズ(Iconsを表示するので大きめに設定)
    final double rotateHandleSize = 24;

    // ベースとなる円を描画
    canvas
      ..drawCircle(rotateHandle, rotateHandleSize / 2, handlePaint)
      ..drawCircle(rotateHandle, rotateHandleSize / 2, handleBorderPaint)
      ..drawLine(bounds.topCenter, rotateHandleBottom, handleBorderPaint);

    // 回転アイコンを描画
    final IconData rotateIcon = Icons.rotate_right;
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(rotateIcon.codePoint),
        style: TextStyle(
          fontSize: rotateHandleSize * 0.8,
          fontFamily: rotateIcon.fontFamily,
          color: handleBorderColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        rotateHandle.dx - textPainter.width / 2,
        rotateHandle.dy - textPainter.height / 2,
      ),
    );
  }

  /// 削除ハンドルを描画する
  ///
  /// [canvas] 描画対象のキャンバス
  /// [bounds] オブジェクトのバウンディングボックス
  void _drawDeleteHandle(Canvas canvas, Rect bounds) {
    final Paint handlePaint = Paint()
      ..color = deleteHandleColor
      ..style = PaintingStyle.fill;

    final Paint handleBorderPaint = Paint()
      ..color = handleBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = handleBorderWidth;

    final Offset deleteHandle = Offset(bounds.center.dx, bounds.bottom + 20);
    final Offset deleteHandleTop = Offset(deleteHandle.dx, deleteHandle.dy - 12);

    /// ハンドルのサイズ(Iconsを表示するので大きめに設定)
    final double deleteHandleSize = 24;

    // ベースとなる円を描画
    canvas
      ..drawCircle(deleteHandle, deleteHandleSize / 2, handlePaint)
      ..drawCircle(deleteHandle, deleteHandleSize / 2, handleBorderPaint)
      ..drawLine(bounds.bottomCenter, deleteHandleTop, handleBorderPaint);

    // 削除アイコンを描画
    final IconData deleteIcon = Icons.delete_outline;
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(deleteIcon.codePoint),
        style: TextStyle(
          fontSize: deleteHandleSize * 0.8,
          fontFamily: deleteIcon.fontFamily,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        deleteHandle.dx - textPainter.width / 2,
        deleteHandle.dy - textPainter.height / 2,
      ),
    );
  }

  /// テキスト編集ハンドルを描画する
  ///
  /// [canvas] 描画対象のキャンバス
  /// [bounds] オブジェクトのバウンディングボックス
  void _drawEditHandle(Canvas canvas, Rect bounds) {
    final Paint handlePaint = Paint()
      ..color = handleFillColor
      ..style = PaintingStyle.fill;

    final Paint handleBorderPaint = Paint()
      ..color = editHandleColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = handleBorderWidth;

    // 編集ハンドルの位置（右中央に配置）
    final Offset editHandle = Offset(bounds.right + 20, bounds.center.dy);
    final Offset editHandleLeft = Offset(editHandle.dx - 12, editHandle.dy);

    /// ハンドルのサイズ(Iconsを表示するので大きめに設定)
    final double editHandleSize = 24;

    // ベースとなる円を描画
    canvas
      ..drawCircle(editHandle, editHandleSize / 2, handlePaint)
      ..drawCircle(editHandle, editHandleSize / 2, handleBorderPaint)
      ..drawLine(bounds.centerRight, editHandleLeft, handleBorderPaint);

    // 編集アイコンを描画
    final IconData editIcon = Icons.edit;
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(editIcon.codePoint),
        style: TextStyle(
          fontSize: editHandleSize * 0.8,
          fontFamily: editIcon.fontFamily,
          color: editHandleColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        editHandle.dx - textPainter.width / 2,
        editHandle.dy - textPainter.height / 2,
      ),
    );
  }
}
