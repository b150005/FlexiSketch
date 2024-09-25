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
  bool _isDrawing = false;

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
    setState(() {
      _transformationController.value = Matrix4.identity()..scale(widget.controller.scale);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerUp,
      child: InteractiveViewer(
        transformationController: _transformationController,
        boundaryMargin: const EdgeInsets.all(double.infinity),
        minScale: 0.1,
        maxScale: 10.0,
        panEnabled: !_isDrawing,
        scaleEnabled: !_isDrawing,
        child: CustomPaint(
          painter: CanvasPainter(controller: widget.controller),
          size: Size.infinite,
        ),
      ),
    );
  }

  void _handlePointerDown(PointerDownEvent event) {
    final localPosition = _transformationController.toScene(event.localPosition);
    setState(() {
      _isDrawing = true;
    });
    widget.controller.startDrawing(localPosition);
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (_isDrawing) {
      final localPosition = _transformationController.toScene(event.localPosition);
      widget.controller.addPoint(localPosition);
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (_isDrawing) {
      widget.controller.endDrawing();
      setState(() {
        _isDrawing = false;
      });
    }
  }
}