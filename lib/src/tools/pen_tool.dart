import 'package:flutter/material.dart';

import '../../flexi_sketch_controller.dart';
import 'drawing_tool.dart';

class PenTool implements DrawingTool {
  @override
  void startDrawing(Offset point, FlexiSketchController controller) {
    controller.startPath(point);
  }

  @override
  void continueDrawing(Offset point, FlexiSketchController controller) {
    controller.addPointToPath(point);
  }

  @override
  void endDrawing(FlexiSketchController controller) {
    controller.endPath();
  }

  @override
  Paint createPaint(Color color, double strokeWidth) {
    return Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round // 線の端を丸くする
      ..strokeJoin = StrokeJoin.round; // 線の接合部も丸くする
  }
}