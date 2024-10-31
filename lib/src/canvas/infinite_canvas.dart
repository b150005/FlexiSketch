import 'dart:developer' as developer;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../flexi_sketch_controller.dart';
import 'canvas_painter.dart';

/// 無限キャンバスウィジェット
///
/// パン・ズーム可能な描画キャンバスを提供します。
/// オブジェクトの選択・移動などの操作機能を備えています。
class InfiniteCanvas extends StatefulWidget {
  /// キャンバスの状態を管理するコントローラ
  final FlexiSketchController controller;

  const InfiniteCanvas({super.key, required this.controller});

  @override
  State<InfiniteCanvas> createState() => _InfiniteCanvasState();
}

class _InfiniteCanvasState extends State<InfiniteCanvas> {
  /// キャンバスの変換(移動、拡大・縮小)を管理するコントローラ
  late TransformationController _transformationController;

  /// 最後のタッチ・マウス位置
  Offset _lastFocalPoint = Offset.zero;

  /// 最後のスケール値
  double _lastScale = 1.0;

  /// ドラッグ操作中かどうか
  bool _isDragging = false;

  /// 現在捜査中のハンドルの種類
  _HandleType? _activeHandle;

  // マウスホイールのズーム感度(大きいほど敏感)
  static const double _mouseWheelZoomSensitivity = 0.002;

  /// 最小ズーム倍率
  static const double _minScale = 0.1;

  /// 最大ズーム倍率
  static const double _maxScale = 5.0;

  /// オブジェクト操作ハンドルのサイズ(px)
  static const double _handleSize = 12.0;

  /// ハンドルの判定範囲(px)
  static const double _handleHitArea = 20.0;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: (PointerSignalEvent event) {
        if (event is PointerScrollEvent) {
          _handleMouseWheel(event);
        }
      },
      child: GestureDetector(
        onScaleStart: _handleScaleStart,
        onScaleUpdate: _handleScaleUpdate,
        onScaleEnd: _handleScaleEnd,
        child: MouseRegion(
          cursor: _getCursor(),
          child: CustomPaint(
            painter: CanvasPainter(
              controller: widget.controller,
              transform: _transformationController.value,
              handleSize: _handleSize,
            ),
            child: Transform(
              transform: _transformationController.value,
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
  }

  /// コントローラの状態変更時に呼び出されるコールバック
  void _onControllerChanged() {
    setState(() {});
  }

  /// 現在の状態に応じたマウスカーソルを取得する
  MouseCursor _getCursor() {
    if (widget.controller.isToolSelected) {
      return SystemMouseCursors.precise;
    }

    switch (_activeHandle) {
      case _HandleType.topLeft:
      case _HandleType.bottomRight:
        return SystemMouseCursors.resizeUpLeftDownRight;
      case _HandleType.topRight:
      case _HandleType.bottomLeft:
        return SystemMouseCursors.resizeUpRightDownLeft;
      case _HandleType.rotate:
        return SystemMouseCursors.alias;
      case _HandleType.delete:
        return SystemMouseCursors.click;
      default:
        if (_isDragging) {
          return SystemMouseCursors.grabbing;
        }
        if (widget.controller.hasSelection) {
          return SystemMouseCursors.move;
        }
        return SystemMouseCursors.grab;
    }
  }

  /// 指定された点に存在するハンドルの種類を取得する
  ///
  /// [point] 判定対象の点の座標
  /// Returns: ハンドルの種類(ハンドルが存在しない場合は `null`)
  _HandleType? _getHandleAtPoint(Offset point) {
    if (!widget.controller.hasSelection) return null;

    final selectedObject = widget.controller.selectedObject!;
    final bounds = selectedObject.bounds;

    // 各ハンドルの位置
    final handlePositions = {
      _HandleType.topLeft: bounds.topLeft,
      _HandleType.topRight: bounds.topRight,
      _HandleType.bottomLeft: bounds.bottomLeft,
      _HandleType.bottomRight: bounds.bottomRight,
      _HandleType.rotate: Offset(bounds.center.dx, bounds.top - 20),
      _HandleType.delete: Offset(bounds.center.dx, bounds.bottom + 20),
    };

    // 変換行列を適用した座標でハンドルを判定
    for (final entry in handlePositions.entries) {
      // オブジェクトのローカル座標をスクリーン座標に変換
      final handlePos = _transformLocalPointToScreen(entry.value);
      final distance = (point - handlePos).distance;

      if (distance <= _handleHitArea) {
        return entry.key;
      }
    }

    return null;
  }

  /// オブジェクトのローカル座標をスクリーン座標に変換するヘルパーメソッド
  Offset _transformLocalPointToScreen(Offset localPoint) {
    final matrix = _transformationController.value;
    final transformed = MatrixUtils.transformPoint(matrix, localPoint);
    return transformed;
  }

  /// スケール操作が開始されたときに呼ばれるコールバック
  ///
  /// [details] スケール開始時の詳細情報
  void _handleScaleStart(ScaleStartDetails details) {
    // 現在の焦点位置を保存
    _lastFocalPoint = details.localFocalPoint;
    // スケールの初期値を設定
    _lastScale = 1.0;
    _isDragging = true;

    if (details.pointerCount == 1) {
      // 焦点位置をシーン座標に変換
      final localPosition = _transformationController.toScene(details.localFocalPoint);

      if (widget.controller.isToolSelected) {
        widget.controller.startDrawing(localPosition);
      } else {
        // ハンドルの判定
        _activeHandle = _getHandleAtPoint(details.localFocalPoint);

        // ハンドル上でない場合はオブジェクトの選択を試行
        if (_activeHandle == null) {
          widget.controller.selectObject(localPosition);
        }
      }
    }
  }

  /// スケール操作が更新されたときに呼ばれるコールバック
  void _handleScaleUpdate(ScaleUpdateDetails details) {
    // ツールが選択されていて、ポインタが1つの場合
    if (widget.controller.isToolSelected && details.pointerCount == 1) {
      // 焦点位置をシーン座標に変換
      final localPosition = _transformationController.toScene(details.localFocalPoint);
      // 描画ポイントを追加
      widget.controller.addPoint(localPosition);
    }
    // 指がハンドル上にあり、オブジェクトが選択されている場合
    else if (_activeHandle != null && widget.controller.hasSelection) {
      _handleObjectTransform(details);
    }
    // オブジェクトが選択されており、1本指で操作する場合
    else if (widget.controller.hasSelection && details.pointerCount == 1) {
      // オブジェクトの移動
      final delta = details.localFocalPoint - _lastFocalPoint;
      final scaledDelta = delta.scale(1 / _transformationController.value.getMaxScaleOnAxis(),
          1 / _transformationController.value.getMaxScaleOnAxis());
      widget.controller.moveSelectedObject(scaledDelta);
    } else {
      // スケールの変化量を計算
      final scaleDiff = details.scale - _lastScale;
      // 現在のスケールを更新
      _lastScale = details.scale;

      // ズームのための変換行列を作成
      final scaleMatrix = Matrix4.identity()
        ..translate(details.localFocalPoint.dx, details.localFocalPoint.dy)
        ..scale(1.0 + scaleDiff)
        ..translate(-details.localFocalPoint.dx, -details.localFocalPoint.dy);

      // パンのための変換行列を作成
      final panDelta = details.localFocalPoint - _lastFocalPoint;
      final panMatrix = Matrix4.identity()..translate(panDelta.dx, panDelta.dy);

      // 変換行列を更新
      _transformationController.value = panMatrix * scaleMatrix * _transformationController.value;
    }

    // 焦点位置を更新
    _lastFocalPoint = details.localFocalPoint;

    // UIを更新
    setState(() {});
  }

  /// スケール操作が終了したときに呼ばれるコールバック
  void _handleScaleEnd(ScaleEndDetails details) {
    // if (widget.controller.isToolSelected) {
    //   widget.controller.endDrawing();
    // }
    if (_activeHandle == _HandleType.delete && widget.controller.hasSelection) {
      widget.controller.deleteSelectedObject();
    }

    _isDragging = false;
    _activeHandle = null;

    if (widget.controller.isToolSelected) {
      widget.controller.endDrawing();
    }
  }

  /// マウスホイールイベントの処理
  ///
  /// マウスホイールの回転に応じてキャンバスのズームを行います。
  /// ズーム倍率は [_minScale] から [_maxScale] の範囲に制限されます。
  ///
  /// [event] マウスホイールイベントの詳細情報
  void _handleMouseWheel(PointerScrollEvent event) {
    // 現在のスケール値を取得
    final double currentScale = _transformationController.value.getMaxScaleOnAxis();

    // スクロール量からスケール変更値を計算
    // 上にスクロール（負の値）でズームイン、下にスクロール（正の値）でズームアウト
    final double scaleChange = -event.scrollDelta.dy * _mouseWheelZoomSensitivity;

    // 新しいスケール値を計算（最小・最大値でクランプ）
    final double targetScale = (currentScale * (1 + scaleChange)).clamp(_minScale, _maxScale);

    // マウスポインタの位置を中心にズーム
    final Offset focalPoint = event.localPosition;

    // ズーム用の変換行列を作成
    final Matrix4 matrix = Matrix4.identity()
      ..translate(focalPoint.dx, focalPoint.dy)
      ..scale(targetScale / currentScale)
      ..translate(-focalPoint.dx, -focalPoint.dy);

    // 現在の変換行列に適用
    _transformationController.value = matrix * _transformationController.value;

    setState(() {});
  }

  /// オブジェクトの変換処理
  ///
  /// [details] スケール更新時の詳細情報
  void _handleObjectTransform(ScaleUpdateDetails details) {
    if (!widget.controller.hasSelection) return;

    final selectedObject = widget.controller.selectedObject!;
    final bounds = selectedObject.bounds;
    final center = bounds.center;

    switch (_activeHandle) {
      case _HandleType.topLeft:
      case _HandleType.topRight:
      case _HandleType.bottomLeft:
      case _HandleType.bottomRight:
        // リサイズ処理
        final initialDistance = (_lastFocalPoint - _transformLocalPointToScreen(center)).distance;
        final currentDistance = (details.localFocalPoint - _transformLocalPointToScreen(center)).distance;
        final scale = currentDistance / initialDistance;

        widget.controller.resizeSelectedObject(scale);
        break;

      case _HandleType.rotate:
        // 回転処理
        final screenCenter = _transformLocalPointToScreen(center);
        final lastAngle = (_lastFocalPoint - screenCenter).direction;
        final currentAngle = (details.localFocalPoint - screenCenter).direction;
        final rotation = currentAngle - lastAngle;

        widget.controller.rotateSelectedObject(rotation);
        break;

      case _HandleType.delete:
        // 削除処理(ドラッグ中は何もしない)
        break;

      default:
        break;
    }
  }
}

/// オブジェクト操作用ハンドルの種類
enum _HandleType {
  /// 左上のリサイズハンドル
  topLeft,

  /// 右上のリサイズハンドル
  topRight,

  /// 左下のリサイズハンドル
  bottomLeft,

  /// 右下のリサイズハンドル
  bottomRight,

  /// 回転ハンドル
  rotate,

  /// 削除ハンドル
  delete,
}
