import 'package:flexi_sketch/flexi_sketch_controller.dart';
import 'package:flexi_sketch/src/canvas/infinite_canvas.dart';
import 'package:flexi_sketch/src/tools/shape_tool.dart';
import 'package:flexi_sketch/src/widgets/color_palette.dart';
import 'package:flexi_sketch/src/widgets/flexi_sketch_widget.dart';
import 'package:flexi_sketch/src/widgets/stroke_width_slider.dart';
import 'package:flexi_sketch/src/widgets/toolbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FlexiSketchWidget has all required components', (WidgetTester tester) async {
    final controller = FlexiSketchController();

    await tester.pumpWidget(MaterialApp(
      home: FlexiSketchWidget(controller: controller),
    ));

    expect(find.byType(Toolbar), findsOneWidget);
    expect(find.byType(InfiniteCanvas), findsOneWidget);
    expect(find.byType(ColorPalette), findsOneWidget);
    expect(find.byType(StrokeWidthSlider), findsOneWidget);
  });

  testWidgets('FlexiSketchWidget can switch between drawing tools', (WidgetTester tester) async {
    final controller = FlexiSketchController();

    await tester.pumpWidget(MaterialApp(
      home: FlexiSketchWidget(controller: controller),
    ));

    // Find and tap the rectangle tool button
    await tester.tap(find.byIcon(Icons.crop_square));
    await tester.pump();

    expect(controller.currentTool, isA<ShapeTool>());
    expect((controller.currentTool as ShapeTool).shapeType, ShapeType.rectangle);

    // Find and tap the circle tool button
    await tester.tap(find.byIcon(Icons.circle_outlined));
    await tester.pump();

    expect(controller.currentTool, isA<ShapeTool>());
    expect((controller.currentTool as ShapeTool).shapeType, ShapeType.circle);
  });
}
