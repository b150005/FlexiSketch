import 'package:flexi_sketch/flexi_sketch_controller.dart';
import 'package:flexi_sketch/src/tools/marker_tool.dart';
import 'package:flexi_sketch/src/tools/shape_tool.dart';
import 'package:flexi_sketch/src/widgets/toolbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Toolbar has all tool buttons', (WidgetTester tester) async {
    final controller = FlexiSketchController();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Toolbar(controller: controller)),
    ));

    expect(find.byIcon(Icons.edit), findsOneWidget);
    expect(find.byIcon(Icons.brush), findsOneWidget);
    expect(find.byIcon(Icons.crop_square), findsOneWidget);
    expect(find.byIcon(Icons.circle_outlined), findsOneWidget);
    expect(find.byIcon(Icons.delete), findsOneWidget);
  });

  testWidgets('Toolbar changes tool when button is pressed', (WidgetTester tester) async {
    final controller = FlexiSketchController();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Toolbar(controller: controller)),
    ));

    await tester.tap(find.byIcon(Icons.brush));
    expect(controller.currentTool, isA<MarkerTool>());

    await tester.tap(find.byIcon(Icons.crop_square));
    expect(controller.currentTool, isA<ShapeTool>());
    expect((controller.currentTool as ShapeTool).shapeType, equals(ShapeType.rectangle));

    await tester.tap(find.byIcon(Icons.circle_outlined));
    expect(controller.currentTool, isA<ShapeTool>());
    expect((controller.currentTool as ShapeTool).shapeType, equals(ShapeType.circle));
  });

  testWidgets('Toolbar animates on appearance', (WidgetTester tester) async {
    final controller = FlexiSketchController();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Toolbar(controller: controller)),
    ));

    // 初期状態（アニメーション開始時）をチェック
    var transform = tester.widget<SlideTransition>(find.byType(SlideTransition)).position.value;
    expect(transform.dy, lessThan(0));

    // アニメーション終了後の状態をチェック
    await tester.pumpAndSettle();
    transform = tester.widget<SlideTransition>(find.byType(SlideTransition)).position.value;
    expect(transform.dy, equals(0));
  });

  testWidgets('Toolbar button changes color when selected', (WidgetTester tester) async {
    final controller = FlexiSketchController();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Toolbar(controller: controller)),
    ));

    // 初期状態をチェック
    var container = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer).first);
    expect(container.decoration, isA<BoxDecoration>().having((d) => d.color, 'color', Colors.transparent));

    // ボタンをタップ
    await tester.tap(find.byType(IconButton).first);
    await tester.pumpAndSettle();

    // タップ後の状態をチェック
    container = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer).first);
    expect(container.decoration, isA<BoxDecoration>().having((d) => d.color, 'color', Colors.blue.withOpacity(0.2)));
  });
}