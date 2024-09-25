import 'package:flutter/material.dart';

import '../../flexi_sketch_controller.dart';
import 'drawing_tool.dart';

class MarkerTool implements DrawingTool {
  @override
  void startDrawing(Offset point, FlexiSketchController controller) {
    controller.startPath(point, blendMode: BlendMode.multiply);
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
      ..color = color.withOpacity(0.3) // 透明度を0.3に設定（0.0が完全に透明、1.0が完全に不透明）
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..blendMode = BlendMode.multiply;
  }
}