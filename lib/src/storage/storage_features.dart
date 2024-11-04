import 'package:flutter/material.dart';

import '../objects/drawable_object.dart';
import 'sketch_storage.dart';

/// FlexiSketchControllerに保存機能を追加するMixin
mixin StorageFeatures on ChangeNotifier {
  /// スケッチの保存・読み込みを担当するストレージ
  SketchStorage? _storage;

  /// 現在のスケッチのメタデータ
  SketchMetadata? _metadata;

  /// 描画オブジェクトのリスト
  /// 
  /// この getter は FlexiSketchController で実装される必要があります。
  List<DrawableObject> get objects;

  /// 描画オブジェクトのリストを設定する
  /// この setter は FlexiSketchController で実装される必要があります。
  set objects(List<DrawableObject> value);

  /// 現在のストレージインスタンスを取得する
  SketchStorage? get storage => _storage;

  /// 現在のメタデータを取得する
  SketchMetadata? get metadata => _metadata;

  /// ストレージを設定する
  ///
  /// [storage] 設定するストレージインスタンス
  void setStorage(SketchStorage storage) {
    _storage = storage;
    notifyListeners();
  }

  /// 現在のスケッチのメタデータを設定する
  ///
  /// [metadata] 設定するメタデータ
  void setMetadata(SketchMetadata metadata) {
    _metadata = metadata;
    notifyListeners();
  }

  /// スケッチを保存する
  ///
  /// [asImage] trueの場合、画像として保存します
  /// [title] スケッチのタイトル（新規保存時のみ使用）
  /// Returns: 保存されたスケッチのメタデータ
  /// Throws: ストレージが設定されていない場合に例外をスローします
  Future<SketchMetadata> saveSketch({
    bool asImage = false,
    String? title,
  }) async {
    if (_storage == null) {
      throw Exception('Storage is not set');
    }

    final metadata = _metadata ?? SketchMetadata.create(title ?? 'Untitled Sketch');
    final data = SketchData(
      metadata: metadata,
      objects: List.from(objects),
    );

    final savedMetadata = await _storage!.saveSketch(data, asImage: asImage);
    _metadata = savedMetadata;
    notifyListeners();
    return savedMetadata;
  }

  /// スケッチを読み込む
  ///
  /// [id] 読み込むスケッチのID
  /// Throws: ストレージが設定されていない場合に例外をスローします
  Future<void> loadSketch(String id) async {
    if (_storage == null) {
      throw Exception('Storage is not set');
    }

    final data = await _storage!.loadSketch(id);
    _metadata = data.metadata;
    objects = data.objects;
    notifyListeners();
  }
}
