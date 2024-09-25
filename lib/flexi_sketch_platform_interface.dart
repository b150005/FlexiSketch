import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flexi_sketch_method_channel.dart';

abstract class FlexiSketchPlatform extends PlatformInterface {
  /// Constructs a FlexiSketchPlatform.
  FlexiSketchPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlexiSketchPlatform _instance = MethodChannelFlexiSketch();

  /// The default instance of [FlexiSketchPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlexiSketch].
  static FlexiSketchPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlexiSketchPlatform] when
  /// they register themselves.
  static set instance(FlexiSketchPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
