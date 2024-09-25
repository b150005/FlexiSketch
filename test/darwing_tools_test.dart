import 'package:flexi_sketch/flexi_sketch_controller.dart';
import 'package:flexi_sketch/src/objects/drawable_object.dart';
import 'package:flexi_sketch/src/tools/eraser_tool.dart';
import 'package:flexi_sketch/src/tools/marker_tool.dart';
import 'package:flexi_sketch/src/tools/pen_tool.dart';
import 'package:flexi_sketch/src/tools/shape_tool.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  late FlexiSketchController controller;

  setUp(() {
    controller = FlexiSketchController();
  });

  test('PenTool creates a path object', () {
    final penTool = PenTool();
    penTool.startDrawing(Offset.zero, controller);
    penTool.continueDrawing(const Offset(10, 10), controller);
    penTool.endDrawing(controller);

    expect(controller.objects.length, 1);
    expect(controller.objects.first, isA<PathObject>());
  });

  test('MarkerTool creates a path object with blend mode', () {
    final markerTool = MarkerTool();
    markerTool.startDrawing(Offset.zero, controller);
    markerTool.continueDrawing(const Offset(10, 10), controller);
    markerTool.endDrawing(controller);

    expect(controller.objects.length, 1);
    expect(controller.objects.first, isA<PathObject>());
    expect((controller.objects.first as PathObject).paint.blendMode, BlendMode.multiply);
  });

  test('EraserTool removes intersecting objects', () {
    // Add a path object
    controller.startPath(Offset.zero);
    controller.addPointToPath(const Offset(10, 10));
    controller.endPath();

    expect(controller.objects.length, 1);

    final eraserTool = EraserTool();
    eraserTool.startDrawing(Offset.zero, controller);
    eraserTool.continueDrawing(const Offset(10, 10), controller);
    eraserTool.endDrawing(controller);

    expect(controller.objects.length, 0);
  });

  test('ShapeTool creates a rectangle', () {
    final shapeTool = ShapeTool(ShapeType.rectangle);
    shapeTool.startDrawing(Offset.zero, controller);
    shapeTool.continueDrawing(const Offset(100, 100), controller);
    shapeTool.endDrawing(controller);

    expect(controller.objects.length, 1);
    expect(controller.objects.first, isA<ShapeObject>());
    expect((controller.objects.first as ShapeObject).shapeType, ShapeType.rectangle);
  });

  test('ShapeTool creates a circle', () {
    final shapeTool = ShapeTool(ShapeType.circle);
    shapeTool.startDrawing(Offset.zero, controller);
    shapeTool.continueDrawing(const Offset(100, 100), controller);
    shapeTool.endDrawing(controller);

    expect(controller.objects.length, 1);
    expect(controller.objects.first, isA<ShapeObject>());
    expect((controller.objects.first as ShapeObject).shapeType, ShapeType.circle);
  });
}