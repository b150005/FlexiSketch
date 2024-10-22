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

  void _handleScaleStart(ScaleStartDetails details) {
    _lastFocalPoint = details.localFocalPoint;
    _lastScale = 1.0;
    if (widget.controller.isToolSelected && details.pointerCount == 1) {
      final localPosition = _transformationController.toScene(details.localFocalPoint);
      widget.controller.startDrawing(localPosition);
    }
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (widget.controller.isToolSelected && details.pointerCount == 1) {
      final localPosition = _transformationController.toScene(details.localFocalPoint);
      widget.controller.addPoint(localPosition);
    } else {
      final scaleDiff = details.scale - _lastScale;
      _lastScale = details.scale;

      final scaleMatrix = Matrix4.identity()
        ..translate(details.localFocalPoint.dx, details.localFocalPoint.dy)
        ..scale(1.0 + scaleDiff)
        ..translate(-details.localFocalPoint.dx, -details.localFocalPoint.dy);

      final panDelta = details.localFocalPoint - _lastFocalPoint;
      final panMatrix = Matrix4.identity()..translate(panDelta.dx, panDelta.dy);

      _transformationController.value = panMatrix * scaleMatrix * _transformationController.value;
      _lastFocalPoint = details.localFocalPoint;
    }

    setState(() {});
  }

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
