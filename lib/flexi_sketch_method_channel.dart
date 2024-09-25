import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flexi_sketch_platform_interface.dart';

/// An implementation of [FlexiSketchPlatform] that uses method channels.
class MethodChannelFlexiSketch extends FlexiSketchPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flexi_sketch');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
