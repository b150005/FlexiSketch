import 'package:flutter/material.dart';

import '../../flexi_sketch_controller.dart';
import 'drawing_tool.dart';

class TextTool implements DrawingTool {
  const TextTool();

  @override
  void startDrawing(Offset point, FlexiSketchController controller) {
    controller.startText(point);
  }

  @override
  void continueDrawing(Offset point, FlexiSketchController controller) {
    // テキストツールでは不要
  }

  @override
  void endDrawing(FlexiSketchController controller) {
    // テキストツールでは不要
  }

  @override
  Paint createPaint(Color color, double strokeWidth) {
    return Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
  }
}
