import 'package:flutter/material.dart';

import '../../flexi_sketch_controller.dart';

class CanvasPainter extends CustomPainter {
  final FlexiSketchController controller;

  CanvasPainter({required this.controller}) : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    // Draw grid
    _drawGrid(canvas, size);

    // Draw all objects
    for (var object in controller.objects) {
      object.draw(canvas);
    }

    // Draw current path if any
    if (controller.currentPath != null) {
      controller.currentPath!.draw(canvas);
    }

    // Draw current shape if any
    if (controller.currentShape != null) {
      controller.currentShape!.draw(canvas);
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.5)
      ..strokeWidth = 0.5;

    for (double i = 0; i < size.width; i += 20) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    for (double i = 0; i < size.height; i += 20) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}