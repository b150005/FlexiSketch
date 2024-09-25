import 'package:flexi_sketch/flexi_sketch_controller.dart';
import 'package:flexi_sketch/src/widgets/zoom_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class MockFlexiSketchController extends FlexiSketchController {
  bool zoomInCalled = false;
  bool zoomOutCalled = false;

  @override
  void zoomIn() {
    zoomInCalled = true;
    notifyListeners();
  }

  @override
  void zoomOut() {
    zoomOutCalled = true;
    notifyListeners();
  }
}

void main() {
  testWidgets('ZoomControls has zoom in and zoom out buttons', (WidgetTester tester) async {
    final controller = FlexiSketchController();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: ZoomControls(controller: controller)),
    ));

    expect(find.byIcon(Icons.zoom_in), findsOneWidget);
    expect(find.byIcon(Icons.zoom_out), findsOneWidget);
  });

  testWidgets('ZoomControls calls zoomIn and zoomOut methods', (WidgetTester tester) async {
    final controller = MockFlexiSketchController();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: ZoomControls(controller: controller)),
    ));

    await tester.tap(find.byIcon(Icons.zoom_in));
    expect(controller.zoomInCalled, isTrue);

    await tester.tap(find.byIcon(Icons.zoom_out));
    expect(controller.zoomOutCalled, isTrue);
  });

  testWidgets('ZoomControls animates on appearance', (WidgetTester tester) async {
    final controller = FlexiSketchController();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: ZoomControls(controller: controller)),
    ));

    // 初期状態（アニメーション開始時）をチェック
    var transform = tester.widget<SlideTransition>(find.byType(SlideTransition)).position.value;
    expect(transform.dx, greaterThan(0));

    // アニメーション終了後の状態をチェック
    await tester.pumpAndSettle();
    transform = tester.widget<SlideTransition>(find.byType(SlideTransition)).position.value;
    expect(transform.dx, equals(0));
  });
}