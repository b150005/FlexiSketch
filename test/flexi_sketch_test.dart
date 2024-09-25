import 'package:flutter_test/flutter_test.dart';
import 'package:flexi_sketch/flexi_sketch.dart';
import 'package:flexi_sketch/flexi_sketch_platform_interface.dart';
import 'package:flexi_sketch/flexi_sketch_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlexiSketchPlatform
    with MockPlatformInterfaceMixin
    implements FlexiSketchPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FlexiSketchPlatform initialPlatform = FlexiSketchPlatform.instance;

  test('$MethodChannelFlexiSketch is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlexiSketch>());
  });

  test('getPlatformVersion', () async {
    FlexiSketch flexiSketchPlugin = FlexiSketch();
    MockFlexiSketchPlatform fakePlatform = MockFlexiSketchPlatform();
    FlexiSketchPlatform.instance = fakePlatform;

    expect(await flexiSketchPlugin.getPlatformVersion(), '42');
  });
}
