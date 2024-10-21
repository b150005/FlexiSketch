import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

import '../../flexi_sketch_controller.dart';
import '../objects/drawable_object.dart';

class CanvasPainter extends CustomPainter {
  final FlexiSketchController controller;

 final Matrix4 transform;

  CanvasPainter({required this.controller, required this.transform}) : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(controller.scale);
    canvas.transform(transform.storage);

    // Calculate visible area
    final Rect visibleRect = _calculateVisibleRect(canvas, size);

    // Draw grid
    _drawGrid(canvas, visibleRect);

    // Draw all objects
    for (var object in controller.objects) {
      if (_isObjectVisible(object, visibleRect)) {
        object.draw(canvas);
      }
    }

    // Draw current path if any
    if (controller.currentPath != null) {
      controller.currentPath!.draw(canvas);
    }

    // Draw current shape if any
    if (controller.currentShape != null) {
      controller.currentShape!.draw(canvas);
    }

    canvas.restore();
  }

  Rect _calculateVisibleRect(Canvas canvas, Size size) {
    final Matrix4 inverseTransform = Matrix4.inverted(transform);
    final topLeft = inverseTransform.transform3(Vector3(0, 0, 0));
    final bottomRight = inverseTransform.transform3(Vector3(size.width, size.height, 0));
    return Rect.fromPoints(Offset(topLeft.x, topLeft.y), Offset(bottomRight.x, bottomRight.y));
  }

  bool _isObjectVisible(DrawableObject object, Rect visibleRect) {
    // Implement this method based on your DrawableObject implementation
    // For example, you might check if the object's bounding box intersects with the visibleRect
    return true; // Placeholder implementation
  }

  void _drawGrid(Canvas canvas, Rect visibleRect) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.5)
      ..strokeWidth = 0.5;

    const gridSize = 20.0;
    final startX = (visibleRect.left / gridSize).floor() * gridSize;
    final endX = (visibleRect.right / gridSize).ceil() * gridSize;
    final startY = (visibleRect.top / gridSize).floor() * gridSize;
    final endY = (visibleRect.bottom / gridSize).ceil() * gridSize;

    for (double x = startX; x <= endX; x += gridSize) {
      canvas.drawLine(Offset(x, visibleRect.top), Offset(x, visibleRect.bottom), paint);
    }

    for (double y = startY; y <= endY; y += gridSize) {
      canvas.drawLine(Offset(visibleRect.left, y), Offset(visibleRect.right, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CanvasPainter oldDelegate) {
    return 
      oldDelegate.controller != controller ||
      oldDelegate.transform != transform ||
      oldDelegate.controller.objects.length != controller.objects.length;
  }
}