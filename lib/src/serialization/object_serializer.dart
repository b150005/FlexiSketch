import 'dart:async';

/// シリアライズ可能なオブジェクトを表すインターフェース
abstract class Serializable {
  /// オブジェクトの種類を表す文字列
  String get type;

  /// シリアライザを取得する
  ObjectSerializer get serializer;
}

/// オブジェクトのシリアライズを担当する基底クラス
abstract class ObjectSerializer<T extends Serializable> {
  const ObjectSerializer();

  /// オブジェクトをJSONに変換する
  ///
  /// 画像データのエンコードなど、非同期処理が必要な場合があるため `FutureOr` 型を返すように変更
  FutureOr<Map<String, dynamic>> toJson(T object);

  /// JSONからオブジェクトを復元する
  FutureOr<T> fromJson(Map<String, dynamic> json);
}
