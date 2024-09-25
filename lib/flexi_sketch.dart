// You have generated a new plugin project without specifying the `--platforms`
// flag. A plugin project with no platform support was generated. To add a
// platform, run `flutter create -t plugin --platforms <platforms> .` under the
// same directory. You can also find a detailed instruction on how to add
// platforms in the `pubspec.yaml` at
// https://flutter.dev/to/pubspec-plugin-platforms.

library flexi_sketch;

import 'flexi_sketch_platform_interface.dart';

export 'src/widgets/flexi_sketch_widget.dart';
export 'flexi_sketch_controller.dart';

class FlexiSketch {
  Future<String?> getPlatformVersion() {
    return FlexiSketchPlatform.instance.getPlatformVersion();
  }
}
