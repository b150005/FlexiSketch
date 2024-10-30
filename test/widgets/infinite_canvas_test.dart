import 'package:flexi_sketch/src/objects/shape_object.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flexi_sketch/flexi_sketch.dart';
import 'package:flexi_sketch/src/canvas/infinite_canvas.dart';
import 'package:flexi_sketch/src/tools/shape_tool.dart';

void main() {
  testWidgets('InfiniteCanvas can draw shapes', (WidgetTester tester) async {
    final controller = FlexiSketchController();
    controller.setTool(ShapeTool(shapeType: ShapeType.rectangle));

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: InfiniteCanvas(controller: controller)),
    ));

    final gesture = await tester.startGesture(const Offset(0, 0));
    await gesture.moveTo(const Offset(100, 100));
    await tester.pump();

    expect(controller.currentShape, isNotNull);
    expect(controller.currentShape!.startPoint, equals(const Offset(0, 0)));
    expect(controller.currentShape!.endPoint, equals(const Offset(100, 100)));

    await gesture.up();
    await tester.pump();

    expect(controller.objects.length, equals(1));
    expect(controller.objects.first, isA<ShapeObject>());
  });

  testWidgets('InfiniteCanvas updates shape preview during drag', (WidgetTester tester) async {
    final controller = FlexiSketchController();
    controller.setTool(ShapeTool(shapeType: ShapeType.circle));

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: InfiniteCanvas(controller: controller)),
    ));

    final gesture = await tester.startGesture(const Offset(0, 0));
    await gesture.moveTo(const Offset(50, 50));
    await tester.pump();

    expect(controller.currentShape, isNotNull);
    expect(controller.currentShape!.startPoint, equals(const Offset(0, 0)));
    expect(controller.currentShape!.endPoint, equals(const Offset(50, 50)));

    await gesture.moveTo(const Offset(100, 100));
    await tester.pump();

    expect(controller.currentShape!.endPoint, equals(const Offset(100, 100)));

    await gesture.up();
    await tester.pump();

    expect(controller.objects.length, equals(1));
    expect(controller.objects.first, isA<ShapeObject>());
  });
}
