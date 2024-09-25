import 'package:flutter/material.dart';

import '../../flexi_sketch_controller.dart';
import 'drawing_tool.dart';

class EraserTool implements DrawingTool {
  @override
  void startDrawing(Offset point, FlexiSketchController controller) {
    controller.startErasing(point);
  }

  @override
  void continueDrawing(Offset point, FlexiSketchController controller) {
    controller.continueErasing(point);
  }

  @override
  void endDrawing(FlexiSketchController controller) {
    controller.endErasing();
  }

  @override
  Paint createPaint(Color color, double strokeWidth) {
    return Paint()
      ..color = Colors.white // 消しゴムの色を白に設定
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..blendMode = BlendMode.clear; // 消しゴム効果を得るためにBlendMode.clearを使用
  }
}