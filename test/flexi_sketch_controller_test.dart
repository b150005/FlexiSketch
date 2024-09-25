import 'package:flexi_sketch/flexi_sketch_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  late FlexiSketchController controller;

  setUp(() {
    controller = FlexiSketchController();
  });

  test('Controller initializes with empty objects list', () {
    expect(controller.objects, isEmpty);
  });

  test('Controller adds object when drawing ends', () {
    controller.startPath(Offset.zero);
    controller.addPointToPath(const Offset(10, 10));
    controller.endPath();

    expect(controller.objects.length, 1);
  });

  test('Controller changes color', () {
    const newColor = Colors.red;
    controller.setColor(newColor);

    expect(controller.currentColor, newColor);
  });

  test('Controller changes stroke width', () {
    const newWidth = 5.0;
    controller.setStrokeWidth(newWidth);

    expect(controller.currentStrokeWidth, newWidth);
  });

  test('Controller clears all objects', () {
    controller.startPath(Offset.zero);
    controller.addPointToPath(const Offset(10, 10));
    controller.endPath();

    expect(controller.objects.length, 1);

    controller.clear();

    expect(controller.objects, isEmpty);
  });
}