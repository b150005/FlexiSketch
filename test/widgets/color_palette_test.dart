import 'package:flexi_sketch/flexi_sketch_controller.dart';
import 'package:flexi_sketch/src/widgets/color_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ColorPalette has all color buttons', (WidgetTester tester) async {
    final controller = FlexiSketchController();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: ColorPalette(controller: controller)),
    ));

    expect(find.byType(GestureDetector), findsNWidgets(6)); // 6 色のボタン
  });

  testWidgets('ColorPalette changes color when button is tapped', (WidgetTester tester) async {
    final controller = FlexiSketchController();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: ColorPalette(controller: controller)),
    ));

    await tester.tap(find.byType(GestureDetector).at(1)); // 2番目の色（赤）をタップ
    await tester.pump(); // ウィジェットツリーを再構築

    expect(controller.currentColor, equals(Colors.red));
  });

  testWidgets('ColorPalette animates on appearance', (WidgetTester tester) async {
    final controller = FlexiSketchController();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: ColorPalette(controller: controller)),
    ));

    // 初期状態（アニメーション開始時）をチェック
    var scale = tester.widget<ScaleTransition>(find.byType(ScaleTransition).first).scale.value;
    expect(scale, lessThan(1));

    // アニメーション終了後の状態をチェック
    await tester.pumpAndSettle();
    scale = tester.widget<ScaleTransition>(find.byType(ScaleTransition).first).scale.value;
    expect(scale, equals(1));
  });
}