import 'package:flutter/material.dart';

import '../../flexi_sketch_controller.dart';

abstract class DrawingTool {
  void startDrawing(Offset point, FlexiSketchController controller);
  void continueDrawing(Offset point, FlexiSketchController controller);
  void endDrawing(FlexiSketchController controller);
  Paint createPaint(Color color, double strokeWidth);
}