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

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleStart: _handleScaleStart,
      onScaleUpdate: _handleScaleUpdate,
      onScaleEnd: _handleScaleEnd,
      child: ClipRect(
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
      final panMatrix = Matrix4.identity()
        ..translate(panDelta.dx, panDelta.dy);

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
}