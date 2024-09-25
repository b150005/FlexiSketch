import 'package:flutter/material.dart';

import '../../flexi_sketch_controller.dart';
import 'drawing_tool.dart';

enum ShapeType { rectangle, circle }

class ShapeTool implements DrawingTool {
  final ShapeType shapeType;

  ShapeTool(this.shapeType);

  @override
  void startDrawing(Offset point, FlexiSketchController controller) {
    controller.startShape(point, shapeType);
  }

  @override
  void continueDrawing(Offset point, FlexiSketchController controller) {
    controller.updateShape(point);
  }

  @override
  void endDrawing(FlexiSketchController controller) {
    controller.endShape();
  }

  @override
  Paint createPaint(Color color, double strokeWidth) {
    return Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
  }
}
