import '../../objects/drawable_object.dart';
import '../object_serializer.dart';
import 'image_object_serializer.dart';
import 'path_object_serializer.dart';
import 'shape_object_serializer.dart';

/// DrawableObjectのシリアライズを担当するクラス
///
/// 描画可能なオブジェクトの共通プロパティ（位置、回転、スケール）のシリアライズと、
/// オブジェクト固有のデータのシリアライズを管理します。
///
/// シリアライズされたデータは以下の構造を持ちます：
/// ```json
/// {
///   "type": "オブジェクトの種類（path, shape, imageなど）",
///   "version": 1,
///   "properties": {
///     "globalCenter": {
///       "x": 中心位置のX座標,
///       "y": 中心位置のY座標
///     },
///     "rotation": 回転角度（ラジアン）,
///     "scale": スケール値
///   },
///   "data": オブジェクト固有のデータ（各Serializerで定義）
/// }
/// ```
///
/// サブクラスのシリアライザは、`ObjectSerializer`を実装し、
/// オブジェクト固有のデータのシリアライズを担当します。
/// - [PathObjectSerializer]: パスオブジェクトのシリアライズ
/// - [ShapeObjectSerializer]: 図形オブジェクトのシリアライズ
/// - [ImageObjectSerializer]: 画像オブジェクトのシリアライズ
class DrawableObjectSerializer extends ObjectSerializer<DrawableObject> {
  /// DrawableObjectSerializerのシングルトンインスタンス
  static const DrawableObjectSerializer instance = DrawableObjectSerializer._();

  const DrawableObjectSerializer._();

  @override
  Future<Map<String, dynamic>> toJson(DrawableObject object) async {
    return {
      'type': object.type,
      'version': 1, // バージョン管理のため追加
      'properties': object.toSerializableMap(),
      'data': await object.serializer.toJson(object),
    };
  }

  /// JSONからDrawableObjectを復元します。
  ///
  /// [json] 復元対象のJSONデータ。[toJson]メソッドで生成された形式に従う必要があります。
  ///
  /// 以下の場合に[FormatException]をスローします：
  /// - バージョンが不正な場合
  /// - オブジェクトの種類が不明な場合
  /// - 必要なプロパティが存在しない場合
  /// - プロパティの型が不正な場合
  @override
  Future<DrawableObject> fromJson(Map<String, dynamic> json) async {
    // バージョンチェック
    final version = json['version'] as int;
    if (version != 1) {
      throw FormatException('Unsupported version: $version');
    }

    final type = json['type'] as String;
    final properties = json['properties'] as Map<String, dynamic>;
    final data = json['data'] as Map<String, dynamic>;

    // 型に応じたシリアライザを取得
    final specificSerializer = _getSerializerForType(type);

    // オブジェクトの復元
    final object = await specificSerializer.fromJson(data);

    // 共通プロパティの復元
    if (object is DrawableObject) {
      object.fromSerializableMap(properties);
      return object;
    }

    throw FormatException('Invalid object type: $type');
  }

  /// オブジェクトの種類に応じたシリアライザを取得します。
  ///
  /// [type] オブジェクトの種類を表す文字列
  /// Returns: オブジェクトの種類に対応するシリアライザ
  /// Throws: [FormatException] 不明なオブジェクトの種類が指定された場合
  ObjectSerializer _getSerializerForType(String type) {
    switch (type) {
      case 'path':
        return PathObjectSerializer.instance;
      case 'shape':
        return ShapeObjectSerializer.instance;
      case 'image':
        return ImageObjectSerializer.instance;
      default:
        throw FormatException('Unknown object type: $type');
    }
  }
}
