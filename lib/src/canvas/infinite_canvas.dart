import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../flexi_sketch_controller.dart';
import 'canvas_painter.dart';

class InfiniteCanvas extends StatefulWidget {
  final FlexiSketchController controller;

  const InfiniteCanvas({super.key, required this.controller});

  @override
  State<InfiniteCanvas> createState() => _InfiniteCanvasState();
}

class _InfiniteCanvasState extends State<InfiniteCanvas> {
  late TransformationController _transformationController;
  Offset _lastFocalPoint = Offset.zero;
  double _lastScale = 1.0;

  // マウスホイールのズーム感度(大きいほど敏感)
  static const double _mouseWheelZoomSensitivity = 0.002;
  // 最小・最大ズーム倍率
  static const double _minScale = 0.1;
  static const double _maxScale = 5.0;

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
        child: CustomPaint(
          painter: CanvasPainter(
            controller: widget.controller,
            transform: _transformationController.value,
          ),
          child: Transform(
            transform: _transformationController.value,
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }

  void _onControllerChanged() {
    setState(() {});
  }

  /// スケール操作が開始されたときに呼ばれるコールバック
  ///
  /// [details]には、スケール操作の開始時の詳細情報が含まれています。
  /// ツールが選択されている場合、描画を開始します。
  void _handleScaleStart(ScaleStartDetails details) {
    // 現在の焦点位置を保存
    _lastFocalPoint = details.localFocalPoint;
    // スケールの初期値を設定
    _lastScale = 1.0;

    if (widget.controller.isToolSelected && details.pointerCount == 1) {
      // 焦点位置をシーン座標に変換
      final localPosition = _transformationController.toScene(details.localFocalPoint);
      // 描画を開始
      widget.controller.startDrawing(localPosition);
    }
  }

  /// スケール操作が更新されたときに呼ばれるコールバック
  ///
  /// [details]には、スケール操作の更新時の詳細情報が含まれています。
  /// ツールが選択されている場合、描画ポイントを追加します。
  /// ツールが選択されていない場合、ズームやパンの操作を処理します。
  void _handleScaleUpdate(ScaleUpdateDetails details) {
    // ツールが選択されていて、ポインタが1つの場合
    if (widget.controller.isToolSelected && details.pointerCount == 1) {
      // 焦点位置をシーン座標に変換
      final localPosition = _transformationController.toScene(details.localFocalPoint);
      // 描画ポイントを追加
      widget.controller.addPoint(localPosition);
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
      // 焦点位置を更新
      _lastFocalPoint = details.localFocalPoint;
    }

    // UIを更新
    setState(() {});
  }

  /// スケール操作が終了したときに呼ばれるコールバック
  ///
  /// ツールが選択されている場合、描画を終了します。
  void _handleScaleEnd(ScaleEndDetails details) {
    if (widget.controller.isToolSelected) {
      widget.controller.endDrawing();
    }
  }

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
}
