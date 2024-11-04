import 'dart:async';

/// オブジェクトのシリアライズを担当する基底クラス
abstract class ObjectSerializer<T> {
  const ObjectSerializer();

  /// オブジェクトをJSONに変換する
  Map<String, Object> toJson(T object);

  /// JSONからオブジェクトを復元する
  FutureOr<T> fromJson(Map<String, Object> json);
}