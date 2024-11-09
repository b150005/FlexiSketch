import 'object_serializer.dart';

/// シリアライズ可能なオブジェクトを表すインターフェース
abstract class Serializable {
  /// オブジェクトの種類を表す文字列
  String get type;

  /// シリアライザを取得する
  ObjectSerializer get serializer;
}
