import 'package:flexi_sketch/flexi_sketch_controller.dart';
import 'package:flexi_sketch/src/widgets/stroke_width_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('StrokeWidthSlider has a slider', (WidgetTester tester) async {
    final controller = FlexiSketchController();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: StrokeWidthSlider(controller: controller)),
    ));

    expect(find.byType(Slider), findsOneWidget);
  });

  testWidgets('StrokeWidthSlider changes stroke width', (WidgetTester tester) async {
    final controller = FlexiSketchController();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: StrokeWidthSlider(controller: controller)),
    ));

    await tester.drag(find.byType(Slider), const Offset(50.0, 0.0));
    expect(controller.currentStrokeWidth, isNot(equals(2.0))); // デフォルト値から変更されていることを確認
  });

  testWidgets('StrokeWidthSlider animates on appearance', (WidgetTester tester) async {
    final controller = FlexiSketchController();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: StrokeWidthSlider(controller: controller)),
    ));

    // 初期状態（アニメーション開始時）をチェック
    var opacity = tester.widget<FadeTransition>(find.byType(FadeTransition)).opacity.value;
    expect(opacity, lessThan(1));

    // アニメーション終了後の状態をチェック
    await tester.pumpAndSettle();
    opacity = tester.widget<FadeTransition>(find.byType(FadeTransition)).opacity.value;
    expect(opacity, equals(1));
  });
}