// You have generated a new plugin project without specifying the `--platforms`
// flag. A plugin project with no platform support was generated. To add a
// platform, run `flutter create -t plugin --platforms <platforms> .` under the
// same directory. You can also find a detailed instruction on how to add
// platforms in the `pubspec.yaml` at
// https://flutter.dev/to/pubspec-plugin-platforms.

import 'flexi_sketch_platform_interface.dart';

// Widget
export 'src/widgets/flexi_sketch_widget.dart';

// Controller
export 'flexi_sketch_controller.dart';

// Handler
export 'src/handlers/save_handler.dart';

/// シリアライザ
export 'src/serialization/serializers/drawable_object_serializer.dart' show DrawableObjectSerializer;

// データ変換のヘルパークラス
export 'src/utils/flexi_sketch_data_helper.dart';

// SketchStorageとその関連クラス
export 'src/storage/sketch_data.dart' show SketchData, SketchMetadata;

/// FlexiSketchプラグインのプラットフォーム固有の機能を提供するクラス
class FlexiSketch {
  /// 現在のプラットフォームのバージョン情報を取得します
  Future<String?> getPlatformVersion() {
    return FlexiSketchPlatform.instance.getPlatformVersion();
  }
}
